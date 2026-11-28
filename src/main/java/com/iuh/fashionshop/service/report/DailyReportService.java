package com.iuh.fashionshop.service.report;

import com.iuh.fashionshop.dto.DailyReportDto;
import com.iuh.fashionshop.dto.DailyReportDto.*;
import com.iuh.fashionshop.repository.iml.AdminStatisticsRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.*;

/**
 * Tổng hợp toàn bộ số liệu cho "Báo cáo doanh thu & vận hành hằng ngày" gửi Admin qua n8n.
 * Ngoài số liệu thô, service còn tự sinh các cảnh báo / việc cần làm dựa trên quy tắc nghiệp vụ
 * (dùng khi AI chưa trả lời, hoặc hiển thị song song với nhận xét của AI).
 */
@Service
public class DailyReportService {

    /** Đơn được tính doanh thu: mọi trạng thái trừ CANCELLED. */
    public static final List<String> REVENUE_STATUSES = List.of("PENDING", "CONFIRMED", "SHIPPING", "COMPLETED");

    private static final Locale VI = Locale.forLanguageTag("vi-VN");
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter DAY_SHORT = DateTimeFormatter.ofPattern("dd/MM");
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter GENERATED = DateTimeFormatter.ofPattern("HH:mm:ss dd/MM/yyyy");

    private static final long LOW_STOCK_THRESHOLD = 5;
    private static final long SLOW_MOVING_MIN_STOCK = 20;
    private static final int PENDING_OVERDUE_HOURS = 2;

    private static final String[] PALETTE = {"#2563eb", "#f59e0b", "#10b981", "#8b5cf6", "#ef4444", "#06b6d4", "#64748b"};

    private final AdminStatisticsRepository repo;

    public DailyReportService(AdminStatisticsRepository repo) {
        this.repo = repo;
    }

    public DailyReportDto build(LocalDate date) {
        LocalDate day = date == null ? LocalDate.now() : date;
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime start = day.atStartOfDay();
        LocalDateTime end = day.plusDays(1).atStartOfDay();
        LocalDateTime yStart = day.minusDays(1).atStartOfDay();

        // ---------- Tài chính ----------
        AdminStatisticsRepository.GrossAndDiscount money = repo.aggregateRevenueDetails(REVENUE_STATUSES, start, end);
        BigDecimal net = nz(money.netRevenue());
        BigDecimal gross = nz(money.grossRevenue());
        BigDecimal discount = nz(money.discountAmount());
        double discountRate = percent(discount, gross);

        AdminStatisticsRepository.Aggregate today = repo.aggregateOrders(REVENUE_STATUSES, start, end);
        AdminStatisticsRepository.Aggregate yesterday = repo.aggregateOrders(REVENUE_STATUSES, yStart, start);
        BigDecimal revenueYesterday = nz(yesterday.revenue());

        // ---------- Xu hướng 7 ngày (6 ngày trước + hôm nay) ----------
        List<DayPoint> trend = new ArrayList<>();
        BigDecimal sumPrev7 = BigDecimal.ZERO;
        for (int i = 7; i >= 1; i--) {
            LocalDate d = day.minusDays(i);
            AdminStatisticsRepository.Aggregate a = repo.aggregateOrders(REVENUE_STATUSES, d.atStartOfDay(), d.plusDays(1).atStartOfDay());
            sumPrev7 = sumPrev7.add(nz(a.revenue()));
            if (i <= 6) {
                trend.add(new DayPoint(DAY_SHORT.format(d), nz(a.revenue()), a.orderCount(), false));
            }
        }
        trend.add(new DayPoint(DAY_SHORT.format(day) + " (nay)", net, today.orderCount(), true));
        BigDecimal avg7 = sumPrev7.divide(BigDecimal.valueOf(7), 0, RoundingMode.HALF_UP);

        // ---------- Đơn hàng theo trạng thái ----------
        Map<String, AdminStatisticsRepository.StatusCountAggregate> statusMap = new HashMap<>();
        for (AdminStatisticsRepository.StatusCountAggregate s : repo.countOrdersByStatus(start, end)) {
            statusMap.put(s.status() == null ? "UNKNOWN" : s.status().toUpperCase(Locale.ROOT), s);
        }
        long pending = count(statusMap, "PENDING");
        long confirmed = count(statusMap, "CONFIRMED");
        long shipping = count(statusMap, "SHIPPING");
        long completed = count(statusMap, "COMPLETED");
        long cancelled = count(statusMap, "CANCELLED");
        long totalOrders = statusMap.values().stream().mapToLong(AdminStatisticsRepository.StatusCountAggregate::orderCount).sum();
        long validOrders = today.orderCount();
        double cancelRate = totalOrders == 0 ? 0 : round1(cancelled * 100.0 / totalOrders);

        List<ShareItem> statusBreakdown = new ArrayList<>();
        addStatus(statusBreakdown, "Hoàn tất", completed, totalOrders, "#10b981");
        addStatus(statusBreakdown, "Đang giao", shipping, totalOrders, "#06b6d4");
        addStatus(statusBreakdown, "Đã xác nhận", confirmed, totalOrders, "#2563eb");
        addStatus(statusBreakdown, "Chờ xác nhận", pending, totalOrders, "#f59e0b");
        addStatus(statusBreakdown, "Đã hủy", cancelled, totalOrders, "#ef4444");

        long sold = repo.countSoldProducts(REVENUE_STATUSES, start, end);
        BigDecimal aov = validOrders == 0 ? BigDecimal.ZERO : net.divide(BigDecimal.valueOf(validOrders), 0, RoundingMode.HALF_UP);
        double itemsPerOrder = validOrders == 0 ? 0 : round1((double) sold / validOrders);

        // ---------- Chi tiết đơn ----------
        List<AdminStatisticsRepository.OrderDetailAggregate> details = repo.findOrderDetails(start, end, 300);
        LocalDateTime overdueBefore = now.minusHours(PENDING_OVERDUE_HOURS);
        long overduePending = details.stream()
                .filter(o -> "PENDING".equalsIgnoreCase(o.status()) && o.createdAt().isBefore(overdueBefore))
                .count();
        List<String> cancelReasons = details.stream()
                .filter(o -> "CANCELLED".equalsIgnoreCase(o.status()))
                .map(o -> o.cancelReason() == null || o.cancelReason().isBlank() ? "Không ghi lý do" : o.cancelReason().trim())
                .distinct()
                .limit(5)
                .toList();
        List<OrderRow> orderRows = details.stream().map(o -> new OrderRow(
                o.orderCode(),
                TIME.format(o.createdAt()),
                o.recipientName(),
                o.recipientPhone(),
                o.items() == null ? "" : o.items(),
                o.totalQuantity(),
                nz(o.discountAmount()),
                nz(o.totalAmount()),
                paymentLabel(o.paymentMethod()),
                paymentStatusLabel(o.paymentStatus()),
                statusLabel(o.status()),
                o.status() == null ? "" : o.status().toUpperCase(Locale.ROOT),
                o.cancelReason()
        )).toList();

        // ---------- Kênh thanh toán ----------
        List<AdminStatisticsRepository.ChannelDetailAggregate> channels = repo.channelRevenueDetailed(REVENUE_STATUSES, start, end);
        List<ShareItem> paymentChannels = new ArrayList<>();
        for (int i = 0; i < channels.size(); i++) {
            AdminStatisticsRepository.ChannelDetailAggregate c = channels.get(i);
            long validCount = c.totalOrders() - c.cancelledOrders();
            paymentChannels.add(new ShareItem(paymentLabel(c.paymentMethod()), validCount, nz(c.revenue()),
                    net.signum() > 0 ? percent(nz(c.revenue()), net) : percent(BigDecimal.valueOf(validCount), BigDecimal.valueOf(Math.max(validOrders, 1))),
                    PALETTE[i % PALETTE.length]));
        }

        // ---------- Danh mục / size / màu ----------
        List<ShareItem> categories = new ArrayList<>();
        List<AdminStatisticsRepository.CategoryAggregate> cats = repo.categoryRevenue(REVENUE_STATUSES, start, end, 6);
        BigDecimal catTotal = cats.stream().map(c -> nz(c.revenue())).reduce(BigDecimal.ZERO, BigDecimal::add);
        for (int i = 0; i < cats.size(); i++) {
            categories.add(new ShareItem(cats.get(i).name(), 0, nz(cats.get(i).revenue()), percent(nz(cats.get(i).revenue()), catTotal), PALETTE[i % PALETTE.length]));
        }
        List<ShareItem> sizes = new ArrayList<>();
        List<AdminStatisticsRepository.SizeAggregate> sizeRows = repo.topSizes(REVENUE_STATUSES, start, end, 6);
        long sizeTotal = sizeRows.stream().mapToLong(AdminStatisticsRepository.SizeAggregate::quantity).sum();
        for (int i = 0; i < sizeRows.size(); i++) {
            sizes.add(new ShareItem("Size " + sizeRows.get(i).size(), sizeRows.get(i).quantity(), BigDecimal.ZERO,
                    sizeTotal == 0 ? 0 : round1(sizeRows.get(i).quantity() * 100.0 / sizeTotal), PALETTE[i % PALETTE.length]));
        }
        List<ShareItem> colors = new ArrayList<>();
        List<AdminStatisticsRepository.ColorAggregate> colorRows = repo.topColors(REVENUE_STATUSES, start, end, 6);
        long colorTotal = colorRows.stream().mapToLong(AdminStatisticsRepository.ColorAggregate::quantity).sum();
        for (AdminStatisticsRepository.ColorAggregate c : colorRows) {
            colors.add(new ShareItem(c.color(), c.quantity(), BigDecimal.ZERO,
                    colorTotal == 0 ? 0 : round1(c.quantity() * 100.0 / colorTotal), colorHex(c.color())));
        }

        // ---------- Top sản phẩm ----------
        Map<String, BigDecimal> yRevenueMap = repo.productRevenueMap(REVENUE_STATUSES, yStart, start);
        List<TopProductRow> topProducts = new ArrayList<>();
        List<AdminStatisticsRepository.ProductWithStockAggregate> tops = repo.topProductsWithStock(REVENUE_STATUSES, start, end, 5);
        for (int i = 0; i < tops.size(); i++) {
            AdminStatisticsRepository.ProductWithStockAggregate p = tops.get(i);
            BigDecimal rev = nz(p.revenue());
            topProducts.add(new TopProductRow(i + 1, p.productName(), p.categoryName(), p.soldQuantity(), rev,
                    percent(rev, net), growth(rev, yRevenueMap.get(p.productName())), p.currentStock(),
                    p.currentStock() <= 0 ? "OUT" : p.currentStock() <= LOW_STOCK_THRESHOLD ? "LOW" : "OK"));
        }
        BigDecimal top3 = topProducts.stream().limit(3).map(TopProductRow::revenue).reduce(BigDecimal.ZERO, BigDecimal::add);

        // ---------- Kho hàng ----------
        AdminStatisticsRepository.StockHealthAggregate stock = repo.countStockHealth();
        List<StockRow> urgent = repo.findUrgentLowStockProducts(8).stream()
                .map(s -> new StockRow(s.productName(), s.categoryName(), s.currentStock(), s.currentStock() <= 0 ? "Hết hàng" : "Sắp hết"))
                .toList();
        List<StockRow> slow = repo.findSlowMovingProducts(day.minusDays(6).atStartOfDay(), end, SLOW_MOVING_MIN_STOCK, 5).stream()
                .map(s -> new StockRow(s.productName(), s.categoryName(), s.currentStock(), "Chậm bán 7 ngày"))
                .toList();

        Double revGrowth = growth(net, revenueYesterday);
        Double ordGrowth = growth(BigDecimal.valueOf(validOrders), BigDecimal.valueOf(yesterday.orderCount()));
        Double avgGrowth = growth(net, avg7);

        // ---------- Cảnh báo & việc cần làm ----------
        List<Insight> insights = buildInsights(net, revGrowth, avgGrowth, validOrders, totalOrders, pending, overduePending,
                shipping, cancelled, cancelRate, cancelReasons, discountRate, itemsPerOrder, paymentChannels, categories,
                sizes, colors, topProducts, stock, urgent, slow);
        List<String> summary = buildExecutiveSummary(net, revGrowth, validOrders, totalOrders, aov, sold, insights, topProducts);

        return new DailyReportDto(
                day, DATE.format(day), day.toString(), capitalize(day.getDayOfWeek().getDisplayName(TextStyle.FULL, VI)),
                GENERATED.format(now),
                net, gross, discount, discountRate, revenueYesterday, revGrowth, avg7, avgGrowth,
                totalOrders, validOrders, yesterday.orderCount(), ordGrowth, aov, itemsPerOrder, sold,
                pending, overduePending, confirmed, shipping, completed, cancelled, cancelRate, cancelReasons,
                paymentChannels, categories, sizes, colors, statusBreakdown,
                topProducts, percent(top3, net),
                stock.outOfStockCount(), stock.lowStockCount(), urgent, slow,
                trend, summary, insights, orderRows
        );
    }

    // ========================================================================================
    // QUY TẮC SINH CẢNH BÁO / ĐỀ XUẤT
    // ========================================================================================

    private List<Insight> buildInsights(BigDecimal net, Double revGrowth, Double avgGrowth, long validOrders, long totalOrders,
                                        long pending, long overduePending, long shipping, long cancelled, double cancelRate,
                                        List<String> cancelReasons, double discountRate, double itemsPerOrder,
                                        List<ShareItem> channels, List<ShareItem> categories, List<ShareItem> sizes,
                                        List<ShareItem> colors, List<TopProductRow> topProducts,
                                        AdminStatisticsRepository.StockHealthAggregate stock,
                                        List<StockRow> urgent, List<StockRow> slow) {
        List<Insight> list = new ArrayList<>();

        // ----- KHO HÀNG -----
        for (TopProductRow p : topProducts) {
            if ("OUT".equals(p.stockStatus())) {
                list.add(new Insight("DANGER", "Kho hàng", "Cháy hàng sản phẩm bán chạy: " + p.productName(),
                        "Sản phẩm Top " + p.rank() + " bán được " + p.soldQuantity() + " cái hôm nay nhưng tồn kho đã về 0.",
                        "Nhập gấp tối thiểu " + suggestRestock(p.soldQuantity(), 0) + " cái hoặc tạm ẩn sản phẩm để tránh khách đặt rồi hủy."));
            } else if ("LOW".equals(p.stockStatus())) {
                list.add(new Insight("WARNING", "Kho hàng", "Sắp hết hàng sản phẩm chủ lực: " + p.productName(),
                        "Bán " + p.soldQuantity() + " cái hôm nay, kho chỉ còn " + p.currentStock() + " cái.",
                        "Lên đơn nhập thêm khoảng " + suggestRestock(p.soldQuantity(), p.currentStock()) + " cái (đủ bán khoảng 7 ngày theo tốc độ hôm nay)."));
            }
        }
        if (stock.outOfStockCount() > 0 || stock.lowStockCount() > 0) {
            String names = urgent.stream().limit(3).map(StockRow::productName).reduce((a, b) -> a + "; " + b).orElse("");
            list.add(new Insight(stock.outOfStockCount() > 0 ? "DANGER" : "WARNING", "Kho hàng",
                    "Toàn kho có " + stock.outOfStockCount() + " biến thể hết hàng, " + stock.lowStockCount() + " biến thể sắp hết (≤ " + LOW_STOCK_THRESHOLD + ")",
                    names.isBlank() ? "Cần kiểm kê lại kho." : "Ưu tiên kiểm tra: " + names + ".",
                    "Kiểm kê và lập kế hoạch nhập hàng trong tuần, ưu tiên mẫu đang có người mua."));
        }
        if (!slow.isEmpty()) {
            StockRow s = slow.get(0);
            list.add(new Insight("INFO", "Kho hàng", "Hàng tồn chậm luân chuyển: " + slow.size() + " sản phẩm không bán được trong 7 ngày",
                    "Nhiều nhất: " + s.productName() + " (tồn " + s.currentStock() + " cái).",
                    "Cân nhắc flash-sale 10-20%, tạo combo bán kèm hoặc đưa lên vị trí nổi bật trên trang chủ để giải phóng tồn kho."));
        }

        // ----- VẬN HÀNH -----
        if (pending > 0) {
            list.add(new Insight(overduePending > 0 ? "DANGER" : "WARNING", "Vận hành",
                    pending + " đơn đang chờ xác nhận" + (overduePending > 0 ? " (" + overduePending + " đơn đã chờ quá " + PENDING_OVERDUE_HOURS + " giờ)" : ""),
                    "Đơn chờ lâu dễ khiến khách hủy hoặc đánh giá xấu về tốc độ xử lý.",
                    "Nhắc nhân viên ca sáng xác nhận và bàn giao vận chuyển trước 10h00."));
        }
        if (shipping > 0) {
            list.add(new Insight("INFO", "Vận hành", shipping + " đơn đang trên đường giao",
                    "Cần theo dõi để cập nhật trạng thái Hoàn tất khi khách nhận hàng.",
                    "Kiểm tra hành trình vận chuyển, chủ động liên hệ khách nếu giao trễ."));
        }
        if (cancelled > 0) {
            String level = cancelRate >= 10 ? "WARNING" : "INFO";
            list.add(new Insight(level, "Vận hành", cancelled + " đơn bị hủy (tỷ lệ hủy " + fmt1(cancelRate) + "%)",
                    "Lý do: " + String.join("; ", cancelReasons) + ".",
                    cancelRate >= 10 ? "Tỷ lệ hủy cao - rà soát lại tồn kho thực tế, mô tả sản phẩm và thời gian xác nhận đơn."
                            : "Theo dõi thêm, tỷ lệ hủy đang ở mức chấp nhận được."));
        }

        // ----- KINH DOANH -----
        if (validOrders == 0) {
            list.add(new Insight("WARNING", "Kinh doanh", "Không phát sinh đơn hàng hợp lệ nào trong ngày",
                    totalOrders > 0 ? "Có " + totalOrders + " đơn nhưng đều đã bị hủy." : "Website không ghi nhận đơn hàng mới.",
                    "Kiểm tra website/thanh toán có hoạt động bình thường không; cân nhắc chạy mã giảm giá hoặc đăng bài quảng bá."));
        } else {
            if (revGrowth != null && revGrowth <= -20) {
                list.add(new Insight("WARNING", "Kinh doanh", "Doanh thu giảm " + fmt1(Math.abs(revGrowth)) + "% so với hôm qua",
                        "Doanh thu hôm nay " + money(net) + ".",
                        "Xem lại chương trình khuyến mãi, quảng cáo và tình trạng hết hàng của các mẫu bán chạy."));
            } else if (revGrowth != null && revGrowth >= 20) {
                list.add(new Insight("SUCCESS", "Kinh doanh", "Doanh thu tăng " + fmt1(revGrowth) + "% so với hôm qua",
                        "Doanh thu hôm nay " + money(net) + (avgGrowth != null ? " (" + signed(avgGrowth) + "% so với trung bình 7 ngày)" : "") + ".",
                        "Duy trì chương trình đang chạy, đảm bảo đủ hàng cho các mẫu bán chạy."));
            }
            if (!topProducts.isEmpty()) {
                TopProductRow p = topProducts.get(0);
                list.add(new Insight("SUCCESS", "Kinh doanh", "Sản phẩm dẫn đầu: " + p.productName(),
                        "Bán " + p.soldQuantity() + " cái, mang về " + money(p.revenue()) + " (" + fmt1(p.revenueShare()) + "% doanh thu).",
                        "Ưu tiên hiển thị ở trang chủ và gợi ý bán kèm sản phẩm cùng phong cách."));
            }
            if (!colors.isEmpty() || !sizes.isEmpty()) {
                String c = colors.isEmpty() ? "" : "màu " + colors.get(0).label() + " (" + fmt1(colors.get(0).percent()) + "%)";
                String s = sizes.isEmpty() ? "" : sizes.get(0).label() + " (" + fmt1(sizes.get(0).percent()) + "%)";
                list.add(new Insight("INFO", "Kinh doanh", "Xu hướng mua: " + String.join(", ", List.of(c, s).stream().filter(x -> !x.isBlank()).toList()),
                        "Đây là màu sắc / kích cỡ được chọn nhiều nhất hôm nay.",
                        "Ưu tiên nhập và hiển thị các biến thể " + String.join(" / ", List.of(c, s).stream().filter(x -> !x.isBlank()).toList()) + "."));
            }
            if (discountRate >= 15) {
                list.add(new Insight("WARNING", "Kinh doanh", "Chi phí giảm giá cao: " + fmt1(discountRate) + "% tiền hàng",
                        "Voucher đang làm giảm đáng kể biên lợi nhuận.",
                        "Rà soát điều kiện áp dụng voucher (giá trị đơn tối thiểu, giới hạn số lượt)."));
            }
            if (validOrders >= 3 && itemsPerOrder < 1.3) {
                list.add(new Insight("INFO", "Kinh doanh", "Khách chủ yếu mua 1 món/đơn (" + fmt1(itemsPerOrder) + " món/đơn)",
                        "Giá trị đơn còn thấp, chưa tận dụng được bán kèm.",
                        "Tạo combo áo + quần hoặc ưu đãi 'mua 2 giảm thêm 5%' để tăng giá trị đơn."));
            }
            channels.stream().filter(c -> c.label().startsWith("COD") && c.percent() >= 70).findFirst().ifPresent(c ->
                    list.add(new Insight("INFO", "Kinh doanh", "Đơn COD chiếm " + fmt1(c.percent()) + "% doanh thu",
                            "Đơn thanh toán khi nhận hàng có rủi ro bom hàng cao hơn.",
                            "Khuyến khích chuyển khoản trước (giảm nhẹ phí ship hoặc tặng voucher nhỏ).")));
        }

        // Sắp xếp theo mức độ ưu tiên
        Map<String, Integer> order = Map.of("DANGER", 0, "WARNING", 1, "SUCCESS", 2, "INFO", 3);
        list.sort(Comparator.comparingInt(i -> order.getOrDefault(i.level(), 9)));
        return list;
    }

    private List<String> buildExecutiveSummary(BigDecimal net, Double revGrowth, long validOrders, long totalOrders,
                                               BigDecimal aov, long sold, List<Insight> insights, List<TopProductRow> tops) {
        List<String> s = new ArrayList<>();
        String growthText = revGrowth == null ? " (hôm qua chưa có doanh thu để so sánh)"
                : " (" + (revGrowth >= 0 ? "tăng " : "giảm ") + fmt1(Math.abs(revGrowth)) + "% so với hôm qua)";
        s.add("Doanh thu ghi nhận " + money(net) + growthText + ".");
        s.add(validOrders + " đơn hợp lệ / " + totalOrders + " đơn phát sinh, " + sold + " sản phẩm bán ra, giá trị trung bình " + money(aov) + "/đơn.");
        if (!tops.isEmpty()) {
            s.add("Sản phẩm bán chạy nhất: " + tops.get(0).productName() + " (" + tops.get(0).soldQuantity() + " cái).");
        }
        long urgentCount = insights.stream().filter(i -> "DANGER".equals(i.level())).count();
        long warnCount = insights.stream().filter(i -> "WARNING".equals(i.level())).count();
        if (urgentCount + warnCount == 0) {
            s.add("Không có cảnh báo khẩn cấp nào cần xử lý.");
        } else {
            Insight first = insights.get(0);
            s.add("Có " + urgentCount + " việc KHẨN CẤP và " + warnCount + " việc CẦN CHÚ Ý. Ưu tiên số 1: " + first.title() + ".");
        }
        return s;
    }

    // ========================================================================================
    // DỮ LIỆU GỬI CHO AI (Gemini) - dạng văn bản ngắn gọn, đủ ý
    // ========================================================================================

    public String buildAiContext(DailyReportDto r) {
        StringBuilder sb = new StringBuilder();
        sb.append("BÁO CÁO NGÀY ").append(r.reportDateLabel()).append(" (").append(r.weekdayLabel()).append(") - FashionShop\n\n");
        sb.append("[TÀI CHÍNH]\n");
        sb.append("- Doanh thu ghi nhận: ").append(money(r.netRevenue()))
                .append(" | Hôm qua: ").append(money(r.revenueYesterday()))
                .append(" | Tăng trưởng: ").append(r.revenueGrowthVsYesterday() == null ? "không so sánh được" : signed(r.revenueGrowthVsYesterday()) + "%")
                .append(" | TB 7 ngày trước: ").append(money(r.avgRevenue7Days())).append('\n');
        sb.append("- Tiền hàng trước giảm giá: ").append(money(r.grossRevenue()))
                .append(" | Giảm giá/voucher: ").append(money(r.discountAmount())).append(" (").append(fmt1(r.discountRate())).append("%)\n");
        sb.append("[ĐƠN HÀNG]\n");
        sb.append("- Tổng đơn phát sinh: ").append(r.totalOrders()).append(" | Hợp lệ: ").append(r.validOrders())
                .append(" | Hôm qua: ").append(r.ordersYesterday()).append('\n');
        sb.append("- Giá trị TB/đơn: ").append(money(r.averageOrderValue())).append(" | Số món/đơn: ").append(fmt1(r.itemsPerOrder()))
                .append(" | Sản phẩm bán ra: ").append(r.soldProducts()).append('\n');
        sb.append("- Trạng thái: Chờ xác nhận ").append(r.pendingOrders()).append(" (quá 2 giờ: ").append(r.overduePendingOrders())
                .append("), Đã xác nhận ").append(r.confirmedOrders()).append(", Đang giao ").append(r.shippingOrders())
                .append(", Hoàn tất ").append(r.completedOrders()).append(", Hủy ").append(r.cancelledOrders())
                .append(" (tỷ lệ hủy ").append(fmt1(r.cancelRate())).append("%)\n");
        if (!r.cancelReasons().isEmpty()) sb.append("- Lý do hủy: ").append(String.join("; ", r.cancelReasons())).append('\n');
        sb.append("[TOP SẢN PHẨM]\n");
        if (r.topProducts().isEmpty()) sb.append("- Không có sản phẩm nào được bán.\n");
        for (TopProductRow p : r.topProducts()) {
            sb.append("- #").append(p.rank()).append(' ').append(p.productName()).append(" (").append(p.categoryName()).append("): bán ")
                    .append(p.soldQuantity()).append(" cái, ").append(money(p.revenue())).append(", chiếm ").append(fmt1(p.revenueShare()))
                    .append("% doanh thu, tồn kho còn ").append(p.currentStock()).append('\n');
        }
        sb.append("[XU HƯỚNG] Size: ").append(shares(r.sizes())).append(" | Màu: ").append(shares(r.colors()))
                .append(" | Danh mục: ").append(shares(r.categories())).append(" | Thanh toán: ").append(shares(r.paymentChannels())).append('\n');
        sb.append("[KHO HÀNG] Biến thể hết hàng: ").append(r.outOfStockVariants()).append(", sắp hết (<=5): ").append(r.lowStockVariants()).append('\n');
        r.urgentStockItems().stream().limit(6).forEach(s -> sb.append("- ").append(s.status()).append(": ").append(s.productName()).append(" còn ").append(s.currentStock()).append('\n'));
        r.slowMovingItems().forEach(s -> sb.append("- Chậm bán 7 ngày: ").append(s.productName()).append(" tồn ").append(s.currentStock()).append('\n'));
        sb.append("[DOANH THU 7 NGÀY] ");
        r.trend7Days().forEach(d -> sb.append(d.label()).append(": ").append(money(d.revenue())).append(" / ").append(d.orders()).append(" đơn; "));
        sb.append('\n');
        return sb.toString();
    }

    // ========================================================================================
    // TIỆN ÍCH
    // ========================================================================================

    private String shares(List<ShareItem> items) {
        if (items.isEmpty()) return "chưa có dữ liệu";
        return items.stream().limit(4).map(i -> i.label() + " " + fmt1(i.percent()) + "%").reduce((a, b) -> a + ", " + b).orElse("");
    }

    private static void addStatus(List<ShareItem> list, String label, long count, long total, String color) {
        if (count > 0) list.add(new ShareItem(label, count, BigDecimal.ZERO, total == 0 ? 0 : round1(count * 100.0 / total), color));
    }

    private static long count(Map<String, AdminStatisticsRepository.StatusCountAggregate> map, String key) {
        AdminStatisticsRepository.StatusCountAggregate a = map.get(key);
        return a == null ? 0 : a.orderCount();
    }

    private static long suggestRestock(long soldToday, long stock) {
        long target = Math.max(10, soldToday * 7);
        return Math.max(10, target - stock);
    }

    static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }

    static double percent(BigDecimal part, BigDecimal total) {
        if (part == null || total == null || total.signum() == 0) return 0;
        return part.multiply(BigDecimal.valueOf(100)).divide(total, 1, RoundingMode.HALF_UP).doubleValue();
    }

    static Double growth(BigDecimal current, BigDecimal previous) {
        if (previous == null || previous.signum() == 0) return null;
        return nz(current).subtract(previous).multiply(BigDecimal.valueOf(100)).divide(previous, 1, RoundingMode.HALF_UP).doubleValue();
    }

    static double round1(double v) {
        return Math.round(v * 10.0) / 10.0;
    }

    public static String money(BigDecimal v) {
        return NumberFormat.getIntegerInstance(VI).format(nz(v).setScale(0, RoundingMode.HALF_UP)) + " đ";
    }

    public static String fmt1(double v) {
        return String.format(VI, "%.1f", v);
    }

    static String signed(double v) {
        return (v >= 0 ? "+" : "") + fmt1(v);
    }

    private static String capitalize(String s) {
        return s == null || s.isEmpty() ? s : Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }

    public static String paymentLabel(String method) {
        if (method == null) return "Khác";
        return switch (method.toUpperCase(Locale.ROOT)) {
            case "COD" -> "COD (trả khi nhận)";
            case "BANK_TRANSFER" -> "Chuyển khoản";
            case "E_WALLET" -> "Ví điện tử";
            default -> method;
        };
    }

    private static String paymentStatusLabel(String status) {
        if (status == null) return "";
        return switch (status.toUpperCase(Locale.ROOT)) {
            case "PAID" -> "Đã thanh toán";
            case "UNPAID" -> "Chưa thanh toán";
            case "REFUNDED" -> "Đã hoàn tiền";
            case "FAILED" -> "Thất bại";
            default -> status;
        };
    }

    public static String statusLabel(String status) {
        if (status == null) return "";
        return switch (status.toUpperCase(Locale.ROOT)) {
            case "PENDING" -> "Chờ xác nhận";
            case "CONFIRMED" -> "Đã xác nhận";
            case "SHIPPING" -> "Đang giao";
            case "COMPLETED" -> "Hoàn tất";
            case "CANCELLED" -> "Đã hủy";
            default -> status;
        };
    }

    static String colorHex(String color) {
        if (color == null) return "#64748b";
        String c = color.trim().toLowerCase(VI);
        if (c.contains("đen")) return "#111827";
        if (c.contains("trắng")) return "#e5e7eb";
        if (c.contains("đỏ")) return "#dc2626";
        if (c.contains("xanh lá") || c.contains("rêu")) return "#16a34a";
        if (c.contains("xanh")) return "#2563eb";
        if (c.contains("vàng")) return "#eab308";
        if (c.contains("hồng")) return "#ec4899";
        if (c.contains("cam")) return "#f97316";
        if (c.contains("nâu") || c.contains("be")) return "#b45309";
        if (c.contains("xám") || c.contains("ghi")) return "#6b7280";
        if (c.contains("tím")) return "#9333ea";
        return "#475569";
    }
}
