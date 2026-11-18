
package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.AdminStatisticsDto;
import com.iuh.fashionshop.repository.iml.AdminStatisticsRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class AdminStatisticsService {

    private static final List<String> SUCCESS_STATUSES = List.of("COMPLETED", "DELIVERED", "SHIPPING", "PROCESSING", "CONFIRMED");
    private static final DateTimeFormatter DATE_LABEL = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter WEEK_LABEL = DateTimeFormatter.ofPattern("dd/MM");
    private static final DateTimeFormatter MONTH_LABEL = DateTimeFormatter.ofPattern("MM/yyyy");
    private static final List<String> CHANNEL_COLORS = List.of("#3b82f6", "#10b981", "#f59e0b", "#8b5cf6", "#ec4899");

    private final AdminStatisticsRepository statisticsRepository;

    public AdminStatisticsService(AdminStatisticsRepository statisticsRepository) {
        this.statisticsRepository = statisticsRepository;
    }

    public AdminStatisticsDto load(LocalDate startDate, LocalDate endDate) {
        LocalDate start = startDate == null ? LocalDate.now().withDayOfMonth(1) : startDate;
        LocalDate end = endDate == null ? start.withDayOfMonth(start.lengthOfMonth()) : endDate;
        if (end.isBefore(start)) {
            end = start;
        }

        LocalDate prevStart = start.minusMonths(1);
        LocalDate prevEnd = end.minusMonths(1);

        LocalDateTime startAt = start.atStartOfDay();
        LocalDateTime endAt = end.plusDays(1).atStartOfDay();
        LocalDateTime prevStartAt = prevStart.atStartOfDay();
        LocalDateTime prevEndAt = prevEnd.plusDays(1).atStartOfDay();

        AdminStatisticsRepository.Aggregate currentAgg = statisticsRepository.aggregateOrders(SUCCESS_STATUSES, startAt, endAt);
        AdminStatisticsRepository.Aggregate prevAgg = statisticsRepository.aggregateOrders(SUCCESS_STATUSES, prevStartAt, prevEndAt);

        long currentSold = statisticsRepository.countSoldProducts(SUCCESS_STATUSES, startAt, endAt);
        long prevSold = statisticsRepository.countSoldProducts(SUCCESS_STATUSES, prevStartAt, prevEndAt);

        BigDecimal currentRevenue = nonNull(currentAgg.revenue());
        BigDecimal prevRevenue = nonNull(prevAgg.revenue());
        long currentOrders = currentAgg.orderCount();
        long prevOrders = prevAgg.orderCount();

        BigDecimal currentAov = currentOrders == 0 ? BigDecimal.ZERO
                : currentRevenue.divide(BigDecimal.valueOf(currentOrders), 0, RoundingMode.HALF_UP);
        BigDecimal prevAov = prevOrders == 0 ? BigDecimal.ZERO
                : prevRevenue.divide(BigDecimal.valueOf(prevOrders), 0, RoundingMode.HALF_UP);

        List<AdminStatisticsDto.WeeklyData> weeklyData = buildWeeklyData(start, end, startAt, endAt);
        AdminStatisticsDto.WeeklyData bestPeriod = weeklyData.stream()
                .filter(w -> w.revenue().compareTo(BigDecimal.ZERO) > 0 || w.orderCount() > 0)
                .max((a, b) -> a.revenue().compareTo(b.revenue()))
                .orElse(weeklyData.isEmpty() ? new AdminStatisticsDto.WeeklyData("N/A", BigDecimal.ZERO, 0) : weeklyData.get(0));

        List<AdminStatisticsDto.CategoryRevenue> categoryRevenues = buildCategoryRevenue(startAt, endAt, currentRevenue);
        List<AdminStatisticsDto.ChannelRevenue> channelRevenues = buildChannelRevenue(startAt, endAt, currentRevenue);
        String channelDonutGradient = buildChannelDonutGradient(channelRevenues);
        List<AdminStatisticsDto.TopProduct> topProducts = buildTopProducts(startAt, endAt, prevStartAt, prevEndAt, currentRevenue);

        BigDecimal topRevenue = topProducts.stream().map(AdminStatisticsDto.TopProduct::revenue).reduce(BigDecimal.ZERO, BigDecimal::add);
        long topSold = topProducts.stream().mapToLong(AdminStatisticsDto.TopProduct::soldQuantity).sum();

        // 4 chỉ số chất lượng doanh thu mới
        AdminStatisticsRepository.GrossAndDiscount revDetails = statisticsRepository.aggregateRevenueDetails(SUCCESS_STATUSES, startAt, endAt);
        BigDecimal grossRevenue = nonNull(revDetails.grossRevenue());
        BigDecimal discountAmount = nonNull(revDetails.discountAmount());
        BigDecimal netRevenue = nonNull(revDetails.netRevenue());
        double discountRate = grossRevenue.compareTo(BigDecimal.ZERO) > 0
                ? discountAmount.multiply(BigDecimal.valueOf(100)).divide(grossRevenue, 1, RoundingMode.HALF_UP).doubleValue()
                : 0.0;
        double itemsPerOrder = currentOrders > 0
                ? Math.round(((double) currentSold / currentOrders) * 10.0) / 10.0
                : 0.0;

        // Phân tích ngành thời trang: Size & Màu sắc
        List<AdminStatisticsDto.SizeShare> sizeShares = buildSizeShares(startAt, endAt, currentSold);
        List<AdminStatisticsDto.ColorShare> colorShares = buildColorShares(startAt, endAt, currentSold);

        // Đánh giá sức khỏe kho hàng toàn sàn
        AdminStatisticsRepository.StockHealthAggregate stockHealth = statisticsRepository.countStockHealth();
        List<AdminStatisticsDto.LowStockItem> urgentLowStockItems = statisticsRepository.findUrgentLowStockProducts(6).stream()
                .map(p -> new AdminStatisticsDto.LowStockItem(
                        p.productId(),
                        p.productName(),
                        p.categoryName(),
                        p.currentStock(),
                        p.currentStock() == 0 ? "bg-danger-subtle text-danger border border-danger-subtle" : "bg-warning-subtle text-warning-emphasis border border-warning-subtle",
                        p.currentStock() == 0 ? "Hết hàng" : "Sắp hết",
                        p.currentStock() == 0 ? "Cần nhập gấp" : "Bổ sung thêm"
                ))
                .toList();

        // Sinh thông điệp kinh doanh thông minh (Smart Insights)
        List<AdminStatisticsDto.SmartInsight> smartInsights = generateSmartInsights(
                categoryRevenues, topProducts, channelRevenues, discountAmount, discountRate, bestPeriod, currentOrders, stockHealth
        );

        return new AdminStatisticsDto(
                start,
                end,
                DATE_LABEL.format(start) + " – " + DATE_LABEL.format(end),
                "tháng " + MONTH_LABEL.format(prevStart),
                new AdminStatisticsDto.Kpi(currentRevenue, growth(currentRevenue, prevRevenue)),
                new AdminStatisticsDto.Kpi(BigDecimal.valueOf(currentOrders), growth(BigDecimal.valueOf(currentOrders), BigDecimal.valueOf(prevOrders))),
                new AdminStatisticsDto.Kpi(currentAov, growth(currentAov, prevAov)),
                new AdminStatisticsDto.Kpi(BigDecimal.valueOf(currentSold), growth(BigDecimal.valueOf(currentSold), BigDecimal.valueOf(prevSold))),
                weeklyData,
                bestPeriod.label(),
                share(bestPeriod.revenue(), currentRevenue),
                bestPeriod.orderCount(),
                categoryRevenues,
                channelRevenues,
                channelDonutGradient,
                currentRevenue,
                topProducts,
                topSold,
                topRevenue,
                share(topRevenue, currentRevenue),
                smartInsights,
                grossRevenue,
                discountAmount,
                netRevenue,
                discountRate,
                itemsPerOrder,
                sizeShares,
                colorShares,
                stockHealth.lowStockCount(),
                stockHealth.outOfStockCount(),
                urgentLowStockItems
        );
    }

    private List<AdminStatisticsDto.WeeklyData> buildWeeklyData(LocalDate start, LocalDate end, LocalDateTime startAt, LocalDateTime endAt) {
        List<AdminStatisticsDto.WeeklyData> rows = new ArrayList<>();
        long totalDays = ChronoUnit.DAYS.between(start, end) + 1;
        int step = (totalDays <= 10) ? 1 : 7;

        List<AdminStatisticsRepository.SoldItemAggregate> allSoldItems = statisticsRepository.findSoldItems(
                SUCCESS_STATUSES, startAt, endAt
        );

        DateTimeFormatter itemDateFormat = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

        LocalDate cursor = start;
        while (!cursor.isAfter(end)) {
            LocalDate segmentEnd = (step == 1) ? cursor : cursor.plusDays(step - 1);
            if (segmentEnd.isAfter(end)) {
                segmentEnd = end;
            }
            LocalDateTime segStart = cursor.atStartOfDay();
            LocalDateTime segEnd = segmentEnd.plusDays(1).atStartOfDay();

            AdminStatisticsRepository.WeeklyAggregate aggregate = statisticsRepository.aggregateWeek(
                    SUCCESS_STATUSES,
                    segStart,
                    segEnd
            );

            List<AdminStatisticsDto.SoldItemDetail> segmentItems = allSoldItems.stream()
                    .filter(item -> !item.createdAt().isBefore(segStart) && item.createdAt().isBefore(segEnd))
                    .map(item -> new AdminStatisticsDto.SoldItemDetail(
                            item.orderCode(),
                            item.productName(),
                            item.color(),
                            item.size(),
                            item.unitPrice(),
                            item.quantity(),
                            item.unitPrice().multiply(BigDecimal.valueOf(item.quantity())),
                            item.createdAt(),
                            item.createdAt().format(itemDateFormat)
                    ))
                    .toList();

            String label = (cursor.equals(segmentEnd))
                    ? WEEK_LABEL.format(cursor)
                    : WEEK_LABEL.format(cursor) + " – " + WEEK_LABEL.format(segmentEnd);

            rows.add(new AdminStatisticsDto.WeeklyData(
                    label,
                    nonNull(aggregate.revenue()),
                    aggregate.orderCount(),
                    segmentItems
            ));
            cursor = segmentEnd.plusDays(1);
        }
        return rows;
    }

    private List<AdminStatisticsDto.CategoryRevenue> buildCategoryRevenue(LocalDateTime start, LocalDateTime end, BigDecimal totalRevenue) {
        return statisticsRepository.categoryRevenue(SUCCESS_STATUSES, start, end, 5).stream()
                .map(row -> new AdminStatisticsDto.CategoryRevenue(
                        row.name(),
                        nonNull(row.revenue()),
                        share(nonNull(row.revenue()), totalRevenue)))
                .toList();
    }

    private List<AdminStatisticsDto.ChannelRevenue> buildChannelRevenue(LocalDateTime start, LocalDateTime end, BigDecimal totalRevenue) {
        List<AdminStatisticsRepository.ChannelDetailAggregate> rows = statisticsRepository.channelRevenueDetailed(SUCCESS_STATUSES, start, end);
        List<AdminStatisticsDto.ChannelRevenue> result = new ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            AdminStatisticsRepository.ChannelDetailAggregate row = rows.get(i);
            String dotClass = switch (i % 3) {
                case 0 -> "dot-1";
                case 1 -> "dot-2";
                default -> "dot-3";
            };
            double successRate = row.totalOrders() > 0
                    ? Math.round(((double) row.completedOrders() * 100 / row.totalOrders()) * 10.0) / 10.0
                    : 100.0;

            result.add(new AdminStatisticsDto.ChannelRevenue(
                    channelLabel(row.paymentMethod()),
                    nonNull(row.revenue()),
                    share(nonNull(row.revenue()), totalRevenue),
                    dotClass,
                    row.totalOrders(),
                    row.completedOrders(),
                    row.cancelledOrders(),
                    successRate
            ));
        }
        return result;
    }

    private String buildChannelDonutGradient(List<AdminStatisticsDto.ChannelRevenue> channels) {
        if (channels == null || channels.isEmpty()) {
            return "conic-gradient(#e2e8f0 0% 100%)";
        }
        double sum = channels.stream().mapToDouble(AdminStatisticsDto.ChannelRevenue::share).sum();
        if (sum <= 0.0) {
            return "conic-gradient(#e2e8f0 0% 100%)";
        }
        StringBuilder sb = new StringBuilder("conic-gradient(");
        double currentPercent = 0.0;
        for (int i = 0; i < channels.size(); i++) {
            AdminStatisticsDto.ChannelRevenue ch = channels.get(i);
            String color = CHANNEL_COLORS.get(i % CHANNEL_COLORS.size());
            double nextPercent = (i == channels.size() - 1) ? 100.0 : Math.min(100.0, currentPercent + ch.share());
            if (i > 0) sb.append(", ");
            sb.append(color).append(" ").append(String.format(Locale.US, "%.1f%%", currentPercent))
                    .append(" ").append(String.format(Locale.US, "%.1f%%", nextPercent));
            currentPercent = nextPercent;
        }
        sb.append(")");
        return sb.toString();
    }

    private List<AdminStatisticsDto.TopProduct> buildTopProducts(
            LocalDateTime start,
            LocalDateTime end,
            LocalDateTime prevStart,
            LocalDateTime prevEnd,
            BigDecimal totalRevenue
    ) {
        Map<String, BigDecimal> previousRevenueMap = statisticsRepository.productRevenueMap(SUCCESS_STATUSES, prevStart, prevEnd);
        List<AdminStatisticsRepository.ProductWithStockAggregate> currentRows = statisticsRepository.topProductsWithStock(SUCCESS_STATUSES, start, end, 5);
        List<AdminStatisticsDto.TopProduct> result = new ArrayList<>();

        for (int i = 0; i < currentRows.size(); i++) {
            AdminStatisticsRepository.ProductWithStockAggregate row = currentRows.get(i);
            BigDecimal currentRevenue = nonNull(row.revenue());
            BigDecimal prevRevenue = nonNull(previousRevenueMap.get(row.productName()));
            long stock = row.currentStock();

            String stockStatus;
            String stockStatusText;
            String stockBadgeClass;
            String recommendation;

            if (stock <= 0) {
                stockStatus = "OUT_OF_STOCK";
                stockStatusText = "Hết hàng (0 sp)";
                stockBadgeClass = "bg-danger-subtle text-danger border border-danger-subtle";
                recommendation = "Cần nhập gấp 🔴";
            } else if (stock <= 5) {
                stockStatus = "LOW_STOCK";
                stockStatusText = "Sắp hết (" + stock + " sp)";
                stockBadgeClass = "bg-warning-subtle text-warning-emphasis border border-warning-subtle";
                recommendation = "Bổ sung thêm 🟡";
            } else {
                stockStatus = "IN_STOCK";
                stockStatusText = "Đủ hàng (" + stock + " sp)";
                stockBadgeClass = "bg-success-subtle text-success border border-success-subtle";
                recommendation = "Duy trì bán 🟢";
            }

            result.add(new AdminStatisticsDto.TopProduct(
                    i + 1,
                    row.productId(),
                    row.productName(),
                    row.categoryName(),
                    row.soldQuantity(),
                    currentRevenue,
                    share(currentRevenue, totalRevenue),
                    growth(currentRevenue, prevRevenue),
                    stock,
                    stockStatus,
                    stockStatusText,
                    stockBadgeClass,
                    recommendation
            ));
        }
        return result;
    }

    private List<AdminStatisticsDto.SizeShare> buildSizeShares(LocalDateTime start, LocalDateTime end, long totalSold) {
        List<AdminStatisticsRepository.SizeAggregate> rows = statisticsRepository.topSizes(SUCCESS_STATUSES, start, end, 5);
        long sum = rows.stream().mapToLong(AdminStatisticsRepository.SizeAggregate::quantity).sum();
        long divisor = sum > 0 ? sum : (totalSold > 0 ? totalSold : 1);

        return rows.stream().map(r -> new AdminStatisticsDto.SizeShare(
                r.size(),
                r.quantity(),
                Math.round(((double) r.quantity() * 100 / divisor) * 10.0) / 10.0
        )).toList();
    }

    private List<AdminStatisticsDto.ColorShare> buildColorShares(LocalDateTime start, LocalDateTime end, long totalSold) {
        List<AdminStatisticsRepository.ColorAggregate> rows = statisticsRepository.topColors(SUCCESS_STATUSES, start, end, 5);
        long sum = rows.stream().mapToLong(AdminStatisticsRepository.ColorAggregate::quantity).sum();
        long divisor = sum > 0 ? sum : (totalSold > 0 ? totalSold : 1);

        return rows.stream().map(r -> {
            String hex = mapColorToHex(r.color());
            return new AdminStatisticsDto.ColorShare(
                    r.color(),
                    r.quantity(),
                    Math.round(((double) r.quantity() * 100 / divisor) * 10.0) / 10.0,
                    hex
            );
        }).toList();
    }

    private String mapColorToHex(String color) {
        if (color == null) return "#64748b";
        String c = color.trim().toLowerCase();
        if (c.contains("đen")) return "#0f172a";
        if (c.contains("trắng")) return "#f8fafc; border: 1px solid #cbd5e1";
        if (c.contains("đỏ")) return "#dc2626";
        if (c.contains("xanh lam") || c.contains("xanh dương") || c.contains("biển")) return "#2563eb";
        if (c.contains("xanh lá") || c.contains("rêu")) return "#16a34a";
        if (c.contains("vàng")) return "#eab308";
        if (c.contains("hồng")) return "#ec4899";
        if (c.contains("cam")) return "#f97316";
        if (c.contains("nâu") || c.contains("be")) return "#b45309";
        if (c.contains("xám") || c.contains("ghi")) return "#64748b";
        if (c.contains("tím")) return "#9333ea";
        return "#475569";
    }

    private List<AdminStatisticsDto.SmartInsight> generateSmartInsights(
            List<AdminStatisticsDto.CategoryRevenue> categoryRevenues,
            List<AdminStatisticsDto.TopProduct> topProducts,
            List<AdminStatisticsDto.ChannelRevenue> channelRevenues,
            BigDecimal discountAmount,
            double discountRate,
            AdminStatisticsDto.WeeklyData bestPeriod,
            long totalOrders,
            AdminStatisticsRepository.StockHealthAggregate stockHealth
    ) {
        List<AdminStatisticsDto.SmartInsight> list = new ArrayList<>();

        // 1. Điểm sáng danh mục (Growth & Category leader)
        if (!categoryRevenues.isEmpty()) {
            AdminStatisticsDto.CategoryRevenue topCat = categoryRevenues.get(0);
            list.add(new AdminStatisticsDto.SmartInsight(
                    "SUCCESS",
                    "Động lực tăng trưởng",
                    "bi-stars text-warning",
                    "Danh mục \"" + topCat.name() + "\" đang dẫn đầu thị phần",
                    "Đóng góp " + String.format(Locale.US, "%.1f%%", topCat.share()) + " tổng doanh thu trong kỳ. Hãy cân nhắc mở rộng mẫu mã và tăng ngân sách quảng cáo cho danh mục này.",
                    "Xem sản phẩm",
                    "/admin/products?q=" + topCat.name()
            ));
        }

        // 2. Cảnh báo tồn kho cho sản phẩm bán chạy hoặc kho toàn sàn (Stock velocity warning)
        java.util.Optional<AdminStatisticsDto.TopProduct> lowStockTopProduct = topProducts.stream()
                .filter(p -> p.currentStock() <= 5)
                .findFirst();

        if (lowStockTopProduct.isPresent()) {
            AdminStatisticsDto.TopProduct p = lowStockTopProduct.get();
            String stockMsg = p.currentStock() == 0
                    ? "Sản phẩm \"" + p.productName() + "\" đã hết sạch hàng trong kho nhưng nhu cầu khách vẫn rất cao!"
                    : "Sản phẩm Top " + p.rank() + " (\"" + p.productName() + "\") có sức bán " + p.soldQuantity() + " sp nhưng trong kho chỉ còn " + p.currentStock() + " chiếc!";
            list.add(new AdminStatisticsDto.SmartInsight(
                    p.currentStock() == 0 ? "DANGER" : "WARNING",
                    "Cảnh báo tồn kho",
                    "bi-exclamation-triangle-fill text-warning",
                    p.currentStock() == 0 ? "Cháy hàng sản phẩm bán chạy" : "Sắp đứt hàng sản phẩm chủ lực",
                    stockMsg + " Khuyến nghị liên hệ xưởng hoặc lên đơn nhập thêm để tránh mất doanh thu.",
                    "Nhập kho ngay",
                    "/admin/products/edit/" + p.productId()
            ));
        } else if (stockHealth != null && (stockHealth.outOfStockCount() > 0 || stockHealth.lowStockCount() > 0)) {
            String title = stockHealth.outOfStockCount() > 0
                    ? "Kho có " + stockHealth.outOfStockCount() + " sản phẩm đã hết hàng"
                    : "Kho có " + stockHealth.lowStockCount() + " sản phẩm chạm ngưỡng cạn (≤ 5 cái)";
            String desc = "Toàn sàn có " + (stockHealth.outOfStockCount() + stockHealth.lowStockCount()) + " sản phẩm đang ở mức báo động tồn kho. Cần chủ động kiểm kê và nhập thêm hàng để sẵn sàng phục vụ.";
            list.add(new AdminStatisticsDto.SmartInsight(
                    stockHealth.outOfStockCount() > 0 ? "DANGER" : "WARNING",
                    "Cảnh báo kho",
                    "bi-box-seam text-danger",
                    title,
                    desc,
                    "Quản lý kho hàng",
                    "/admin/inventory?stockStatus=LOW"
            ));
        } else if (!topProducts.isEmpty()) {
            AdminStatisticsDto.TopProduct p = topProducts.get(0);
            list.add(new AdminStatisticsDto.SmartInsight(
                    "INFO",
                    "Sản phẩm ngôi sao",
                    "bi-award-fill text-primary",
                    "Sản phẩm \"" + p.productName() + "\" đạt doanh số cao nhất",
                    "Đã tiêu thụ " + p.soldQuantity() + " chiếc với doanh thu " + String.format(Locale.US, "%,d đ", p.revenue().longValue()) + ". Hiện kho vẫn đảm bảo với " + p.currentStock() + " sản phẩm sẵn sàng phục vụ.",
                    "Xem chi tiết",
                    "/admin/products/edit/" + p.productId()
            ));
        }

        // 3. Rủi ro COD & Kênh thanh toán
        java.util.Optional<AdminStatisticsDto.ChannelRevenue> codChannel = channelRevenues.stream()
                .filter(c -> c.channelName().toUpperCase().contains("COD"))
                .findFirst();

        if (codChannel.isPresent() && codChannel.get().totalOrders() > 0) {
            AdminStatisticsDto.ChannelRevenue cod = codChannel.get();
            double cancelRate = cod.totalOrders() > 0 ? (double) cod.cancelledOrders() * 100 / cod.totalOrders() : 0.0;
            if (cancelRate > 10.0 || cod.cancelledOrders() > 0) {
                list.add(new AdminStatisticsDto.SmartInsight(
                        "WARNING",
                        "Kiểm soát rủi ro COD",
                        "bi-shield-exclamation text-danger",
                        "Đơn COD có " + cod.cancelledOrders() + " đơn bị hủy/hoàn (" + String.format(Locale.US, "%.1f%%", cancelRate) + ")",
                        "",
                        "Xem đơn COD",
                        "/admin/orders?payment=COD"
                ));
            } else {
                list.add(new AdminStatisticsDto.SmartInsight(
                        "INFO",
                        "Thanh toán an toàn",
                        "bi-credit-card-fill text-success",
                        "Tỷ lệ thanh toán không tiền mặt đang ổn định",
                        "Khách hàng có xu hướng tin tưởng thanh toán chuyển khoản và ví điện tử, giúp giảm thiểu tối đa rủi ro bom hàng.",
                        null,
                        null
                ));
            }
        }

        // 4. Hiệu quả khuyến mãi
        if (discountAmount != null && discountAmount.compareTo(BigDecimal.ZERO) > 0) {
            list.add(new AdminStatisticsDto.SmartInsight(
                    "INFO",
                    "Hiệu quả khuyến mãi",
                    "bi-ticket-perforated-fill text-info",
                    "Mã giảm giá đã hỗ trợ kích cầu " + String.format(Locale.US, "%,d đ", discountAmount.longValue()),
                    "Mức chiết khấu chiếm " + String.format(Locale.US, "%.1f%%", discountRate) + " doanh thu gộp. Khuyến mãi đang phát huy tác dụng kích thích khách hàng hoàn tất giỏ hàng.",
                    "Quản lý Voucher",
                    "/admin/coupons"
            ));
        }

        return list;
    }

    private String channelLabel(String paymentMethod) {
        if (paymentMethod == null) {
            return "Kênh khác";
        }
        return switch (paymentMethod.toUpperCase(Locale.ROOT)) {
            case "E_WALLET" -> "Ví điện tử & App";
            case "BANK_TRANSFER" -> "Kênh chuyển khoản";
            case "COD" -> "Thanh toán khi nhận hàng (COD)";
            default -> "Kênh " + paymentMethod;
        };
    }

    private BigDecimal nonNull(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private double growth(BigDecimal current, BigDecimal previous) {
        if (current == null) current = BigDecimal.ZERO;
        if (previous == null || previous.compareTo(BigDecimal.ZERO) == 0) {
            return current.compareTo(BigDecimal.ZERO) == 0 ? 0.0 : 100.0;
        }
        return current.subtract(previous)
                .multiply(BigDecimal.valueOf(100))
                .divide(previous, 2, RoundingMode.HALF_UP)
                .doubleValue();
    }

    private double share(BigDecimal value, BigDecimal total) {
        if (value == null) value = BigDecimal.ZERO;
        if (total == null || total.compareTo(BigDecimal.ZERO) == 0) {
            return 0.0;
        }
        return value.multiply(BigDecimal.valueOf(100))
                .divide(total, 2, RoundingMode.HALF_UP)
                .doubleValue();
    }
}
