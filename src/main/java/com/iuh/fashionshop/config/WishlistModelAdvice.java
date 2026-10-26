package com.iuh.fashionshop.config;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

/**
 * Cung cấp số lượng sản phẩm yêu thích (wishlistCount) cho toàn bộ view Thymeleaf.
 */
@ControllerAdvice
public class WishlistModelAdvice {

    @ModelAttribute("wishlistCount")
    public int populateWishlistCount() {
        // TODO: người phụ trách yêu thích sẽ thay bằng số lượng thật
        return 0;
    }
}
