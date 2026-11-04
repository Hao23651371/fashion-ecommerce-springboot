package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.ProductVariant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductVariantRepository extends JpaRepository<ProductVariant, Long> {

    Optional<ProductVariant> findBySku(String sku);

    List<ProductVariant> findByProductId(Long productId);

    @Query("select v from ProductVariant v join fetch v.product p join fetch p.category c where v.id = :id")
    Optional<ProductVariant> findByIdWithProductAndCategory(@Param("id") Long id);

    @Query("""
        select distinct v from ProductVariant v
        join fetch v.product p
        join fetch p.category c
        order by p.id desc, v.id asc
    """)
    List<ProductVariant> findAllWithProductAndCategory();
}
