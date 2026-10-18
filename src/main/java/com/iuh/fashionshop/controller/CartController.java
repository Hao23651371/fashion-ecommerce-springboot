package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Giỏ hàng. Cần đăng nhập (đã cấu hình trong SecurityConfig). */
@Controller
@RequestMapping("/cart")
public class CartController {

    @GetMapping
    public String index() {
        return "user/cart";
    }
}
