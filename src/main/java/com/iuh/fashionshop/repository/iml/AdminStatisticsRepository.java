
package com.iuh.fashionshop.repository.iml;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Repository
public class AdminStatisticsRepository {

    public record Aggregate(BigDecimal revenue, long orderCount) {
    }

    public record WeeklyAggregate(BigDecimal revenue, long orderCount) {
    }

    public record CategoryAggregate(String name, BigDecimal revenue) {
    }

    public record ChannelAggregate(String paymentMethod, BigDecimal revenue) {
    }

    public record ProductAggregate(String productName, String categoryName, long soldQuantity, BigDecimal revenue) {
    }

    public record SoldItemAggregate(
            String orderCode,
            String productName,
            String color,
            String size,
            BigDecimal unitPrice,
            int quantity,
            LocalDateTime createdAt
    ) {
    }

    public record GrossAndDiscount(BigDecimal grossRevenue, BigDecimal discountAmount, BigDecimal netRevenue) {}

    public record SizeAggregate(String size, long quantity) {}

    public record ColorAggregate(String color, long quantity) {}

    public record ChannelDetailAggregate(String paymentMethod, BigDecimal revenue, long totalOrders, long completedOrders, long cancelledOrders) {}

    public record ProductWithStockAggregate(
            Long productId,
            String productName,
            String categoryName,
            long soldQuantity,
            BigDecimal revenue,
            long currentStock
    ) {}

    private final JdbcTemplate jdbc;

    public AdminStatisticsRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Aggregate aggregateOrders(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive) {
        String inClause = inClause(successStatuses);
        return jdbc.queryForObject("""
                SELECT COALESCE(SUM(o.total_amount), 0) AS revenue, COUNT(*) AS orderCount
                FROM orders o
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                """.formatted(inClause), (rs, i) -> new Aggregate(
                rs.getBigDecimal("revenue"),
                rs.getLong("orderCount")), startInclusive, endExclusive);
    }

    public long countSoldProducts(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive) {
        String inClause = inClause(successStatuses);
        Long count = jdbc.queryForObject("""
                SELECT COALESCE(SUM(oi.quantity), 0)
                FROM order_item oi
                JOIN orders o ON o.id = oi.order_id
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                """.formatted(inClause), Long.class, startInclusive, endExclusive);
        return count == null ? 0L : count;
    }

    public WeeklyAggregate aggregateWeek(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive) {
        String inClause = inClause(successStatuses);
        return jdbc.queryForObject("""
                SELECT COALESCE(SUM(o.total_amount), 0) AS revenue, COUNT(*) AS orderCount
                FROM orders o
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                """.formatted(inClause), (rs, i) -> new WeeklyAggregate(
                rs.getBigDecimal("revenue"),
                rs.getLong("orderCount")), startInclusive, endExclusive);
    }

    public List<SoldItemAggregate> findSoldItems(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive) {
        String inClause = inClause(successStatuses);
        return jdbc.query("""
                SELECT o.order_code AS orderCode,
                       oi.product_name AS productName,
                       COALESCE(oi.color, '') AS color,
                       COALESCE(oi.size, '') AS size,
                       oi.unit_price AS unitPrice,
                       oi.quantity AS quantity,
                       o.created_at AS createdAt
                FROM order_item oi
                JOIN orders o ON o.id = oi.order_id
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                ORDER BY o.created_at DESC, oi.id ASC
                """.formatted(inClause), (rs, i) -> new SoldItemAggregate(
                rs.getString("orderCode"),
                rs.getString("productName"),
                rs.getString("color"),
                rs.getString("size"),
                rs.getBigDecimal("unitPrice"),
                rs.getInt("quantity"),
                rs.getTimestamp("createdAt").toLocalDateTime()
        ), startInclusive, endExclusive);
    }

    public List<CategoryAggregate> categoryRevenue(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive, int limit) {
        String inClause = inClause(successStatuses);
        return jdbc.query("""
                SELECT c.name AS categoryName, COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS revenue
                FROM order_item oi
                JOIN orders o ON o.id = oi.order_id
                LEFT JOIN product_variant pv ON pv.id = oi.variant_id
                LEFT JOIN product p ON p.id = pv.product_id
                LEFT JOIN category c ON c.id = p.category_id
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                GROUP BY c.id, c.name
                ORDER BY revenue DESC
                LIMIT ?
                """.formatted(inClause), (rs, i) -> new CategoryAggregate(
                rs.getString("categoryName") == null ? "Khác" : rs.getString("categoryName"),
                rs.getBigDecimal("revenue")), startInclusive, endExclusive, limit);
    }

    public List<ChannelAggregate> channelRevenue(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive) {
        String inClause = inClause(successStatuses);
        return jdbc.query("""
                SELECT o.payment_method AS paymentMethod, COALESCE(SUM(o.total_amount), 0) AS revenue
                FROM orders o
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                GROUP BY o.payment_method
                ORDER BY revenue DESC
                """.formatted(inClause), (rs, i) -> new ChannelAggregate(
                rs.getString("paymentMethod"),
                rs.getBigDecimal("revenue")), startInclusive, endExclusive);
    }

    public List<ProductAggregate> topProducts(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive, int limit) {
        String inClause = inClause(successStatuses);
        return jdbc.query("""
                SELECT oi.product_name AS productName,
                       COALESCE(MAX(c.name), 'Khác') AS categoryName,
                       COALESCE(SUM(oi.quantity), 0) AS soldQuantity,
                       COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS revenue
                FROM order_item oi
                JOIN orders o ON o.id = oi.order_id
                LEFT JOIN product_variant pv ON pv.id = oi.variant_id
                LEFT JOIN product p ON p.id = pv.product_id
                LEFT JOIN category c ON c.id = p.category_id
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                GROUP BY oi.product_name
                ORDER BY revenue DESC
                LIMIT ?
                """.formatted(inClause), (rs, i) -> new ProductAggregate(
                rs.getString("productName"),
                rs.getString("categoryName"),
                rs.getLong("soldQuantity"),
                rs.getBigDecimal("revenue")), startInclusive, endExclusive, limit);
    }

    public Map<String, BigDecimal> productRevenueMap(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive) {
        String inClause = inClause(successStatuses);
        Map<String, BigDecimal> result = new LinkedHashMap<>();
        jdbc.query("""
            SELECT oi.product_name AS productName,
                   COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS revenue
            FROM order_item oi
            JOIN orders o ON o.id = oi.order_id
            WHERE o.status IN (%s)
              AND o.created_at >= ?
              AND o.created_at < ?
            GROUP BY oi.product_name
            """.formatted(inClause),
                (java.sql.ResultSet rs) -> {
                    result.put(rs.getString("productName"), rs.getBigDecimal("revenue"));
                },
                startInclusive, endExclusive);
        return result;
    }

    public GrossAndDiscount aggregateRevenueDetails(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive) {
        String inClause = inClause(successStatuses);
        return jdbc.queryForObject("""
                SELECT COALESCE(SUM(o.subtotal), 0) AS grossRevenue,
                       COALESCE(SUM(o.discount_amount), 0) AS discountAmount,
                       COALESCE(SUM(o.total_amount), 0) AS netRevenue
                FROM orders o
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                """.formatted(inClause), (rs, i) -> new GrossAndDiscount(
                rs.getBigDecimal("grossRevenue"),
                rs.getBigDecimal("discountAmount"),
                rs.getBigDecimal("netRevenue")
        ), startInclusive, endExclusive);
    }

    public List<SizeAggregate> topSizes(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive, int limit) {
        String inClause = inClause(successStatuses);
        return jdbc.query("""
                SELECT COALESCE(NULLIF(TRIM(oi.size), ''), 'FreeSize') AS sizeName,
                       COALESCE(SUM(oi.quantity), 0) AS totalQty
                FROM order_item oi
                JOIN orders o ON o.id = oi.order_id
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                GROUP BY COALESCE(NULLIF(TRIM(oi.size), ''), 'FreeSize')
                ORDER BY totalQty DESC
                LIMIT ?
                """.formatted(inClause), (rs, i) -> new SizeAggregate(
                rs.getString("sizeName"),
                rs.getLong("totalQty")
        ), startInclusive, endExclusive, limit);
    }

    public List<ColorAggregate> topColors(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive, int limit) {
        String inClause = inClause(successStatuses);
        return jdbc.query("""
                SELECT COALESCE(NULLIF(TRIM(oi.color), ''), 'Tiêu chuẩn') AS colorName,
                       COALESCE(SUM(oi.quantity), 0) AS totalQty
                FROM order_item oi
                JOIN orders o ON o.id = oi.order_id
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                GROUP BY COALESCE(NULLIF(TRIM(oi.color), ''), 'Tiêu chuẩn')
                ORDER BY totalQty DESC
                LIMIT ?
                """.formatted(inClause), (rs, i) -> new ColorAggregate(
                rs.getString("colorName"),
                rs.getLong("totalQty")
        ), startInclusive, endExclusive, limit);
    }

    public List<ChannelDetailAggregate> channelRevenueDetailed(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive) {
        String inClause = inClause(successStatuses);
        return jdbc.query("""
                SELECT o.payment_method AS paymentMethod,
                       COALESCE(SUM(CASE WHEN o.status IN (%s) THEN o.total_amount ELSE 0 END), 0) AS revenue,
                       COUNT(*) AS totalOrders,
                       COALESCE(SUM(CASE WHEN o.status = 'COMPLETED' THEN 1 ELSE 0 END), 0) AS completedOrders,
                       COALESCE(SUM(CASE WHEN o.status = 'CANCELLED' THEN 1 ELSE 0 END), 0) AS cancelledOrders
                FROM orders o
                WHERE o.created_at >= ?
                  AND o.created_at < ?
                GROUP BY o.payment_method
                ORDER BY revenue DESC
                """.formatted(inClause), (rs, i) -> new ChannelDetailAggregate(
                rs.getString("paymentMethod"),
                rs.getBigDecimal("revenue"),
                rs.getLong("totalOrders"),
                rs.getLong("completedOrders"),
                rs.getLong("cancelledOrders")
        ), startInclusive, endExclusive);
    }

    public List<ProductWithStockAggregate> topProductsWithStock(List<String> successStatuses, LocalDateTime startInclusive, LocalDateTime endExclusive, int limit) {
        String inClause = inClause(successStatuses);
        return jdbc.query("""
                SELECT COALESCE(p.id, 0) AS productId,
                       oi.product_name AS productName,
                       COALESCE(MAX(c.name), 'Thời trang') AS categoryName,
                       COALESCE(SUM(oi.quantity), 0) AS soldQuantity,
                       COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS revenue,
                       COALESCE(MAX(st.total_stock), 0) AS currentStock
                FROM order_item oi
                JOIN orders o ON o.id = oi.order_id
                LEFT JOIN product_variant pv ON pv.id = oi.variant_id
                LEFT JOIN product p ON p.id = pv.product_id
                LEFT JOIN category c ON c.id = p.category_id
                LEFT JOIN (
                    SELECT product_id, SUM(stock_quantity) AS total_stock
                    FROM product_variant
                    GROUP BY product_id
                ) st ON st.product_id = p.id
                WHERE o.status IN (%s)
                  AND o.created_at >= ?
                  AND o.created_at < ?
                GROUP BY p.id, oi.product_name
                ORDER BY revenue DESC
                LIMIT ?
                """.formatted(inClause), (rs, i) -> new ProductWithStockAggregate(
                rs.getLong("productId"),
                rs.getString("productName"),
                rs.getString("categoryName"),
                rs.getLong("soldQuantity"),
                rs.getBigDecimal("revenue"),
                rs.getLong("currentStock")
        ), startInclusive, endExclusive, limit);
    }

    public record StockHealthAggregate(long outOfStockCount, long lowStockCount) {}

    public StockHealthAggregate countStockHealth() {
        return jdbc.queryForObject("""
                SELECT 
                    COALESCE(SUM(CASE WHEN stock_quantity = 0 THEN 1 ELSE 0 END), 0) AS outOfStockCount,
                    COALESCE(SUM(CASE WHEN stock_quantity > 0 AND stock_quantity <= 5 THEN 1 ELSE 0 END), 0) AS lowStockCount
                FROM product_variant
                """, (rs, i) -> new StockHealthAggregate(
                rs.getLong("outOfStockCount"),
                rs.getLong("lowStockCount")
        ));
    }

    public record LowStockProductAggregate(Long productId, String productName, String categoryName, long currentStock) {}

    public List<LowStockProductAggregate> findUrgentLowStockProducts(int limit) {
        return jdbc.query("""
                SELECT p.id AS productId,
                       CASE 
                           WHEN pv.size IS NOT NULL AND TRIM(pv.size) != '' AND pv.color IS NOT NULL AND TRIM(pv.color) != '' 
                               THEN CONCAT(p.name, ' (', pv.color, ' - Size ', pv.size, ')')
                           WHEN pv.size IS NOT NULL AND TRIM(pv.size) != '' 
                               THEN CONCAT(p.name, ' (Size ', pv.size, ')')
                           ELSE p.name 
                       END AS productName,
                       COALESCE(c.name, 'Thời trang') AS categoryName,
                       pv.stock_quantity AS currentStock
                FROM product_variant pv
                JOIN product p ON p.id = pv.product_id
                LEFT JOIN category c ON c.id = p.category_id
                WHERE pv.stock_quantity <= 5
                ORDER BY pv.stock_quantity ASC, pv.id DESC
                LIMIT ?
                """, (rs, i) -> new LowStockProductAggregate(
                rs.getLong("productId"),
                rs.getString("productName"),
                rs.getString("categoryName"),
                rs.getLong("currentStock")
        ), limit);
    }

    // ===================== DỮ LIỆU CHO BÁO CÁO VẬN HÀNH HẰNG NGÀY (n8n) =====================

    public record StatusCountAggregate(String status, long orderCount, BigDecimal amount) {}

    /** Đếm số đơn + tổng tiền theo từng trạng thái (tính cả đơn hủy). */
    public List<StatusCountAggregate> countOrdersByStatus(LocalDateTime startInclusive, LocalDateTime endExclusive) {
        return jdbc.query("""
                SELECT o.status AS status, COUNT(*) AS orderCount, COALESCE(SUM(o.total_amount), 0) AS amount
                FROM orders o
                WHERE o.created_at >= ?
                  AND o.created_at < ?
                GROUP BY o.status
                """, (rs, i) -> new StatusCountAggregate(
                rs.getString("status"),
                rs.getLong("orderCount"),
                rs.getBigDecimal("amount")
        ), startInclusive, endExclusive);
    }

    public record OrderDetailAggregate(
            String orderCode,
            LocalDateTime createdAt,
            String recipientName,
            String recipientPhone,
            String items,
            long totalQuantity,
            BigDecimal discountAmount,
            BigDecimal totalAmount,
            String paymentMethod,
            String paymentStatus,
            String status,
            String cancelReason
    ) {}

    /** Danh sách chi tiết đơn hàng trong khoảng thời gian (dùng cho phụ lục báo cáo). */
    public List<OrderDetailAggregate> findOrderDetails(LocalDateTime startInclusive, LocalDateTime endExclusive, int limit) {
        return jdbc.query("""
                SELECT o.order_code AS orderCode,
                       o.created_at AS createdAt,
                       o.recipient_name AS recipientName,
                       o.recipient_phone AS recipientPhone,
                       o.discount_amount AS discountAmount,
                       o.total_amount AS totalAmount,
                       o.payment_method AS paymentMethod,
                       o.payment_status AS paymentStatus,
                       o.status AS status,
                       o.cancel_reason AS cancelReason,
                       (SELECT COALESCE(SUM(oi.quantity), 0) FROM order_item oi WHERE oi.order_id = o.id) AS totalQuantity,
                       (SELECT GROUP_CONCAT(CONCAT(oi.product_name, ' (',
                                    COALESCE(NULLIF(TRIM(oi.color), ''), '-'), '/',
                                    COALESCE(NULLIF(TRIM(oi.size), ''), '-'), ') x', oi.quantity)
                                ORDER BY oi.id SEPARATOR '; ')
                        FROM order_item oi WHERE oi.order_id = o.id) AS items
                FROM orders o
                WHERE o.created_at >= ?
                  AND o.created_at < ?
                ORDER BY o.created_at ASC
                LIMIT ?
                """, (rs, i) -> new OrderDetailAggregate(
                rs.getString("orderCode"),
                rs.getTimestamp("createdAt").toLocalDateTime(),
                rs.getString("recipientName"),
                rs.getString("recipientPhone"),
                rs.getString("items"),
                rs.getLong("totalQuantity"),
                rs.getBigDecimal("discountAmount"),
                rs.getBigDecimal("totalAmount"),
                rs.getString("paymentMethod"),
                rs.getString("paymentStatus"),
                rs.getString("status"),
                rs.getString("cancelReason")
        ), startInclusive, endExclusive, limit);
    }

    /** Sản phẩm tồn kho nhiều nhưng không bán được đơn nào trong khoảng thời gian (hàng chậm luân chuyển). */
    public List<LowStockProductAggregate> findSlowMovingProducts(LocalDateTime startInclusive, LocalDateTime endExclusive,
                                                                 long minStock, int limit) {
        return jdbc.query("""
                SELECT p.id AS productId,
                       p.name AS productName,
                       COALESCE(MAX(c.name), 'Thời trang') AS categoryName,
                       COALESCE(SUM(pv.stock_quantity), 0) AS currentStock
                FROM product p
                JOIN product_variant pv ON pv.product_id = p.id
                LEFT JOIN category c ON c.id = p.category_id
                WHERE p.status = 'ACTIVE'
                  AND NOT EXISTS (
                      SELECT 1
                      FROM order_item oi
                      JOIN orders o ON o.id = oi.order_id
                      JOIN product_variant pv2 ON pv2.id = oi.variant_id
                      WHERE pv2.product_id = p.id
                        AND o.status <> 'CANCELLED'
                        AND o.created_at >= ?
                        AND o.created_at < ?
                  )
                GROUP BY p.id, p.name
                HAVING COALESCE(SUM(pv.stock_quantity), 0) >= ?
                ORDER BY currentStock DESC
                LIMIT ?
                """, (rs, i) -> new LowStockProductAggregate(
                rs.getLong("productId"),
                rs.getString("productName"),
                rs.getString("categoryName"),
                rs.getLong("currentStock")
        ), startInclusive, endExclusive, minStock, limit);
    }

    private String inClause(List<String> statuses) {
        return statuses.stream().map(s -> "'" + s + "'").reduce((a, b) -> a + "," + b).orElse("'COMPLETED'");
    }
}
