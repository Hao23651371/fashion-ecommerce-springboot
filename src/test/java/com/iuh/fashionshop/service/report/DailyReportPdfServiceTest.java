package com.iuh.fashionshop.service.report;

import com.iuh.fashionshop.dto.DailyReportDto;
import com.iuh.fashionshop.dto.DailyReportDto.*;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class DailyReportPdfServiceTest {

    @Test
    void shouldGenerateValidPdfWithChartsAndAiAnalysis() {
        DailyReportChartService chartService = new DailyReportChartService();
        DailyReportPdfService pdfService = new DailyReportPdfService(chartService);

        DailyReportDto sample = new DailyReportDto(
                LocalDate.of(2026, 11, 28),
                "28/11/2026",
                "2026-11-28",
                "Thứ Bảy",
                "22:00:05 28/11/2026",
                new BigDecimal("12450000"),
                new BigDecimal("13200000"),
                new BigDecimal("750000"),
                5.7,
                new BigDecimal("10800000"),
                15.3,
                new BigDecimal("9500000"),
                31.1,
                28,
                27,
                22,
                22.7,
                new BigDecimal("461111"),
                2.1,
                58,
                2,
                1,
                5,
                4,
                16,
                1,
                3.6,
                List.of("Khách đổi ý"),
                List.of(
                        new ShareItem("COD (trả khi nhận)", 16, new BigDecimal("7450000"), 59.8, "#2563eb"),
                        new ShareItem("Chuyển khoản", 11, new BigDecimal("5000000"), 40.2, "#10b981")
                ),
                List.of(new ShareItem("Áo sơ mi", 0, new BigDecimal("6800000"), 54.6, "#2563eb")),
                List.of(new ShareItem("Size L", 26, BigDecimal.ZERO, 44.8, "#2563eb")),
                List.of(new ShareItem("Trắng", 29, BigDecimal.ZERO, 50.0, "#e5e7eb")),
                List.of(
                        new ShareItem("Hoàn tất", 16, BigDecimal.ZERO, 57.1, "#10b981"),
                        new ShareItem("Đang giao", 4, BigDecimal.ZERO, 14.3, "#06b6d4"),
                        new ShareItem("Chờ xác nhận", 2, BigDecimal.ZERO, 7.1, "#f59e0b"),
                        new ShareItem("Đã hủy", 1, BigDecimal.ZERO, 3.6, "#ef4444")
                ),
                List.of(
                        new TopProductRow(1, "Áo sơ mi Oxford Slimfit", "Áo sơ mi", 12, new BigDecimal("5400000"), 43.4, 20.0, 2, "LOW"),
                        new TopProductRow(2, "Quần Tây Nam Co Giãn", "Quần tây", 8, new BigDecimal("4000000"), 32.1, 10.0, 15, "OK")
                ),
                75.5,
                1,
                3,
                List.of(new StockRow("Áo sơ mi Oxford Slimfit (Trắng - Size L)", "Áo sơ mi", 2, "Sắp hết")),
                List.of(new StockRow("Quần Tây Nam Be", "Quần tây", 35, "Chậm bán 7 ngày")),
                List.of(
                        new DayPoint("22/11", new BigDecimal("8200000"), 18, false),
                        new DayPoint("23/11", new BigDecimal("9100000"), 20, false),
                        new DayPoint("24/11", new BigDecimal("7800000"), 15, false),
                        new DayPoint("25/11", new BigDecimal("10200000"), 21, false),
                        new DayPoint("26/11", new BigDecimal("11000000"), 24, false),
                        new DayPoint("27/11", new BigDecimal("10800000"), 22, false),
                        new DayPoint("28/11 (nay)", new BigDecimal("12450000"), 27, true)
                ),
                List.of("Doanh thu đạt 12.450.000 đ (tăng 15,3% so với hôm qua)."),
                List.of(new Insight("WARNING", "Kho hàng", "Sắp hết hàng sản phẩm chủ lực",
                        "Áo sơ mi Oxford chỉ còn 2 cái.", "Nhập thêm tối thiểu 50 cái.")),
                List.of(new OrderRow("ORD-20261128-01", "14:20", "Nguyễn Văn A", "0901234567",
                        "Áo sơ mi Oxford (Trắng/L) x2", 2, BigDecimal.ZERO, new BigDecimal("900000"),
                        "Chuyển khoản", "Đã thanh toán", "Hoàn tất", "COMPLETED", null))
        );

        String aiText = """
                ### Đánh giá chung
                Hôm nay doanh thu **tăng mạnh +15,3%** nhờ nhóm áo sơ mi.
                ### Đề xuất hành động cho ngày mai
                - **Kho hàng:** Nhập gấp Áo sơ mi Oxford size L.
                - **Vận hành:** Xử lý 2 đơn chờ duyệt trước 10h00.
                """;

        byte[] pdf = pdfService.generatePdf(sample, aiText);
        assertNotNull(pdf);
        assertTrue(pdf.length > 5000, "PDF phải có dung lượng đủ lớn (chứa biểu đồ và nội dung)");
        String header = new String(pdf, 0, 5, StandardCharsets.US_ASCII);
        assertEquals("%PDF-", header);
    }
}
