import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
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
// 2. KẾT NỐI DATABASE (MariaDB / MySQL Connection Pool dùng chung)
// =========================================================================
export const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || "fashionshop_mcp",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "fashionshop",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  decimalNumbers: true
});

// =========================================================================
// 3. FACTORY TẠO MCP SERVER VÀ ĐĂNG KÝ TRỌN BỘ 5 TOOLS
// Dùng chung cho cả chế độ stdio (cá nhân) lẫn SSE/HTTP (Deploy Online)
// =========================================================================
export function createMcpServer() {
  const server = new McpServer({
    name: "FashionShop Admin AI Copilot",
    version: "1.0.0"
  });

  // TOOL 1: check_low_stock
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

  // TOOL 2: get_revenue_summary
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

  // TOOL 3: create_promotional_coupon
  server.tool(
    "create_promotional_coupon",
    "Tạo mã giảm giá khuyến mãi mới vào CSDL với các quy tắc kiểm tra kinh doanh an toàn.",
    {
      code: z
        .string()
        .min(3, "Mã giảm giá tối thiểu 3 ký tự")
        .max(20, "Mã giảm giá tối đa 20 ký tự")
        .regex(/^[A-Z0-9_-]+$/, "Mã chỉ gồm chữ cái IN HOA, số, dấu gạch nối (-) hoặc gạch dưới (_)")
        .describe("Mã code của coupon (ví dụ: SALE10, BLACKFRIDAY20)"),
      name: z.string().min(3).max(100).describe("Tên hoặc mô tả ngắn của chương trình khuyến mãi"),
      discountType: z
        .enum(["PERCENTAGE", "FIXED_AMOUNT"])
        .default("PERCENTAGE")
        .describe("Loại giảm giá: PERCENTAGE (theo %) hoặc FIXED_AMOUNT (theo số tiền cố định VND)"),
      discountValue: z
        .number()
        .positive("Giá trị giảm giá phải lớn hơn 0")
        .describe("Giá trị giảm: Nếu % thì từ 1-50; nếu cố định thì tối đa 2.000.000 VND"),
      maxDiscount: z
        .number()
        .min(0)
        .optional()
        .describe("Số tiền giảm tối đa (VND) khi áp dụng PERCENTAGE"),
      minOrderValue: z
        .number()
        .min(0)
        .default(0)
        .describe("Giá trị đơn hàng tối thiểu (VND) để áp dụng mã"),
      quantity: z
        .number()
        .int()
        .positive()
        .default(100)
        .describe("Số lượt sử dụng tối đa của mã (mặc định 100)"),
      durationDays: z
        .number()
        .int()
        .min(1)
        .max(90)
        .default(30)
        .describe("Thời hạn hiệu lực của mã tính theo số ngày kể từ hôm nay (mặc định 30 ngày)")
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
        const normalizedCode = code.trim().toUpperCase();

        if (discountType === "PERCENTAGE") {
          if (discountValue < 1 || discountValue > 50) {
            return {
              content: [
                {
                  type: "text",
                  text: `Lỗi bảo mật: Tỷ lệ giảm giá theo phần trăm phải nằm trong khoảng từ 1% đến 50%. (Yêu cầu: ${discountValue}%)`
                }
              ],
              isError: true
            };
          }
        } else {
          if (discountValue > 2000000) {
            return {
              content: [
                {
                  type: "text",
                  text: `Lỗi bảo mật: Số tiền giảm cố định không được vượt quá 2.000.000 VND. (Yêu cầu: ${discountValue} VND)`
                }
              ],
              isError: true
            };
          }
        }

        const [existing] = await pool.query(
          "SELECT id FROM coupon WHERE code = ? LIMIT 1",
          [normalizedCode]
        );
        if (existing.length > 0) {
          return {
            content: [
              {
                type: "text",
                text: `Lỗi trùng lặp: Mã giảm giá "${normalizedCode}" đã tồn tại trong hệ thống. Vui lòng chọn mã khác.`
              }
            ],
            isError: true
          };
        }

        const now = new Date();
        const startDate = now.toISOString().slice(0, 19).replace("T", " ");
        const endDateObj = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
        const endDate = endDateObj.toISOString().slice(0, 19).replace("T", " ");

        const insertQuery = `
          INSERT INTO coupon (
            code,
            name,
            discount_type,
            discount_value,
            max_discount_amount,
            min_order_value,
            max_uses,
            used_count,
            start_date,
            end_date,
            is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?, 1)
        `;

        const [result] = await pool.query(insertQuery, [
          normalizedCode,
          name,
          discountType,
          discountValue,
          discountType === "PERCENTAGE" ? maxDiscount || null : null,
          minOrderValue,
          quantity,
          startDate,
          endDate
        ]);

        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  status: "SUCCESS",
                  message: `Đã tạo thành công mã giảm giá ${normalizedCode} vào CSDL!`,
                  coupon: {
                    id: result.insertId,
                    code: normalizedCode,
                    name,
                    discount_type: discountType,
                    discount_value:
                      discountType === "PERCENTAGE"
                        ? `${discountValue}%`
                        : `${new Intl.NumberFormat("vi-VN").format(discountValue)} VND`,
                    max_discount: maxDiscount
                      ? `${new Intl.NumberFormat("vi-VN").format(maxDiscount)} VND`
                      : "Không giới hạn",
                    min_order_value: `${new Intl.NumberFormat("vi-VN").format(minOrderValue)} VND`,
                    quantity,
                    valid_from: startDate,
                    valid_to: endDate
                  }
                },
                null,
                2
              )
            }
          ]
        };
      } catch (error) {
        console.error("Lỗi khi tạo coupon:", error);
        return {
          content: [{ type: "text", text: `Lỗi khi lưu mã giảm giá vào CSDL: ${error.message}` }],
          isError: true
        };
      }
    }
  );

  // TOOL 4: search_products
  server.tool(
    "search_products",
    "Tìm kiếm thông tin sản phẩm và biến thể trong danh mục của shop theo từ khóa tên hoặc danh mục.",
    {
      keyword: z.string().describe("Từ khóa cần tìm kiếm (tên sản phẩm hoặc tên danh mục)"),
      limit: z.number().int().min(1).max(50).default(10).describe("Số lượng kết quả tối đa (mặc định 10)")
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

  // TOOL 5: get_recent_sales
  server.tool(
    "get_recent_sales",
    "Liệt kê chi tiết các mặt hàng/sản phẩm đã được khách hàng đặt mua gần đây (kèm size, màu, số lượng, đơn giá, mã đơn) và tổng hợp top sản phẩm bán chạy nhất trong N ngày.",
    {
      days: z
        .number()
        .int()
        .min(1)
        .max(365)
        .default(30)
        .describe("Số ngày cần lấy lịch sử bán hàng tính ngược từ hiện tại (mặc định 30 ngày)"),
      limit: z
        .number()
        .int()
        .min(1)
        .max(100)
        .default(20)
        .describe("Số lượng dòng giao dịch tối đa cần trả về (mặc định 20)"),
      status: z
        .enum(["ALL", "EXCLUDE_CANCELLED", "COMPLETED", "SHIPPING", "PENDING"])
        .default("EXCLUDE_CANCELLED")
        .describe("Bộ lọc trạng thái đơn: EXCLUDE_CANCELLED (bỏ qua đơn hủy - mặc định), ALL (tất cả), COMPLETED (hoàn thành), SHIPPING, PENDING")
    },
    async ({ days, limit, status }) => {
      try {
        let statusCondition = "";
        const params = [days];

        if (status === "EXCLUDE_CANCELLED") {
          statusCondition = "AND o.status != 'CANCELLED'";
        } else if (status !== "ALL") {
          statusCondition = "AND o.status = ?";
          params.push(status);
        }

        const detailQuery = `
          SELECT 
            o.order_code,
            o.status AS order_status,
            o.created_at,
            oi.product_name,
            oi.size,
            oi.color,
            oi.quantity,
            oi.unit_price,
            (oi.unit_price * oi.quantity) AS subtotal
          FROM order_item oi
          JOIN orders o ON oi.order_id = o.id
          WHERE o.created_at >= NOW() - INTERVAL ? DAY
            ${statusCondition}
          ORDER BY o.created_at DESC
          LIMIT ?
        `;
        const [recentItems] = await pool.query(detailQuery, [...params, limit]);

        const topSellingQuery = `
          SELECT 
            oi.product_name,
            oi.size,
            oi.color,
            SUM(oi.quantity) AS total_quantity_sold,
            SUM(oi.unit_price * oi.quantity) AS total_revenue
          FROM order_item oi
          JOIN orders o ON oi.order_id = o.id
          WHERE o.created_at >= NOW() - INTERVAL ? DAY
            ${statusCondition}
          GROUP BY oi.product_name, oi.size, oi.color
          ORDER BY total_quantity_sold DESC, total_revenue DESC
          LIMIT 10
        `;
        const [topSelling] = await pool.query(topSellingQuery, params);

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
                  filter_status: status,
                  recent_sales_count: recentItems.length,
                  recent_sales: recentItems.map((item) => ({
                    ...item,
                    unit_price_formatted: formatter.format(item.unit_price),
                    subtotal_formatted: formatter.format(item.subtotal)
                  })),
                  top_selling_products: topSelling.map((item) => ({
                    ...item,
                    total_revenue_formatted: formatter.format(item.total_revenue)
                  }))
                },
                null,
                2
              )
            }
          ]
        };
      } catch (error) {
        console.error("Lỗi khi gọi tool get_recent_sales:", error);
        return {
          content: [{ type: "text", text: `Lỗi truy vấn CSDL lịch sử bán hàng: ${error.message}` }],
          isError: true
        };
      }
    }
  );

  return server;
}
