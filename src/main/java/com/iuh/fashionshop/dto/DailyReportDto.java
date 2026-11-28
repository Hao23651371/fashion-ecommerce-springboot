package com.iuh.fashionshop.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Toàn bộ số liệu của "Báo cáo doanh thu & vận hành hằng ngày".
 * Được dùng chung cho: API JSON (n8n đọc), file PDF đính kèm và nội dung email tóm tắt.
 */
public record DailyReportDto(
        // ===== Thông tin chung =====
        LocalDate reportDate,
        String reportDateLabel,      // 28/11/2026
        String reportDateIso,        // 2026-11-28
        String weekdayLabel,         // Thứ Bảy
        String generatedAtLabel,     // 22:00:05 28/11/2026

        // ===== 1. Tài chính =====
        BigDecimal netRevenue,       // Doanh thu ghi nhận (tổng tiền khách trả, không tính đơn hủy)
        BigDecimal grossRevenue,     // Tổng tiền hàng trước giảm giá
        BigDecimal discountAmount,   // Tiền giảm giá / voucher
        double discountRate,         // % giảm giá trên tiền hàng
        BigDecimal revenueYesterday,
        Double revenueGrowthVsYesterday, // null nếu hôm qua = 0
        BigDecimal avgRevenue7Days,      // trung bình 7 ngày trước đó
        Double revenueGrowthVsAvg7,

        // ===== 2. Đơn hàng =====
        long totalOrders,            // Tổng đơn phát sinh (kể cả hủy)
        long validOrders,            // Đơn hợp lệ (không hủy)
        long ordersYesterday,
        Double ordersGrowthVsYesterday,
        BigDecimal averageOrderValue,
        double itemsPerOrder,
        long soldProducts,
        long pendingOrders,
        long overduePendingOrders,   // Đơn chờ xác nhận quá 2 giờ
        long confirmedOrders,
        long shippingOrders,
        long completedOrders,
        long cancelledOrders,
        double cancelRate,
        List<String> cancelReasons,

        // ===== 3. Xu hướng thời trang & kênh bán =====
        List<ShareItem> paymentChannels,
        List<ShareItem> categories,
        List<ShareItem> sizes,
        List<ShareItem> colors,
        List<ShareItem> statusBreakdown,

        // ===== 4. Sản phẩm =====
        List<TopProductRow> topProducts,
        double top3RevenueShare,

        // ===== 5. Kho hàng =====
        long outOfStockVariants,
        long lowStockVariants,
        List<StockRow> urgentStockItems,
        List<StockRow> slowMovingItems,

        // ===== 6. Xu hướng 7 ngày =====
        List<DayPoint> trend7Days,

        // ===== 7. Cảnh báo / việc cần làm (hệ thống tự tính) =====
        List<String> executiveSummary,
        List<Insight> insights,

        // ===== 8. Phụ lục chi tiết đơn hàng =====
        List<OrderRow> orders
) {

    public record ShareItem(String label, long quantity, BigDecimal amount, double percent, String color) {}

    public record TopProductRow(
            int rank,
            String productName,
            String categoryName,
            long soldQuantity,
            BigDecimal revenue,
            double revenueShare,
            Double growthVsYesterday,
            long currentStock,
            String stockStatus      // OUT | LOW | OK
    ) {}

    public record StockRow(String productName, String categoryName, long currentStock, String status) {}

    public record DayPoint(String label, BigDecimal revenue, long orders, boolean today) {}

    /**
     * level: DANGER | WARNING | INFO | SUCCESS
     * group: Kho hàng | Vận hành | Kinh doanh
     */
    public record Insight(String level, String group, String title, String detail, String action) {}

    public record OrderRow(
            String orderCode,
            String time,
            String customer,
            String phone,
            String items,
            long quantity,
            BigDecimal discount,
            BigDecimal total,
            String paymentMethod,
            String paymentStatus,
            String status,
            String statusCode,
            String cancelReason
    ) {}
}
