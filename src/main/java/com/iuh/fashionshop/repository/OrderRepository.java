package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.model.enums.PaymentMethod;
import com.iuh.fashionshop.model.enums.PaymentStatus;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

/**
 * Ghi đè / thay file repository hiện có — thêm query cho admin.
 */
@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    List<Order> findByStatusOrderByCreatedAtAsc(OrderStatus status);

    long countByUserProfileId(Long profileId);
    boolean existsByUserProfileIdAndStatusIn(Long profileId, List<OrderStatus> statuses);

    long countByUserProfileIdAndCouponIdAndStatusNot(Long profileId, Long couponId, OrderStatus status);

    interface CouponStatProjection {
        Long getCouponId();
        Long getOrderCount();
        java.math.BigDecimal getTotalDiscount();
        java.math.BigDecimal getTotalRevenue();
    }

    @Query("""
        select o.coupon.id as couponId,
               count(o.id) as orderCount,
               coalesce(sum(o.discountAmount), 0) as totalDiscount,
               coalesce(sum(o.totalAmount), 0) as totalRevenue
        from Order o
        where o.coupon is not null and o.status != 'CANCELLED'
        group by o.coupon.id
        """)
    List<CouponStatProjection> getCouponUsageStats();

    long countByStatus(OrderStatus status);

    Optional<Order> findByOrderCode(String orderCode);

    @Query("""
        select distinct o from Order o
        join fetch o.userProfile up
        left join fetch o.items oi
        left join fetch oi.variant v
        left join fetch v.product p
        where o.id = :id
        """)
    Optional<Order> findByIdWithDetails(@Param("id") Long id);

    @Query("""
        select distinct o from Order o
        left join fetch o.userProfile
        left join fetch o.items
        order by o.createdAt desc
        """)
    List<Order> findAllWithBasicDetails();

    @Query("""
        select o from Order o
        left join fetch o.userProfile
        where (:status is null or o.status = :status)
          and (:paymentMethod is null or o.paymentInfo.paymentMethod = :paymentMethod)
          and (:paymentStatus is null or o.paymentInfo.paymentStatus = :paymentStatus)
          and (:from is null or o.createdAt >= :from)
          and (:to is null or o.createdAt < :to)
          and (
                :q is null or :q = ''
                or lower(o.orderCode) like lower(concat('%', :q, '%'))
                or lower(o.shippingInfo.recipientName) like lower(concat('%', :q, '%'))
                or lower(o.shippingInfo.recipientPhone) like lower(concat('%', :q, '%'))
              )
        order by o.createdAt desc
        """)
    List<Order> searchAdmin(@Param("q") String q,
                            @Param("status") OrderStatus status,
                            @Param("paymentMethod") PaymentMethod paymentMethod,
                            @Param("paymentStatus") PaymentStatus paymentStatus,
                            @Param("from") LocalDateTime from,
                            @Param("to") LocalDateTime to);
}
