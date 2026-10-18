package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Trang admin: Sản phẩm. Người phụ trách viết tiếp chức năng trong class này. */
@Controller
@RequestMapping("/admin/products")
public class AdminProductController {

    @GetMapping
    public String list(Model model) {
        model.addAttribute("pageTitle", "Sản phẩm");
        return "admin/products";
    }
}
