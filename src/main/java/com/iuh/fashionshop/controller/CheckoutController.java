package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.CartItem;
import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.OrderItem;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.model.enums.PaymentMethod;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.CouponRepository;
import com.iuh.fashionshop.repository.OrderRepository;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import com.iuh.fashionshop.service.CartService;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Thanh toán. Cần đăng nhập (đã cấu hình trong SecurityConfig).
 *
 * Hai chế độ:
 *  - Mua ngay:  /checkout?variantId=...&quantity=...  -> chỉ thanh toán đúng 1 món đó,
 *               KHÔNG đụng tới giỏ hàng (không ghi gì vào bảng cart_item).
 *  - Từ giỏ:    /checkout                              -> thanh toán toàn bộ giỏ hàng.
 */
@Controller
@RequestMapping("/checkout")
public class CheckoutController {

    private static final BigDecimal SHIPPING_FEE = new BigDecimal("30000");

    private final CartService cartService;
    private final ProductVariantRepository productVariantRepository;
    private final OrderRepository orderRepository;
    private final CouponRepository couponRepository;

    public CheckoutController(CartService cartService,
                              ProductVariantRepository productVariantRepository,
                              OrderRepository orderRepository,
                              CouponRepository couponRepository) {
        this.cartService = cartService;
        this.productVariantRepository = productVariantRepository;
        this.orderRepository = orderRepository;
        this.couponRepository = couponRepository;
    }

    @GetMapping
    public String index(@RequestParam(required = false) Long variantId,
                        @RequestParam(defaultValue = "1") int quantity,
                        Authentication auth,
                        Model model,
                        RedirectAttributes redirectAttributes) {

        List<CartItem> items;
        boolean buyNow = variantId != null;

        if (buyNow) {
            // ===== MUA NGAY: chỉ 1 sản phẩm, không dùng giỏ hàng =====
            ProductVariant variant = productVariantRepository.findByIdWithProduct(variantId).orElse(null);
            if (variant == null
                    || variant.getStatus() != VariantStatus.ACTIVE
                    || variant.getStockQuantity() <= 0) {
                redirectAttributes.addFlashAttribute("errorMessage", "Sản phẩm này hiện không thể mua.");
                return "redirect:/shop";
            }

            int qty = Math.max(1, Math.min(quantity, variant.getStockQuantity()));

            // CartItem tạm trong bộ nhớ (KHÔNG save) để tái sử dụng giao diện checkout
            CartItem temp = new CartItem();
            temp.setVariant(variant);
            temp.setQuantity(qty);
            items = List.of(temp);

            model.addAttribute("buyNow", true);
            model.addAttribute("buyNowVariantId", variant.getId());
            model.addAttribute("buyNowQuantity", qty);
        } else {
            // ===== THANH TOÁN TỪ GIỎ HÀNG =====
            items = cartService.getCartItems(auth);
            if (items.isEmpty()) {
                return "redirect:/cart";
            }
            model.addAttribute("buyNow", false);
        }

        BigDecimal subtotal = BigDecimal.ZERO;
        for (CartItem item : items) {
            subtotal = subtotal.add(item.calculateSubtotal());
        }

        model.addAttribute("cartItems", items);
        model.addAttribute("cartSubtotal", subtotal);
        model.addAttribute("shippingFee", SHIPPING_FEE);
        model.addAttribute("grandTotal", subtotal.add(SHIPPING_FEE));
        model.addAttribute("profile", cartService.getOrCreateProfile(auth));
        return "user/checkout";
    }

    /**
     * Đặt hàng.
     *  - Có buyNowVariantId: chỉ tạo đơn từ đúng món đó, KHÔNG đụng tới giỏ hàng.
     *  - Không có: tạo đơn từ toàn bộ giỏ hàng rồi xoá giỏ.
     */
    @PostMapping
    @Transactional
    public String placeOrder(@RequestParam String recipientName,
                             @RequestParam String recipientPhone,
                             @RequestParam String shippingAddress,
                             @RequestParam(required = false) String note,
                             @RequestParam(defaultValue = "COD") String paymentMethod,
                             @RequestParam(required = false) String couponCode,
                             @RequestParam(required = false) Long buyNowVariantId,
                             @RequestParam(defaultValue = "1") int buyNowQuantity,
                             Authentication auth,
                             RedirectAttributes ra) {

        boolean buyNow = buyNowVariantId != null;
        String backUrl = buyNow
                ? "redirect:/checkout?variantId=" + buyNowVariantId + "&quantity=" + buyNowQuantity
                : "redirect:/checkout";

        UserProfile profile = cartService.getOrCreateProfile(auth);
        if (profile == null) {
            return "redirect:/login";
        }

        // ---- Kiểm tra thông tin giao hàng ----
        String name = recipientName == null ? "" : recipientName.trim();
        String phone = recipientPhone == null ? "" : recipientPhone.trim().replaceAll("\\s+", "");
        String address = shippingAddress == null ? "" : shippingAddress.trim();
        if (name.isEmpty() || address.isEmpty()) {
            ra.addFlashAttribute("errorMessage", "Vui lòng nhập đầy đủ họ tên và địa chỉ nhận hàng.");
            return backUrl;
        }
        if (!phone.matches("^\\+?[0-9]{9,14}$")) {
            ra.addFlashAttribute("errorMessage", "Số điện thoại không hợp lệ.");
            return backUrl;
        }

        PaymentMethod method;
        try {
            method = PaymentMethod.valueOf(paymentMethod);
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("errorMessage", "Phương thức thanh toán không hợp lệ.");
            return backUrl;
        }

        // ---- Lấy danh sách món cần mua: (variantId, quantity) ----
        List<ProductVariant> variants = new ArrayList<>();
        List<Integer> quantities = new ArrayList<>();

        if (buyNow) {
            ProductVariant v = productVariantRepository.findByIdWithProduct(buyNowVariantId).orElse(null);
            if (v == null) {
                ra.addFlashAttribute("errorMessage", "Sản phẩm không tồn tại.");
                return "redirect:/shop";
            }
            variants.add(v);
            quantities.add(Math.max(1, buyNowQuantity));
        } else {
            List<CartItem> cartItems = cartService.getCartItems(auth);
            if (cartItems.isEmpty()) {
                return "redirect:/cart";
            }
            for (CartItem ci : cartItems) {
                variants.add(ci.getVariant());
                quantities.add(ci.getQuantity());
            }
        }

        // ---- Tạo đơn hàng ----
        Order order = new Order();
        order.setOrderCode(generateOrderCode());
        order.setUserProfile(profile);
        order.setStatus(OrderStatus.PENDING);

        order.getShippingInfo().setRecipientName(name);
        order.getShippingInfo().setRecipientPhone(phone);
        order.getShippingInfo().setShippingAddress(address);
        order.getShippingInfo().setShippingFee(SHIPPING_FEE);
        order.getShippingInfo().setNote(note == null || note.isBlank() ? null : note.trim());
        order.getPaymentInfo().setPaymentMethod(method);

        for (int i = 0; i < variants.size(); i++) {
            ProductVariant v = variants.get(i);
            int qty = quantities.get(i);

            if (v.getStatus() != VariantStatus.ACTIVE || !v.isInStock(qty)) {
                ra.addFlashAttribute("errorMessage", "Sản phẩm \"" + v.getProduct().getName()
                        + "\" (" + v.getColor() + " - " + v.getSize() + ") không đủ hàng.");
                return buyNow ? "redirect:/shop" : "redirect:/cart";
            }

            OrderItem oi = new OrderItem();
            oi.setVariant(v);
            oi.setProductName(v.getProduct().getName());
            oi.setSize(v.getSize());
            oi.setColor(v.getColor());
            oi.setUnitPrice(v.getProduct().getCurrentPrice());
            oi.setQuantity(qty);
            order.addItem(oi);
        }

        // ---- Mã giảm giá (nếu có) ----
        BigDecimal subtotal = order.getItems().stream()
                .map(OrderItem::calculateSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        Coupon coupon = null;
        if (couponCode != null && !couponCode.isBlank()) {
            coupon = couponRepository.findByCodeIgnoreCase(couponCode.trim()).orElse(null);
            if (coupon == null || !coupon.isValid(subtotal)) {
                ra.addFlashAttribute("errorMessage", "Mã giảm giá không hợp lệ hoặc không đủ điều kiện áp dụng.");
                return backUrl;
            }
            order.setCoupon(coupon);
        }

        order.recalculateTotal();

        // ---- Trừ tồn kho (có @Version nên hai người mua cùng lúc sẽ không bị âm kho) ----
        try {
            for (OrderItem oi : order.getItems()) {
                ProductVariant v = oi.getVariant();
                v.decreaseStock(oi.getQuantity());
                productVariantRepository.saveAndFlush(v);
            }
        } catch (IllegalStateException | org.springframework.orm.ObjectOptimisticLockingFailureException e) {
            // Huỷ toàn bộ thay đổi tồn kho đã trừ trước đó trong giao dịch này
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
            ra.addFlashAttribute("errorMessage", "Sản phẩm vừa hết hàng hoặc có người khác vừa mua, vui lòng thử lại.");
            return buyNow ? "redirect:/shop" : "redirect:/cart";
        }

        if (coupon != null) {
            coupon.setUsedCount(coupon.getUsedCount() + 1);
            couponRepository.save(coupon);
        }

        orderRepository.save(order);

        // Chỉ xoá giỏ hàng khi thanh toán từ giỏ. Mua ngay thì giữ nguyên giỏ.
        if (!buyNow) {
            cartService.clearCart(auth);
        }

        ra.addFlashAttribute("successMessage", "Đặt hàng thành công! Mã đơn: " + order.getOrderCode());
        return "redirect:/orders/" + order.getId();
    }

    private String generateOrderCode() {
        String time = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyMMddHHmmss"));
        int rnd = ThreadLocalRandom.current().nextInt(100, 1000);
        return "FS" + time + rnd;
    }
}
