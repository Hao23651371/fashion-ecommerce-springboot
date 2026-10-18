package com.iuh.fashionshop.repository.iml;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

/**
 * Làm việc với bảng product_embedding bằng SQL thuần (JPA chưa hỗ trợ kiểu VECTOR của MariaDB).
 */
@Repository
public class ProductEmbeddingRepository {

    /** Dữ liệu một sản phẩm dùng để tạo văn bản embedding. */
    public record ProductSource(long id, String name, String description, String gender,
                                BigDecimal price, BigDecimal salePrice,
                                String category, String colors, String sizes) {
    }

    /** Một kết quả gần nhất: id sản phẩm và khoảng cách cosine (càng nhỏ càng giống). */
    public record Hit(long productId, double distance) {
    }

    private final JdbcTemplate jdbc;

    public ProductEmbeddingRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Lấy sản phẩm đang bán; onlyMissing=true thì chỉ lấy sản phẩm chưa có vector. */
    public List<ProductSource> findSources(boolean onlyMissing) {
        String sql = """
                SELECT p.id, p.name, p.description, p.gender, p.price, p.sale_price,
                       c.name AS category,
                       GROUP_CONCAT(DISTINCT v.color ORDER BY v.color SEPARATOR ', ') AS colors,
                       GROUP_CONCAT(DISTINCT v.size  ORDER BY v.size  SEPARATOR ', ') AS sizes
                FROM product p
                JOIN category c ON c.id = p.category_id
                LEFT JOIN product_variant v ON v.product_id = p.id AND v.status = 'ACTIVE'
                WHERE p.status = 'ACTIVE' AND c.status = 'VISIBLE'
                """
                + (onlyMissing ? " AND NOT EXISTS (SELECT 1 FROM product_embedding e WHERE e.product_id = p.id) " : "")
                + """
                GROUP BY p.id, p.name, p.description, p.gender, p.price, p.sale_price, c.name
                ORDER BY p.id
                """;
        return jdbc.query(sql, (rs, i) -> new ProductSource(
                rs.getLong("id"),
                rs.getString("name"),
                rs.getString("description"),
                rs.getString("gender"),
                rs.getBigDecimal("price"),
                rs.getBigDecimal("sale_price"),
                rs.getString("category"),
                rs.getString("colors"),
                rs.getString("sizes")));
    }

    /** Lưu (hoặc cập nhật) vector của một sản phẩm. vectorText có dạng "[0.1,0.2,...]". */
    public void save(long productId, String vectorText) {
        jdbc.update("""
                INSERT INTO product_embedding (product_id, embedding)
                VALUES (?, VEC_FromText(?))
                ON DUPLICATE KEY UPDATE embedding = VALUES(embedding), updated_at = CURRENT_TIMESTAMP(6)
                """, productId, vectorText);
    }

    /** Tìm các sản phẩm gần nghĩa nhất với vector truy vấn (khoảng cách cosine tăng dần). */
    public List<Hit> searchNearest(String queryVectorText, int limit) {
        return jdbc.query("""
                SELECT product_id, VEC_DISTANCE_COSINE(embedding, VEC_FromText(?)) AS distance
                FROM product_embedding
                ORDER BY VEC_DISTANCE_COSINE(embedding, VEC_FromText(?))
                LIMIT ?
                """,
                (rs, i) -> new Hit(rs.getLong("product_id"), rs.getDouble("distance")),
                queryVectorText, queryVectorText, limit);
    }

    public long count() {
        Long n = jdbc.queryForObject("SELECT COUNT(*) FROM product_embedding", Long.class);
        return n == null ? 0 : n;
    }
}