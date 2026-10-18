package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Trang Sale: sản phẩm đang giảm giá. Công khai, không cần đăng nhập. */
@Controller
@RequestMapping("/sale")
public class SaleController {

    @GetMapping
    public String sale(Model model) {
        return "user/sale";
    }
}