package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.service.ProductService;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Danh sách yêu thích. Cần đăng nhập (đã cấu hình trong SecurityConfig). */
@Controller
@RequestMapping("/wishlist")
public class WishlistController {

    private final JdbcTemplate jdbc;
    private final ProductService productService;

    public WishlistController(JdbcTemplate jdbc, ProductService productService) {
        this.jdbc = jdbc;
        this.productService = productService;
    }

    @GetMapping
    public String index(Authentication auth, Model model) {
        Long profileId = getProfileId(auth);
        List<ProductCardDto> products = new ArrayList<>();
        long orderCount = 0;
        long wishlistCount = 0;

        if (profileId != null) {
            List<Long> productIds = jdbc.query(
                    "SELECT product_id FROM wishlist_item WHERE user_profile_id = ? ORDER BY added_at DESC",
                    (rs, rowNum) -> rs.getLong("product_id"),
                    profileId
            );
            if (!productIds.isEmpty()) {
                products = productService.getCardsByIds(productIds);
            }
            wishlistCount = productIds.size();

            Long orders = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM orders WHERE user_profile_id = ?",
                    Long.class,
                    profileId
            );
            orderCount = orders != null ? orders : 0;
        }

        model.addAttribute("products", products);
        model.addAttribute("totalCount", products.size());
        model.addAttribute("wishlistCount", wishlistCount);
        model.addAttribute("orderCount", orderCount);
        return "user/wishlist";
    }

    @PostMapping({"/remove/{productId}", "/remove"})
    @ResponseBody
    public ResponseEntity<?> removeItem(@PathVariable(required = false) Long productId,
                                         @RequestParam(required = false) Long id,
                                         Authentication auth) {
        Long targetId = productId != null ? productId : id;
        if (targetId == null) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Thiếu mã sản phẩm"));
        }
        Long profileId = getProfileId(auth);
        if (profileId == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        jdbc.update("DELETE FROM wishlist_item WHERE user_profile_id = ? AND product_id = ?", profileId, targetId);
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM wishlist_item WHERE user_profile_id = ?", Integer.class, profileId);
        return ResponseEntity.ok(Map.of("success", true, "count", count != null ? count : 0));
    }

    @PostMapping("/clear")
    @ResponseBody
    public ResponseEntity<?> clearAll(Authentication auth) {
        Long profileId = getProfileId(auth);
        if (profileId == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        jdbc.update("DELETE FROM wishlist_item WHERE user_profile_id = ?", profileId);
        return ResponseEntity.ok(Map.of("success", true, "count", 0));
    }

    @PostMapping({"/toggle/{productId}", "/toggle"})
    @ResponseBody
    public ResponseEntity<?> toggleItem(@PathVariable(required = false) Long productId,
                                        @RequestParam(required = false) Long id,
                                        Authentication auth) {
        Long targetId = productId != null ? productId : id;
        if (targetId == null) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Thiếu mã sản phẩm"));
        }
        Long profileId = getProfileId(auth);
        if (profileId == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        Integer exists = jdbc.queryForObject(
                "SELECT COUNT(*) FROM wishlist_item WHERE user_profile_id = ? AND product_id = ?",
                Integer.class,
                profileId,
                targetId
        );
        boolean liked;
        if (exists != null && exists > 0) {
            jdbc.update("DELETE FROM wishlist_item WHERE user_profile_id = ? AND product_id = ?", profileId, targetId);
            liked = false;
        } else {
            jdbc.update("INSERT INTO wishlist_item (user_profile_id, product_id, added_at) VALUES (?, ?, NOW(6))", profileId, targetId);
            liked = true;
        }
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM wishlist_item WHERE user_profile_id = ?", Integer.class, profileId);
        return ResponseEntity.ok(Map.of("success", true, "liked", liked, "count", count != null ? count : 0));
    }

    private Long getProfileId(Authentication auth) {
        if (auth == null || !auth.isAuthenticated()) {
            return null;
        }
        String email = auth.getName() != null ? auth.getName().trim().toLowerCase() : "";
        List<Long> list = jdbc.query(
                "SELECT up.id FROM account a JOIN user_profile up ON up.account_id = a.id WHERE LOWER(a.email) = ?",
                (rs, rowNum) -> rs.getLong("id"),
                email
        );
        if (!list.isEmpty()) {
            return list.get(0);
        }
        try {
            List<Long> accountIds = jdbc.query("SELECT id FROM account WHERE LOWER(email) = ?", (rs, rowNum) -> rs.getLong("id"), email);
            if (!accountIds.isEmpty()) {
                Long accountId = accountIds.get(0);
                jdbc.update("INSERT INTO user_profile (account_id, full_name) VALUES (?, ?)", accountId, email);
                List<Long> newIds = jdbc.query("SELECT id FROM user_profile WHERE account_id = ?", (rs, rowNum) -> rs.getLong("id"), accountId);
                if (!newIds.isEmpty()) {
                    return newIds.get(0);
                }
            }
        } catch (Exception ignored) {
        }
        return null;
    }
}

