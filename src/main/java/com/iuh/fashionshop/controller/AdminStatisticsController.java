package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.AdminStatisticsDto;
import com.iuh.fashionshop.service.AdminStatisticsService;
import com.iuh.fashionshop.service.StatisticsExcelExportService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.time.LocalDate;

/** Trang Thống kê của admin. Được bảo vệ bởi /admin/** trong SecurityConfig. */
@Controller
@RequestMapping("/admin/statistics")
public class AdminStatisticsController {

    private final AdminStatisticsService statisticsService;
    private final StatisticsExcelExportService excelExportService;

    public AdminStatisticsController(AdminStatisticsService statisticsService,
                                   StatisticsExcelExportService excelExportService) {
        this.statisticsService = statisticsService;
        this.excelExportService = excelExportService;
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

    @GetMapping("/export")
    public ResponseEntity<byte[]> exportExcel(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        AdminStatisticsDto stats = statisticsService.load(startDate, endDate);
        byte[] excelBytes = excelExportService.exportToExcel(stats);

        String startStr = stats.startDate() != null ? stats.startDate().toString() : "all";
        String endStr = stats.endDate() != null ? stats.endDate().toString() : "all";
        String filename = "Bao-cao-thong-ke_" + startStr + "_" + endStr + ".xlsx";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }
}
