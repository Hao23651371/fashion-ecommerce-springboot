package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.AdminDashboardDto;
import com.iuh.fashionshop.model.DashboardSetting;
import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.repository.DashboardSettingRepository;
import com.iuh.fashionshop.repository.OrderRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminDashboardService {

    private static final List<String> SUCCESS_STATUSES = List.of("COMPLETED", "DELIVERED", "SHIPPING", "PROCESSING", "CONFIRMED");
    private static final Locale VI_LOCALE = new Locale("vi", "VN");

    private final DashboardSettingRepository settingRepository;
    private final OrderRepository orderRepository;
    private final JdbcTemplate jdbc;

    public AdminDashboardService(DashboardSettingRepository settingRepository,
                                 OrderRepository orderRepository,
                                 JdbcTemplate jdbc) {
        this.settingRepository = settingRepository;
        this.orderRepository = orderRepository;
        this.jdbc = jdbc;
    }

    /**
     * Tải dữ liệu tổng hợp cho Bảng điều khiển từ cơ sở dữ liệu thật.
     * @param filterDate Ngày/tháng được chọn để lọc số liệu KPI chính
     * @param paramYear Năm tài chính được chọn để xem tiến độ mục tiêu 12 tháng
     */
    @Transactional(readOnly = true)
    public AdminDashboardDto loadDashboard(LocalDate filterDate, Integer paramYear, String currentUserName, String userRole) {
        LocalDate today = filterDate != null ? filterDate : LocalDate.now();
        int activeYear = today.getYear();
        int activeMonth = today.getMonthValue();
        int selectedYear = (paramYear != null && paramYear >= 2020) ? paramYear : activeYear;

        // 1. Cấu hình mục tiêu từ database cho tháng & năm đang chọn
        Optional<DashboardSetting> settingOpt = settingRepository.findFirstByTargetMonthAndTargetYearOrderByUpdatedAtDesc(activeMonth, activeYear);
        boolean hasMonthlyTarget = settingOpt.isPresent() && settingOpt.get().getMonthlyTarget() != null && settingOpt.get().getMonthlyTarget().compareTo(BigDecimal.ZERO) > 0;
        BigDecimal monthlyTarget = hasMonthlyTarget ? settingOpt.get().getMonthlyTarget() : BigDecimal.ZERO;
        String highlightNote = settingOpt.map(DashboardSetting::getHighlightNote).orElse("");

        // Kiểm tra tháng đang xem có phải là tháng trong quá khứ đã chốt không
        YearMonth activePeriod = YearMonth.of(activeYear, activeMonth);
        YearMonth currentPeriod = YearMonth.now();
        boolean canEditActiveTarget = !activePeriod.isBefore(currentPeriod);

        // 2. Định dạng ngày tháng
        DateTimeFormatter dayFormatter = DateTimeFormatter.ofPattern("EEEE, 'ngày' dd 'tháng' MM, yyyy", VI_LOCALE);
        String todayFormatted = "Hôm nay: " + dayFormatter.format(today);
        String currentFilterDate = today.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));

        // 3. Doanh thu và Đơn hàng tháng này & tháng trước (Dữ liệu thật 100% từ bảng orders)
        LocalDateTime startOfMonth = today.withDayOfMonth(1).atStartOfDay();
        LocalDateTime endOfMonth = today.withDayOfMonth(today.lengthOfMonth()).plusDays(1).atStartOfDay();

        LocalDate prevMonthDate = today.minusMonths(1);
        LocalDateTime startOfPrevMonth = prevMonthDate.withDayOfMonth(1).atStartOfDay();
        LocalDateTime endOfPrevMonth = prevMonthDate.withDayOfMonth(prevMonthDate.lengthOfMonth()).plusDays(1).atStartOfDay();

        String statusInClause = SUCCESS_STATUSES.stream().map(s -> "'" + s + "'").reduce((a, b) -> a + "," + b).orElse("'COMPLETED'");

        // Query doanh thu thực tế tháng này
        BigDecimal currentMonthRevenue = queryRevenue(statusInClause, startOfMonth, endOfMonth);
        long currentMonthOrders = queryOrderCount(statusInClause, startOfMonth, endOfMonth);

        // Query doanh thu thực tế tháng trước
        BigDecimal prevMonthRevenue = queryRevenue(statusInClause, startOfPrevMonth, endOfPrevMonth);
        long prevMonthOrders = queryOrderCount(statusInClause, startOfPrevMonth, endOfPrevMonth);

        // Tỷ lệ tăng trưởng doanh thu & đơn hàng
        double revenueGrowthRate = calculateGrowth(currentMonthRevenue, prevMonthRevenue);
        double ordersGrowthRate = calculateGrowth(BigDecimal.valueOf(currentMonthOrders), BigDecimal.valueOf(prevMonthOrders));
        String revenueGrowthRateText = String.format(Locale.US, "%s%.1f%%", revenueGrowthRate >= 0 ? "+" : "", revenueGrowthRate);
        String ordersGrowthRateText = String.format(Locale.US, "%s%.1f%%", ordersGrowthRate >= 0 ? "+" : "", ordersGrowthRate);

        // Tỷ lệ đạt mục tiêu tháng đang chọn
        double targetAchievedPercent = (hasMonthlyTarget && monthlyTarget.compareTo(BigDecimal.ZERO) > 0)
                ? currentMonthRevenue.divide(monthlyTarget, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100)).doubleValue()
                : 0.0;
        double targetAchievedPercentClamped = Math.min(100.0, Math.max(0.0, targetAchievedPercent));

        // 4. Tỷ lệ hoàn thành đơn hàng tổng
        long totalAllOrders = queryTotalAllOrders();
        long totalCompletedOrders = queryOrdersByStatus("COMPLETED");
        double fulfillmentRate = totalAllOrders > 0
                ? BigDecimal.valueOf(totalCompletedOrders).divide(BigDecimal.valueOf(totalAllOrders), 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100)).doubleValue()
                : 0.0;

        // 5. Phân bổ trạng thái đơn hàng theo Ngày, Tuần, Tháng, Năm, Toàn bộ
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();
        LocalDateTime startOfWeek = today.minusDays(6).atStartOfDay();
        LocalDateTime startOfYear = LocalDate.of(selectedYear, 1, 1).atStartOfDay();
        LocalDateTime endOfYear = LocalDate.of(selectedYear + 1, 1, 1).atStartOfDay();

        AdminDashboardDto.PipelineStats todayPipeline = queryPipelineStats(startOfDay, endOfDay);
        AdminDashboardDto.PipelineStats weekPipeline = queryPipelineStats(startOfWeek, endOfDay);
        AdminDashboardDto.PipelineStats monthPipeline = queryPipelineStats(startOfMonth, endOfMonth);
        AdminDashboardDto.PipelineStats yearPipeline = queryPipelineStats(startOfYear, endOfYear);
        AdminDashboardDto.PipelineStats allPipeline = queryPipelineStats(null, null);

        // Giá trị mặc định tương thích: lấy theo ngày hôm nay (todayPipeline)
        long totalOrdersToday = todayPipeline.totalOrders();
        long completed = todayPipeline.completedCount();
        double completedPct = todayPipeline.completedPercent();
        long processing = todayPipeline.processingCount();
        double processingPct = todayPipeline.processingPercent();
        long shipping = todayPipeline.shippingCount();
        double shippingPct = todayPipeline.shippingPercent();
        long cancelled = todayPipeline.cancelledCount();
        double cancelledPct = todayPipeline.cancelledPercent();

        // 6. Top 5 sản phẩm bán chạy nhất trong tháng
        List<AdminDashboardDto.DashboardTopProduct> topProducts = queryTopProducts(statusInClause, currentMonthRevenue, startOfMonth, endOfMonth);
        long totalTopProductsSold = topProducts.stream().mapToLong(AdminDashboardDto.DashboardTopProduct::soldQuantity).sum();

        // 7. Biểu đồ chu kỳ tài chính (12 tháng trong năm)
        List<String> chartLabels = new ArrayList<>();
        List<BigDecimal> chartRevenues = new ArrayList<>();
        List<Long> chartOrders = new ArrayList<>();
        loadAnnualChartData(selectedYear, statusInClause, chartLabels, chartRevenues, chartOrders);

        // 8. BẢNG TIẾN ĐỘ MỤC TIÊU & MỨC ĐỘ HOÀN THÀNH 12 THÁNG
        List<AdminDashboardDto.MonthlyTargetProgressDto> monthlyProgressList =
                loadMonthlyTargetProgress(selectedYear, activeMonth, activeYear, statusInClause);

        List<Integer> availableYears = loadAvailableYears(activeYear);

        // 9. Danh sách đơn hàng chờ duyệt để thao tác nhanh
        List<AdminDashboardDto.PendingOrderSummary> pendingOrders = queryPendingOrders();

        // 10. Biểu đồ đơn hàng phát sinh theo giờ trong ngày (24 khung giờ thật từ database)
        List<String> hourlyLabels = new ArrayList<>();
        List<Long> hourlyOrders = new ArrayList<>();
        List<Long> hourlyPendingOrders = new ArrayList<>();
        List<Long> hourlyConfirmedOrders = new ArrayList<>();
        List<BigDecimal> hourlyRevenues = new ArrayList<>();
        List<AdminDashboardDto.TodayOrderSummary> todayOrders = new ArrayList<>();
        loadIntradayData(today, hourlyLabels, hourlyOrders, hourlyPendingOrders, hourlyConfirmedOrders, hourlyRevenues, todayOrders);

        // 11. Biểu đồ 7 ngày gần nhất (dữ liệu thật từ database)
        List<String> weeklyLabels = new ArrayList<>();
        List<BigDecimal> weeklyRevenues = new ArrayList<>();
        List<Long> weeklyOrders = new ArrayList<>();
        loadWeeklyData(today, statusInClause, weeklyLabels, weeklyRevenues, weeklyOrders);

        // Thống kê đơn hôm nay
        long todayPendingOrdersCount = todayOrders.stream().filter(AdminDashboardDto.TodayOrderSummary::isPending).count();
        long todayConfirmedOrdersCount = todayOrders.stream().filter(o -> !o.isPending() && !"CANCELLED".equalsIgnoreCase(o.status())).count();
        BigDecimal todayTotalRevenue = todayOrders.stream()
                .filter(o -> !"CANCELLED".equalsIgnoreCase(o.status()))
                .map(AdminDashboardDto.TodayOrderSummary::totalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new AdminDashboardDto(
                todayFormatted,
                currentFilterDate,
                currentUserName != null ? currentUserName : "Nguyễn Quản Trị",
                userRole != null ? userRole : "Quản trị viên cấp cao",
                currentMonthRevenue,
                revenueGrowthRate,
                revenueGrowthRateText,
                monthlyTarget,
                hasMonthlyTarget,
                targetAchievedPercent,
                targetAchievedPercentClamped,
                activeMonth,
                activeYear,
                canEditActiveTarget,
                currentMonthOrders,
                ordersGrowthRate,
                ordersGrowthRateText,
                fulfillmentRate,
                topProducts,
                totalTopProductsSold,
                chartLabels,
                chartRevenues,
                chartOrders,
                highlightNote,
                todayPipeline,
                weekPipeline,
                monthPipeline,
                yearPipeline,
                allPipeline,
                totalOrdersToday,
                completed,
                completedPct,
                processing,
                processingPct,
                shipping,
                shippingPct,
                cancelled,
                cancelledPct,
                selectedYear,
                availableYears,
                monthlyProgressList,
                pendingOrders,
                hourlyLabels,
                hourlyOrders,
                hourlyPendingOrders,
                hourlyConfirmedOrders,
                hourlyRevenues,
                weeklyLabels,
                weeklyRevenues,
                weeklyOrders,
                todayPendingOrdersCount,
                todayConfirmedOrdersCount,
                todayTotalRevenue,
                todayOrders
        );
    }

    /**
     * Tải danh sách mục tiêu và mức độ hoàn thành cho 12 tháng trong năm tài chính.
     * Quy tắc nghiệp vụ chuẩn:
     * - Tháng quá khứ (< tháng hiện tại): ĐÃ CHỐT SỔ, KHÔNG THỂ SỬA MỤC TIÊU.
     *   + Nếu Doanh thu >= Mục tiêu => "Đạt chỉ tiêu 🎉"
     *   + Nếu Doanh thu < Mục tiêu  => "Không đạt ⚠️"
     * - Tháng hiện tại (== tháng hiện tại): ĐANG TIẾN HÀNH. Được phép sửa (kèm xác nhận).
     *   + Nếu Doanh thu >= Mục tiêu => "Cán mốc sớm 🚀"
     *   + Nếu Doanh thu < Mục tiêu  => "Đang tiến hành ⏳"
     * - Tháng tương lai (> tháng hiện tại): KẾ HOẠCH. Được phép sửa.
     */
    private List<AdminDashboardDto.MonthlyTargetProgressDto> loadMonthlyTargetProgress(
            int year, int activeMonth, int activeYear, String statusInClause) {

        Map<Integer, BigDecimal> revByMonth = new HashMap<>();
        Map<Integer, Long> ordersByMonth = new HashMap<>();

        String sql = """
            SELECT MONTH(created_at) AS monthNumber,
                   COALESCE(SUM(total_amount), 0) AS monthRevenue,
                   COUNT(*) AS monthOrders
            FROM orders
            WHERE status IN (%s) AND YEAR(created_at) = ?
            GROUP BY MONTH(created_at)
        """.formatted(statusInClause);

        jdbc.query(sql, rs -> {
            int m = rs.getInt("monthNumber");
            revByMonth.put(m, rs.getBigDecimal("monthRevenue"));
            ordersByMonth.put(m, rs.getLong("monthOrders"));
        }, year);

        List<DashboardSetting> settings = settingRepository.findAllByTargetYearOrderByTargetMonthAsc(year);
        Map<Integer, DashboardSetting> settingMap = settings.stream()
                .collect(Collectors.toMap(DashboardSetting::getTargetMonth, s -> s, (s1, s2) -> s1));

        YearMonth currentPeriod = YearMonth.now();

        List<AdminDashboardDto.MonthlyTargetProgressDto> list = new ArrayList<>();
        for (int m = 1; m <= 12; m++) {
            BigDecimal actualRev = revByMonth.getOrDefault(m, BigDecimal.ZERO);
            long ordersCount = ordersByMonth.getOrDefault(m, 0L);

            DashboardSetting s = settingMap.get(m);
            boolean hasTarget = s != null && s.getMonthlyTarget() != null && s.getMonthlyTarget().compareTo(BigDecimal.ZERO) > 0;
            BigDecimal target = hasTarget ? s.getMonthlyTarget() : BigDecimal.ZERO;

            double percent = (hasTarget && target.compareTo(BigDecimal.ZERO) > 0)
                    ? actualRev.divide(target, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100)).doubleValue()
                    : 0.0;
            double clamped = Math.min(100.0, Math.max(0.0, percent));

            YearMonth monthPeriod = YearMonth.of(year, m);
            boolean isPastMonth = monthPeriod.isBefore(currentPeriod);
            boolean isCurrentMonth = monthPeriod.equals(currentPeriod);
            boolean isFutureMonth = monthPeriod.isAfter(currentPeriod);
            boolean canEdit = !isPastMonth; // Tháng quá khứ đã chốt sổ => KHÔNG ĐƯỢC PHÉP SỬA

            String statusText;
            String badgeClass;

            if (isPastMonth) {
                // THÁNG ĐÃ QUA TRONG QUÁ KHỨ (ĐÃ CHỐT SỔ KẾ TOÁN)
                if (hasTarget) {
                    if (actualRev.compareTo(target) >= 0) {
                        statusText = "Đạt chỉ tiêu 🎉";
                        badgeClass = "status-success";
                    } else {
                        statusText = "Không đạt ⚠️";
                        badgeClass = "status-failed";
                    }
                } else {
                    statusText = "Đã chốt sổ 🔒";
                    badgeClass = "status-closed";
                }
            } else if (isCurrentMonth) {
                // THÁNG HIỆN TẠI (ĐANG TRONG KỲ KINH DOANH)
                if (hasTarget) {
                    if (actualRev.compareTo(target) >= 0) {
                        statusText = "Cán mốc sớm 🚀";
                        badgeClass = "status-success";
                    } else {
                        statusText = "Đang tiến hành ⏳";
                        badgeClass = "status-progress";
                    }
                } else {
                    statusText = "Chưa đặt chỉ tiêu";
                    badgeClass = "status-none";
                }
            } else {
                // THÁNG TƯƠNG LAI (KỲ KẾ HOẠCH)
                if (hasTarget) {
                    statusText = "Kế hoạch 📋";
                    badgeClass = "status-plan";
                } else {
                    statusText = "Chưa lập chỉ tiêu";
                    badgeClass = "status-none";
                }
            }

            list.add(new AdminDashboardDto.MonthlyTargetProgressDto(
                    m,
                    year,
                    "Tháng " + m,
                    target,
                    hasTarget,
                    actualRev,
                    roundOneDecimal(percent),
                    roundOneDecimal(clamped),
                    ordersCount,
                    statusText,
                    badgeClass,
                    isPastMonth,
                    isCurrentMonth,
                    isFutureMonth,
                    canEdit
            ));
        }

        return list;
    }

    private List<Integer> loadAvailableYears(int activeYear) {
        Set<Integer> years = new TreeSet<>(Comparator.reverseOrder());
        years.add(activeYear);
        years.add(activeYear - 1);
        years.add(activeYear + 1);

        try {
            List<Integer> orderYears = jdbc.queryForList(
                    "SELECT DISTINCT YEAR(created_at) FROM orders WHERE created_at IS NOT NULL", Integer.class);
            years.addAll(orderYears);
        } catch (Exception ignored) {}

        try {
            List<Integer> settingYears = jdbc.queryForList(
                    "SELECT DISTINCT target_year FROM dashboard_setting WHERE target_year IS NOT NULL", Integer.class);
            years.addAll(settingYears);
        } catch (Exception ignored) {}

        return new ArrayList<>(years);
    }

    /**
     * THAO TÁC DATABASE: Cập nhật mục tiêu doanh thu cho tháng/năm.
     * NGHIỆP VỤ BẢO VỆ: Chặn không cho sửa mục tiêu của các tháng trong quá khứ đã chốt sổ!
     */
    @Transactional
    public DashboardSetting updateTarget(BigDecimal newTarget, String note, Integer month, Integer year) {
        int targetM = (month != null && month >= 1 && month <= 12) ? month : LocalDate.now().getMonthValue();
        int targetY = (year != null && year >= 2020) ? year : LocalDate.now().getYear();

        YearMonth targetPeriod = YearMonth.of(targetY, targetM);
        YearMonth currentPeriod = YearMonth.now();

        // CHẶN SỬA MỤC TIÊU THÁNG QUÁ KHỨ
        if (targetPeriod.isBefore(currentPeriod)) {
            throw new IllegalStateException("Tháng " + targetM + "/" + targetY + " đã kết thúc và chốt số liệu. Không thể chỉnh sửa mục tiêu của kỳ kinh doanh trong quá khứ!");
        }

        DashboardSetting setting = settingRepository.findFirstByTargetMonthAndTargetYearOrderByUpdatedAtDesc(targetM, targetY)
                .orElseGet(() -> {
                    DashboardSetting s = new DashboardSetting();
                    s.setTargetMonth(targetM);
                    s.setTargetYear(targetY);
                    return s;
                });

        if (newTarget != null && newTarget.compareTo(BigDecimal.ZERO) >= 0) {
            setting.setMonthlyTarget(newTarget);
        }
        if (note != null) {
            setting.setHighlightNote(note.trim());
        }
        setting.setUpdatedAt(LocalDateTime.now());
        return settingRepository.save(setting);
    }

    /**
     * THAO TÁC DATABASE: Duyệt nhanh đơn hàng đang chờ duyệt.
     */
    @Transactional
    public boolean quickConfirmOrder(Long orderId) {
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            if (order.getStatus() == OrderStatus.PENDING) {
                order.setStatus(OrderStatus.CONFIRMED);
                orderRepository.save(order);
                return true;
            }
        }
        return false;
    }

    /**
     * THAO TÁC DATABASE: Duyệt toàn bộ đơn hàng đang ở trạng thái PENDING.
     */
    @Transactional
    public int quickConfirmAllPendingOrders() {
        return jdbc.update("UPDATE orders SET status = 'CONFIRMED' WHERE status = 'PENDING'");
    }

    /**
     * THAO TÁC DATABASE: Hủy đơn hàng kèm lý do.
     */
    @Transactional
    public boolean quickCancelOrder(Long orderId, String reason) {
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            if (order.getStatus() == OrderStatus.PENDING || order.getStatus() == OrderStatus.CONFIRMED) {
                order.setStatus(OrderStatus.CANCELLED);
                order.setCancelReason(reason != null && !reason.isBlank() ? reason.trim() : "Quản trị viên hủy đơn nhanh");
                order.setCancelledAt(LocalDateTime.now());
                orderRepository.save(order);
                return true;
            }
        }
        return false;
    }

    /**
     * Tải dữ liệu phát sinh đơn hàng 24 khung giờ trong ngày từ database thật.
     */
    private void loadIntradayData(
            LocalDate date,
            List<String> hourlyLabels,
            List<Long> hourlyOrders,
            List<Long> hourlyPendingOrders,
            List<Long> hourlyConfirmedOrders,
            List<BigDecimal> hourlyRevenues,
            List<AdminDashboardDto.TodayOrderSummary> todayOrders) {

        for (int h = 0; h < 24; h++) {
            hourlyLabels.add(String.format("%02d:00", h));
            hourlyOrders.add(0L);
            hourlyPendingOrders.add(0L);
            hourlyConfirmedOrders.add(0L);
            hourlyRevenues.add(BigDecimal.ZERO);
        }

        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();

        String sql = """
            SELECT id, order_code, recipient_name, recipient_phone, total_amount, payment_method, status, created_at,
                   HOUR(created_at) AS order_hour
            FROM orders
            WHERE created_at >= ? AND created_at < ?
            ORDER BY created_at DESC
        """;

        DateTimeFormatter timeFmt = DateTimeFormatter.ofPattern("HH:mm");
        DateTimeFormatter fullFmt = DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy");

        jdbc.query(sql, rs -> {
            Long id = rs.getLong("id");
            String code = rs.getString("order_code");
            String recipient = rs.getString("recipient_name");
            String phone = rs.getString("recipient_phone");
            BigDecimal total = rs.getBigDecimal("total_amount");
            if (total == null) total = BigDecimal.ZERO;
            String payMethod = rs.getString("payment_method");
            String status = rs.getString("status");
            int hour = rs.getInt("order_hour");
            LocalDateTime createdAt = rs.getTimestamp("created_at").toLocalDateTime();

            boolean isPending = "PENDING".equalsIgnoreCase(status);
            boolean isCancelled = "CANCELLED".equalsIgnoreCase(status);
            boolean isConfirmedOrBetter = !isPending && !isCancelled;

            String statusNameVi = switch (status != null ? status.toUpperCase() : "") {
                case "PENDING" -> "Chờ xác nhận";
                case "CONFIRMED" -> "Đã xác nhận";
                case "SHIPPING" -> "Đang giao";
                case "COMPLETED" -> "Hoàn tất";
                case "CANCELLED" -> "Đã hủy";
                default -> status != null ? status : "Chờ xử lý";
            };

            String badgeClass = switch (status != null ? status.toUpperCase() : "") {
                case "PENDING" -> "bg-warning-subtle text-warning-emphasis border border-warning-subtle";
                case "CONFIRMED" -> "bg-primary-subtle text-primary border border-primary-subtle";
                case "SHIPPING" -> "bg-info-subtle text-info-emphasis border border-info-subtle";
                case "COMPLETED" -> "bg-success-subtle text-success border border-success-subtle";
                case "CANCELLED" -> "bg-danger-subtle text-danger border border-danger-subtle";
                default -> "bg-light text-dark border";
            };

            if (hour >= 0 && hour < 24) {
                hourlyOrders.set(hour, hourlyOrders.get(hour) + 1);
                if (isPending) {
                    hourlyPendingOrders.set(hour, hourlyPendingOrders.get(hour) + 1);
                }
                if (isConfirmedOrBetter) {
                    hourlyConfirmedOrders.set(hour, hourlyConfirmedOrders.get(hour) + 1);
                }
                if (!isCancelled) {
                    hourlyRevenues.set(hour, hourlyRevenues.get(hour).add(total));
                }
            }

            todayOrders.add(new AdminDashboardDto.TodayOrderSummary(
                    id, code, recipient != null ? recipient : "Khách vãng lai",
                    phone != null ? phone : "-",
                    total, payMethod != null ? payMethod : "COD",
                    status != null ? status : "PENDING",
                    statusNameVi, badgeClass, hour,
                    createdAt.format(timeFmt),
                    createdAt.format(fullFmt),
                    isPending
            ));
        }, startOfDay, endOfDay);
    }

    /**
     * Tải dữ liệu 7 ngày gần nhất từ database thật.
     */
    private void loadWeeklyData(
            LocalDate date,
            String statusInClause,
            List<String> weeklyLabels,
            List<BigDecimal> weeklyRevenues,
            List<Long> weeklyOrders) {

        LocalDate startDate = date.minusDays(6);
        LocalDateTime start = startDate.atStartOfDay();
        LocalDateTime end = date.plusDays(1).atStartOfDay();

        Map<LocalDate, BigDecimal> revMap = new HashMap<>();
        Map<LocalDate, Long> ordMap = new HashMap<>();

        String sql = """
            SELECT DATE(created_at) AS order_date,
                   COALESCE(SUM(total_amount), 0) AS daily_rev,
                   COUNT(*) AS daily_orders
            FROM orders
            WHERE status IN (%s) AND created_at >= ? AND created_at < ?
            GROUP BY DATE(created_at)
        """.formatted(statusInClause);

        jdbc.query(sql, rs -> {
            LocalDate d = rs.getDate("order_date").toLocalDate();
            revMap.put(d, rs.getBigDecimal("daily_rev"));
            ordMap.put(d, rs.getLong("daily_orders"));
        }, start, end);

        DateTimeFormatter lblFmt = DateTimeFormatter.ofPattern("dd/MM");
        for (int i = 0; i < 7; i++) {
            LocalDate d = startDate.plusDays(i);
            String dayOfWeekName = switch (d.getDayOfWeek()) {
                case MONDAY -> "T2";
                case TUESDAY -> "T3";
                case WEDNESDAY -> "T4";
                case THURSDAY -> "T5";
                case FRIDAY -> "T6";
                case SATURDAY -> "T7";
                case SUNDAY -> "CN";
            };
            weeklyLabels.add(dayOfWeekName + " (" + d.format(lblFmt) + ")");
            weeklyRevenues.add(revMap.getOrDefault(d, BigDecimal.ZERO));
            weeklyOrders.add(ordMap.getOrDefault(d, 0L));
        }
    }

    // =========================================================================
    // HELPER QUERIES (JDBCTEMPLATE)
    // =========================================================================

    private BigDecimal queryRevenue(String statusInClause, LocalDateTime start, LocalDateTime end) {
        String sql = """
            SELECT COALESCE(SUM(total_amount), 0)
            FROM orders
            WHERE status IN (%s) AND created_at >= ? AND created_at < ?
        """.formatted(statusInClause);
        BigDecimal rev = jdbc.queryForObject(sql, BigDecimal.class, start, end);
        return rev != null ? rev : BigDecimal.ZERO;
    }

    private long queryOrderCount(String statusInClause, LocalDateTime start, LocalDateTime end) {
        String sql = """
            SELECT COUNT(*)
            FROM orders
            WHERE status IN (%s) AND created_at >= ? AND created_at < ?
        """.formatted(statusInClause);
        Long count = jdbc.queryForObject(sql, Long.class, start, end);
        return count != null ? count : 0L;
    }

    private long queryTotalAllOrders() {
        Long count = jdbc.queryForObject("SELECT COUNT(*) FROM orders", Long.class);
        return count != null ? count : 0L;
    }

    private long queryOrdersByStatus(String status) {
        Long count = jdbc.queryForObject("SELECT COUNT(*) FROM orders WHERE status = ?", Long.class, status);
        return count != null ? count : 0L;
    }

    private AdminDashboardDto.PipelineStats queryPipelineStats(LocalDateTime start, LocalDateTime end) {
        String sql;
        List<Object> paramList = new ArrayList<>();
        if (start != null && end != null) {
            sql = "SELECT status, COUNT(*) AS cnt FROM orders WHERE created_at >= ? AND created_at < ? GROUP BY status";
            paramList.add(start);
            paramList.add(end);
        } else if (start != null) {
            sql = "SELECT status, COUNT(*) AS cnt FROM orders WHERE created_at >= ? GROUP BY status";
            paramList.add(start);
        } else {
            sql = "SELECT status, COUNT(*) AS cnt FROM orders GROUP BY status";
        }

        Map<String, Long> map = new HashMap<>();
        jdbc.query(sql, rs -> {
            map.put(rs.getString("status"), rs.getLong("cnt"));
        }, paramList.toArray());

        long completed = map.getOrDefault("COMPLETED", 0L);
        long processing = map.getOrDefault("PENDING", 0L) + map.getOrDefault("CONFIRMED", 0L);
        long shipping = map.getOrDefault("SHIPPING", 0L);
        long cancelled = map.getOrDefault("CANCELLED", 0L);
        long total = completed + processing + shipping + cancelled;

        long divisor = total > 0 ? total : 1;
        double completedPct = total > 0 ? roundOneDecimal((double) completed * 100 / divisor) : 0.0;
        double processingPct = total > 0 ? roundOneDecimal((double) processing * 100 / divisor) : 0.0;
        double shippingPct = total > 0 ? roundOneDecimal((double) shipping * 100 / divisor) : 0.0;
        double cancelledPct = total > 0 ? roundOneDecimal((double) cancelled * 100 / divisor) : 0.0;

        return new AdminDashboardDto.PipelineStats(
                total, completed, completedPct, processing, processingPct, shipping, shippingPct, cancelled, cancelledPct
        );
    }

    private List<AdminDashboardDto.DashboardTopProduct> queryTopProducts(
            String statusInClause, BigDecimal totalRevenue, LocalDateTime start, LocalDateTime end) {
        String sql = """
            SELECT 
                p.id AS productId,
                COALESCE(p.name, oi.product_name) AS productName,
                COALESCE(p.image_url, '/images/products/default.jpg') AS imageUrl,
                COALESCE(MAX(pv.sku), CONCAT('AT-', p.id)) AS sku,
                COALESCE(MAX(c.name), 'Thời trang') AS categoryName,
                COALESCE(p.price, MAX(oi.unit_price)) AS price,
                COALESCE(SUM(oi.quantity), 0) AS soldQuantity,
                COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS revenue
            FROM order_item oi
            JOIN orders o ON o.id = oi.order_id
            LEFT JOIN product_variant pv ON pv.id = oi.variant_id
            LEFT JOIN product p ON p.id = pv.product_id
            LEFT JOIN category c ON c.id = p.category_id
            WHERE o.status IN (%s) AND o.created_at >= ? AND o.created_at < ?
            GROUP BY p.id, COALESCE(p.name, oi.product_name), p.image_url, p.price
            ORDER BY revenue DESC
            LIMIT 5
        """.formatted(statusInClause);

        List<AdminDashboardDto.DashboardTopProduct> list = new ArrayList<>();
        jdbc.query(sql, rs -> {
            int rank = list.size() + 1;
            Long pId = rs.getLong("productId");
            String pName = rs.getString("productName");
            String img = rs.getString("imageUrl");
            String sku = rs.getString("sku");
            String catName = rs.getString("categoryName");
            BigDecimal price = rs.getBigDecimal("price");
            if (price == null) price = BigDecimal.ZERO;
            long soldQty = rs.getLong("soldQuantity");
            BigDecimal rev = rs.getBigDecimal("revenue");
            if (rev == null) rev = BigDecimal.ZERO;

            double share = totalRevenue.compareTo(BigDecimal.ZERO) > 0
                    ? rev.divide(totalRevenue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100)).doubleValue()
                    : 0.0;

            list.add(new AdminDashboardDto.DashboardTopProduct(
                    rank, pId, pName != null ? pName : "Sản phẩm #" + pId,
                    "SKU: " + (sku != null ? sku : "AT-" + pId) + " • " + (catName != null ? catName : "Atelier"),
                    catName != null ? catName : "Atelier",
                    img != null ? img : "/images/products/default.jpg",
                    soldQty, price, rev, share
            ));
        }, start, end);

        return list;
    }

    private void loadAnnualChartData(int year, String statusInClause, List<String> labels, List<BigDecimal> revenues, List<Long> orders) {
        // Khởi tạo 12 tháng từ T1 đến T12
        for (int m = 1; m <= 12; m++) {
            labels.add("T" + m);
            revenues.add(BigDecimal.ZERO);
            orders.add(0L);
        }

        String sql = """
            SELECT MONTH(created_at) AS monthNumber,
                   COALESCE(SUM(total_amount), 0) AS monthRevenue,
                   COUNT(*) AS monthOrders
            FROM orders
            WHERE status IN (%s) AND YEAR(created_at) = ?
            GROUP BY MONTH(created_at)
        """.formatted(statusInClause);

        jdbc.query(sql, rs -> {
            int m = rs.getInt("monthNumber");
            if (m >= 1 && m <= 12) {
                revenues.set(m - 1, rs.getBigDecimal("monthRevenue"));
                orders.set(m - 1, rs.getLong("monthOrders"));
            }
        }, year);
    }

    private List<AdminDashboardDto.PendingOrderSummary> queryPendingOrders() {
        DateTimeFormatter df = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
        List<AdminDashboardDto.PendingOrderSummary> list = new ArrayList<>();
        String sql = """
            SELECT id, order_code, recipient_name, recipient_phone, total_amount, payment_method, created_at
            FROM orders
            WHERE status = 'PENDING'
            ORDER BY created_at DESC
            LIMIT 10
        """;
        jdbc.query(sql, rs -> {
            BigDecimal totalAmt = rs.getBigDecimal("total_amount");
            list.add(new AdminDashboardDto.PendingOrderSummary(
                    rs.getLong("id"),
                    rs.getString("order_code"),
                    rs.getString("recipient_name"),
                    rs.getString("recipient_phone"),
                    totalAmt != null ? totalAmt : BigDecimal.ZERO,
                    rs.getString("payment_method"),
                    rs.getTimestamp("created_at").toLocalDateTime().format(df)
            ));
        });
        return list;
    }

    private double calculateGrowth(BigDecimal current, BigDecimal prev) {
        if (prev == null || prev.compareTo(BigDecimal.ZERO) == 0) {
            return current.compareTo(BigDecimal.ZERO) > 0 ? 100.0 : 0.0;
        }
        return current.subtract(prev)
                .divide(prev, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .doubleValue();
    }

    private double roundOneDecimal(double val) {
        return Math.round(val * 10.0) / 10.0;
    }
}
