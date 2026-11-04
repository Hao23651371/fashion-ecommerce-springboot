package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.StockHistory;
import com.iuh.fashionshop.model.UserProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StockHistoryRepository extends JpaRepository<StockHistory, Long> {

    @Query("""
        select h from StockHistory h
        left join fetch h.variant v
        left join fetch v.product p
        left join fetch h.performedBy u
        where h.variant.id = :variantId
        order by h.createdAt desc
    """)
    List<StockHistory> findByVariantIdOrderByCreatedAtDesc(@Param("variantId") Long variantId);

    @Query("""
        select h from StockHistory h
        left join fetch h.variant v
        left join fetch v.product p
        left join fetch p.category c
        left join fetch h.performedBy u
        left join fetch u.account a
        order by h.createdAt desc
    """)
    List<StockHistory> findAllWithDetails();

    @Query(value = """
        select h from StockHistory h
        left join fetch h.variant v
        left join fetch v.product p
        left join fetch h.performedBy u
        order by h.createdAt desc
    """, countQuery = "select count(h) from StockHistory h")
    Page<StockHistory> findAllWithDetails(Pageable pageable);

    @Query("""
        select distinct u from StockHistory h
        join h.performedBy u
        left join fetch u.account a
        where h.performedBy is not null
        order by u.fullName asc
    """)
    List<UserProfile> findDistinctPerformers();
}
