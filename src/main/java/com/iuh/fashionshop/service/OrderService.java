package com.iuh.fashionshop.service;

import com.iuh.fashionshop.form.CheckoutForm;
import com.iuh.fashionshop.model.*;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.model.enums.PaymentMethod;
import com.iuh.fashionshop.model.enums.PaymentStatus;
import com.iuh.fashionshop.repository.CouponRepository;
import com.iuh.fashionshop.repository.OrderRepository;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Đặt hàng & thanh toán (COD / chuyển khoản / ví điện tử giả lập).
 * Không sửa Entity hay file khung; chỉ gọi repository/service có sẵn.
 */
@Service
@Transactional
public class OrderService {

    /** Miễn phí ship từ mốc này (đồng bộ với dữ liệu mẫu fashion4.sql). */
    public static final BigDecimal FREE_SHIP_THRESHOLD = new BigDecimal("1000000");
    public static final BigDecimal DEFAULT_SHIPPING_FEE = new BigDecimal("30000");

    private final OrderRepository orderRepository;
    private final CouponRepository couponRepository;
    private final ProductVariantRepository productVariantRepository;
    private final CartService cartService;

    public OrderService(OrderRepository orderRepository,
                        CouponRepository couponRepository,
                        ProductVariantRepository productVariantRepository,
                        CartService cartService) {
        this.orderRepository = orderRepository;
        this.couponRepository = couponRepository;
        this.productVariantRepository = productVariantRepository;
        this.cartService = cartService;
    }

    /**
     * Tính phí ship: miễn phí nếu tạm tính >= 1.000.000đ.
     */
    public BigDecimal calculateShippingFee(BigDecimal subtotal) {
        if (subtotal == null) {
            return DEFAULT_SHIPPING_FEE;
        }
        return subtotal.compareTo(FREE_SHIP_THRESHOLD) >= 0
                ? BigDecimal.ZERO
                : DEFAULT_SHIPPING_FEE;
    }

    /**
     * Validate mã giảm giá, trả về coupon hợp lệ hoặc null.
     * Ném IllegalArgumentException nếu mã sai / hết hạn / không đủ điều kiện.
     */
    @Transactional(readOnly = true)
    public Coupon validateCoupon(String code, BigDecimal subtotal) {
        if (code == null || code.isBlank()) {
            return null;
        }
        Coupon coupon = couponRepository.findByCodeIgnoreCase(code.trim())
                .orElseThrow(() -> new IllegalArgumentException("Mã giảm giá không tồn tại"));
        if (!coupon.isValid(subtotal)) {
            throw new IllegalArgumentException("Mã giảm giá không hợp lệ, đã hết hạn hoặc chưa đủ điều kiện áp dụng");
        }
        return coupon;
    }

    /**
     * Đặt hàng từ giỏ hiện tại.
     * - COD: status PENDING, payment UNPAID
     * - BANK_TRANSFER: status PENDING, payment UNPAID (admin xác nhận sau)
     * - E_WALLET: status PENDING, payment UNPAID → client chuyển sang trang giả lập thanh toán ví
     *
     * Trả về Order đã lưu. Giỏ hàng được xóa sau khi tạo đơn thành công.
     */
    public Order placeOrder(CheckoutForm form, Authentication auth) {
        UserProfile profile = cartService.getOrCreateProfile(auth);
        if (profile == null) {
            throw new IllegalStateException("Vui lòng đăng nhập để đặt hàng");
        }

        List<CartItem> cartItems = cartService.getCartItems(auth);
        if (cartItems == null || cartItems.isEmpty()) {
            throw new IllegalStateException("Giỏ hàng trống. Vui lòng chọn sản phẩm trước khi thanh toán");
        }

        // Kiểm tra tồn kho trước khi tạo đơn
        for (CartItem item : cartItems) {
            ProductVariant variant = item.getVariant();
            if (variant == null || !variant.isInStock(item.getQuantity())) {
                String name = (variant != null && variant.getProduct() != null)
                        ? variant.getProduct().getName()
                        : "Sản phẩm";
                throw new IllegalStateException("Không đủ hàng: " + name
                        + (variant != null ? " (" + variant.getColor() + " / " + variant.getSize() + ")" : ""));
            }
        }

        BigDecimal subtotal = cartItems.stream()
                .map(CartItem::calculateSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Coupon coupon = null;
        BigDecimal discount = BigDecimal.ZERO;
        if (form.getCouponCode() != null && !form.getCouponCode().isBlank()) {
            coupon = validateCoupon(form.getCouponCode(), subtotal);
            discount = coupon.calculateDiscount(subtotal);
        }

        BigDecimal shippingFee = calculateShippingFee(subtotal);
        BigDecimal total = subtotal.subtract(discount).add(shippingFee);

        Order order = new Order();
        order.setOrderCode(generateOrderCode());
        order.setUserProfile(profile);
        order.setCoupon(coupon);
        order.setStatus(OrderStatus.PENDING);
        order.setSubtotal(subtotal);
        order.setDiscountAmount(discount);
        order.setTotalAmount(total);

        ShippingInfo shipping = new ShippingInfo();
        shipping.setRecipientName(form.getRecipientName().trim());
        shipping.setRecipientPhone(form.getRecipientPhone().trim());
        shipping.setShippingAddress(form.getShippingAddress().trim());
        shipping.setShippingFee(shippingFee);
        shipping.setNote(form.getNote() != null && !form.getNote().isBlank() ? form.getNote().trim() : null);
        order.setShippingInfo(shipping);

        PaymentMethod method = form.getPaymentMethod() != null ? form.getPaymentMethod() : PaymentMethod.COD;
        PaymentInfo payment = new PaymentInfo();
        payment.setPaymentMethod(method);
        payment.setPaymentStatus(PaymentStatus.UNPAID);
        payment.setPaidAt(null);
        order.setPaymentInfo(payment);

        // Snapshot item + trừ kho
        for (CartItem cartItem : cartItems) {
            ProductVariant variant = cartItem.getVariant();
            Product product = variant.getProduct();

            OrderItem oi = new OrderItem();
            oi.setVariant(variant);
            oi.setProductName(product.getName());
            oi.setSize(variant.getSize());
            oi.setColor(variant.getColor());
            oi.setUnitPrice(product.getCurrentPrice());
            oi.setQuantity(cartItem.getQuantity());
            order.addItem(oi);

            variant.decreaseStock(cartItem.getQuantity());
            productVariantRepository.save(variant);
        }

        if (coupon != null) {
            coupon.setUsedCount(coupon.getUsedCount() + 1);
            couponRepository.save(coupon);
        }

        Order saved = orderRepository.save(order);
        cartService.clearCart(auth);
        return saved;
    }

    /**
     * Xác nhận thanh toán online thành công (giả lập ZaloPay / MoMo / ShopeePay).
     * Chỉ áp dụng cho đơn E_WALLET còn UNPAID của đúng user.
     */
    public Order confirmOnlinePayment(Long orderId, Authentication auth) {
        UserProfile profile = cartService.getOrCreateProfile(auth);
        if (profile == null) {
            throw new IllegalStateException("Vui lòng đăng nhập");
        }

        Order order = orderRepository.findByIdWithDetails(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

        if (!order.getUserProfile().getId().equals(profile.getId())) {
            throw new IllegalStateException("Bạn không có quyền thao tác đơn hàng này");
        }

        PaymentInfo pay = order.getPaymentInfo();
        if (pay == null || pay.getPaymentMethod() != PaymentMethod.E_WALLET) {
            throw new IllegalStateException("Đơn hàng không phải thanh toán ví điện tử");
        }
        if (pay.getPaymentStatus() == PaymentStatus.PAID) {
            return order; // idempotent
        }
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new IllegalStateException("Đơn hàng đã bị hủy, không thể thanh toán");
        }

        pay.setPaymentStatus(PaymentStatus.PAID);
        pay.setPaidAt(LocalDateTime.now());
        // Sau khi thanh toán ví thành công → xác nhận đơn
        if (order.getStatus() == OrderStatus.PENDING) {
            order.setStatus(OrderStatus.CONFIRMED);
        }
        return orderRepository.save(order);
    }

    /**
     * Đánh dấu thanh toán ví thất bại (giả lập).
     */
    public Order failOnlinePayment(Long orderId, Authentication auth) {
        UserProfile profile = cartService.getOrCreateProfile(auth);
        if (profile == null) {
            throw new IllegalStateException("Vui lòng đăng nhập");
        }

        Order order = orderRepository.findByIdWithDetails(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

        if (!order.getUserProfile().getId().equals(profile.getId())) {
            throw new IllegalStateException("Bạn không có quyền thao tác đơn hàng này");
        }

        PaymentInfo pay = order.getPaymentInfo();
        if (pay == null || pay.getPaymentMethod() != PaymentMethod.E_WALLET) {
            throw new IllegalStateException("Đơn hàng không phải thanh toán ví điện tử");
        }
        if (pay.getPaymentStatus() == PaymentStatus.PAID) {
            throw new IllegalStateException("Đơn đã thanh toán, không thể đánh dấu thất bại");
        }

        pay.setPaymentStatus(PaymentStatus.FAILED);
        // Hủy đơn + hoàn kho + hoàn lượt coupon (tương tự OrderController cancel)
        if (order.getStatus() == OrderStatus.PENDING) {
            order.setStatus(OrderStatus.CANCELLED);
            order.setCancelledAt(LocalDateTime.now());
            order.setCancelReason("Thanh toán ví điện tử thất bại");

            for (OrderItem item : order.getItems()) {
                if (item.getVariant() != null) {
                    item.getVariant().increaseStock(item.getQuantity());
                    productVariantRepository.save(item.getVariant());
                }
            }
            if (order.getCoupon() != null) {
                Coupon c = order.getCoupon();
                if (c.getUsedCount() > 0) {
                    c.setUsedCount(c.getUsedCount() - 1);
                    couponRepository.save(c);
                }
            }
        }
        return orderRepository.save(order);
    }

    /** Mã đơn dạng FS + yyyyMMdd + 3 số ngẫu nhiên (khớp mẫu FS20261010001). */
    private String generateOrderCode() {
        String datePart = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        int seq = ThreadLocalRandom.current().nextInt(100, 1000);
        String code = "FS" + datePart + seq;
        // Tránh trùng cực hiếm
        int guard = 0;
        while (orderRepository.findByOrderCode(code).isPresent() && guard < 20) {
            seq = ThreadLocalRandom.current().nextInt(100, 1000);
            code = "FS" + datePart + seq;
            guard++;
        }
        return code;
    }
}
