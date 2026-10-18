package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.service.ProductService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/** Trang chủ khách hàng. Công khai, ai cũng xem được. */
@Controller
public class UserController {

    /** Số sản phẩm hiển thị ở trang chủ (đổi số này nếu muốn nhiều/ít hơn). */
    private static final int HOME_PRODUCT_LIMIT = 15;

    private final ProductService productService;

    public UserController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("latestProducts", productService.getLatestProducts(HOME_PRODUCT_LIMIT));
        return "user/home";
    }
}