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
  password: process.env.DB_PASSWORD || "",
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
// HELPER CHUNG CHO TRUY VẤN SẢN PHẨM (search_products & get_latest_products)
// =========================================================================
async function queryProducts({ keyword = "", days = null, status = "ALL", limit = 10 }) {
  const conditions = [];
  const params = [];

  if (keyword && keyword.trim().length > 0) {
    const searchPattern = `%${keyword.trim()}%`;
    conditions.push("(p.name LIKE ? OR c.name LIKE ?)");
    params.push(searchPattern, searchPattern);
  }

  if (days !== null && days !== undefined) {
    conditions.push("p.created_at >= NOW() - INTERVAL ? DAY");
    params.push(days);
  }

  if (status && status !== "ALL") {
    conditions.push("p.status = ?");
    params.push(status);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

  const query = `
    SELECT 
      p.id,
      p.name,
      c.name AS category_name,
      p.price,
      p.sale_price,
      p.gender,
      p.status,
      p.created_at,
      COALESCE(SUM(pv.stock_quantity), 0) AS total_stock_quantity,
      COUNT(pv.id) AS variant_count
    FROM product p
    JOIN category c ON p.category_id = c.id
    LEFT JOIN product_variant pv ON p.id = pv.product_id
    ${whereClause}
    GROUP BY p.id, p.name, c.name, p.price, p.sale_price, p.gender, p.status, p.created_at
    ORDER BY p.created_at DESC, p.id DESC
    LIMIT ?
  `;
  const [rows] = await pool.query(query, [...params, limit]);

  const formatter = new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND"
  });

  return rows.map((row) => ({
    ...row,
    price_formatted: formatter.format(row.price),
    sale_price_formatted: row.sale_price != null ? formatter.format(row.sale_price) : null
  }));
}

// =========================================================================
// TOOL 4: search_products
// Tìm kiếm sản phẩm theo tên hoặc danh mục kèm ngày tạo, giá và tổng tồn kho
// =========================================================================
server.tool(
  "search_products",
  "Tìm kiếm sản phẩm theo tên sản phẩm hoặc tên danh mục (để trống từ khóa sẽ liệt kê sản phẩm mới nhất) kèm ngày tạo created_at, giá, giá sale, trạng thái và tổng tồn kho biến thể.",
  {
    keyword: z
      .string()
      .trim()
      .optional()
      .default("")
      .describe("Từ khóa tên sản phẩm hoặc tên danh mục thời trang (ví dụ: áo sơ mi, đầm, quần tây). Để trống nếu muốn lấy sản phẩm mới nhất."),
    status: z
      .enum(["ALL", "ACTIVE", "INACTIVE"])
      .default("ALL")
      .describe("Lọc trạng thái sản phẩm: ALL (tất cả - mặc định), ACTIVE (đang bán), INACTIVE (đang ẩn)"),
    limit: z
      .number()
      .int()
      .min(1)
      .max(50)
      .default(10)
      .describe("Số lượng sản phẩm tối đa trả về (mặc định 10)")
  },
  async ({ keyword, status, limit }) => {
    try {
      const products = await queryProducts({ keyword, status, limit });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                keyword,
                filter_status: status,
                count: products.length,
                products
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
// TOOL 6: get_latest_products
// Lấy danh sách sản phẩm được thêm mới nhất (theo created_at giảm dần)
// =========================================================================
server.tool(
  "get_latest_products",
  "Lấy danh sách các sản phẩm được thêm mới nhất vào hệ thống (sắp xếp theo ngày tạo created_at mới nhất trước), có thể lọc trong N ngày gần đây, kèm danh mục, giá, giá sale, trạng thái và tổng tồn kho.",
  {
    days: z
      .number()
      .int()
      .min(1)
      .max(365)
      .optional()
      .describe("Tùy chọn: chỉ lấy các sản phẩm được tạo trong N ngày gần đây (bỏ trống để lấy mới nhất từ trước đến nay)"),
    status: z
      .enum(["ALL", "ACTIVE", "INACTIVE"])
      .default("ALL")
      .describe("Lọc trạng thái sản phẩm: ALL (tất cả - mặc định), ACTIVE, INACTIVE"),
    limit: z
      .number()
      .int()
      .min(1)
      .max(50)
      .default(10)
      .describe("Số lượng sản phẩm mới nhất cần lấy (mặc định 10)")
  },
  async ({ days, status, limit }) => {
    try {
      const products = await queryProducts({ days: days ?? null, status, limit });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                filter_days: days ?? "all_time",
                filter_status: status,
                count: products.length,
                latest_products: products
              },
              null,
              2
            )
          }
        ]
      };
    } catch (error) {
      console.error("Lỗi khi gọi tool get_latest_products:", error);
      return {
        content: [{ type: "text", text: `Lỗi truy vấn sản phẩm mới nhất: ${error.message}` }],
        isError: true
      };
    }
  }
);

// =========================================================================
// TOOL 5: get_recent_sales
// Liệt kê chi tiết các sản phẩm vừa bán gần đây và top sản phẩm bán chạy
// =========================================================================
const ORDER_STATUS_LABELS = {
  PENDING: "Chờ xác nhận",
  CONFIRMED: "Đã xác nhận",
  SHIPPING: "Đang giao hàng",
  COMPLETED: "Giao hàng thành công",
  CANCELLED: "Đã hủy"
};

const PAYMENT_STATUS_LABELS = {
  UNPAID: "Chưa thanh toán",
  PAID: "Đã thanh toán thành công",
  FAILED: "Thanh toán thất bại"
};

const PAYMENT_METHOD_LABELS = {
  COD: "Thanh toán khi nhận hàng (COD)",
  BANK_TRANSFER: "Chuyển khoản ngân hàng",
  E_WALLET: "Ví điện tử"
};

server.tool(
  "get_recent_sales",
  "Liệt kê chi tiết các đơn/món hàng vừa được đặt gần đây (mã đơn, thời gian tạo, tên người đặt, sản phẩm, trạng thái đơn hàng như Chờ xác nhận/Đang giao/Thành công, trạng thái thanh toán, phương thức thanh toán, giảm giá và tổng thanh toán order_total_amount; không trả phí ship) và top sản phẩm bán chạy nhất trong N ngày.",
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
      .enum(["ALL", "EXCLUDE_CANCELLED", "PENDING", "CONFIRMED", "SHIPPING", "COMPLETED", "CANCELLED"])
      .default("EXCLUDE_CANCELLED")
      .describe("Bộ lọc trạng thái đơn: EXCLUDE_CANCELLED (bỏ qua đơn hủy - mặc định), ALL, PENDING, CONFIRMED, SHIPPING, COMPLETED, CANCELLED")
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

      // 1. Chi tiết các món hàng vừa bán gần nhất (kèm người đặt, trạng thái đơn, trạng thái thanh toán, tổng thanh toán)
      const detailQuery = `
        SELECT 
          o.order_code,
          COALESCE(up.full_name, o.recipient_name) AS customer_name,
          o.recipient_name,
          o.status AS order_status,
          o.payment_method,
          o.payment_status,
          o.created_at,
          oi.product_name,
          oi.size,
          oi.color,
          oi.quantity,
          oi.unit_price,
          (oi.unit_price * oi.quantity) AS subtotal,
          o.subtotal AS order_subtotal,
          o.discount_amount,
          o.total_amount AS order_total_amount
        FROM order_item oi
        JOIN orders o ON oi.order_id = o.id
        LEFT JOIN user_profile up ON o.user_profile_id = up.id
        WHERE o.created_at >= NOW() - INTERVAL ? DAY
          ${statusCondition}
        ORDER BY o.created_at DESC
        LIMIT ?
      `;
      const [recentItems] = await pool.query(detailQuery, [...params, limit]);

      // 2. Tổng hợp các sản phẩm bán chạy nhất trong khoảng thời gian này
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
                  order_status_text: ORDER_STATUS_LABELS[item.order_status] || item.order_status,
                  payment_status_text: PAYMENT_STATUS_LABELS[item.payment_status] || item.payment_status,
                  payment_method_text: PAYMENT_METHOD_LABELS[item.payment_method] || item.payment_method,
                  unit_price_formatted: formatter.format(item.unit_price),
                  subtotal_formatted: formatter.format(item.subtotal),
                  order_subtotal_formatted: formatter.format(item.order_subtotal ?? 0),
                  discount_amount_formatted: formatter.format(item.discount_amount ?? 0),
                  order_total_amount_formatted: formatter.format(item.order_total_amount ?? 0)
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

// =========================================================================
// TOOL 7: get_stock_history
// Xem lịch sử nhập kho, kiểm kê / điều chỉnh kho và ai là người thực hiện
// =========================================================================
const STOCK_MOVEMENT_LABELS = {
  IMPORT: "Nhập kho",
  ADJUSTMENT: "Kiểm kê / Điều chỉnh kho",
  SALE: "Xuất bán đơn hàng",
  CANCELLED_ORDER: "Hoàn kho do hủy đơn"
};

server.tool(
  "get_stock_history",
  "Tra cứu lịch sử nhập kho, kiểm kê/điều chỉnh kho (hoặc xuất bán/hoàn kho) kèm thông tin người thực hiện (họ tên, email, vai trò), mã phiếu (receipt_code), số lượng thay đổi, tồn kho sau thay đổi, nhà cung cấp, giá nhập, lý do và thời gian.",
  {
    type: z
      .enum(["IMPORT_AND_AUDIT", "IMPORT", "ADJUSTMENT", "SALE", "CANCELLED_ORDER", "ALL"])
      .default("IMPORT_AND_AUDIT")
      .describe("Loại biến động kho: IMPORT_AND_AUDIT (nhập kho & kiểm kê - mặc định), IMPORT (chỉ nhập kho), ADJUSTMENT (chỉ kiểm kê/điều chỉnh), SALE (xuất bán), CANCELLED_ORDER (hoàn kho), ALL (tất cả)"),
    days: z
      .number()
      .int()
      .min(1)
      .max(365)
      .default(30)
      .describe("Số ngày cần xem tính ngược từ hiện tại (mặc định 30 ngày)"),
    keyword: z
      .string()
      .trim()
      .optional()
      .default("")
      .describe("Từ khóa lọc theo tên sản phẩm, SKU, mã phiếu, tên/email người thực hiện hoặc nhà cung cấp (tùy chọn)"),
    limit: z
      .number()
      .int()
      .min(1)
      .max(100)
      .default(20)
      .describe("Số lượng dòng lịch sử tối đa trả về (mặc định 20)")
  },
  async ({ type, days, keyword, limit }) => {
    try {
      const conditions = ["sh.created_at >= NOW() - INTERVAL ? DAY"];
      const params = [days];

      if (type === "IMPORT_AND_AUDIT") {
        conditions.push("sh.type IN ('IMPORT', 'ADJUSTMENT')");
      } else if (type !== "ALL") {
        conditions.push("sh.type = ?");
        params.push(type);
      }

      if (keyword && keyword.length > 0) {
        const kw = `%${keyword}%`;
        conditions.push(
          "(p.name LIKE ? OR pv.sku LIKE ? OR sh.receipt_code LIKE ? OR up.full_name LIKE ? OR acc.email LIKE ? OR sh.supplier LIKE ?)"
        );
        params.push(kw, kw, kw, kw, kw, kw);
      }

      const query = `
        SELECT
          sh.id,
          sh.receipt_code,
          sh.type,
          sh.quantity_change,
          sh.stock_after,
          sh.supplier,
          sh.import_price,
          sh.reason,
          sh.created_at,
          p.name AS product_name,
          pv.size,
          pv.color,
          pv.sku,
          up.full_name AS performed_by_name,
          acc.email AS performed_by_email,
          acc.role AS performed_by_role,
          o.order_code
        FROM stock_history sh
        JOIN product_variant pv ON sh.variant_id = pv.id
        JOIN product p ON pv.product_id = p.id
        LEFT JOIN user_profile up ON sh.performed_by_id = up.id
        LEFT JOIN account acc ON up.account_id = acc.id
        LEFT JOIN orders o ON sh.order_id = o.id
        WHERE ${conditions.join(" AND ")}
        ORDER BY sh.created_at DESC, sh.id DESC
        LIMIT ?
      `;
      const [rows] = await pool.query(query, [...params, limit]);

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
                filter_type: type,
                keyword,
                count: rows.length,
                stock_history: rows.map((item) => ({
                  ...item,
                  type_text: STOCK_MOVEMENT_LABELS[item.type] || item.type,
                  import_price_formatted: item.import_price != null ? formatter.format(item.import_price) : null
                }))
              },
              null,
              2
            )
          }
        ]
      };
    } catch (error) {
      console.error("Lỗi khi gọi tool get_stock_history:", error);
      return {
        content: [{ type: "text", text: `Lỗi truy vấn lịch sử kho: ${error.message}` }],
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
