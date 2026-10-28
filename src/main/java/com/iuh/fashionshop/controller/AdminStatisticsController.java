package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.AdminStatisticsDto;
import com.iuh.fashionshop.service.AdminStatisticsService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.time.LocalDate;

/** Trang Thống kê của admin (hiện là khung giao diện). Được bảo vệ bởi /admin/** trong SecurityConfig. */
@Controller
@RequestMapping("/admin/statistics")
public class AdminStatisticsController {

    private final AdminStatisticsService statisticsService;

    public AdminStatisticsController(AdminStatisticsService statisticsService) {
        this.statisticsService = statisticsService;
    }

    @GetMapping
    public String statistics(@RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
                             @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
                             Model model) {
        AdminStatisticsDto stats = statisticsService.load(startDate, endDate);

        model.addAttribute("pageTitle", "Thống kê");
        model.addAttribute("stats", stats);
        return "admin/statistics";
    }
}