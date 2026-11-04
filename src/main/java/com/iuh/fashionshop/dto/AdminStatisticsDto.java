package com.iuh.fashionshop.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
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
        double topProductsShare
) {
    public record Kpi(BigDecimal value, double growthRate) {
        public double growthPercent() {
            return growthRate;
        }
    }

    public record WeeklyData(String label, BigDecimal revenue, long orderCount) {
    }

    public record CategoryRevenue(String name, BigDecimal revenue, double share) {
        public double sharePercent() {
            return share;
        }
    }

    public record ChannelRevenue(String channelName, BigDecimal revenue, double share, String dotClass) {
        public String name() {
            return channelName;
        }

        public double sharePercent() {
            return share;
        }
    }

    public record TopProduct(
            int rank,
            String productName,
            String categoryName,
            long soldQuantity,
            BigDecimal revenue,
            double share,
            double growthRate
    ) {
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
