package com.iuh.fashionshop.repository;


import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.model.enums.ProductStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

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




}
