package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.model.enums.ProductStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ProductRepository extends JpaRepository<Product, Long> {

        /** Sản phẩm mới nhất: đang bán và thuộc danh mục đang hiển thị. */
        @Query("""
                        select p from Product p
                        join fetch p.category c
                        where p.status = :status and c.status = :categoryStatus
                        order by p.createdAt desc, p.id desc
                        """)
        List<Product> findLatest(@Param("status") ProductStatus status,
                        @Param("categoryStatus") CategoryStatus categoryStatus,
                        Pageable pageable);

        /** Sản phẩm đang giảm giá (giá sale > 0 và nhỏ hơn giá gốc). */
        @Query("""
                        select p from Product p
                        join fetch p.category c
                        where p.status = :status and c.status = :categoryStatus
                          and p.salePrice is not null and p.salePrice > 0 and p.salePrice < p.price
                        order by p.createdAt desc, p.id desc
                        """)
        List<Product> findOnSale(@Param("status") ProductStatus status,
                        @Param("categoryStatus") CategoryStatus categoryStatus,
                        Pageable pageable);

        /** Tìm theo tên (gợi ý khi gõ). */
        @Query("""
                        select p from Product p
                        join fetch p.category c
                        where p.status = :status and c.status = :categoryStatus
                          and lower(p.name) like lower(concat('%', :kw, '%'))
                        order by p.createdAt desc, p.id desc
                        """)
        List<Product> searchByName(@Param("kw") String kw,
                        @Param("status") ProductStatus status,
                        @Param("categoryStatus") CategoryStatus categoryStatus,
                        Pageable pageable);

        /** Tìm chi tiết sản phẩm kèm danh mục và các biến thể theo ID. */
        @Query("""
                        select distinct p from Product p
                        join fetch p.category c
                        left join fetch p.variants v
                        where p.id = :id
                        """)
        Optional<Product> findByIdWithDetails(@Param("id") Long id);

        /**
         * Tìm các sản phẩm liên quan cùng danh mục (loại trừ chính sản phẩm đang xem).
         */
        @Query("""
                        select p from Product p
                        join fetch p.category c
                        where p.category.id = :categoryId
                          and p.id <> :productId
                          and p.status = :status
                          and c.status = :categoryStatus
                        order by p.createdAt desc, p.id desc
                        """)
        List<Product> findRelatedProducts(@Param("categoryId") Long categoryId,
                        @Param("productId") Long productId,
                        @Param("status") ProductStatus status,
                        @Param("categoryStatus") CategoryStatus categoryStatus,
                        Pageable pageable);

        /**
         * Lấy tất cả sản phẩm đang bán kèm danh mục và các biến thể (dùng cho Chatbot /
         * Tra cứu).
         */
        @Query("""
                        select distinct p from Product p
                        join fetch p.category c
                        left join fetch p.variants v
                        where p.status = :status and c.status = :categoryStatus
                        order by p.createdAt desc, p.id desc
                        """)
        List<Product> findAllActiveWithVariants(@Param("status") ProductStatus status,
                        @Param("categoryStatus") CategoryStatus categoryStatus);
}
