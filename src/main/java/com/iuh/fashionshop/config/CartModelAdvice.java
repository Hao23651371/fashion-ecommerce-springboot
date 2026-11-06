package com.iuh.fashionshop.config;

import com.iuh.fashionshop.service.CartService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

/**
 * Cung cấp số lượng sản phẩm trong giỏ hàng (cartCount) cho toàn bộ view Thymeleaf.
 */
@ControllerAdvice
public class CartModelAdvice {

    private final CartService cartService;

    public CartModelAdvice(CartService cartService) {
        this.cartService = cartService;
    }

    @ModelAttribute("cartCount")
    public int populateCartCount(Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return 0;
        }
        return cartService.getCartCount(auth);
    }
}
