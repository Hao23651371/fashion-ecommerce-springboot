package com.iuh.fashionshop.config;

import com.iuh.fashionshop.service.WishlistService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

/**
 * Nạp số lượng yêu thích vào model cho header dùng chung.
 */
@ControllerAdvice
public class WishlistModelAdvice {

    private final WishlistService wishlistService;

    public WishlistModelAdvice(WishlistService wishlistService) {
        this.wishlistService = wishlistService;
    }

    @ModelAttribute("wishlistCount")
    public int populateWishlistCount() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return wishlistService.getWishlistCount(auth);
    }
}
