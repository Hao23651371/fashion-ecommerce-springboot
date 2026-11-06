package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.ProductVariant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ProductVariantRepository extends JpaRepository<ProductVariant, Long> {

    @Query("select v from ProductVariant v join fetch v.product p join fetch p.category where v.id = :id")
    Optional<ProductVariant> findByIdWithProduct(@Param("id") Long id);
}

