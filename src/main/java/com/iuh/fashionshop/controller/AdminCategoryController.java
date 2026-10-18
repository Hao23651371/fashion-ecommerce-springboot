package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Trang admin: Danh mục. Người phụ trách viết tiếp chức năng trong class này. */
@Controller
@RequestMapping("/admin/categories")
public class AdminCategoryController {

    @GetMapping
    public String list(Model model) {
        model.addAttribute("pageTitle", "Danh mục");
        return "admin/categories";
    }
}
