import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import mysql from "mysql2/promise";
import dotenv from "dotenv";
import { z } from "zod";
import path from "path";
import { fileURLToPath } from "url";

// =========================================================================
// 1. CẤU HÌNH BIẾN MÔI TRƯỜNG (.env)
// =========================================================================
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, ".env") });

// =========================================================================
// 2. KẾT NỐI DATABASE (MariaDB / MySQL Connection Pool)
// =========================================================================
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || "fashionshop_mcp",
  password: process.env.DB_PASSWORD || "mcp_secret_pass_2026",
  database: process.env.DB_NAME || "fashionshop",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  decimalNumbers: true
});

// =========================================================================
// 3. KHỞI TẠO MCP SERVER
// =========================================================================
const server = new McpServer({
  name: "FashionShop Admin AI Copilot",
  version: "1.0.0"
});

// =========================================================================
// TOOL 1: check_low_stock
// Cảnh báo tồn kho theo biến thể (size, màu)
// =========================================================================
server.tool(
  "check_low_stock",
  "Kiểm tra và cảnh báo danh sách các biến thể sản phẩm (size, màu) có tồn kho nhỏ hơn hoặc bằng một ngưỡng nhất định.",
  {
    threshold: z
      .number()
      .int()
      .min(0)
      .max(1000)
      .default(5)
      .describe("Ngưỡng số lượng tồn kho cần cảnh báo (mặc định là 5)")
  },
  async ({ threshold }) => {
    try {
      const query = `
        SELECT 
          pv.id AS variant_id,
          p.id AS product_id,
          p.name AS product_name,
          c.name AS category_name,
          pv.size,
          pv.color,
          pv.sku,
          pv.stock_quantity,
          p.price,
          p.sale_price
        FROM product_variant pv
        JOIN product p ON pv.product_id = p.id
        JOIN category c ON p.category_id = c.id
        WHERE pv.stock_quantity <= ?
          AND pv.status = 'ACTIVE'
          AND p.status = 'ACTIVE'
        ORDER BY pv.stock_quantity ASC, p.name ASC
        LIMIT 100
      `;
      const [rows] = await pool.query(query, [threshold]);

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                count: rows.length,
                threshold,
                message:
                  rows.length === 0
                    ? `Kho hàng an toàn: Không có biến thể sản phẩm nào có tồn kho <= ${threshold}.`
                    : `Cảnh báo: Có ${rows.length} biến thể sản phẩm tồn kho thấp (<= ${threshold}):`,
                data: rows
              },
              null,
              2
            )
          }
        ]
      };
    } catch (error) {
      console.error("Lỗi khi gọi tool check_low_stock:", error);
      return {
        content: [{ type: "text", text: `Lỗi truy vấn CSDL: ${error.message}` }],
        isError: true
      };
    }
  }
);

// =========================================================================
// TOOL 2: get_revenue_summary
// Báo cáo doanh thu thực tế (đơn COMPLETED) và tổng quan các trạng thái đơn
// =========================================================================
server.tool(
  "get_revenue_summary",
  "Thống kê tổng doanh thu thực tế (chỉ tính đơn hàng COMPLETED) và tổng quan số lượng các trạng thái đơn hàng trong N ngày gần nhất.",
  {
    days: z
      .number()
      .int()
      .min(1)
      .max(365)
      .default(7)
      .describe("Số ngày cần thống kê tính ngược từ hiện tại (mặc định 7 ngày)")
  },
  async ({ days }) => {
    try {
      // 1. Phân bổ tất cả trạng thái đơn hàng trong N ngày
      const statusQuery = `
        SELECT 
          status,
          COUNT(*) AS order_count,
          COALESCE(SUM(total_amount), 0) AS total_value
        FROM orders
        WHERE created_at >= NOW() - INTERVAL ? DAY
        GROUP BY status
      `;
      const [statusRows] = await pool.query(statusQuery, [days]);

      // 2. Thống kê doanh thu thực tế (chỉ đơn hàng COMPLETED)
      const revenueQuery = `
        SELECT 
          COUNT(*) AS completed_order_count,
          COALESCE(SUM(total_amount), 0) AS completed_revenue,
          COALESCE(AVG(total_amount), 0) AS average_order_value
        FROM orders
        WHERE status = 'COMPLETED'
          AND created_at >= NOW() - INTERVAL ? DAY
      `;
      const [revRows] = await pool.query(revenueQuery, [days]);
      const rev = revRows[0] || {
        completed_order_count: 0,
        completed_revenue: 0,
        average_order_value: 0
      };

      const formatter = new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency: "VND"
      });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                period_days: days,
                completed_revenue: rev.completed_revenue,
                completed_revenue_formatted: formatter.format(rev.completed_revenue),
                completed_orders: rev.completed_order_count,
                average_order_value_formatted: formatter.format(rev.average_order_value),
                status_breakdown: statusRows
              },
              null,
              2
            )
          }
        ]
      };
    } catch (error) {
      console.error("Lỗi khi gọi tool get_revenue_summary:", error);
      return {
        content: [{ type: "text", text: `Lỗi truy vấn CSDL: ${error.message}` }],
        isError: true
      };
    }
  }
);

// =========================================================================
// TOOL 3: create_promotional_coupon
// Tạo mã giảm giá mới với các quy tắc kiểm tra an toàn chặt chẽ
// =========================================================================
server.tool(
  "create_promotional_coupon",
  "Tạo mã giảm giá khuyến mãi mới vào database với các quy tắc kiểm tra nghiêm ngặt (chống trùng mã, giới hạn % và số tiền).",
  {
    code: z
      .string()
      .trim()
      .toUpperCase()
      .regex(/^[A-Z0-9_-]{3,20}$/, "Mã coupon chỉ chứa chữ in hoa, chữ số, dấu gạch ngang/dưới (3 đến 20 ký tự)")
      .describe("Mã giảm giá (ví dụ: FLASH10, SALE2026, VIP50)"),
    name: z
      .string()
      .trim()
      .min(3, "Tên chương trình phải có ít nhất 3 ký tự")
      .max(150, "Tên chương trình tối đa 150 ký tự")
      .describe("Tên hoặc mô tả ngắn của chương trình khuyến mãi"),
    discountType: z
      .enum(["PERCENT", "FIXED_AMOUNT"])
      .describe("Loại giảm giá: 'PERCENT' (% đơn hàng) hoặc 'FIXED_AMOUNT' (số tiền cố định VNĐ)"),
    discountValue: z
      .number()
      .positive("Giá trị giảm giá phải lớn hơn 0")
      .describe("Giá trị giảm: Nếu PERCENT thì từ 1 đến 50 (%); nếu FIXED_AMOUNT thì số tiền VNĐ cụ thể (tối đa 2.000.000 VNĐ)"),
    maxDiscount: z
      .number()
      .positive("Số tiền giảm tối đa phải lớn hơn 0")
      .optional()
      .describe("Số tiền giảm tối đa (VNĐ) khi áp dụng PERCENT (không bắt buộc)"),
    minOrderValue: z
      .number()
      .min(0, "Giá trị đơn tối thiểu không được âm")
      .default(0)
      .describe("Giá trị đơn hàng tối thiểu để áp dụng mã (VNĐ, mặc định 0)"),
    quantity: z
      .number()
      .int()
      .min(1, "Số lượng mã phải từ 1 trở lên")
      .max(10000, "Số lượng mã tối đa 10.000")
      .default(100)
      .describe("Tổng số lượt sử dụng của mã (mặc định 100)"),
    durationDays: z
      .number()
      .int()
      .min(1, "Thời hạn tối thiểu là 1 ngày")
      .max(365, "Thời hạn tối đa là 365 ngày")
      .default(30)
      .describe("Thời hạn hiệu lực của mã tính theo ngày kể từ hôm nay (mặc định 30 ngày)")
  },
  async ({
    code,
    name,
    discountType,
    discountValue,
    maxDiscount,
    minOrderValue,
    quantity,
    durationDays
  }) => {
    try {
      // 1. Kiểm tra nghiệp vụ loại giảm giá
      if (discountType === "PERCENT") {
        if (discountValue < 1 || discountValue > 50) {
          return {
            content: [
              {
                type: "text",
                text: `Lỗi nghiệp vụ: Với loại giảm giá PERCENT, giá trị giảm phải nằm trong khoảng từ 1% đến 50%. Bạn đã nhập: ${discountValue}%.`
              }
            ],
            isError: true
          };
        }
      } else if (discountType === "FIXED_AMOUNT") {
        if (discountValue <= 0 || discountValue > 2000000) {
          return {
            content: [
              {
                type: "text",
                text: `Lỗi nghiệp vụ: Với loại giảm giá FIXED_AMOUNT, giá trị giảm phải từ 1.000 VNĐ đến 2.000.000 VNĐ. Bạn đã nhập: ${discountValue}.`
              }
            ],
            isError: true
          };
        }
      }

      // 2. Kiểm tra chống trùng mã coupon trong database
      const checkQuery = "SELECT id FROM coupon WHERE code = ?";
      const [existing] = await pool.query(checkQuery, [code]);
      if (existing.length > 0) {
        return {
          content: [
            {
              type: "text",
              text: `Lỗi: Mã giảm giá '${code}' đã tồn tại trong CSDL. Vui lòng chọn một mã khác.`
            }
          ],
          isError: true
        };
      }

      // 3. Insert an toàn bằng câu lệnh tham số hóa (?)
      const insertQuery = `
        INSERT INTO coupon (
          code, name, discount_type, discount_value, max_discount, 
          min_order_value, quantity, used_count, start_date, end_date, status
        ) VALUES (
          ?, ?, ?, ?, ?, 
          ?, ?, 0, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY), 'ACTIVE'
        )
      `;
      const [result] = await pool.query(insertQuery, [
        code,
        name,
        discountType,
        discountValue,
        maxDiscount || null,
        minOrderValue,
        quantity,
        durationDays
      ]);

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                success: true,
                message: `Đã tạo thành công mã giảm giá '${code}' trong CSDL FashionShop!`,
                coupon: {
                  id: result.insertId,
                  code,
                  name,
                  discount_type: discountType,
                  discount_value:
                    discountType === "PERCENT"
                      ? `${discountValue}%`
                      : `${discountValue.toLocaleString("vi-VN")} VNĐ`,
                  max_discount: maxDiscount
                    ? `${maxDiscount.toLocaleString("vi-VN")} VNĐ`
                    : "Không giới hạn",
                  min_order_value: `${minOrderValue.toLocaleString("vi-VN")} VNĐ`,
                  quantity,
                  duration_days: durationDays,
                  status: "ACTIVE"
                }
              },
              null,
              2
            )
          }
        ]
      };
    } catch (error) {
      console.error("Lỗi khi gọi tool create_promotional_coupon:", error);
      return {
        content: [{ type: "text", text: `Lỗi lưu coupon vào CSDL: ${error.message}` }],
        isError: true
      };
    }
  }
);

// =========================================================================
// TOOL 4: search_products
// Tìm kiếm sản phẩm theo tên hoặc danh mục kèm thông tin giá và tổng tồn kho
// =========================================================================
server.tool(
  "search_products",
  "Tìm kiếm sản phẩm theo tên sản phẩm hoặc tên danh mục kèm thông tin giá, sale và tổng tồn kho biến thể.",
  {
    keyword: z
      .string()
      .trim()
      .min(1)
      .describe("Từ khóa tên sản phẩm hoặc tên danh mục thời trang (ví dụ: áo sơ mi, đầm, quần tây)"),
    limit: z
      .number()
      .int()
      .min(1)
      .max(50)
      .default(10)
      .describe("Số lượng sản phẩm tối đa trả về (mặc định 10)")
  },
  async ({ keyword, limit }) => {
    try {
      const query = `
        SELECT 
          p.id,
          p.name,
          c.name AS category_name,
          p.price,
          p.sale_price,
          p.gender,
          p.status,
          COALESCE(SUM(pv.stock_quantity), 0) AS total_stock_quantity,
          COUNT(pv.id) AS variant_count
        FROM product p
        JOIN category c ON p.category_id = c.id
        LEFT JOIN product_variant pv ON p.id = pv.product_id
        WHERE (p.name LIKE ? OR c.name LIKE ?)
          AND p.status = 'ACTIVE'
        GROUP BY p.id, p.name, c.name, p.price, p.sale_price, p.gender, p.status
        ORDER BY p.id DESC
        LIMIT ?
      `;
      const searchPattern = `%${keyword}%`;
      const [rows] = await pool.query(query, [searchPattern, searchPattern, limit]);

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                keyword,
                count: rows.length,
                products: rows
              },
              null,
              2
            )
          }
        ]
      };
    } catch (error) {
      console.error("Lỗi khi gọi tool search_products:", error);
      return {
        content: [{ type: "text", text: `Lỗi tìm kiếm sản phẩm: ${error.message}` }],
        isError: true
      };
    }
  }
);

// =========================================================================
// 4. KẾT NỐI TRANSPORT STDIO (CHỐNG VỠ GIAO THỨC)
// Lưu ý: Chỉ dùng console.error để ghi log, TUYỆT ĐỐI KHÔNG DÙNG console.log!
// =========================================================================
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("FashionShop Admin MCP Server đã khởi động thành công trên stdio!");
}

main().catch((error) => {
  console.error("Lỗi nghiêm trọng khi khởi động MCP Server:", error);
  process.exit(1);
});
