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

    private String inClause(List<String> statuses) {
        return statuses.stream().map(s -> "'" + s + "'").reduce((a, b) -> a + "," + b).orElse("'COMPLETED'");
    }
}
