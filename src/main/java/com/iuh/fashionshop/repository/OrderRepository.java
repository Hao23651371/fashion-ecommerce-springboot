package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.enums.OrderStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByStatusOrderByCreatedAtAsc(OrderStatus status);
    long countByUserProfileId(Long profileId);

    @Query("""
        select distinct o from Order o
        join fetch o.userProfile up
        left join fetch o.items oi
        left join fetch oi.variant v
        left join fetch v.product p
        where o.id = :id
    """)
    Optional<Order> findByIdWithDetails(@Param("id") Long id);

    Optional<Order> findByOrderCode(String orderCode);
}
