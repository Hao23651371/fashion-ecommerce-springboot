package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.service.WishlistService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** Danh sách yêu thích. Cần đăng nhập (đã cấu hình trong SecurityConfig). */
@Controller
@RequestMapping("/wishlist")
public class WishlistController {

    private final WishlistService wishlistService;

    public WishlistController(WishlistService wishlistService) {
        this.wishlistService = wishlistService;
    }

    @GetMapping
    public String index(Authentication auth, Model model) {
        List<ProductCardDto> products = wishlistService.getWishlistCards(auth);
        int wishlistCount = wishlistService.getWishlistCount(auth);
        long orderCount = wishlistService.getOrderCount(auth);

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
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        int count = wishlistService.removeItem(targetId, auth);
        return ResponseEntity.ok(Map.of("success", true, "count", count));
    }

    @PostMapping("/clear")
    @ResponseBody
    public ResponseEntity<?> clearAll(Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        wishlistService.clearAll(auth);
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
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Vui lòng đăng nhập"));
        }
        try {
            boolean liked = wishlistService.toggleItem(targetId, auth);
            int count = wishlistService.getWishlistCount(auth);
            return ResponseEntity.ok(Map.of("success", true, "liked", liked, "count", count));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }
}
