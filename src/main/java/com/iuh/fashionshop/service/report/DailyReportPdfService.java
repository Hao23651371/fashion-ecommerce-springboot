package com.iuh.fashionshop.service.report;

import com.iuh.fashionshop.dto.DailyReportDto;
import com.iuh.fashionshop.dto.DailyReportDto.*;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.math.BigDecimal;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Tạo file PDF "Báo cáo doanh thu & vận hành hằng ngày" chuẩn quản trị:
 * - Hỗ trợ đầy đủ tiếng Việt (nạp font Arial hệ thống Windows / fallback DejaVu trên Linux).
 * - Nhúng trực tiếp biểu đồ PNG sắc nét (có chú giải, nhãn trục, số liệu trên cột và chú thích).
 * - Hiển thị lời nhận xét & đề xuất hành động từ AI Gemini (kèm cảnh báo nghiệp vụ từ hệ thống).
 */
@Service
public class DailyReportPdfService {

    private static final Pattern BOLD_PATTERN = Pattern.compile("\\*\\*(.+?)\\*\\*");

    private final DailyReportChartService chartService;

    public DailyReportPdfService(DailyReportChartService chartService) {
        this.chartService = chartService;
    }

    public byte[] generatePdf(DailyReportDto report, String aiAnalysis) {
        String html = buildHtml(report, aiAnalysis);
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            registerVietnameseFonts(builder);
            builder.withHtmlContent(html, null);
            builder.toStream(out);
            builder.run();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Không thể tạo file PDF báo cáo: " + e.getMessage(), e);
        }
    }

    private void registerVietnameseFonts(PdfRendererBuilder builder) {
        String[][] candidates = {
                {"C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/arialbd.ttf"},
                {"C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/segoeuib.ttf"},
                {"C:/Windows/Fonts/tahoma.ttf", "C:/Windows/Fonts/tahomabd.ttf"},
                {"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"}
        };
        for (String[] pair : candidates) {
            File regular = new File(pair[0]);
            if (regular.exists()) {
                builder.useFont(regular, "ReportFont", 400, PdfRendererBuilder.FontStyle.NORMAL, true);
                File bold = new File(pair[1]);
                if (bold.exists()) {
                    builder.useFont(bold, "ReportFont", 700, PdfRendererBuilder.FontStyle.NORMAL, true);
                }
                return;
            }
        }
    }

    public String buildHtml(DailyReportDto r, String aiAnalysis) {
        String chart7Days = chartService.renderRevenue7DaysChart(r);
        String chartTopProducts = chartService.renderTopProductsChart(r);
        String chartStatus = chartService.renderPieChart(
                "Cơ cấu trạng thái đơn hàng",
                "Tổng đơn phát sinh: " + r.totalOrders() + " đơn",
                r.statusBreakdown(),
                false
        );
        String chartChannels = chartService.renderPieChart(
                "Cơ cấu kênh thanh toán",
                "Tính theo giá trị đơn hợp lệ",
                r.paymentChannels(),
                true
        );

        StringBuilder sb = new StringBuilder();
        sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        sb.append("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n");
        sb.append("<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"vi\">\n<head>\n");
        sb.append("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n");
        sb.append("<style type=\"text/css\">\n");
        sb.append(css());
        sb.append("</style>\n</head>\n<body>\n");

        // ===== HEADER =====
        sb.append("<div class=\"header\">\n");
        sb.append("  <table class=\"w100\"><tr>\n");
        sb.append("    <td>\n");
        sb.append("      <div class=\"brand\">FASHIONSHOP</div>\n");
        sb.append("      <div class=\"doc-title\">BÁO CÁO DOANH THU &amp; VẬN HÀNH HẰNG NGÀY</div>\n");
        sb.append("    </td>\n");
        sb.append("    <td class=\"text-right\">\n");
        sb.append("      <div class=\"meta-badge\">").append(esc(r.weekdayLabel())).append(", ").append(esc(r.reportDateLabel())).append("</div>\n");
        sb.append("      <div class=\"meta-sub\">Xuất lúc: ").append(esc(r.generatedAtLabel())).append("</div>\n");
        sb.append("    </td>\n");
        sb.append("  </tr></table>\n");
        sb.append("</div>\n");

        // ===== TÓM TẮT NHANH =====
        sb.append("<div class=\"summary-box\">\n");
        sb.append("  <div class=\"summary-title\">TÓM TẮT NHANH CHO ADMIN</div>\n");
        sb.append("  <ul>\n");
        for (String line : r.executiveSummary()) {
            sb.append("    <li>").append(esc(line)).append("</li>\n");
        }
        sb.append("  </ul>\n");
        sb.append("</div>\n");

        // ===== PHẦN 1: CHỈ SỐ KINH DOANH CHI TIẾT =====
        sb.append("<div class=\"section-title\">1. BẢNG ĐIỀU HÀNH CHỈ SỐ KINH DOANH (KPI DASHBOARD)</div>\n");
        sb.append("<table class=\"kpi-grid\"><tr>\n");
        sb.append(kpiCard("DOANH THU THỰC NHẬN", DailyReportService.money(r.netRevenue()),
                growthLabel(r.revenueGrowthVsYesterday(), "so với hôm qua"), "#2563eb"));
        sb.append(kpiCard("ĐƠN HỢP LỆ / TỔNG", r.validOrders() + " / " + r.totalOrders() + " đơn",
                growthLabel(r.ordersGrowthVsYesterday(), "so với hôm qua"), "#10b981"));
        sb.append(kpiCard("GIÁ TRỊ TB / ĐƠN (AOV)", DailyReportService.money(r.averageOrderValue()),
                DailyReportService.fmt1(r.itemsPerOrder()) + " món/đơn (" + r.soldProducts() + " sp)", "#8b5cf6"));
        sb.append(kpiCard("ĐƠN CHỜ DUYỆT / HỦY", r.pendingOrders() + " chờ | " + r.cancelledOrders() + " hủy",
                "Tỷ lệ hủy: " + DailyReportService.fmt1(r.cancelRate()) + "%",
                (r.overduePendingOrders() > 0 || r.cancelRate() >= 10) ? "#dc2626" : "#f59e0b"));
        sb.append("</tr></table>\n");

        // Bảng chi tiết 4 nhóm chỉ số
        sb.append("<table class=\"detail-grid\"><tr>\n");
        sb.append("  <td class=\"half-col\">\n");
        sb.append("    <div class=\"sub-box\">\n");
        sb.append("      <div class=\"sub-title\">Tài chính &amp; Khuyến mãi</div>\n");
        sb.append("      <table class=\"kv-table\">\n");
        sb.append(kvRow("Tổng tiền hàng (trước giảm giá)", DailyReportService.money(r.grossRevenue())));
        sb.append(kvRow("Tiền giảm giá / Voucher", DailyReportService.money(r.discountAmount()) + " (" + DailyReportService.fmt1(r.discountRate()) + "%)"));
        sb.append(kvRow("Doanh thu thực nhận hôm nay", "<b>" + DailyReportService.money(r.netRevenue()) + "</b>"));
        sb.append(kvRow("Doanh thu hôm qua", DailyReportService.money(r.revenueYesterday())));
        sb.append(kvRow("Trung bình 7 ngày trước", DailyReportService.money(r.avgRevenue7Days())));
        sb.append("      </table>\n");
        sb.append("    </div>\n");
        sb.append("  </td>\n");
        sb.append("  <td class=\"half-col\">\n");
        sb.append("    <div class=\"sub-box\">\n");
        sb.append("      <div class=\"sub-title\">Trạng thái đơn &amp; Sức khỏe kho</div>\n");
        sb.append("      <table class=\"kv-table\">\n");
        sb.append(kvRow("Hoàn tất / Đang giao", r.completedOrders() + " hoàn tất | " + r.shippingOrders() + " đang giao"));
        sb.append(kvRow("Đã xác nhận / Chờ duyệt", r.confirmedOrders() + " xác nhận | " + r.pendingOrders() + " chờ duyệt"));
        sb.append(kvRow("Đơn chờ duyệt quá 2 giờ", r.overduePendingOrders() > 0 ? "<span class=\"text-danger\"><b>" + r.overduePendingOrders() + " đơn (Cần xử lý)</b></span>" : "0 đơn"));
        sb.append(kvRow("Biến thể HẾT HÀNG (tồn = 0)", r.outOfStockVariants() > 0 ? "<span class=\"text-danger\"><b>" + r.outOfStockVariants() + " mẫu</b></span>" : "0 mẫu"));
        sb.append(kvRow("Biến thể SẮP HẾT (tồn <= 5)", r.lowStockVariants() > 0 ? "<span class=\"text-warn\"><b>" + r.lowStockVariants() + " mẫu</b></span>" : "0 mẫu"));
        sb.append("      </table>\n");
        sb.append("    </div>\n");
        sb.append("  </td>\n");
        sb.append("</tr></table>\n");

        // Xu hướng thời trang: Size, Màu, Danh mục
        sb.append("<table class=\"trend-bar\"><tr>\n");
        sb.append("  <td><b>Size bán chạy:</b> ").append(esc(formatShares(r.sizes()))).append("</td>\n");
        sb.append("  <td><b>Màu sắc ưa chuộng:</b> ").append(esc(formatShares(r.colors()))).append("</td>\n");
        sb.append("  <td><b>Kênh thanh toán:</b> ").append(esc(formatShares(r.paymentChannels()))).append("</td>\n");
        sb.append("</tr></table>\n");

        // ===== PHẦN 2: PHÂN TÍCH THỊ GIÁC (BIỂU ĐỒ) =====
        sb.append("<div class=\"section-title\">2. PHÂN TÍCH THỊ GIÁC (BIỂU ĐỒ CÓ CHÚ THÍCH)</div>\n");
        if (chart7Days != null) {
            sb.append("<div class=\"chart-card\">\n");
            sb.append("  <img src=\"").append(chart7Days).append("\" class=\"chart-img\" alt=\"Biểu đồ doanh thu 7 ngày\" />\n");
            sb.append("  <div class=\"chart-caption\"><b>Ghi chú biểu đồ:</b> So sánh doanh thu 6 ngày trước (cột xanh nhạt) với ngày báo cáo ").append(esc(r.reportDateLabel())).append(" (cột xanh đậm). Mức trung bình 7 ngày trước là ").append(esc(DailyReportService.money(r.avgRevenue7Days()))).append(".</div>\n");
            sb.append("</div>\n");
        }
        if (chartTopProducts != null) {
            sb.append("<div class=\"chart-card\">\n");
            sb.append("  <img src=\"").append(chartTopProducts).append("\" class=\"chart-img\" alt=\"Biểu đồ top sản phẩm\" />\n");
            sb.append("  <div class=\"chart-caption\"><b>Ghi chú biểu đồ:</b> Xếp hạng các sản phẩm tạo ra doanh thu lớn nhất trong ngày. Top 3 sản phẩm dẫn đầu đóng góp ").append(DailyReportService.fmt1(r.top3RevenueShare())).append("% tổng doanh thu.</div>\n");
            sb.append("</div>\n");
        }
        if (chartStatus != null || chartChannels != null) {
            sb.append("<table class=\"pie-grid\"><tr>\n");
            if (chartStatus != null) {
                sb.append("  <td class=\"half-col\"><div class=\"chart-card\">\n");
                sb.append("    <img src=\"").append(chartStatus).append("\" class=\"pie-img\" alt=\"Cơ cấu trạng thái\" />\n");
                sb.append("    <div class=\"chart-caption\"><b>Chú thích:</b> Tỷ lệ phần trăm đơn hàng theo từng trạng thái xử lý trong ngày.</div>\n");
                sb.append("  </div></td>\n");
            }
            if (chartChannels != null) {
                sb.append("  <td class=\"half-col\"><div class=\"chart-card\">\n");
                sb.append("    <img src=\"").append(chartChannels).append("\" class=\"pie-img\" alt=\"Kênh thanh toán\" />\n");
                sb.append("    <div class=\"chart-caption\"><b>Chú thích:</b> Tỷ trọng doanh thu giữa COD, chuyển khoản và ví điện tử.</div>\n");
                sb.append("  </div></td>\n");
            }
            sb.append("</tr></table>\n");
        }

        // ===== PHẦN 3: NHẬN XÉT & ĐỀ XUẤT HÀNH ĐỘNG TỪ AI =====
        sb.append("<div class=\"section-title page-break\">3. ĐÁNH GIÁ CHUYÊN SÂU &amp; ĐỀ XUẤT CẢI THIỆN (AI GEMINI)</div>\n");
        if (aiAnalysis != null && !aiAnalysis.isBlank()) {
            sb.append("<div class=\"ai-box\">\n");
            sb.append("  <div class=\"ai-badge\">Phân tích tự động bởi Trợ lý AI Gemini dựa trên số liệu ngày ").append(esc(r.reportDateLabel())).append("</div>\n");
            sb.append("  <div class=\"ai-content\">").append(markdownToHtml(aiAnalysis)).append("</div>\n");
            sb.append("</div>\n");
        } else {
            sb.append("<div class=\"ai-box\">\n");
            sb.append("  <div class=\"ai-badge\">Đánh giá tự động bởi hệ thống FashionShop</div>\n");
            sb.append("  <div class=\"ai-content\"><p>Chưa có đoạn phân tích từ Gemini AI cho lần xuất này. Admin vui lòng xem chi tiết các cảnh báo ưu tiên do hệ thống tổng hợp ngay bên dưới.</p></div>\n");
            sb.append("</div>\n");
        }

        // Các cảnh báo & việc cần làm theo quy tắc hệ thống
        sb.append("<div class=\"section-title\">4. DANH SÁCH VIỆC CẦN XEM XÉT &amp; XỬ LÝ NGAY</div>\n");
        for (Insight insight : r.insights()) {
            String cssClass = switch (insight.level()) {
                case "DANGER" -> "insight-danger";
                case "WARNING" -> "insight-warn";
                case "SUCCESS" -> "insight-success";
                default -> "insight-info";
            };
            String badge = switch (insight.level()) {
                case "DANGER" -> "KHẨN CẤP";
                case "WARNING" -> "CẦN CHÚ Ý";
                case "SUCCESS" -> "ĐIỂM SÁNG";
                default -> "GỢI Ý";
            };
            sb.append("<div class=\"insight-card ").append(cssClass).append("\">\n");
            sb.append("  <div class=\"insight-head\"><span class=\"pill\">").append(badge).append("</span> <span class=\"group-tag\">[").append(esc(insight.group())).append("]</span> <b>").append(esc(insight.title())).append("</b></div>\n");
            sb.append("  <div class=\"insight-detail\">").append(esc(insight.detail())).append("</div>\n");
            sb.append("  <div class=\"insight-action\"><b>Đề xuất hành động:</b> ").append(esc(insight.action())).append("</div>\n");
            sb.append("</div>\n");
        }

        // ===== PHẦN 5: BẢNG TOP SẢN PHẨM & CẢNH BÁO KHO =====
        sb.append("<div class=\"section-title\">5. CHI TIẾT SẢN PHẨM BÁN CHẠY &amp; TỒN KHO CẢNH BÁO</div>\n");

        sb.append("<div class=\"table-label\">A. Top sản phẩm bán chạy trong ngày</div>\n");
        if (r.topProducts().isEmpty()) {
            sb.append("<p class=\"empty-note\">Hôm nay chưa có sản phẩm nào phát sinh đơn hàng hợp lệ.</p>\n");
        } else {
            sb.append("<table class=\"data-table\">\n<thead><tr><th>#</th><th>Tên sản phẩm</th><th>Danh mục</th><th class=\"text-right\">SL bán</th><th class=\"text-right\">Doanh thu</th><th class=\"text-right\">Tỷ trọng</th><th class=\"text-right\">Tồn kho</th></tr></thead>\n<tbody>\n");
            for (TopProductRow p : r.topProducts()) {
                String stockClass = "OUT".equals(p.stockStatus()) ? "text-danger" : "LOW".equals(p.stockStatus()) ? "text-warn" : "";
                sb.append("<tr><td>").append(p.rank()).append("</td><td><b>").append(esc(p.productName())).append("</b></td><td>").append(esc(p.categoryName()))
                        .append("</td><td class=\"text-right\">").append(p.soldQuantity()).append("</td><td class=\"text-right\">").append(esc(DailyReportService.money(p.revenue())))
                        .append("</td><td class=\"text-right\">").append(DailyReportService.fmt1(p.revenueShare())).append("%</td><td class=\"text-right ").append(stockClass).append("\"><b>")
                        .append(p.currentStock()).append("</b></td></tr>\n");
            }
            sb.append("</tbody></table>\n");
        }

        sb.append("<div class=\"table-label\">B. Biến thể hết hàng / sắp hết hàng cần nhập kho (tồn &lt;= 5)</div>\n");
        if (r.urgentStockItems().isEmpty()) {
            sb.append("<p class=\"empty-note\">Tất cả sản phẩm hiện đều còn đủ tồn kho (&gt; 5 cái).</p>\n");
        } else {
            sb.append("<table class=\"data-table\">\n<thead><tr><th>Sản phẩm / Biến thể</th><th>Danh mục</th><th class=\"text-right\">Tồn hiện tại</th><th>Mức cảnh báo</th></tr></thead>\n<tbody>\n");
            for (StockRow s : r.urgentStockItems()) {
                String cls = s.currentStock() <= 0 ? "text-danger" : "text-warn";
                sb.append("<tr><td>").append(esc(s.productName())).append("</td><td>").append(esc(s.categoryName()))
                        .append("</td><td class=\"text-right ").append(cls).append("\"><b>").append(s.currentStock()).append("</b></td><td class=\"").append(cls).append("\"><b>")
                        .append(esc(s.status())).append("</b></td></tr>\n");
            }
            sb.append("</tbody></table>\n");
        }

        if (!r.slowMovingItems().isEmpty()) {
            sb.append("<div class=\"table-label\">C. Hàng tồn nhiều nhưng chưa bán được trong 7 ngày qua (gợi ý xả kho / khuyến mãi)</div>\n");
            sb.append("<table class=\"data-table\">\n<thead><tr><th>Sản phẩm</th><th>Danh mục</th><th class=\"text-right\">Tồn kho</th><th>Trạng thái</th></tr></thead>\n<tbody>\n");
            for (StockRow s : r.slowMovingItems()) {
                sb.append("<tr><td>").append(esc(s.productName())).append("</td><td>").append(esc(s.categoryName()))
                        .append("</td><td class=\"text-right\">").append(s.currentStock()).append("</td><td>").append(esc(s.status())).append("</td></tr>\n");
            }
            sb.append("</tbody></table>\n");
        }

        // ===== PHẦN 6: PHỤ LỤC CHI TIẾT ĐƠN HÀNG =====
        sb.append("<div class=\"section-title\">6. PHỤ LỤC: DANH SÁCH ĐƠN HÀNG TRONG NGÀY (").append(r.orders().size()).append(" ĐƠN)</div>\n");
        if (r.orders().isEmpty()) {
            sb.append("<p class=\"empty-note\">Không có đơn hàng nào được tạo trong ngày ").append(esc(r.reportDateLabel())).append(".</p>\n");
        } else {
            sb.append("<table class=\"data-table small-table\">\n<thead><tr><th>Mã đơn</th><th>Giờ</th><th>Khách hàng</th><th>Sản phẩm</th><th class=\"text-right\">Tổng tiền</th><th>Thanh toán</th><th>Trạng thái</th></tr></thead>\n<tbody>\n");
            for (OrderRow o : r.orders()) {
                sb.append("<tr><td><b>").append(esc(o.orderCode())).append("</b></td><td>").append(esc(o.time())).append("</td><td>")
                        .append(esc(o.customer())).append("<br/><span class=\"muted\">").append(esc(o.phone())).append("</span></td><td>")
                        .append(esc(o.items())).append("</td><td class=\"text-right\"><b>").append(esc(DailyReportService.money(o.total())))
                        .append("</b></td><td>").append(esc(o.paymentMethod())).append("</td><td>").append(esc(o.status())).append("</td></tr>\n");
            }
            sb.append("</tbody></table>\n");
        }

        sb.append("<div class=\"footer\">FashionShop Automated Management Report &bull; Xuất tự động qua Spring Boot &amp; n8n Workflow</div>\n");
        sb.append("</body>\n</html>");
        return sb.toString();
    }

    // ========================================================================================
    // HELPER RENDER HTML
    // ========================================================================================

    private String kpiCard(String label, String value, String sub, String accent) {
        return "<td class=\"kpi-cell\"><div class=\"kpi-card\" style=\"border-top: 3px solid " + accent + ";\">"
                + "<div class=\"kpi-label\">" + esc(label) + "</div>"
                + "<div class=\"kpi-value\">" + esc(value) + "</div>"
                + "<div class=\"kpi-sub\">" + esc(sub) + "</div>"
                + "</div></td>\n";
    }

    private String kvRow(String key, String rawHtmlValue) {
        return "<tr><td class=\"kv-key\">" + esc(key) + "</td><td class=\"kv-val\">" + rawHtmlValue + "</td></tr>\n";
    }

    private String growthLabel(Double growth, String suffix) {
        if (growth == null) return "Chưa có dữ liệu hôm qua";
        return (growth >= 0 ? "▲ +" : "▼ ") + DailyReportService.fmt1(growth) + "% " + suffix;
    }

    private String formatShares(List<ShareItem> items) {
        if (items == null || items.isEmpty()) return "Chưa có dữ liệu";
        return items.stream().limit(3)
                .map(i -> i.label() + " (" + DailyReportService.fmt1(i.percent()) + "%)")
                .reduce((a, b) -> a + ", " + b)
                .orElse("Chưa có dữ liệu");
    }

    /** Chuyển văn bản Markdown đơn giản từ Gemini (tiêu đề ###, gạch đầu dòng -, **in đậm**) sang XHTML sạch. */
    private String markdownToHtml(String md) {
        StringBuilder out = new StringBuilder();
        boolean inList = false;
        String[] lines = md.replace("\r\n", "\n").split("\n");
        for (String raw : lines) {
            String line = raw.trim();
            if (line.isEmpty()) {
                if (inList) {
                    out.append("</ul>\n");
                    inList = false;
                }
                continue;
            }
            if (line.startsWith("### ") || line.startsWith("## ") || line.startsWith("# ")) {
                if (inList) {
                    out.append("</ul>\n");
                    inList = false;
                }
                String heading = line.replaceFirst("^#+\\s*", "");
                out.append("<h4>").append(inlineFormat(heading)).append("</h4>\n");
            } else if (line.startsWith("- ") || line.startsWith("* ") || line.startsWith("• ")) {
                if (!inList) {
                    out.append("<ul>\n");
                    inList = true;
                }
                out.append("<li>").append(inlineFormat(line.substring(2).trim())).append("</li>\n");
            } else {
                if (inList) {
                    out.append("</ul>\n");
                    inList = false;
                }
                out.append("<p>").append(inlineFormat(line)).append("</p>\n");
            }
        }
        if (inList) out.append("</ul>\n");
        return out.toString();
    }

    private String inlineFormat(String text) {
        String escaped = esc(text);
        Matcher m = BOLD_PATTERN.matcher(escaped);
        StringBuffer sb = new StringBuffer();
        while (m.find()) {
            m.appendReplacement(sb, "<b>" + Matcher.quoteReplacement(m.group(1)) + "</b>");
        }
        m.appendTail(sb);
        return sb.toString();
    }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private static String css() {
        return """
                @page { size: A4; margin: 14mm 12mm 16mm 12mm; }
                body { font-family: 'ReportFont', sans-serif; font-size: 9.5pt; color: #1e293b; line-height: 1.45; }
                .w100 { width: 100%; border-collapse: collapse; }
                .text-right { text-align: right; }
                .text-danger { color: #dc2626; }
                .text-warn { color: #d97706; }
                .muted { color: #64748b; font-size: 8pt; }
                .header { background: #0f172a; color: #ffffff; padding: 14px 16px; border-radius: 6px; margin-bottom: 12px; }
                .brand { font-size: 9pt; letter-spacing: 2px; color: #93c5fd; font-weight: bold; }
                .doc-title { font-size: 14pt; font-weight: bold; margin-top: 2px; }
                .meta-badge { display: inline-block; background: #1e293b; border: 1px solid #334155; padding: 4px 10px; border-radius: 4px; font-weight: bold; font-size: 9.5pt; }
                .meta-sub { font-size: 8pt; color: #cbd5e1; margin-top: 4px; }
                .summary-box { background: #eff6ff; border-left: 4px solid #2563eb; padding: 10px 14px; border-radius: 4px; margin-bottom: 12px; }
                .summary-title { font-weight: bold; color: #1d4ed8; font-size: 9.5pt; margin-bottom: 4px; }
                .summary-box ul { margin: 0; padding-left: 16px; }
                .summary-box li { margin-bottom: 2px; }
                .section-title { font-size: 10.5pt; font-weight: bold; color: #0f172a; border-bottom: 2px solid #2563eb; padding-bottom: 3px; margin: 14px 0 8px 0; }
                .page-break { page-break-before: always; }
                .kpi-grid { width: 100%; border-collapse: separate; border-spacing: 6px 0; margin: 0 -6px 10px -6px; }
                .kpi-cell { width: 25%; vertical-align: top; }
                .kpi-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 5px; padding: 8px 10px; }
                .kpi-label { font-size: 7.5pt; font-weight: bold; color: #64748b; }
                .kpi-value { font-size: 11.5pt; font-weight: bold; color: #0f172a; margin: 3px 0; }
                .kpi-sub { font-size: 7.8pt; color: #475569; }
                .detail-grid { width: 100%; border-collapse: separate; border-spacing: 8px 0; margin: 0 -8px 8px -8px; }
                .half-col { width: 50%; vertical-align: top; }
                .sub-box { border: 1px solid #e2e8f0; border-radius: 5px; padding: 8px 10px; background: #ffffff; }
                .sub-title { font-weight: bold; font-size: 9pt; color: #1e293b; border-bottom: 1px solid #e2e8f0; padding-bottom: 4px; margin-bottom: 6px; }
                .kv-table { width: 100%; border-collapse: collapse; font-size: 8.5pt; }
                .kv-table td { padding: 3px 0; border-bottom: 1px dashed #f1f5f9; }
                .kv-key { color: #475569; }
                .kv-val { text-align: right; color: #0f172a; }
                .trend-bar { width: 100%; border-collapse: collapse; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 4px; margin-bottom: 8px; font-size: 8.2pt; }
                .trend-bar td { padding: 6px 8px; border-right: 1px solid #e2e8f0; }
                .trend-bar td:last-child { border-right: none; }
                .chart-card { border: 1px solid #e2e8f0; border-radius: 6px; padding: 8px; margin-bottom: 10px; background: #ffffff; text-align: center; page-break-inside: avoid; }
                .chart-img { width: 100%; height: auto; }
                .pie-grid { width: 100%; table-layout: fixed; border-collapse: separate; border-spacing: 8px 0; margin: 0 -8px 8px -8px; }
                .pie-img { width: 290px; height: auto; }
                .chart-caption { font-size: 8pt; color: #475569; text-align: left; background: #f8fafc; padding: 5px 8px; border-radius: 4px; margin-top: 6px; }
                .ai-box { background: #faf5ff; border: 1px solid #d8b4fe; border-left: 4px solid #7c3aed; border-radius: 6px; padding: 10px 14px; margin-bottom: 10px; }
                .ai-badge { font-size: 8.5pt; font-weight: bold; color: #6d28d9; margin-bottom: 6px; }
                .ai-content h4 { margin: 8px 0 4px 0; font-size: 9.5pt; color: #4c1d95; }
                .ai-content p { margin: 4px 0; }
                .ai-content ul { margin: 4px 0 6px 0; padding-left: 16px; }
                .ai-content li { margin-bottom: 3px; }
                .insight-card { border: 1px solid #e2e8f0; border-left: 4px solid #64748b; border-radius: 4px; padding: 7px 10px; margin-bottom: 7px; page-break-inside: avoid; }
                .insight-danger { border-left-color: #dc2626; background: #fef2f2; }
                .insight-warn { border-left-color: #f59e0b; background: #fffbeb; }
                .insight-success { border-left-color: #10b981; background: #ecfdf5; }
                .insight-info { border-left-color: #2563eb; background: #f8fafc; }
                .insight-head { font-size: 9pt; margin-bottom: 3px; }
                .pill { display: inline-block; font-size: 7.5pt; font-weight: bold; padding: 1px 6px; border-radius: 3px; background: #1e293b; color: #ffffff; margin-right: 4px; }
                .group-tag { font-size: 8pt; color: #475569; font-weight: bold; margin-right: 4px; }
                .insight-detail { font-size: 8.5pt; color: #334155; }
                .insight-action { font-size: 8.5pt; color: #0f172a; margin-top: 3px; }
                .table-label { font-weight: bold; font-size: 9pt; color: #1e293b; margin: 10px 0 4px 0; }
                .data-table { width: 100%; border-collapse: collapse; font-size: 8.3pt; margin-bottom: 10px; }
                .data-table th { background: #f1f5f9; color: #0f172a; text-align: left; padding: 6px; border-bottom: 1.5px solid #cbd5e1; font-weight: bold; }
                .data-table td { padding: 5px 6px; border-bottom: 1px solid #e2e8f0; vertical-align: top; }
                .small-table { font-size: 7.8pt; }
                .empty-note { font-style: italic; color: #64748b; font-size: 8.5pt; margin: 4px 0 10px 0; }
                .footer { margin-top: 16px; padding-top: 8px; border-top: 1px solid #e2e8f0; text-align: center; font-size: 8pt; color: #94a3b8; }
                """;
    }
}
