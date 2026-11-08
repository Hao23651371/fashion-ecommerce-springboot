package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.form.CheckoutForm;
import com.iuh.fashionshop.model.CartItem;
import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.PaymentMethod;
import com.iuh.fashionshop.repository.ShippingAddressRepository;
import com.iuh.fashionshop.service.CartService;
import com.iuh.fashionshop.service.OrderService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Thanh toán (COD / Chuyển khoản / Ví điện tử giả lập ZaloPay-MoMo).
 * Cần đăng nhập (SecurityConfig đã cấu hình /checkout/**).
 */
@Controller
@RequestMapping("/checkout")
public class CheckoutController {

    private final CartService cartService;
    private final OrderService orderService;
    private final ShippingAddressRepository shippingAddressRepository;

    public CheckoutController(CartService cartService,
                              OrderService orderService,
                              ShippingAddressRepository shippingAddressRepository) {
        this.cartService = cartService;
        this.orderService = orderService;
        this.shippingAddressRepository = shippingAddressRepository;
    }

    @GetMapping
    public String index(Authentication auth, Model model,
                        @RequestParam(value = "coupon", required = false) String couponParam) {
        List<CartItem> cartItems = cartService.getCartItems(auth);
        if (cartItems == null || cartItems.isEmpty()) {
            return "redirect:/cart";
        }

        UserProfile profile = cartService.getOrCreateProfile(auth);
        BigDecimal cartSubtotal = cartService.getCartSubtotal(auth);
        BigDecimal discountAmount = BigDecimal.ZERO;
        String couponMessage = null;
        String appliedCode = null;

        if (couponParam != null && !couponParam.isBlank()) {
            try {
                Coupon c = orderService.validateCoupon(couponParam, cartSubtotal);
                discountAmount = c.calculateDiscount(cartSubtotal);
                appliedCode = c.getCode();
                couponMessage = "Áp dụng mã " + c.getCode() + " thành công (−"
                        + discountAmount.toPlainString() + " ₫)";
            } catch (IllegalArgumentException ex) {
                couponMessage = ex.getMessage();
            }
        }

        BigDecimal shippingFee = orderService.calculateShippingFee(cartSubtotal);
        BigDecimal grandTotal = cartSubtotal.subtract(discountAmount).add(shippingFee);

        CheckoutForm form = new CheckoutForm();
        if (profile != null) {
            form.setRecipientName(profile.getFullName());
            form.setRecipientPhone(profile.getPhoneNumber());
            shippingAddressRepository.findByUserProfileIdAndDefaultAddressTrue(profile.getId())
                    .ifPresent(addr -> form.setShippingAddress(addr.getAddress()));
        }
        if (appliedCode != null) {
            form.setCouponCode(appliedCode);
        }
        form.setPaymentMethod(PaymentMethod.COD);

        model.addAttribute("checkoutForm", form);
        model.addAttribute("profile", profile);
        model.addAttribute("cartItems", cartItems);
        model.addAttribute("cartSubtotal", cartSubtotal);
        model.addAttribute("discountAmount", discountAmount);
        model.addAttribute("shippingFee", shippingFee);
        model.addAttribute("grandTotal", grandTotal);
        model.addAttribute("couponMessage", couponMessage);
        return "user/checkout";
    }

    @PostMapping
    public String placeOrder(@Valid @ModelAttribute("checkoutForm") CheckoutForm form,
                             BindingResult bindingResult,
                             Authentication auth,
                             Model model,
                             RedirectAttributes ra) {
        List<CartItem> cartItems = cartService.getCartItems(auth);
        if (cartItems == null || cartItems.isEmpty()) {
            ra.addFlashAttribute("errorMessage", "Giỏ hàng trống.");
            return "redirect:/cart";
        }

        if (bindingResult.hasErrors()) {
            prepareCheckoutModel(model, auth, form, cartItems);
            return "user/checkout";
        }

        try {
            Order order = orderService.placeOrder(form, auth);

            // Ví điện tử → trang giả lập cổng thanh toán
            if (order.getPaymentInfo().getPaymentMethod() == PaymentMethod.E_WALLET) {
                return "redirect:/checkout/payment/" + order.getId();
            }

            // COD / chuyển khoản → trang chi tiết đơn
            ra.addFlashAttribute("successMessage",
                    "Đặt hàng thành công! Mã đơn: " + order.getOrderCode()
                            + (form.getPaymentMethod() == PaymentMethod.BANK_TRANSFER
                            ? ". Vui lòng chuyển khoản theo hướng dẫn và chờ xác nhận."
                            : ". Bạn sẽ thanh toán khi nhận hàng (COD)."));
            return "redirect:/orders/" + order.getId();
        } catch (IllegalArgumentException | IllegalStateException e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
            // Giữ form + coupon khi redirect về GET
            String q = (form.getCouponCode() != null && !form.getCouponCode().isBlank())
                    ? ("?coupon=" + form.getCouponCode().trim())
                    : "";
            return "redirect:/checkout" + q;
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", "Có lỗi khi đặt hàng: " + e.getMessage());
            return "redirect:/checkout";
        }
    }

    /**
     * Trang giả lập cổng thanh toán ví (ZaloPay / MoMo / ShopeePay).
     * Không tích hợp API thật (cần merchant key) — phù hợp đồ án, mô phỏng flow.
     */
    @GetMapping("/payment/{orderId}")
    public String paymentGateway(@PathVariable Long orderId, Authentication auth, Model model,
                                 RedirectAttributes ra) {
        try {
            // Chỉ load qua confirm không đổi trạng thái — dùng find trong service qua confirm fail-safe
            // Ở đây dùng lại orderService qua một lần "read" bằng confirmOnlinePayment không gọi khi GET
            // Đơn giản: render trang với orderId, JS/form sẽ POST confirm/fail
            model.addAttribute("orderId", orderId);
            return "user/payment-gateway";
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/orders";
        }
    }

    @PostMapping("/payment/{orderId}/success")
    public String paymentSuccess(@PathVariable Long orderId, Authentication auth, RedirectAttributes ra) {
        try {
            Order order = orderService.confirmOnlinePayment(orderId, auth);
            ra.addFlashAttribute("successMessage",
                    "Thanh toán ví điện tử thành công! Mã đơn: " + order.getOrderCode());
            return "redirect:/orders/" + order.getId();
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/orders";
        }
    }

    @PostMapping("/payment/{orderId}/fail")
    public String paymentFail(@PathVariable Long orderId, Authentication auth, RedirectAttributes ra) {
        try {
            Order order = orderService.failOnlinePayment(orderId, auth);
            ra.addFlashAttribute("errorMessage",
                    "Thanh toán thất bại. Đơn " + order.getOrderCode() + " đã được hủy và hoàn kho.");
            return "redirect:/orders/" + order.getId();
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/orders";
        }
    }

    /** AJAX kiểm tra / áp dụng mã giảm giá. */
    @PostMapping("/coupon")
    @ResponseBody
    public ResponseEntity<?> applyCoupon(@RequestParam String couponCode, Authentication auth) {
        try {
            BigDecimal subtotal = cartService.getCartSubtotal(auth);
            Coupon coupon = orderService.validateCoupon(couponCode, subtotal);
            BigDecimal discount = coupon.calculateDiscount(subtotal);
            BigDecimal shipping = orderService.calculateShippingFee(subtotal);
            BigDecimal grand = subtotal.subtract(discount).add(shipping);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Áp dụng mã " + coupon.getCode() + " thành công",
                    "code", coupon.getCode(),
                    "discountAmount", discount,
                    "shippingFee", shipping,
                    "grandTotal", grand
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("success", false, "message", "Lỗi: " + e.getMessage()));
        }
    }

    private void prepareCheckoutModel(Model model, Authentication auth, CheckoutForm form, List<CartItem> cartItems) {
        BigDecimal cartSubtotal = cartService.getCartSubtotal(auth);
        BigDecimal discountAmount = BigDecimal.ZERO;
        String couponMessage = null;
        if (form.getCouponCode() != null && !form.getCouponCode().isBlank()) {
            try {
                Coupon c = orderService.validateCoupon(form.getCouponCode(), cartSubtotal);
                discountAmount = c.calculateDiscount(cartSubtotal);
                couponMessage = "Áp dụng mã " + c.getCode() + " thành công";
            } catch (IllegalArgumentException ex) {
                couponMessage = ex.getMessage();
            }
        }
        BigDecimal shippingFee = orderService.calculateShippingFee(cartSubtotal);
        model.addAttribute("profile", cartService.getOrCreateProfile(auth));
        model.addAttribute("cartItems", cartItems);
        model.addAttribute("cartSubtotal", cartSubtotal);
        model.addAttribute("discountAmount", discountAmount);
        model.addAttribute("shippingFee", shippingFee);
        model.addAttribute("grandTotal", cartSubtotal.subtract(discountAmount).add(shippingFee));
        model.addAttribute("couponMessage", couponMessage);
        model.addAttribute("checkoutForm", form);
    }
}
