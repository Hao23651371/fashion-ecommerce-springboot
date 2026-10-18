package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Trang admin: Trợ giúp & Thiết lập. Người phụ trách viết tiếp chức năng trong class này. */
@Controller
@RequestMapping("/admin/settings")
public class AdminSettingsController {

    @GetMapping
    public String list(Model model) {
        model.addAttribute("pageTitle", "Trợ giúp & Thiết lập");
        return "admin/settings";
    }
}
