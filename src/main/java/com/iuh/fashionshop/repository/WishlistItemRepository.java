package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.WishlistItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WishlistItemRepository extends JpaRepository<WishlistItem, Long> {

    @Query("""
        SELECT w.product.id FROM WishlistItem w
        JOIN w.product p
        JOIN p.category c
        WHERE w.userProfile.id = :profileId
          AND p.status = com.iuh.fashionshop.model.enums.ProductStatus.ACTIVE
          AND c.status = com.iuh.fashionshop.model.enums.CategoryStatus.VISIBLE
        ORDER BY w.addedAt DESC
    """)
    List<Long> findProductIdsByProfileId(@Param("profileId") Long profileId);

    @Query("""
        SELECT COUNT(w) FROM WishlistItem w
        JOIN w.product p
        JOIN p.category c
        WHERE w.userProfile.id = :profileId
          AND p.status = com.iuh.fashionshop.model.enums.ProductStatus.ACTIVE
          AND c.status = com.iuh.fashionshop.model.enums.CategoryStatus.VISIBLE
    """)
    int countByUserProfileId(@Param("profileId") Long profileId);

    @Query("""
        SELECT COUNT(w) FROM WishlistItem w
        JOIN w.product p
        JOIN p.category c
        WHERE w.userProfile.account.email = :email
          AND p.status = com.iuh.fashionshop.model.enums.ProductStatus.ACTIVE
          AND c.status = com.iuh.fashionshop.model.enums.CategoryStatus.VISIBLE
    """)
    int countByAccountEmail(@Param("email") String email);

    boolean existsByUserProfileIdAndProductId(Long profileId, Long productId);

    Optional<WishlistItem> findByUserProfileIdAndProductId(Long profileId, Long productId);

    @Modifying
    @Query("DELETE FROM WishlistItem w WHERE w.userProfile.id = :profileId AND w.product.id = :productId")
    void deleteByUserProfileIdAndProductId(@Param("profileId") Long profileId, @Param("productId") Long productId);

    @Modifying
    @Query("DELETE FROM WishlistItem w WHERE w.userProfile.id = :profileId")
    void deleteAllByUserProfileId(@Param("profileId") Long profileId);
}
