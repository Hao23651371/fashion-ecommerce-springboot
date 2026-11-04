package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.enums.OrderStatus;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByStatusOrderByCreatedAtAsc(OrderStatus status);
}
