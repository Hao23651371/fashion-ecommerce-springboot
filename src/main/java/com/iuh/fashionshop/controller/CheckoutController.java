package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.CartItem;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import com.iuh.fashionshop.service.CartService;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.util.List;

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

    public CheckoutController(CartService cartService,
                              ProductVariantRepository productVariantRepository) {
        this.cartService = cartService;
        this.productVariantRepository = productVariantRepository;
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
}
