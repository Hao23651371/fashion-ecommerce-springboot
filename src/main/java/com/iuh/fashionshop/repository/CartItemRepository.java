package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    @Query("""
        select c from CartItem c
        join fetch c.variant v
        join fetch v.product p
        join fetch p.category cat
        where c.userProfile.id = :profileId
        order by c.addedAt desc, c.id desc
    """)
    List<CartItem> findByProfileIdWithDetails(@Param("profileId") Long profileId);

    Optional<CartItem> findByUserProfileIdAndVariantId(Long userProfileId, Long variantId);

    @Query("select coalesce(sum(c.quantity), 0) from CartItem c where c.userProfile.id = :profileId")
    int countTotalQuantityByProfileId(@Param("profileId") Long profileId);

    void deleteByUserProfileIdAndId(Long userProfileId, Long id);

    void deleteAllByUserProfileId(Long userProfileId);
}

