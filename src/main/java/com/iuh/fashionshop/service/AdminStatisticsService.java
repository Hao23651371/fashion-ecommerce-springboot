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

        List<AdminStatisticsDto.WeeklyData> weeklyData = buildWeeklyData(start, end);
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
                share(topRevenue, currentRevenue)
        );
    }

    private List<AdminStatisticsDto.WeeklyData> buildWeeklyData(LocalDate start, LocalDate end) {
        List<AdminStatisticsDto.WeeklyData> rows = new ArrayList<>();
        long totalDays = ChronoUnit.DAYS.between(start, end) + 1;
        int step = (totalDays <= 10) ? 1 : 7;

        LocalDate cursor = start;
        while (!cursor.isAfter(end)) {
            LocalDate segmentEnd = (step == 1) ? cursor : cursor.plusDays(step - 1);
            if (segmentEnd.isAfter(end)) {
                segmentEnd = end;
            }
            AdminStatisticsRepository.WeeklyAggregate aggregate = statisticsRepository.aggregateWeek(
                    SUCCESS_STATUSES,
                    cursor.atStartOfDay(),
                    segmentEnd.plusDays(1).atStartOfDay()
            );

            String label = (cursor.equals(segmentEnd))
                    ? WEEK_LABEL.format(cursor)
                    : WEEK_LABEL.format(cursor) + " – " + WEEK_LABEL.format(segmentEnd);

            rows.add(new AdminStatisticsDto.WeeklyData(
                    label,
                    nonNull(aggregate.revenue()),
                    aggregate.orderCount()
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
        List<AdminStatisticsRepository.ChannelAggregate> rows = statisticsRepository.channelRevenue(SUCCESS_STATUSES, start, end);
        List<AdminStatisticsDto.ChannelRevenue> result = new ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            AdminStatisticsRepository.ChannelAggregate row = rows.get(i);
            String dotClass = switch (i % 3) {
                case 0 -> "dot-1";
                case 1 -> "dot-2";
                default -> "dot-3";
            };
            result.add(new AdminStatisticsDto.ChannelRevenue(
                    channelLabel(row.paymentMethod()),
                    nonNull(row.revenue()),
                    share(nonNull(row.revenue()), totalRevenue),
                    dotClass
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
        List<AdminStatisticsRepository.ProductAggregate> currentRows = statisticsRepository.topProducts(SUCCESS_STATUSES, start, end, 5);
        List<AdminStatisticsDto.TopProduct> result = new ArrayList<>();

        for (int i = 0; i < currentRows.size(); i++) {
            AdminStatisticsRepository.ProductAggregate row = currentRows.get(i);
            BigDecimal currentRevenue = nonNull(row.revenue());
            BigDecimal prevRevenue = nonNull(previousRevenueMap.get(row.productName()));

            result.add(new AdminStatisticsDto.TopProduct(
                    i + 1,
                    row.productName(),
                    row.categoryName(),
                    row.soldQuantity(),
                    currentRevenue,
                    share(currentRevenue, totalRevenue),
                    growth(currentRevenue, prevRevenue)
            ));
        }
        return result;
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
