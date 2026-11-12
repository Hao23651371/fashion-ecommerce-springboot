package com.iuh.fashionshop.model;

import com.iuh.fashionshop.model.enums.CouponStatus;
import com.iuh.fashionshop.model.enums.CustomerTargetType;
import com.iuh.fashionshop.model.enums.DiscountType;
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

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "discount_type", nullable = false, length = 20)
    private DiscountType discountType = DiscountType.PERCENT;

    @Column(name = "discount_value", nullable = false, precision = 15, scale = 2)
    private BigDecimal discountValue; // PERCENT: 10 = 10% ; FIXED_AMOUNT: absolute amount ; FREESHIP: 0 = full, >0 = max ship discount

    @Column(name = "max_discount", precision = 15, scale = 2)
    private BigDecimal maxDiscount; // applies to PERCENT (max VND discount), null = unlimited

    @Column(name = "min_order_value", precision = 15, scale = 2)
    private BigDecimal minOrderValue;

    @Column(nullable = false)
    private int quantity; // Total usage limit across system

    @Column(name = "used_count", nullable = false)
    private int usedCount = 0;

    @Column(name = "per_user_limit", nullable = false)
    private int perUserLimit = 1; // Giới hạn số lượt dùng trên mỗi tài khoản khách hàng

    @Enumerated(EnumType.STRING)
    @Column(name = "target_customer_type", nullable = false, length = 20)
    private CustomerTargetType targetCustomerType = CustomerTargetType.ALL; // ALL, NEW_CUSTOMER, VIP

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "applicable_category_id")
    private Category applicableCategory; // null = Toàn shop (ALL), khác null = chỉ áp dụng riêng cho danh mục này

    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CouponStatus status = CouponStatus.ACTIVE;

    /**
     * Xác định trạng thái vòng đời thực tế của mã:
     * - PAUSED (Admin chủ động tạm dừng)
     * - UPCOMING (Chưa đến ngày bắt đầu)
     * - EXPIRED (Đã qua ngày kết thúc hoặc hết sạch lượt dùng)
     * - ACTIVE (Đang hoạt động bình thường)
     */
    public CouponStatus getComputedStatus() {
        if (status == CouponStatus.PAUSED || status == CouponStatus.DISABLED || status == CouponStatus.INACTIVE) {
            return CouponStatus.PAUSED;
        }
        LocalDateTime now = LocalDateTime.now();
        if (startDate != null && now.isBefore(startDate)) {
            return CouponStatus.UPCOMING;
        }
        if ((endDate != null && now.isAfter(endDate)) || (quantity > 0 && usedCount >= quantity)) {
            return CouponStatus.EXPIRED;
        }
        return CouponStatus.ACTIVE;
    }

    public boolean isValid(BigDecimal subtotal) {
        boolean active = getComputedStatus() == CouponStatus.ACTIVE;
        boolean minAmountMet = (minOrderValue == null || subtotal == null || subtotal.compareTo(minOrderValue) >= 0);
        return active && minAmountMet;
    }

    /**
     * QUY TẮC NGHIỆP VỤ TÍNH MỨC GIẢM GIÁ TIỀN HÀNG:
     * - eligibleSubtotal: Tổng giá trị các sản phẩm hợp lệ được áp dụng mã.
     *   + Nếu áp dụng toàn shop: eligibleSubtotal = subtotal toàn đơn.
     *   + Nếu áp dụng cho danh mục nhất định: eligibleSubtotal = tổng giá trị các sản phẩm thuộc danh mục đó.
     * - Nếu mã giảm theo Phần trăm (%):
     *   + Số tiền giảm = (eligibleSubtotal * discountValue) / 100.
     *   + Nếu có cài đặt "Mức giảm tối đa (maxDiscount)", số tiền giảm không được vượt quá maxDiscount.
     * - Nếu mã giảm theo Số tiền cố định (FIXED_AMOUNT): Giảm trực tiếp discountValue (tối đa bằng eligibleSubtotal).
     * - Nếu mã là FREESHIP: Trả về 0 (vì freeship chỉ giảm trên phí ship).
     */
    public BigDecimal calculateDiscount(BigDecimal eligibleSubtotal) {
        if (eligibleSubtotal == null || eligibleSubtotal.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        if (discountType == DiscountType.FREESHIP) {
            // Mã freeship chỉ giảm phí ship, không giảm trực tiếp tiền hàng
            return BigDecimal.ZERO;
        }
        BigDecimal discount;
        if (discountType == DiscountType.PERCENT) {
            discount = eligibleSubtotal.multiply(discountValue).divide(BigDecimal.valueOf(100), 0, RoundingMode.HALF_UP);
            if (maxDiscount != null && discount.compareTo(maxDiscount) > 0) {
                discount = maxDiscount;
            }
        } else {
            discount = discountValue != null ? discountValue : BigDecimal.ZERO;
        }
        return discount.min(eligibleSubtotal);
    }

    /**
     * QUY TẮC NGHIỆP VỤ MIỄN PHÍ VẬN CHUYỂN (FREESHIP):
     * - Nếu discountValue null hoặc <= 0: Miễn phí 100% (giảm toàn bộ phí vận chuyển).
     * - Nếu discountValue > 0: Hỗ trợ một phần phí vận chuyển (giảm tối đa discountValue VNĐ).
     */
    public BigDecimal calculateShippingDiscount(BigDecimal shippingFee) {
        if (shippingFee == null || shippingFee.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        if (discountType != DiscountType.FREESHIP) {
            return BigDecimal.ZERO;
        }
        // Nếu discountValue null hoặc 0 => miễn 100% phí ship
        if (discountValue == null || discountValue.compareTo(BigDecimal.ZERO) <= 0) {
            return shippingFee;
        }
        // Ngược lại giảm tối đa discountValue
        return discountValue.min(shippingFee);
    }
}

