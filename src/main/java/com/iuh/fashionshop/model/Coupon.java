package com.iuh.fashionshop.model;

import com.iuh.fashionshop.model.enums.DiscountType;
import com.iuh.fashionshop.model.enums.CouponStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;

@Entity
@Table(name = "coupon",
        uniqueConstraints = @UniqueConstraint(name = "uk_coupon_code", columnNames = {"code"}))
@Getter
@Setter
@NoArgsConstructor
public class Coupon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @Column(nullable = false, length = 150)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "discount_type", nullable = false, length = 20)
    private DiscountType discountType;

    @Column(name = "discount_value", nullable = false, precision = 15, scale = 2)
    private BigDecimal discountValue; // PERCENT: 10 = 10% ; FIXED_AMOUNT: absolute amount

    @Column(name = "max_discount", precision = 15, scale = 2)
    private BigDecimal maxDiscount; // only applies to PERCENT, null = unlimited

    @Column(name = "min_order_value", precision = 15, scale = 2)
    private BigDecimal minOrderValue;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "used_count", nullable = false)
    private int usedCount = 0;

    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CouponStatus status = CouponStatus.ACTIVE;

    public boolean isValid(BigDecimal subtotal) {
        LocalDateTime now = LocalDateTime.now();
        boolean validStatus = status == CouponStatus.ACTIVE;
        boolean withinDates = !now.isBefore(startDate) && !now.isAfter(endDate);
        boolean hasRemaining = usedCount < quantity;
        boolean minAmountMet = minOrderValue == null || subtotal.compareTo(minOrderValue) >= 0;
        return validStatus && withinDates && hasRemaining && minAmountMet;
    }

    public BigDecimal calculateDiscount(BigDecimal subtotal) {
        BigDecimal discount;
        if (discountType == DiscountType.PERCENT) {
            discount = subtotal.multiply(discountValue).divide(BigDecimal.valueOf(100), 0, RoundingMode.HALF_UP);
            if (maxDiscount != null && discount.compareTo(maxDiscount) > 0) {
                discount = maxDiscount;
            }
        } else {
            discount = discountValue;
        }
        return discount.min(subtotal);
    }
}
