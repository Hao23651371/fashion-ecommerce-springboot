package com.iuh.fashionshop.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public record AdminStatisticsDto(
        LocalDate startDate,
        LocalDate endDate,
        String dateRangeLabel,
        String previousMonthLabel,
        Kpi revenueKpi,
        Kpi ordersKpi,
        Kpi aovKpi,
        Kpi soldProductsKpi,
        List<WeeklyData> weeklyData,
        String bestPeriodLabel,
        double bestPeriodShare,
        long bestPeriodOrders,
        List<CategoryRevenue> categoryRevenues,
        List<ChannelRevenue> channelRevenues,
        String channelDonutGradient,
        BigDecimal totalRevenue,
        List<TopProduct> topProducts,
        long topProductsSold,
        BigDecimal topProductsRevenue,
        double topProductsShare,

        // === CÁC CHỈ SỐ MỚI NÂNG CAO: "CON SỐ BIẾT NÓI" & BUSINESS INTELLIGENCE ===
        List<SmartInsight> smartInsights,
        BigDecimal grossRevenue,
        BigDecimal discountAmount,
        BigDecimal netRevenue,
        double discountRate,
        double itemsPerOrder,
        List<SizeShare> sizeShares,
        List<ColorShare> colorShares,

        // === CẢNH BÁO TỒN KHO TOÀN DIỆN (TOÀN BỘ KHO HÀNG) ===
        long totalLowStockCount,
        long totalOutOfStockCount,
        List<LowStockItem> urgentLowStockItems
) {
    public AdminStatisticsDto(
            LocalDate startDate, LocalDate endDate, String dateRangeLabel, String previousMonthLabel,
            Kpi revenueKpi, Kpi ordersKpi, Kpi aovKpi, Kpi soldProductsKpi, List<WeeklyData> weeklyData,
            String bestPeriodLabel, double bestPeriodShare, long bestPeriodOrders,
            List<CategoryRevenue> categoryRevenues, List<ChannelRevenue> channelRevenues,
            String channelDonutGradient, BigDecimal totalRevenue, List<TopProduct> topProducts,
            long topProductsSold, BigDecimal topProductsRevenue, double topProductsShare,
            List<SmartInsight> smartInsights, BigDecimal grossRevenue, BigDecimal discountAmount,
            BigDecimal netRevenue, double discountRate, double itemsPerOrder,
            List<SizeShare> sizeShares, List<ColorShare> colorShares
    ) {
        this(startDate, endDate, dateRangeLabel, previousMonthLabel, revenueKpi, ordersKpi, aovKpi, soldProductsKpi,
                weeklyData, bestPeriodLabel, bestPeriodShare, bestPeriodOrders, categoryRevenues, channelRevenues,
                channelDonutGradient, totalRevenue, topProducts, topProductsSold, topProductsRevenue, topProductsShare,
                smartInsights, grossRevenue, discountAmount, netRevenue, discountRate, itemsPerOrder, sizeShares, colorShares,
                0L, 0L, List.of());
    }

    public record LowStockItem(
            Long productId,
            String productName,
            String categoryName,
            long currentStock,
            String badgeClass,
            String statusText,
            String recommendation
    ) {}

    public record Kpi(BigDecimal value, double growthRate) {
        public double growthPercent() {
            return growthRate;
        }
    }

    public record SmartInsight(
            String type, // "SUCCESS", "WARNING", "INFO", "DANGER"
            String badgeText,
            String iconClass,
            String title,
            String description,
            String actionLabel,
            String actionUrl
    ) {}

    public record SizeShare(
            String size,
            long quantity,
            double share
    ) {}

    public record ColorShare(
            String color,
            long quantity,
            double share,
            String hexColor
    ) {}

    public record SoldItemDetail(
            String orderCode,
            String productName,
            String color,
            String size,
            BigDecimal unitPrice,
            int quantity,
            BigDecimal totalPrice,
            LocalDateTime soldAt,
            String formattedSoldDate
    ) {}

    public record WeeklyData(
            String label,
            BigDecimal revenue,
            long orderCount,
            List<SoldItemDetail> items
    ) {
        public WeeklyData(String label, BigDecimal revenue, long orderCount) {
            this(label, revenue, orderCount, List.of());
        }
    }

    public record CategoryRevenue(String name, BigDecimal revenue, double share) {
        public double sharePercent() {
            return share;
        }
    }

    public record ChannelRevenue(
            String channelName,
            BigDecimal revenue,
            double share,
            String dotClass,
            long totalOrders,
            long completedOrders,
            long cancelledOrders,
            double successRate
    ) {
        public ChannelRevenue(String channelName, BigDecimal revenue, double share, String dotClass) {
            this(channelName, revenue, share, dotClass, 0L, 0L, 0L, 100.0);
        }

        public String name() {
            return channelName;
        }

        public double sharePercent() {
            return share;
        }
    }

    public record TopProduct(
            int rank,
            Long productId,
            String productName,
            String categoryName,
            long soldQuantity,
            BigDecimal revenue,
            double share,
            double growthRate,
            long currentStock,
            String stockStatus,
            String stockStatusText,
            String stockBadgeClass,
            String recommendation
    ) {
        public TopProduct(int rank, String productName, String categoryName, long soldQuantity, BigDecimal revenue, double share, double growthRate) {
            this(rank, 0L, productName, categoryName, soldQuantity, revenue, share, growthRate, 0L, "IN_STOCK", "Đủ hàng", "bg-success-subtle text-success", "Duy trì");
        }

        public double revenueSharePercent() {
            return share;
        }

        public double growthPercent() {
            return growthRate;
        }
    }

    // Compatibility aliases:
    public String rangeLabel() {
        return dateRangeLabel;
    }

    public String comparisonMonthLabel() {
        return previousMonthLabel;
    }

    public Kpi successOrderKpi() {
        return ordersKpi;
    }

    public Kpi averageOrderValueKpi() {
        return aovKpi;
    }

    public Kpi soldProductKpi() {
        return soldProductsKpi;
    }

    public double bestPeriodRevenueShare() {
        return bestPeriodShare;
    }

    public long bestPeriodOrderCount() {
        return bestPeriodOrders;
    }

    public long topProductsSoldQuantity() {
        return topProductsSold;
    }

    public double topProductsRevenueShare() {
        return topProductsShare;
    }
}
