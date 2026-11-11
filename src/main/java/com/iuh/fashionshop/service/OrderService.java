package com.iuh.fashionshop.service;

import com.iuh.fashionshop.form.CheckoutForm;
import com.iuh.fashionshop.model.*;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.model.enums.PaymentMethod;
import com.iuh.fashionshop.model.enums.PaymentStatus;
import com.iuh.fashionshop.model.enums.StockMovementType;
import com.iuh.fashionshop.repository.CouponRepository;
import com.iuh.fashionshop.repository.OrderRepository;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Nghiệp vụ đơn hàng đầy đủ: checkout khách + vận hành admin.
 */
@Service
@Transactional
public class OrderService {

    public static final BigDecimal FREE_SHIP_THRESHOLD = new BigDecimal("1000000");
    public static final BigDecimal DEFAULT_SHIPPING_FEE = new BigDecimal("30000");

    private static final Set<OrderStatus> CAN_CANCEL =
            EnumSet.of(OrderStatus.PENDING, OrderStatus.CONFIRMED);

    private final OrderRepository orderRepository;
    private final CouponRepository couponRepository;
    private final ProductVariantRepository productVariantRepository;
    private final CartService cartService;
    private final InventoryService inventoryService;

    public OrderService(OrderRepository orderRepository,
                        CouponRepository couponRepository,
                        ProductVariantRepository productVariantRepository,
                        CartService cartService,
                        InventoryService inventoryService) {
        this.orderRepository = orderRepository;
        this.couponRepository = couponRepository;
        this.productVariantRepository = productVariantRepository;
        this.cartService = cartService;
        this.inventoryService = inventoryService;
    }

    // ===================== CHECKOUT (KHÁCH) =====================

    public BigDecimal calculateShippingFee(BigDecimal subtotal) {
        if (subtotal == null) {
            return DEFAULT_SHIPPING_FEE;
        }
        return subtotal.compareTo(FREE_SHIP_THRESHOLD) >= 0
                ? BigDecimal.ZERO
                : DEFAULT_SHIPPING_FEE;
    }

    @Transactional(readOnly = true)
    public Coupon validateCoupon(String code, BigDecimal subtotal) {
        if (code == null || code.isBlank()) {
            return null;
        }
        Coupon coupon = couponRepository.findByCodeIgnoreCase(code.trim())
                .orElseThrow(() -> new IllegalArgumentException("Mã giảm giá không tồn tại"));
        if (!coupon.isValid(subtotal)) {
            throw new IllegalArgumentException(
                    "Mã giảm giá không hợp lệ, đã hết hạn hoặc chưa đủ điều kiện áp dụng");
        }
        return coupon;
    }

    public Order placeOrder(CheckoutForm form, Authentication auth) {
        UserProfile profile = cartService.getOrCreateProfile(auth);
        if (profile == null) {
            throw new IllegalStateException("Vui lòng đăng nhập để đặt hàng");
        }

        List<CartItem> cartItems = cartService.getCartItems(auth);
        if (cartItems == null || cartItems.isEmpty()) {
            throw new IllegalStateException("Giỏ hàng trống. Vui lòng chọn sản phẩm trước khi thanh toán");
        }

        for (CartItem item : cartItems) {
            ProductVariant variant = item.getVariant();
            if (variant == null || !variant.isInStock(item.getQuantity())) {
                String name = (variant != null && variant.getProduct() != null)
                        ? variant.getProduct().getName() : "Sản phẩm";
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

        // Ghi lịch sử kho (SALE) cho từng sản phẩm trong đơn
        for (OrderItem oi : saved.getItems()) {
            inventoryService.recordOrderMovement(oi.getVariant(), StockMovementType.SALE,
                    -oi.getQuantity(), saved, "Bán hàng - đơn " + saved.getOrderCode());
        }

        cartService.clearCart(auth);
        return saved;
    }

    public Order confirmOnlinePayment(Long orderId, Authentication auth) {
        UserProfile profile = requireProfile(auth);
        Order order = requireOrderOwned(orderId, profile);

        PaymentInfo pay = order.getPaymentInfo();
        if (pay == null || pay.getPaymentMethod() != PaymentMethod.E_WALLET) {
            throw new IllegalStateException("Đơn hàng không phải thanh toán ví điện tử");
        }
        if (pay.getPaymentStatus() == PaymentStatus.PAID) {
            return order;
        }
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new IllegalStateException("Đơn hàng đã bị hủy, không thể thanh toán");
        }

        pay.setPaymentStatus(PaymentStatus.PAID);
        pay.setPaidAt(LocalDateTime.now());
        if (order.getStatus() == OrderStatus.PENDING) {
            order.setStatus(OrderStatus.CONFIRMED);
        }
        return orderRepository.save(order);
    }

    public Order failOnlinePayment(Long orderId, Authentication auth) {
        UserProfile profile = requireProfile(auth);
        Order order = requireOrderOwned(orderId, profile);

        PaymentInfo pay = order.getPaymentInfo();
        if (pay == null || pay.getPaymentMethod() != PaymentMethod.E_WALLET) {
            throw new IllegalStateException("Đơn hàng không phải thanh toán ví điện tử");
        }
        if (pay.getPaymentStatus() == PaymentStatus.PAID) {
            throw new IllegalStateException("Đơn đã thanh toán, không thể đánh dấu thất bại");
        }

        pay.setPaymentStatus(PaymentStatus.FAILED);
        if (order.getStatus() == OrderStatus.PENDING) {
            cancelInternal(order, "Thanh toán ví điện tử thất bại");
        }
        return orderRepository.save(order);
    }

    // ===================== ADMIN =====================

    @Transactional(readOnly = true)
    public List<Order> searchForAdmin(String q, String statusStr, String paymentMethodStr,
                                      String fromStr, String toStr) {
        OrderStatus status = parseStatus(statusStr);
        PaymentMethod method = parseMethod(paymentMethodStr);
        LocalDateTime from = parseDateStart(fromStr);
        LocalDateTime to = parseDateEnd(toStr);
        String keyword = (q != null && !q.isBlank()) ? q.trim() : null;
        return orderRepository.searchAdmin(keyword, status, method, null, from, to);
    }

    @Transactional(readOnly = true)
    public Order getByIdForAdmin(Long id) {
        return orderRepository.findByIdWithDetails(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng #" + id));
    }

    @Transactional(readOnly = true)
    public long countByStatus(OrderStatus status) {
        return orderRepository.countByStatus(status);
    }

    /**
     * PENDING → CONFIRMED → SHIPPING → COMPLETED
     * Khi COMPLETED: nếu còn UNPAID (COD / CK) → PAID.
     */
    public Order updateStatus(Long orderId, OrderStatus target, String cancelReason) {
        Order order = getByIdForAdmin(orderId);
        OrderStatus current = order.getStatus();

        if (target == current) {
            return order;
        }

        if (target == OrderStatus.CANCELLED) {
            if (!CAN_CANCEL.contains(current)) {
                throw new IllegalStateException("Không thể hủy đơn đang ở trạng thái " + current);
            }
            cancelInternal(order, cancelReason != null && !cancelReason.isBlank()
                    ? cancelReason.trim()
                    : "Admin hủy đơn");
            return orderRepository.save(order);
        }

        if (current == OrderStatus.CANCELLED || current == OrderStatus.COMPLETED) {
            throw new IllegalStateException("Đơn " + current + " không thể đổi sang " + target);
        }

        validateTransition(current, target);
        order.setStatus(target);

        if (target == OrderStatus.COMPLETED) {
            order.setCompletedAt(LocalDateTime.now());
            markPaidIfUnpaid(order);
        }

        return orderRepository.save(order);
    }

    /**
     * Khách tự hủy đơn (chỉ đơn PENDING). Dùng chung cancelInternal với admin hủy / quá hạn thanh toán nên
     * kết quả luôn đồng nhất: hoàn kho + ghi lịch sử kho + hoàn lượt mã giảm giá + đổi UNPAID -> FAILED (ví điện tử).
     */
    public Order cancelByCustomer(Long orderId, Authentication auth, String reason) {
        UserProfile profile = requireProfile(auth);
        Order order = requireOrderOwned(orderId, profile);

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new IllegalStateException(
                    "Đơn hàng đang ở trạng thái '" + order.getStatus() + "', không thể hủy.");
        }
        cancelInternal(order, reason != null && !reason.isBlank() ? reason.trim() : "Khách hàng tự hủy đơn");
        return orderRepository.save(order);
    }

    /** Xác nhận đã nhận chuyển khoản → PAID (+ CONFIRMED nếu còn PENDING). */
    public Order confirmBankTransferPaid(Long orderId) {
        Order order = getByIdForAdmin(orderId);
        PaymentInfo pay = order.getPaymentInfo();
        if (pay == null || pay.getPaymentMethod() != PaymentMethod.BANK_TRANSFER) {
            throw new IllegalStateException("Đơn không phải chuyển khoản ngân hàng");
        }
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new IllegalStateException("Đơn đã hủy");
        }
        if (pay.getPaymentStatus() == PaymentStatus.PAID) {
            return order;
        }
        pay.setPaymentStatus(PaymentStatus.PAID);
        pay.setPaidAt(LocalDateTime.now());
        if (order.getStatus() == OrderStatus.PENDING) {
            order.setStatus(OrderStatus.CONFIRMED);
        }
        return orderRepository.save(order);
    }

    /** Đánh dấu đã thu COD. */
    public Order confirmCodCollected(Long orderId) {
        Order order = getByIdForAdmin(orderId);
        PaymentInfo pay = order.getPaymentInfo();
        if (pay == null || pay.getPaymentMethod() != PaymentMethod.COD) {
            throw new IllegalStateException("Đơn không phải COD");
        }
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new IllegalStateException("Đơn đã hủy");
        }
        markPaidIfUnpaid(order);
        return orderRepository.save(order);
    }

    private void validateTransition(OrderStatus from, OrderStatus to) {
        boolean ok = (from == OrderStatus.PENDING && (to == OrderStatus.CONFIRMED || to == OrderStatus.SHIPPING))
                || (from == OrderStatus.CONFIRMED && (to == OrderStatus.SHIPPING || to == OrderStatus.COMPLETED))
                || (from == OrderStatus.SHIPPING && to == OrderStatus.COMPLETED);
        if (!ok) {
            throw new IllegalStateException(
                    "Không hợp lệ: " + from + " → " + to
                            + ". Quy trình: PENDING → CONFIRMED → SHIPPING → COMPLETED (hoặc Hủy từ PENDING/CONFIRMED)");
        }
    }

    private void markPaidIfUnpaid(Order order) {
        PaymentInfo pay = order.getPaymentInfo();
        if (pay != null && pay.getPaymentStatus() != PaymentStatus.PAID) {
            pay.setPaymentStatus(PaymentStatus.PAID);
            pay.setPaidAt(LocalDateTime.now());
        }
    }

    private void cancelInternal(Order order, String reason) {
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledAt(LocalDateTime.now());
        order.setCancelReason(reason);

        for (OrderItem item : order.getItems()) {
            if (item.getVariant() != null) {
                item.getVariant().increaseStock(item.getQuantity());
                productVariantRepository.save(item.getVariant());

                // Ghi lịch sử kho (CANCELLED_ORDER)
                inventoryService.recordOrderMovement(item.getVariant(), StockMovementType.CANCELLED_ORDER,
                        item.getQuantity(), order,
                        "Hủy đơn " + order.getOrderCode() + (reason != null && !reason.isBlank() ? " - " + reason : ""));
            }
        }
        if (order.getCoupon() != null) {
            Coupon c = order.getCoupon();
            if (c.getUsedCount() > 0) {
                c.setUsedCount(c.getUsedCount() - 1);
                couponRepository.save(c);
            }
        }
        PaymentInfo pay = order.getPaymentInfo();
        if (pay != null && pay.getPaymentMethod() == PaymentMethod.E_WALLET
                && pay.getPaymentStatus() == PaymentStatus.UNPAID) {
            pay.setPaymentStatus(PaymentStatus.FAILED);
        }
    }

    private UserProfile requireProfile(Authentication auth) {
        UserProfile profile = cartService.getOrCreateProfile(auth);
        if (profile == null) {
            throw new IllegalStateException("Vui lòng đăng nhập");
        }
        return profile;
    }

    private Order requireOrderOwned(Long orderId, UserProfile profile) {
        Order order = orderRepository.findByIdWithDetails(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));
        if (!order.getUserProfile().getId().equals(profile.getId())) {
            throw new IllegalStateException("Bạn không có quyền thao tác đơn hàng này");
        }
        return order;
    }

    private String generateOrderCode() {
        String datePart = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        int seq = ThreadLocalRandom.current().nextInt(100, 1000);
        String code = "FS" + datePart + seq;
        int guard = 0;
        while (orderRepository.findByOrderCode(code).isPresent() && guard < 20) {
            seq = ThreadLocalRandom.current().nextInt(100, 1000);
            code = "FS" + datePart + seq;
            guard++;
        }
        return code;
    }

    private OrderStatus parseStatus(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            return OrderStatus.valueOf(s.trim().toUpperCase());
        } catch (Exception e) {
            return null;
        }
    }

    private PaymentMethod parseMethod(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            return PaymentMethod.valueOf(s.trim().toUpperCase());
        } catch (Exception e) {
            return null;
        }
    }

    private LocalDateTime parseDateStart(String s) {
        if (s == null || s.isBlank()) return null;
        return LocalDate.parse(s).atStartOfDay();
    }

    private LocalDateTime parseDateEnd(String s) {
        if (s == null || s.isBlank()) return null;
        return LocalDate.parse(s).atTime(LocalTime.MAX);
    }
}