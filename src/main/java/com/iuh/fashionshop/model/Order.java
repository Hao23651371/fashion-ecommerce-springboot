package com.iuh.fashionshop.model;

import com.iuh.fashionshop.model.enums.OrderStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders",
        uniqueConstraints = @UniqueConstraint(name = "uk_orders_code", columnNames = {"order_code"}))
@Getter
@Setter
@NoArgsConstructor
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_code", nullable = false, length = 30)
    private String orderCode;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_profile_id", nullable = false)
    private UserProfile userProfile;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coupon_id")
    private Coupon coupon;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrderStatus status = OrderStatus.PENDING;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal subtotal = BigDecimal.ZERO;

    @Column(name = "discount_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal discountAmount = BigDecimal.ZERO;

    @Column(name = "total_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalAmount = BigDecimal.ZERO;

    @Column(name = "cancel_reason", length = 255)
    private String cancelReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

    @Embedded
    private ShippingInfo shippingInfo = new ShippingInfo();

    @Embedded
    private PaymentInfo paymentInfo = new PaymentInfo();

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    @PrePersist
    void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    public void addItem(OrderItem item) {
        item.setOrder(this);
        items.add(item);
    }

    /**
     * QUY TẮC NGHIỆP VỤ TÍNH TỔNG TIỀN ĐƠN HÀNG (totalAmount = subtotal - discountAmount + shippingFee):
     * 1. subtotal: Tổng giá trị tiền hàng trước khi giảm giá.
     * 2. shippingFee: Phí vận chuyển.
     * 3. discountAmount (Mức giảm giá):
     *    - Nếu mã là FREESHIP: Giảm trên phí ship (tối đa phí ship).
     *    - Nếu mã có HẠN CHẾ DANH MỤC (applicableCategory != null): Mức giảm CHỈ ĐƯỢC TÍNH TRÊN
     *      TỔNG GIÁ TRỊ CÁC SẢN PHẨM HỢP LỆ THUỘC DANH MỤC ĐÓ TRONG ĐƠN (eligibleSubtotal),
     *      KHÔNG tính trên toàn bộ đơn hàng.
     *      (Ví dụ: Đơn 500k gồm Áo sơ mi 200k + Quần jean 300k, mã giảm 10% Áo sơ mi -> giảm 10% x 200k = 20k).
     *    - Nếu mã không giới hạn danh mục: Tính trên toàn bộ subtotal.
     *    - Nếu là mã giảm theo %: Bị chặn bởi mức giảm tối đa (maxDiscount).
     */
    public void recalculateTotal() {
        subtotal = items.stream()
                .map(OrderItem::calculateSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal fee = (shippingInfo != null && shippingInfo.getShippingFee() != null)
                ? shippingInfo.getShippingFee()
                : BigDecimal.ZERO;
        if (coupon != null) {
            if (coupon.getDiscountType() == com.iuh.fashionshop.model.enums.DiscountType.FREESHIP) {
                discountAmount = coupon.calculateShippingDiscount(fee);
            } else {
                BigDecimal eligibleSubtotal = subtotal;
                if (coupon.getApplicableCategory() != null) {
                    Long targetCatId = coupon.getApplicableCategory().getId();
                    eligibleSubtotal = items.stream()
                            .filter(item -> item.getVariant() != null && item.getVariant().getProduct() != null
                                    && item.getVariant().getProduct().getCategory() != null
                                    && java.util.Objects.equals(item.getVariant().getProduct().getCategory().getId(), targetCatId))
                            .map(OrderItem::calculateSubtotal)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                }
                discountAmount = coupon.calculateDiscount(eligibleSubtotal);
            }
        } else {
            discountAmount = BigDecimal.ZERO;
        }
        totalAmount = subtotal.subtract(discountAmount).add(fee).max(BigDecimal.ZERO);
    }

    public boolean canBeCancelled() {
        return status == OrderStatus.PENDING;
    }
}
