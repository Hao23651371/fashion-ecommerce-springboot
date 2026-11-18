package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.AdminDashboardDto;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.repository.UserProfileRepository;
import com.iuh.fashionshop.service.AdminDashboardService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;
import java.util.Optional;

/**
 * Trang Bảng điều khiển (Tổng quan kinh doanh) của Admin Fashion Shop.
 * Hỗ trợ hiển thị KPI thời gian thực, tiến độ mục tiêu, pipeline đơn hàng,
 * và các thao tác lưu dữ liệu trực tiếp vào database.
 */
@Controller
@RequestMapping("/admin")
public class AdminController {

    private final AdminDashboardService dashboardService;
    private final UserProfileRepository userProfileRepository;

    public AdminController(AdminDashboardService dashboardService,
                           UserProfileRepository userProfileRepository) {
        this.dashboardService = dashboardService;
        this.userProfileRepository = userProfileRepository;
    }

    @GetMapping({"", "/dashboard"})
    public String dashboard(@RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
                            @RequestParam(required = false) Integer month,
                            @RequestParam(required = false) Integer year,
                            Authentication auth,
                            Model model) {
        String userName = "Nguyễn Bảo Duy";
        String userRole = "Quản trị viên cấp cao";

        if (auth != null && auth.isAuthenticated()) {
            String email = auth.getName().trim().toLowerCase();
            Optional<UserProfile> profileOpt = userProfileRepository.findByAccountEmail(email);
            if (profileOpt.isPresent() && profileOpt.get().getFullName() != null && !profileOpt.get().getFullName().isBlank()) {
                userName = profileOpt.get().getFullName();
            } else {
                userName = email;
            }

            boolean isAdmin = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().contains("ADMIN"));
            userRole = isAdmin ? "Quản trị viên cấp cao" : "Nhân viên quản lý";
        }

        LocalDate targetDate = date;
        if (targetDate == null && month != null && month >= 1 && month <= 12) {
            int y = (year != null && year >= 2020) ? year : LocalDate.now().getYear();
            targetDate = LocalDate.of(y, month, 1);
        }

        AdminDashboardDto dashboardData = dashboardService.loadDashboard(targetDate, year, userName, userRole);

        model.addAttribute("pageTitle", "Tổng quan kinh doanh");
        model.addAttribute("dashboard", dashboardData);
        return "admin/dashboard";
    }

    /**
     * THAO TÁC DATABASE: Lưu mục tiêu doanh thu tháng mới vào database.
     */
    @PostMapping("/dashboard/target")
    public String updateTarget(@RequestParam("monthlyTarget") BigDecimal monthlyTarget,
                               @RequestParam(value = "highlightNote", required = false) String highlightNote,
                               @RequestParam(value = "targetMonth", required = false) Integer targetMonth,
                               @RequestParam(value = "targetYear", required = false) Integer targetYear,
                               RedirectAttributes redirectAttributes) {
        try {
            dashboardService.updateTarget(monthlyTarget, highlightNote, targetMonth, targetYear);
            redirectAttributes.addFlashAttribute("successMessage", "Cập nhật mục tiêu kinh doanh Tháng " + targetMonth + "/" + targetYear + " vào Database thành công!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Không thể lưu mục tiêu: " + e.getMessage());
        }
        return "redirect:/admin/dashboard?month=" + (targetMonth != null ? targetMonth : "") + "&year=" + (targetYear != null ? targetYear : "");
    }

    /**
     * THAO TÁC DATABASE: Duyệt nhanh đơn hàng PENDING sang CONFIRMED.
     */
    @PostMapping("/dashboard/quick-confirm/{id}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> quickConfirmOrder(@PathVariable("id") Long id) {
        boolean ok = dashboardService.quickConfirmOrder(id);
        if (ok) {
            return ResponseEntity.ok(Map.of("success", true, "message", "Đã xác nhận đơn hàng thành công trên hệ thống!"));
        } else {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Không thể xác nhận đơn (đơn không tồn tại hoặc đã xử lý)."));
        }
    }

    /**
     * THAO TÁC DATABASE: Duyệt toàn bộ đơn hàng PENDING thành CONFIRMED.
     */
    @PostMapping("/dashboard/quick-confirm-all")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> quickConfirmAllOrders() {
        int count = dashboardService.quickConfirmAllPendingOrders();
        return ResponseEntity.ok(Map.of(
                "success", true,
                "count", count,
                "message", "Đã duyệt thành công tất cả " + count + " đơn hàng đang chờ duyệt!"
        ));
    }

    /**
     * THAO TÁC DATABASE: Hủy nhanh đơn hàng kèm lý do.
     */
    @PostMapping("/dashboard/quick-cancel/{id}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> quickCancelOrder(@PathVariable("id") Long id,
                                                               @RequestParam(value = "reason", required = false) String reason) {
        boolean ok = dashboardService.quickCancelOrder(id, reason);
        if (ok) {
            return ResponseEntity.ok(Map.of("success", true, "message", "Đã hủy đơn hàng thành công!"));
        } else {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Không thể hủy đơn hàng này."));
        }
    }
}
