package com.iuh.fashionshop.dto;

import java.math.BigDecimal;
import java.util.List;

public record AdminDashboardDto(
        String todayFormatted,
        String currentFilterDate,
        String currentUserName,
        String userRole,

        // KPI 1: Doanh thu
        BigDecimal totalRevenue,
        double revenueGrowthRate,
        String revenueGrowthRateText,
        BigDecimal monthlyTarget,
        boolean hasMonthlyTarget,
        double targetAchievedPercent,
        double targetAchievedPercentClamped,
        int targetMonth,
        int targetYear,
        boolean canEditActiveTarget,

        // KPI 2: Đơn hàng
        long successfulOrders,
        double ordersGrowthRate,
        String ordersGrowthRateText,
        double fulfillmentRate,

        // Top 5 sản phẩm bán chạy nhất
        List<DashboardTopProduct> topProducts,
        long totalTopProductsSold,

        // Biểu đồ chu kỳ tài chính (12 tháng)
        List<String> chartLabels,
        List<BigDecimal> chartRevenues,
        List<Long> chartOrders,
        String peakMonthNote,

        // Phân bổ trạng thái xử lý đơn hàng theo các mốc thời gian (Ngày, Tuần, Tháng, Năm, Toàn bộ)
        PipelineStats todayPipeline,
        PipelineStats weekPipeline,
        PipelineStats monthPipeline,
        PipelineStats yearPipeline,
        PipelineStats allPipeline,

        // Phân bổ trạng thái xử lý đơn hàng hôm nay (giữ để tương thích)
        long totalOrdersToday,
        long completedCount,
        double completedPercent,
        long processingCount,
        double processingPercent,
        long shippingCount,
        double shippingPercent,
        long cancelledCount,
        double cancelledPercent,

        // Theo dõi mục tiêu & mức độ hoàn thành 12 tháng
        int selectedYear,
        List<Integer> availableYears,
        List<MonthlyTargetProgressDto> monthlyProgressList,

        // Danh sách đơn hàng chờ duyệt để thao tác nhanh trên database
        List<PendingOrderSummary> pendingOrders,

        // === CÁC TRƯỜNG DỮ LIỆU CHO BIỂU ĐỒ ĐƠN HÀNG TRONG NGÀY & ĐIỀU PHỐI XỬ LÝ NHANH ===
        List<String> hourlyLabels,
        List<Long> hourlyOrders,
        List<Long> hourlyPendingOrders,
        List<Long> hourlyConfirmedOrders,
        List<BigDecimal> hourlyRevenues,

        // Dữ liệu 7 ngày gần nhất từ database thật
        List<String> weeklyLabels,
        List<BigDecimal> weeklyRevenues,
        List<Long> weeklyOrders,

        // Thống kê nhanh đơn hôm nay
        long todayPendingOrdersCount,
        long todayConfirmedOrdersCount,
        BigDecimal todayTotalRevenue,

        // Danh sách chi tiết các đơn phát sinh trong ngày để xử lý nhanh trực tiếp
        List<TodayOrderSummary> todayOrders
) {
    public record DashboardTopProduct(
            int rank,
            Long productId,
            String productName,
            String sku,
            String categoryName,
            String imageUrl,
            long soldQuantity,
            BigDecimal unitPrice,
            BigDecimal revenue,
            double sharePercent
    ) {}

    public record MonthlyTargetProgressDto(
            int month,
            int year,
            String monthLabel,
            BigDecimal targetAmount,
            boolean hasTarget,
            BigDecimal actualRevenue,
            double achievedPercent,
            double achievedPercentClamped,
            long ordersCount,
            String statusText,
            String badgeClass,
            boolean isPastMonth,
            boolean isCurrentMonth,
            boolean isFutureMonth,
            boolean canEditTarget
    ) {}

    public record PendingOrderSummary(
            Long id,
            String orderCode,
            String recipientName,
            String phone,
            BigDecimal totalAmount,
            String paymentMethod,
            String createdAtFormatted
    ) {}

    public record TodayOrderSummary(
            Long id,
            String orderCode,
            String recipientName,
            String phone,
            BigDecimal totalAmount,
            String paymentMethod,
            String status,
            String statusNameVi,
            String statusBadgeClass,
            int hourSlot,
            String timeFormatted,
            String dateTimeFormatted,
            boolean isPending
    ) {}

    public record PipelineStats(
            long totalOrders,
            long completedCount,
            double completedPercent,
            long processingCount,
            double processingPercent,
            long shippingCount,
            double shippingPercent,
            long cancelledCount,
            double cancelledPercent
    ) {}
}
