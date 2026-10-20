package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.enums.CouponStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface CouponRepository extends JpaRepository<Coupon, Long> {

    @Query("""
            select c from Coupon c
            where c.status = :status
              and c.startDate <= :now and c.endDate >= :now
              and c.usedCount < c.quantity
            order by c.endDate asc
            """)
    List<Coupon> findActiveCoupons(@Param("status") CouponStatus status,
                                  @Param("now") LocalDateTime now);

    Optional<Coupon> findByCodeIgnoreCase(String code);
}
