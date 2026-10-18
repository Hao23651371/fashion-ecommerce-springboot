package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Thanh toán. Cần đăng nhập (đã cấu hình trong SecurityConfig). */
@Controller
@RequestMapping("/checkout")
public class CheckoutController {

    @GetMapping
    public String index() {
        return "user/checkout";
    }
}
