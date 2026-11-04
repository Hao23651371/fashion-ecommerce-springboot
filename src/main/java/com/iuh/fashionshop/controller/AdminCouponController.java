package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.enums.CouponStatus;
import com.iuh.fashionshop.model.enums.DiscountType;
import com.iuh.fashionshop.repository.CouponRepository;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.LocalDateTime;
import java.util.Locale;
import java.util.List;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
@RequestMapping("/admin/coupons")
public class AdminCouponController {

    private final CouponRepository couponRepository;

    public AdminCouponController(CouponRepository couponRepository) {
        this.couponRepository = couponRepository;
    }

    @GetMapping
    public String list(Model model) {
        List<Coupon> coupons = couponRepository.findAll();
        long activeCoupons = coupons.stream()
                .filter(coupon -> coupon.getStatus() == CouponStatus.ACTIVE)
                .count();
        long totalUses = coupons.stream()
                .mapToLong(Coupon::getUsedCount)
                .sum();
        long totalQuota = coupons.stream()
                .mapToLong(Coupon::getQuantity)
                .sum();

        model.addAttribute("pageTitle", "Mã giảm giá");
        model.addAttribute("coupons", coupons.stream().map(CouponRow::new).toList());
        model.addAttribute("totalCoupons", coupons.size());
        model.addAttribute("activeCoupons", activeCoupons);
        model.addAttribute("totalUses", totalUses);
        model.addAttribute("totalQuota", totalQuota);
        return "admin/coupons";
    }

    @PostMapping
    public String create(@RequestParam String code,
                         @RequestParam String name,
                         @RequestParam DiscountType discountType,
                         @RequestParam BigDecimal discountValue,
                         @RequestParam(required = false) BigDecimal maxDiscount,
                         @RequestParam(required = false) BigDecimal minOrderValue,
                         @RequestParam int quantity,
                         @RequestParam String startDate,
                         @RequestParam String endDate) {
        Coupon coupon = new Coupon();
        coupon.setCode(code.trim().toUpperCase(Locale.ROOT));
        coupon.setName(name.trim());
        coupon.setDiscountType(discountType);
        coupon.setDiscountValue(discountValue);
        coupon.setMaxDiscount(maxDiscount);
        coupon.setMinOrderValue(minOrderValue);
        coupon.setQuantity(quantity);
        coupon.setStartDate(LocalDateTime.parse(startDate));
        coupon.setEndDate(LocalDateTime.parse(endDate));
        coupon.setStatus(CouponStatus.ACTIVE);
        couponRepository.save(coupon);
        return "redirect:/admin/coupons";
    }

    public static class CouponRow {
        private final Coupon coupon;
        public CouponRow(Coupon coupon) { this.coupon = coupon; }
        public String getCode() { return coupon.getCode(); }
        public String getName() { return coupon.getName(); }
        public String getStatus() { return coupon.getStatus().name(); }
        public String getDiscountType() { return coupon.getDiscountType().name(); }
        public String getDiscountText() {
            return coupon.getDiscountType() == DiscountType.PERCENT
                    ? "Giảm " + format(coupon.getDiscountValue()) + "%"
                    : "Giảm " + format(coupon.getDiscountValue()) + " đ";
        }
        public String getMaxDiscountText() {
            return coupon.getMaxDiscount() == null ? "Không giới hạn"
                    : "Tối đa " + format(coupon.getMaxDiscount()) + " đ";
        }
        public String getMinOrderText() {
            return coupon.getMinOrderValue() == null ? "Không yêu cầu"
                    : format(coupon.getMinOrderValue()) + " đ";
        }
        public String getStartDateText() { return coupon.getStartDate().toLocalDate().format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy")); }
        public String getEndDateText() { return coupon.getEndDate().toLocalDate().format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy")); }
        public int getUsedCount() { return coupon.getUsedCount(); }
        public int getQuantity() { return coupon.getQuantity(); }
        public int getUsagePercent() { return coupon.getQuantity() <= 0 ? 0 : Math.min(100, coupon.getUsedCount() * 100 / coupon.getQuantity()); }
        private static String format(BigDecimal value) {
            return NumberFormat.getNumberInstance(new Locale("vi", "VN")).format(value);
        }
    }
}
