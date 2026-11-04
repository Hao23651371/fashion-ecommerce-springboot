package com.iuh.fashionshop.config;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

/**
 * Cung cấp số lượng sản phẩm yêu thích (wishlistCount) cho toàn bộ view Thymeleaf.
 */
@ControllerAdvice
public class WishlistModelAdvice {

    private final JdbcTemplate jdbc;

    public WishlistModelAdvice(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @ModelAttribute("wishlistCount")
    public int populateWishlistCount() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return 0;
        }
        try {
            Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM wishlist_item wi
                JOIN user_profile up ON up.id = wi.user_profile_id
                JOIN account a ON a.id = up.account_id
                WHERE a.email = ?
            """, Integer.class, auth.getName());
            return count != null ? count : 0;
        } catch (Exception e) {
            return 0;
        }
    }
}
