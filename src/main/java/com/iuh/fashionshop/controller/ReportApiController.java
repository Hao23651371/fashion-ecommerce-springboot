package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.DailyReportDto;
import com.iuh.fashionshop.service.ai.SpringAiGeminiChatClient;
import com.iuh.fashionshop.service.report.DailyReportPdfService;
import com.iuh.fashionshop.service.report.DailyReportService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * REST API phục vụ n8n Workflow "Báo cáo doanh thu & vận hành hằng ngày":
 * 1) GET  /api/reports/daily-sales      -> Trả về toàn bộ số liệu chi tiết + aiContext để gửi cho Gemini.
 * 2) POST /api/reports/ai-analysis      -> Gọi trực tiếp Spring AI Gemini phân tích số liệu ngày.
 * 3) POST /api/reports/daily-pdf        -> Nhận lời nhận xét từ Gemini (hoặc tự gọi Gemini nếu trống) và trả về file PDF.
 * 4) GET  /api/reports/daily-pdf        -> Cho phép Admin mở trực tiếp trên trình duyệt để xem thử PDF nhanh.
 */
@RestController
@RequestMapping("/api/reports")
public class ReportApiController {

    private static final Logger log = LoggerFactory.getLogger(ReportApiController.class);

    private static final String AI_SYSTEM_PROMPT = """
            Bạn là Giám đốc vận hành (COO) của thương hiệu thời trang FashionShop.
            Dựa vào dữ liệu bán hàng thực tế được cung cấp, hãy viết phân tích chuyên sâu bằng tiếng Việt theo đúng 3 mục Markdown (###):
            ### 1. Đánh giá tổng quan hôm nay
            (2-3 câu ngắn gọn, chỉ rõ điểm mạnh/điểm yếu dựa trên số liệu thật).
            ### 2. Cảnh báo quan trọng cần xử lý ngay
            (Gạch đầu dòng - nêu rõ tồn kho hết/sắp hết, đơn chờ duyệt hoặc tỷ lệ hủy).
            ### 3. Đề xuất hành động cụ thể cho ngày mai
            (3 gạch đầu dòng - đề xuất nhập hàng, đẩy sản phẩm hot, xử lý hàng tồn chậm hoặc tối ưu doanh thu).
            Tuyệt đối không bịa số liệu ngoài dữ liệu được cung cấp.
            """;

    private final DailyReportService reportService;
    private final DailyReportPdfService pdfService;
    private final SpringAiGeminiChatClient geminiChatClient;

    public ReportApiController(DailyReportService reportService,
                               DailyReportPdfService pdfService,
                               SpringAiGeminiChatClient geminiChatClient) {
        this.reportService = reportService;
        this.pdfService = pdfService;
        this.geminiChatClient = geminiChatClient;
    }

    @GetMapping("/daily-sales")
    public Map<String, Object> getDailySales(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        DailyReportDto r = reportService.build(date);

        Map<String, Object> payload = new LinkedHashMap<>();
        // Các trường tương thích ngược với workflow cũ
        payload.put("reportDate", r.reportDateLabel());
        payload.put("reportDateIso", r.reportDateIso());
        payload.put("weekday", r.weekdayLabel());
        payload.put("orderCount", r.validOrders());
        payload.put("totalOrders", r.totalOrders());
        payload.put("soldProducts", r.soldProducts());
        payload.put("revenue", r.netRevenue());
        payload.put("formattedRevenue", DailyReportService.money(r.netRevenue()));
        payload.put("generatedAt", r.generatedAtLabel());

        // Chỉ số quản trị mở rộng
        payload.put("grossRevenue", r.grossRevenue());
        payload.put("formattedGrossRevenue", DailyReportService.money(r.grossRevenue()));
        payload.put("discountAmount", r.discountAmount());
        payload.put("formattedDiscountAmount", DailyReportService.money(r.discountAmount()));
        payload.put("discountRate", r.discountRate());
        payload.put("averageOrderValue", r.averageOrderValue());
        payload.put("formattedAov", DailyReportService.money(r.averageOrderValue()));
        payload.put("itemsPerOrder", r.itemsPerOrder());
        payload.put("revenueGrowthVsYesterday", r.revenueGrowthVsYesterday());
        payload.put("pendingOrders", r.pendingOrders());
        payload.put("overduePendingOrders", r.overduePendingOrders());
        payload.put("completedOrders", r.completedOrders());
        payload.put("shippingOrders", r.shippingOrders());
        payload.put("cancelledOrders", r.cancelledOrders());
        payload.put("cancelRate", r.cancelRate());
        payload.put("outOfStockVariants", r.outOfStockVariants());
        payload.put("lowStockVariants", r.lowStockVariants());

        // Danh sách chi tiết + cảnh báo + ngữ cảnh sẵn cho AI Gemini
        payload.put("executiveSummary", r.executiveSummary());
        payload.put("topProducts", r.topProducts());
        payload.put("urgentStockItems", r.urgentStockItems());
        payload.put("slowMovingItems", r.slowMovingItems());
        payload.put("insights", r.insights());
        payload.put("trend7Days", r.trend7Days());
        payload.put("paymentChannels", r.paymentChannels());
        payload.put("sizes", r.sizes());
        payload.put("colors", r.colors());
        payload.put("aiContext", reportService.buildAiContext(r));
        return payload;
    }

    public record DailyPdfRequest(String date, String aiAnalysis) {}

    @PostMapping(value = "/daily-pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> generateDailyPdfPost(@RequestBody(required = false) DailyPdfRequest request) {
        LocalDate targetDate = null;
        String aiAnalysis = null;
        if (request != null) {
            if (request.date() != null && !request.date().isBlank()) {
                targetDate = LocalDate.parse(request.date().trim());
            }
            aiAnalysis = request.aiAnalysis();
        }
        return buildPdfResponse(targetDate, aiAnalysis, false);
    }

    @GetMapping(value = "/daily-pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> generateDailyPdfGet(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String aiAnalysis) {
        return buildPdfResponse(date, aiAnalysis, true);
    }

    @PostMapping("/ai-analysis")
    public Map<String, Object> generateAiAnalysis(@RequestBody(required = false) DailyPdfRequest request) {
        LocalDate targetDate = (request != null && request.date() != null && !request.date().isBlank())
                ? LocalDate.parse(request.date().trim())
                : null;
        DailyReportDto report = reportService.build(targetDate);
        String analysis = callGeminiSafely(report);
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("reportDate", report.reportDateLabel());
        res.put("aiAnalysis", analysis);
        return res;
    }

    private ResponseEntity<byte[]> buildPdfResponse(LocalDate date, String aiAnalysis, boolean inline) {
        DailyReportDto report = reportService.build(date);
        String finalAnalysis = (aiAnalysis != null && !aiAnalysis.isBlank())
                ? aiAnalysis
                : callGeminiSafely(report);
        byte[] pdfBytes = pdfService.generatePdf(report, finalAnalysis);

        String fileName = "BaoCao_FashionShop_" + report.reportDateIso() + ".pdf";
        ContentDisposition disposition = (inline ? ContentDisposition.inline() : ContentDisposition.attachment())
                .filename(fileName, StandardCharsets.UTF_8)
                .build();

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                .contentType(MediaType.APPLICATION_PDF)
                .contentLength(pdfBytes.length)
                .body(pdfBytes);
    }

    private String callGeminiSafely(DailyReportDto report) {
        try {
            String context = reportService.buildAiContext(report);
            String result = geminiChatClient.generate(AI_SYSTEM_PROMPT, context);
            return (result != null && !result.isBlank()) ? result.trim() : null;
        } catch (Exception e) {
            log.warn("Không thể gọi Spring AI Gemini cho báo cáo ngày {}: {}", report.reportDateIso(), e.getMessage());
            return null;
        }
    }
}
