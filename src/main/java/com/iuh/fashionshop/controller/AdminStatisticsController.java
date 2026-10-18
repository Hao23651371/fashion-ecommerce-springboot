package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Trang Thống kê của admin (hiện là khung giao diện). Được bảo vệ bởi /admin/** trong SecurityConfig. */
@Controller
@RequestMapping("/admin/statistics")
public class AdminStatisticsController {

    @GetMapping
    public String statistics(Model model) {
        model.addAttribute("pageTitle", "Thống kê");
        return "admin/statistics";
    }
}