package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Trang Bảng điều khiển (Tổng quan) của admin. */
@Controller
@RequestMapping("/admin")
public class AdminController {

    @GetMapping({"", "/dashboard"})
    public String dashboard(Model model) {
        model.addAttribute("pageTitle", "Tổng quan");
        return "admin/dashboard";
    }
}
