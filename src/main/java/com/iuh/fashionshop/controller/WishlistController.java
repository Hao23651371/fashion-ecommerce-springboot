package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Danh sách yêu thích. Cần đăng nhập (đã cấu hình trong SecurityConfig). */
@Controller
@RequestMapping("/wishlist")
public class WishlistController {

    @GetMapping
    public String index() {
        return "user/wishlist";
    }
}
