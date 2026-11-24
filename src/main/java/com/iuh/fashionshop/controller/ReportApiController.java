package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.repository.iml.AdminStatisticsRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@RestController
@RequestMapping("/api/reports")
public class ReportApiController {

    private static final List<String> SUCCESS_STATUSES = List.of("COMPLETED", "DELIVERED", "SHIPPING", "PROCESSING", "CONFIRMED", "PENDING");

    private final AdminStatisticsRepository statisticsRepository;

    public ReportApiController(AdminStatisticsRepository statisticsRepository) {
        this.statisticsRepository = statisticsRepository;
    }

    @GetMapping("/daily-sales")
    public Map<String, Object> getDailySales() {
        LocalDate today = LocalDate.now();
        LocalDateTime startAt = today.atStartOfDay();
        LocalDateTime endAt = today.plusDays(1).atStartOfDay();

        AdminStatisticsRepository.Aggregate agg = statisticsRepository.aggregateOrders(SUCCESS_STATUSES, startAt, endAt);
        long soldProducts = statisticsRepository.countSoldProducts(SUCCESS_STATUSES, startAt, endAt);

        BigDecimal revenue = agg.revenue() != null ? agg.revenue() : BigDecimal.ZERO;
        String formattedRevenue = NumberFormat.getInstance(new Locale("vi", "VN")).format(revenue) + " đ";

        Map<String, Object> report = new HashMap<>();
        report.put("reportDate", today.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")));
        report.put("orderCount", agg.orderCount());
        report.put("soldProducts", soldProducts);
        report.put("revenue", revenue);
        report.put("formattedRevenue", formattedRevenue);
        report.put("generatedAt", LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss dd/MM/yyyy")));
        return report;
    }
}
