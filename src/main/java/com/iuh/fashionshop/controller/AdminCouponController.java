package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.enums.CouponStatus;
import com.iuh.fashionshop.model.enums.CustomerTargetType;
import com.iuh.fashionshop.model.enums.DiscountType;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.repository.CouponRepository;
import com.iuh.fashionshop.repository.OrderRepository;
import com.iuh.fashionshop.repository.OrderRepository.CouponStatProjection;
import com.iuh.fashionshop.service.CouponExcelExportService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Controller
@RequestMapping("/admin/coupons")
public class AdminCouponController {

    private final CouponRepository couponRepository;
    private final CategoryRepository categoryRepository;
    private final OrderRepository orderRepository;
    private final CouponExcelExportService couponExcelExportService;

    public AdminCouponController(CouponRepository couponRepository,
                               CategoryRepository categoryRepository,
                               OrderRepository orderRepository,
                               CouponExcelExportService couponExcelExportService) {
        this.couponRepository = couponRepository;
        this.categoryRepository = categoryRepository;
        this.orderRepository = orderRepository;
        this.couponExcelExportService = couponExcelExportService;
    }

    @GetMapping
    public String list(@RequestParam(required = false, defaultValue = "all") String tab,
                       @RequestParam(required = false) String keyword,
                       @RequestParam(required = false) String type,
                       @RequestParam(required = false) String target,
                       @RequestParam(required = false) Long categoryId,
                       Model model) {

        List<Coupon> allCoupons = couponRepository.findAll();
        List<Category> categories = categoryRepository.findAll();

        // Lấy thống kê hiệu quả chiến dịch từ database
        Map<Long, CouponStatProjection> statsMap = new HashMap<>();
        List<CouponStatProjection> statsList = orderRepository.getCouponUsageStats();
        for (CouponStatProjection s : statsList) {
            statsMap.put(s.getCouponId(), s);
        }

        // Tính toán các chỉ số thống kê tổng quan
        long activeCount = 0;
        long upcomingCount = 0;
        long expiredCount = 0;
        long pausedCount = 0;
        long totalUses = 0;
        long totalQuota = 0;
        BigDecimal totalDiscountAmount = BigDecimal.ZERO;
        BigDecimal totalRevenueGenerated = BigDecimal.ZERO;

        List<CouponRow> allRows = new ArrayList<>();
        for (Coupon c : allCoupons) {
            CouponStatus computed = c.getComputedStatus();
            switch (computed) {
                case ACTIVE -> activeCount++;
                case UPCOMING -> upcomingCount++;
                case EXPIRED -> expiredCount++;
                case PAUSED, DISABLED, INACTIVE -> pausedCount++;
            }

            totalUses += c.getUsedCount();
            totalQuota += c.getQuantity();

            CouponStatProjection stat = statsMap.get(c.getId());
            long orderCount = stat != null ? stat.getOrderCount() : 0;
            BigDecimal discount = stat != null && stat.getTotalDiscount() != null ? stat.getTotalDiscount() : BigDecimal.ZERO;
            BigDecimal revenue = stat != null && stat.getTotalRevenue() != null ? stat.getTotalRevenue() : BigDecimal.ZERO;

            totalDiscountAmount = totalDiscountAmount.add(discount);
            totalRevenueGenerated = totalRevenueGenerated.add(revenue);

            allRows.add(new CouponRow(c, orderCount, discount, revenue));
        }

        // Sắp xếp mã mới tạo lên trước
        allRows.sort((a, b) -> Long.compare(b.getId() != null ? b.getId() : 0, a.getId() != null ? a.getId() : 0));

        model.addAttribute("pageTitle", "Quản lý mã giảm giá");
        model.addAttribute("coupons", allRows);
        model.addAttribute("categories", categories);

        // Các chỉ số KPI tổng hợp
        model.addAttribute("totalCoupons", allCoupons.size());
        model.addAttribute("activeCoupons", activeCount);
        model.addAttribute("upcomingCoupons", upcomingCount);
        model.addAttribute("expiredCoupons", expiredCount);
        model.addAttribute("pausedCoupons", pausedCount);
        model.addAttribute("totalUses", totalUses);
        model.addAttribute("totalQuota", totalQuota);
        model.addAttribute("totalDiscountAmount", totalDiscountAmount);
        model.addAttribute("formattedTotalDiscount", formatMoney(totalDiscountAmount));
        model.addAttribute("totalRevenueGenerated", totalRevenueGenerated);
        model.addAttribute("formattedTotalRevenue", formatMoney(totalRevenueGenerated));

        // Lưu filter parameters
        model.addAttribute("selectedTab", tab);
        model.addAttribute("keyword", keyword != null ? keyword : "");
        model.addAttribute("selectedType", type != null ? type : "");
        model.addAttribute("selectedTarget", target != null ? target : "");
        model.addAttribute("selectedCategory", categoryId);

        return "admin/coupons";
    }

    @PostMapping
    public Object create(@RequestParam String code,
                         @RequestParam String name,
                         @RequestParam(required = false) String description,
                         @RequestParam DiscountType discountType,
                         @RequestParam(required = false) BigDecimal discountValue,
                         @RequestParam(required = false) BigDecimal maxDiscount,
                         @RequestParam(required = false) BigDecimal minOrderValue,
                         @RequestParam int quantity,
                         @RequestParam(required = false, defaultValue = "1") int perUserLimit,
                         @RequestParam(required = false, defaultValue = "ALL") CustomerTargetType targetCustomerType,
                         @RequestParam(required = false) Long categoryId,
                         @RequestParam String startDate,
                         @RequestParam String endDate,
                         HttpServletRequest request,
                         RedirectAttributes ra) {
        try {
            String cleanCode = code.trim().toUpperCase(Locale.ROOT);
            if (couponRepository.findByCodeIgnoreCase(cleanCode).isPresent()) {
                String msg = "Mã code \"" + cleanCode + "\" đã tồn tại. Vui lòng chọn mã khác.";
                if (isAjax(request)) {
                    return ResponseEntity.badRequest().body(Map.of("success", false, "message", msg));
                }
                ra.addFlashAttribute("errorMessage", msg);
                return "redirect:/admin/coupons";
            }

            LocalDateTime start = LocalDateTime.parse(startDate);
            LocalDateTime end = LocalDateTime.parse(endDate);
            if (end.isBefore(start)) {
                String msg = "Thời gian kết thúc phải sau thời gian bắt đầu.";
                if (isAjax(request)) {
                    return ResponseEntity.badRequest().body(Map.of("success", false, "message", msg));
                }
                ra.addFlashAttribute("errorMessage", msg);
                return "redirect:/admin/coupons";
            }

            Coupon coupon = new Coupon();
            coupon.setCode(cleanCode);
            coupon.setName(name.trim());
            coupon.setDescription(description != null && !description.isBlank() ? description.trim() : null);
            coupon.setDiscountType(discountType);
            coupon.setDiscountValue(discountValue != null ? discountValue : BigDecimal.ZERO);
            coupon.setMaxDiscount(discountType == DiscountType.PERCENT ? maxDiscount : null);
            coupon.setMinOrderValue(minOrderValue);
            coupon.setQuantity(Math.max(1, quantity));
            coupon.setPerUserLimit(Math.max(1, perUserLimit));
            coupon.setTargetCustomerType(targetCustomerType != null ? targetCustomerType : CustomerTargetType.ALL);

            if (categoryId != null && categoryId > 0) {
                categoryRepository.findById(categoryId).ifPresent(coupon::setApplicableCategory);
            }

            coupon.setStartDate(start);
            coupon.setEndDate(end);
            coupon.setStatus(CouponStatus.ACTIVE);

            Coupon saved = couponRepository.save(coupon);
            String successMsg = "Tạo mã giảm giá \"" + cleanCode + "\" thành công!";
            if (isAjax(request)) {
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", successMsg,
                        "coupon", toCouponMap(saved),
                        "stats", calculateStats()
                ));
            }
            ra.addFlashAttribute("successMessage", successMsg);
        } catch (Exception e) {
            String errorMsg = "Lỗi tạo mã giảm giá: " + e.getMessage();
            if (isAjax(request)) {
                return ResponseEntity.badRequest().body(Map.of("success", false, "message", errorMsg));
            }
            ra.addFlashAttribute("errorMessage", errorMsg);
        }
        return "redirect:/admin/coupons";
    }

    @PostMapping("/{id}/edit")
    public Object edit(@PathVariable Long id,
                       @RequestParam String name,
                       @RequestParam(required = false) String description,
                       @RequestParam DiscountType discountType,
                       @RequestParam(required = false) BigDecimal discountValue,
                       @RequestParam(required = false) BigDecimal maxDiscount,
                       @RequestParam(required = false) BigDecimal minOrderValue,
                       @RequestParam int quantity,
                       @RequestParam(required = false, defaultValue = "1") int perUserLimit,
                       @RequestParam(required = false, defaultValue = "ALL") CustomerTargetType targetCustomerType,
                       @RequestParam(required = false) Long categoryId,
                       @RequestParam String startDate,
                       @RequestParam String endDate,
                       HttpServletRequest request,
                       RedirectAttributes ra) {
        try {
            Coupon coupon = couponRepository.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy mã giảm giá"));

            LocalDateTime start = LocalDateTime.parse(startDate);
            LocalDateTime end = LocalDateTime.parse(endDate);
            if (end.isBefore(start)) {
                String msg = "Thời gian kết thúc phải sau thời gian bắt đầu.";
                if (isAjax(request)) {
                    return ResponseEntity.badRequest().body(Map.of("success", false, "message", msg));
                }
                ra.addFlashAttribute("errorMessage", msg);
                return "redirect:/admin/coupons";
            }

            coupon.setName(name.trim());
            coupon.setDescription(description != null && !description.isBlank() ? description.trim() : null);
            coupon.setDiscountType(discountType);
            coupon.setDiscountValue(discountValue != null ? discountValue : BigDecimal.ZERO);
            coupon.setMaxDiscount(discountType == DiscountType.PERCENT ? maxDiscount : null);
            coupon.setMinOrderValue(minOrderValue);
            coupon.setQuantity(Math.max(coupon.getUsedCount(), quantity));
            coupon.setPerUserLimit(Math.max(1, perUserLimit));
            coupon.setTargetCustomerType(targetCustomerType != null ? targetCustomerType : CustomerTargetType.ALL);

            if (categoryId != null && categoryId > 0) {
                categoryRepository.findById(categoryId).ifPresent(coupon::setApplicableCategory);
            } else {
                coupon.setApplicableCategory(null);
            }

            coupon.setStartDate(start);
            coupon.setEndDate(end);

            Coupon saved = couponRepository.save(coupon);
            String successMsg = "Cập nhật mã \"" + coupon.getCode() + "\" thành công!";
            if (isAjax(request)) {
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", successMsg,
                        "coupon", toCouponMap(saved),
                        "stats", calculateStats()
                ));
            }
            ra.addFlashAttribute("successMessage", successMsg);
        } catch (Exception e) {
            String errorMsg = "Lỗi cập nhật mã: " + e.getMessage();
            if (isAjax(request)) {
                return ResponseEntity.badRequest().body(Map.of("success", false, "message", errorMsg));
            }
            ra.addFlashAttribute("errorMessage", errorMsg);
        }
        return "redirect:/admin/coupons";
    }

    @PostMapping("/{id}/toggle-status")
    public Object toggleStatus(@PathVariable Long id,
                               HttpServletRequest request,
                               RedirectAttributes ra) {
        try {
            Coupon coupon = couponRepository.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy mã giảm giá"));

            String successMsg;
            if (coupon.getStatus() == CouponStatus.ACTIVE) {
                coupon.setStatus(CouponStatus.PAUSED);
                successMsg = "Đã tạm dừng mã \"" + coupon.getCode() + "\".";
            } else {
                coupon.setStatus(CouponStatus.ACTIVE);
                successMsg = "Đã kích hoạt mã \"" + coupon.getCode() + "\".";
            }
            Coupon saved = couponRepository.save(coupon);

            if (isAjax(request)) {
                Map<String, Object> map = toCouponMap(saved);
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", successMsg,
                        "coupon", map,
                        "status", saved.getStatus().name(),
                        "computedStatus", saved.getComputedStatus().name(),
                        "computedStatusText", map.get("computedStatusText"),
                        "statusBadgeClass", map.get("statusBadgeClass"),
                        "stats", calculateStats()
                ));
            }
            ra.addFlashAttribute("successMessage", successMsg);
        } catch (Exception e) {
            String errorMsg = "Lỗi chuyển trạng thái: " + e.getMessage();
            if (isAjax(request)) {
                return ResponseEntity.badRequest().body(Map.of("success", false, "message", errorMsg));
            }
            ra.addFlashAttribute("errorMessage", errorMsg);
        }
        return "redirect:/admin/coupons";
    }

    @PostMapping("/{id}/delete")
    public Object delete(@PathVariable Long id,
                         HttpServletRequest request,
                         RedirectAttributes ra) {
        try {
            Coupon coupon = couponRepository.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy mã"));

            boolean isHardDelete = true;
            String successMsg;
            if (coupon.getUsedCount() > 0) {
                // Đã có đơn hàng sử dụng mã -> không xóa cứng để tránh hỏng dữ liệu liên kết, chuyển sang DISABLED
                coupon.setStatus(CouponStatus.DISABLED);
                Coupon saved = couponRepository.save(coupon);
                isHardDelete = false;
                successMsg = "Mã \"" + coupon.getCode() + "\" đã có " + coupon.getUsedCount()
                        + " lượt dùng trong đơn hàng nên được chuyển sang trạng thái Vô hiệu hóa (không xóa cứng).";

                if (isAjax(request)) {
                    Map<String, Object> map = toCouponMap(saved);
                    return ResponseEntity.ok(Map.of(
                            "success", true,
                            "action", "DISABLED",
                            "message", successMsg,
                            "coupon", map,
                            "stats", calculateStats()
                    ));
                }
            } else {
                couponRepository.delete(coupon);
                successMsg = "Đã xóa hoàn toàn mã \"" + coupon.getCode() + "\".";
                if (isAjax(request)) {
                    return ResponseEntity.ok(Map.of(
                            "success", true,
                            "action", "DELETED",
                            "message", successMsg,
                            "id", id,
                            "stats", calculateStats()
                    ));
                }
            }
            ra.addFlashAttribute("successMessage", successMsg);
        } catch (Exception e) {
            String errorMsg = "Lỗi khi xóa mã: " + e.getMessage();
            if (isAjax(request)) {
                return ResponseEntity.badRequest().body(Map.of("success", false, "message", errorMsg));
            }
            ra.addFlashAttribute("errorMessage", errorMsg);
        }
        return "redirect:/admin/coupons";
    }

    @GetMapping("/export")
    public ResponseEntity<byte[]> exportExcel() {
        List<Coupon> allCoupons = couponRepository.findAll();
        Map<Long, CouponStatProjection> statsMap = new HashMap<>();
        for (CouponStatProjection s : orderRepository.getCouponUsageStats()) {
            statsMap.put(s.getCouponId(), s);
        }

        List<CouponRow> rows = allCoupons.stream()
                .map(c -> {
                    CouponStatProjection stat = statsMap.get(c.getId());
                    long orderCount = stat != null ? stat.getOrderCount() : 0;
                    BigDecimal discount = stat != null && stat.getTotalDiscount() != null ? stat.getTotalDiscount() : BigDecimal.ZERO;
                    BigDecimal revenue = stat != null && stat.getTotalRevenue() != null ? stat.getTotalRevenue() : BigDecimal.ZERO;
                    return new CouponRow(c, orderCount, discount, revenue);
                })
                .sorted((a, b) -> Long.compare(b.getId() != null ? b.getId() : 0, a.getId() != null ? a.getId() : 0))
                .toList();

        byte[] excelBytes = couponExcelExportService.exportToExcel(rows);
        String filename = "Danh-sach-ma-giam-gia_" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".xlsx";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    private boolean isAjax(HttpServletRequest request) {
        if (request == null) return false;
        String requestedWith = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        return "XMLHttpRequest".equalsIgnoreCase(requestedWith)
                || (accept != null && accept.contains("application/json"));
    }

    private Map<String, Object> calculateStats() {
        List<Coupon> allCoupons = couponRepository.findAll();
        Map<Long, CouponStatProjection> statsMap = new HashMap<>();
        for (CouponStatProjection s : orderRepository.getCouponUsageStats()) {
            statsMap.put(s.getCouponId(), s);
        }
        long activeCount = 0;
        long upcomingCount = 0;
        long expiredCount = 0;
        long pausedCount = 0;
        long totalUses = 0;
        long totalQuota = 0;
        BigDecimal totalDiscountAmount = BigDecimal.ZERO;
        BigDecimal totalRevenueGenerated = BigDecimal.ZERO;

        for (Coupon c : allCoupons) {
            CouponStatus computed = c.getComputedStatus();
            switch (computed) {
                case ACTIVE -> activeCount++;
                case UPCOMING -> upcomingCount++;
                case EXPIRED -> expiredCount++;
                case PAUSED, DISABLED, INACTIVE -> pausedCount++;
            }
            totalUses += c.getUsedCount();
            totalQuota += c.getQuantity();

            CouponStatProjection stat = statsMap.get(c.getId());
            BigDecimal discount = stat != null && stat.getTotalDiscount() != null ? stat.getTotalDiscount() : BigDecimal.ZERO;
            BigDecimal revenue = stat != null && stat.getTotalRevenue() != null ? stat.getTotalRevenue() : BigDecimal.ZERO;
            totalDiscountAmount = totalDiscountAmount.add(discount);
            totalRevenueGenerated = totalRevenueGenerated.add(revenue);
        }

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalCoupons", allCoupons.size());
        stats.put("activeCoupons", activeCount);
        stats.put("upcomingCoupons", upcomingCount);
        stats.put("expiredCoupons", expiredCount);
        stats.put("pausedCoupons", pausedCount);
        stats.put("totalUses", totalUses);
        stats.put("totalQuota", totalQuota);
        stats.put("totalDiscountAmount", totalDiscountAmount);
        stats.put("formattedTotalDiscount", formatMoney(totalDiscountAmount));
        stats.put("totalRevenueGenerated", totalRevenueGenerated);
        stats.put("formattedTotalRevenue", formatMoney(totalRevenueGenerated));
        return stats;
    }

    private Map<String, Object> toCouponMap(Coupon coupon) {
        CouponStatProjection stat = orderRepository.getCouponUsageStats().stream()
                .filter(s -> s.getCouponId().equals(coupon.getId()))
                .findFirst().orElse(null);
        long orderCount = stat != null ? stat.getOrderCount() : 0;
        BigDecimal discount = stat != null && stat.getTotalDiscount() != null ? stat.getTotalDiscount() : BigDecimal.ZERO;
        BigDecimal revenue = stat != null && stat.getTotalRevenue() != null ? stat.getTotalRevenue() : BigDecimal.ZERO;

        CouponRow row = new CouponRow(coupon, orderCount, discount, revenue);
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", row.getId());
        map.put("code", row.getCode());
        map.put("name", row.getName());
        map.put("description", row.getDescription());
        map.put("status", row.getStatus().name());
        map.put("computedStatus", row.getComputedStatus().name());
        map.put("computedStatusText", row.getComputedStatusText());
        map.put("statusBadgeClass", row.getStatusBadgeClass());
        map.put("discountType", row.getDiscountType().name());
        map.put("discountTypeText", row.getDiscountTypeText());
        map.put("discountValue", row.getDiscountValue());
        map.put("discountText", row.getDiscountText());
        map.put("maxDiscount", row.getMaxDiscount());
        map.put("maxDiscountText", row.getMaxDiscountText());
        map.put("minOrderValue", row.getMinOrderValue());
        map.put("minOrderText", row.getMinOrderText());
        map.put("quantity", row.getQuantity());
        map.put("usedCount", row.getUsedCount());
        map.put("usagePercent", row.getUsagePercent());
        map.put("perUserLimit", row.getPerUserLimit());
        map.put("targetCustomerType", row.getTargetCustomerType().name());
        map.put("targetCustomerText", row.getTargetCustomerText());
        map.put("applicableCategoryId", row.getApplicableCategoryId());
        map.put("categoryText", row.getCategoryText());
        map.put("startDateIso", row.getStartDateIso());
        map.put("endDateIso", row.getEndDateIso());
        map.put("startDateText", row.getStartDateText());
        map.put("endDateText", row.getEndDateText());
        map.put("orderCount", row.getOrderCount());
        map.put("totalDiscount", row.getTotalDiscount());
        map.put("totalDiscountFormatted", row.getTotalDiscountFormatted());
        map.put("totalRevenue", row.getTotalRevenue());
        map.put("totalRevenueFormatted", row.getTotalRevenueFormatted());
        return map;
    }

    private String formatMoney(BigDecimal amount) {
        if (amount == null) return "0 ₫";
        return NumberFormat.getNumberInstance(Locale.forLanguageTag("vi-VN")).format(amount) + " ₫";
    }

    public static class CouponRow {
        private final Coupon coupon;
        private final long orderCount;
        private final BigDecimal totalDiscount;
        private final BigDecimal totalRevenue;

        public CouponRow(Coupon coupon, long orderCount, BigDecimal totalDiscount, BigDecimal totalRevenue) {
            this.coupon = coupon;
            this.orderCount = orderCount;
            this.totalDiscount = totalDiscount != null ? totalDiscount : BigDecimal.ZERO;
            this.totalRevenue = totalRevenue != null ? totalRevenue : BigDecimal.ZERO;
        }

        public Long getId() { return coupon.getId(); }
        public String getCode() { return coupon.getCode(); }
        public String getName() { return coupon.getName(); }
        public String getDescription() { return coupon.getDescription() != null ? coupon.getDescription() : ""; }
        public CouponStatus getStatus() { return coupon.getStatus(); }
        public CouponStatus getComputedStatus() { return coupon.getComputedStatus(); }

        public String getComputedStatusText() {
            return switch (coupon.getComputedStatus()) {
                case ACTIVE -> "Đang hoạt động";
                case UPCOMING -> "Sắp diễn ra";
                case EXPIRED -> "Hết hạn";
                case PAUSED, DISABLED, INACTIVE -> "Tạm dừng";
            };
        }

        public String getStatusBadgeClass() {
            return switch (coupon.getComputedStatus()) {
                case ACTIVE -> "status-active";
                case UPCOMING -> "status-upcoming";
                case EXPIRED -> "status-expired";
                case PAUSED, DISABLED, INACTIVE -> "status-paused";
            };
        }

        public DiscountType getDiscountType() { return coupon.getDiscountType(); }

        public String getDiscountTypeText() {
            if (coupon.getDiscountType() == null) return "Theo phần trăm";
            return switch (coupon.getDiscountType()) {
                case PERCENT -> "Theo phần trăm (%)";
                case FIXED_AMOUNT -> "Số tiền cố định";
                case FREESHIP -> "Miễn phí ship";
            };
        }

        public String getDiscountText() {
            if (coupon.getDiscountType() == DiscountType.PERCENT) {
                return "Giảm " + format(coupon.getDiscountValue()) + "%";
            } else if (coupon.getDiscountType() == DiscountType.FREESHIP) {
                if (coupon.getDiscountValue() == null || coupon.getDiscountValue().compareTo(BigDecimal.ZERO) <= 0) {
                    return "Freeship 100%";
                } else {
                    return "Freeship tối đa " + format(coupon.getDiscountValue()) + " đ";
                }
            } else {
                return "Giảm " + format(coupon.getDiscountValue()) + " đ";
            }
        }

        public String getMaxDiscountText() {
            if (coupon.getDiscountType() != DiscountType.PERCENT) {
                return "–";
            }
            return coupon.getMaxDiscount() == null ? "Không giới hạn"
                    : "Tối đa " + format(coupon.getMaxDiscount()) + " đ";
        }

        public String getMinOrderText() {
            return coupon.getMinOrderValue() == null ? "Không yêu cầu"
                    : format(coupon.getMinOrderValue()) + " đ";
        }

        public int getPerUserLimit() {
            return coupon.getPerUserLimit() > 0 ? coupon.getPerUserLimit() : 1;
        }

        public CustomerTargetType getTargetCustomerType() {
            return coupon.getTargetCustomerType() != null ? coupon.getTargetCustomerType() : CustomerTargetType.ALL;
        }

        public String getTargetCustomerText() {
            CustomerTargetType t = getTargetCustomerType();
            return switch (t) {
                case ALL -> "Tất cả khách hàng";
                case NEW_CUSTOMER -> "Khách hàng mới (Đơn đầu)";
                case VIP -> "Khách hàng V.I.P";
            };
        }

        public String getCategoryText() {
            return coupon.getApplicableCategory() != null
                    ? coupon.getApplicableCategory().getName()
                    : "Toàn bộ cửa hàng";
        }

        public Long getApplicableCategoryId() {
            return coupon.getApplicableCategory() != null ? coupon.getApplicableCategory().getId() : null;
        }

        public String getStartDateIso() {
            return coupon.getStartDate() != null ? coupon.getStartDate().toString() : "";
        }

        public String getEndDateIso() {
            return coupon.getEndDate() != null ? coupon.getEndDate().toString() : "";
        }

        public String getStartDateText() {
            return coupon.getStartDate() != null ? coupon.getStartDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")) : "";
        }

        public String getEndDateText() {
            return coupon.getEndDate() != null ? coupon.getEndDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")) : "";
        }

        public int getUsedCount() { return coupon.getUsedCount(); }
        public int getQuantity() { return coupon.getQuantity(); }

        public int getUsagePercent() {
            return coupon.getQuantity() <= 0 ? 0 : Math.min(100, coupon.getUsedCount() * 100 / coupon.getQuantity());
        }

        public long getOrderCount() { return orderCount; }
        public BigDecimal getTotalDiscount() { return totalDiscount; }
        public String getTotalDiscountFormatted() { return format(totalDiscount) + " đ"; }
        public BigDecimal getTotalRevenue() { return totalRevenue; }
        public String getTotalRevenueFormatted() { return format(totalRevenue) + " đ"; }
        public BigDecimal getDiscountValue() { return coupon.getDiscountValue(); }
        public BigDecimal getMaxDiscount() { return coupon.getMaxDiscount(); }
        public BigDecimal getMinOrderValue() { return coupon.getMinOrderValue(); }

        private static String format(BigDecimal value) {
            if (value == null) return "0";
            return NumberFormat.getNumberInstance(Locale.forLanguageTag("vi-VN")).format(value);
        }
    }
}
