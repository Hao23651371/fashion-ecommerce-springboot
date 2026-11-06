package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.CartItem;
import com.iuh.fashionshop.service.CartService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.util.List;
import java.util.Map;

/** Giỏ hàng. Cần đăng nhập (đã cấu hình trong SecurityConfig). */
@Controller
@RequestMapping("/cart")
public class CartController {

    private final CartService cartService;
    private static final DecimalFormat CURRENCY_FORMAT = new DecimalFormat("#,### ₫");

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    @GetMapping
    public String index(Authentication auth, Model model) {
        List<CartItem> cartItems = cartService.getCartItems(auth);
        BigDecimal cartSubtotal = cartService.getCartSubtotal(auth);
        int cartCount = cartService.getCartCount(auth);

        model.addAttribute("cartItems", cartItems);
        model.addAttribute("cartSubtotal", cartSubtotal);
        model.addAttribute("cartCount", cartCount);
        return "user/cart";
    }

    @PostMapping("/add")
    @ResponseBody
    public ResponseEntity<?> addToCart(@RequestParam Long variantId,
                                       @RequestParam(defaultValue = "1") int quantity,
                                       Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập để thêm vào giỏ hàng"));
        }
        try {
            int newCount = cartService.addToCart(variantId, quantity, auth);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Đã thêm sản phẩm vào giỏ hàng thành công!",
                    "cartCount", newCount
            ));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("success", false, "message", "Có lỗi xảy ra: " + e.getMessage()));
        }
    }

    @PostMapping("/update")
    @ResponseBody
    public ResponseEntity<?> updateQuantity(@RequestParam Long cartItemId,
                                            @RequestParam int quantity,
                                            Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        try {
            cartService.updateQuantity(cartItemId, quantity, auth);
            BigDecimal subtotal = cartService.getCartSubtotal(auth);
            int newCount = cartService.getCartCount(auth);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "cartCount", newCount,
                    "subtotal", subtotal,
                    "formattedSubtotal", CURRENCY_FORMAT.format(subtotal)
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }

    @PostMapping("/remove")
    @ResponseBody
    public ResponseEntity<?> removeItem(@RequestParam Long cartItemId, Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        try {
            int newCount = cartService.removeItem(cartItemId, auth);
            BigDecimal subtotal = cartService.getCartSubtotal(auth);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Đã xóa sản phẩm khỏi giỏ hàng",
                    "cartCount", newCount,
                    "subtotal", subtotal,
                    "formattedSubtotal", CURRENCY_FORMAT.format(subtotal)
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }

    @PostMapping("/clear")
    @ResponseBody
    public ResponseEntity<?> clearCart(Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        cartService.clearCart(auth);
        return ResponseEntity.ok(Map.of("success", true, "cartCount", 0));
    }
}
