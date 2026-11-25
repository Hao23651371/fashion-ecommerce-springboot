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
// Tự động làm sạch khoảng trắng (.trim()) để tránh lỗi getaddrinfo ENOTFOUND
// =========================================================================
const dbHost = (process.env.DB_HOST || "localhost").trim();
const dbPort = Number(String(process.env.DB_PORT || 3306).trim());
const dbUser = (process.env.DB_USER || "fashionshop_mcp").trim();
const dbPassword = (process.env.DB_PASSWORD || "").trim();
const dbName = (process.env.DB_NAME || "fashionshop").trim();
const isSSL = String(process.env.DB_SSL || "").trim().toLowerCase() === "true" || dbHost.includes("tidbcloud");

export const pool = mysql.createPool({
  host: dbHost,
  port: dbPort,
  user: dbUser,
  password: dbPassword,
  database: dbName,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  decimalNumbers: true,
  ssl: isSSL ? { rejectUnauthorized: false } : undefined
});

// =========================================================================
// 3. FACTORY TẠO MCP SERVER VÀ ĐĂNG KÝ TRỌN BỘ 7 TOOLS
// Dùng chung cho cả chế độ stdio (cá nhân) lẫn SSE/HTTP (Deploy Online)
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

const STOCK_MOVEMENT_LABELS = {
  IMPORT: "Nhập kho",
  ADJUSTMENT: "Kiểm kê / Điều chỉnh kho",
  SALE: "Xuất bán đơn hàng",
  CANCELLED_ORDER: "Hoàn kho do hủy đơn"
};

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
    "Tìm kiếm sản phẩm theo tên sản phẩm hoặc tên danh mục (để trống từ khóa sẽ liệt kê sản phẩm mới nhất) kèm ngày tạo created_at, giá, giá sale, trạng thái và tổng tồn kho biến thể.",
    {
      keyword: z
        .string()
        .trim()
        .optional()
        .default("")
        .describe("Từ khóa cần tìm kiếm (tên sản phẩm hoặc tên danh mục). Để trống nếu muốn lấy sản phẩm mới nhất."),
      status: z
        .enum(["ALL", "ACTIVE", "INACTIVE"])
        .default("ALL")
        .describe("Lọc trạng thái sản phẩm: ALL (tất cả - mặc định), ACTIVE, INACTIVE"),
      limit: z.number().int().min(1).max(50).default(10).describe("Số lượng kết quả tối đa (mặc định 10)")
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

  // TOOL 5: get_recent_sales
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

  // TOOL 6: get_latest_products
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
        .describe("Tùy chọn: chỉ lấy các sản phẩm được tạo trong N ngày gần đây"),
      status: z
        .enum(["ALL", "ACTIVE", "INACTIVE"])
        .default("ALL")
        .describe("Lọc trạng thái sản phẩm: ALL (tất cả - mặc định), ACTIVE, INACTIVE"),
      limit: z.number().int().min(1).max(50).default(10).describe("Số lượng sản phẩm mới nhất cần lấy (mặc định 10)")
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

  // TOOL 7: get_stock_history
  server.tool(
    "get_stock_history",
    "Tra cứu lịch sử nhập kho, kiểm kê/điều chỉnh kho (hoặc xuất bán/hoàn kho) kèm thông tin người thực hiện (họ tên, email, vai trò), mã phiếu (receipt_code), số lượng thay đổi, tồn kho sau thay đổi, nhà cung cấp, giá nhập, lý do và thời gian.",
    {
      type: z
        .enum(["IMPORT_AND_AUDIT", "IMPORT", "ADJUSTMENT", "SALE", "CANCELLED_ORDER", "ALL"])
        .default("IMPORT_AND_AUDIT")
        .describe("Loại biến động kho: IMPORT_AND_AUDIT (nhập kho & kiểm kê - mặc định), IMPORT, ADJUSTMENT, SALE, CANCELLED_ORDER, ALL"),
      days: z.number().int().min(1).max(365).default(30).describe("Số ngày cần xem tính ngược từ hiện tại (mặc định 30 ngày)"),
      keyword: z
        .string()
        .trim()
        .optional()
        .default("")
        .describe("Từ khóa lọc theo tên sản phẩm, SKU, mã phiếu, tên/email người thực hiện hoặc nhà cung cấp"),
      limit: z.number().int().min(1).max(100).default(20).describe("Số lượng dòng lịch sử tối đa trả về (mặc định 20)")
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

  return server;
}
