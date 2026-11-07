package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.enums.CouponStatus;
import com.iuh.fashionshop.model.enums.Gender;
import com.iuh.fashionshop.repository.CouponRepository;
import com.iuh.fashionshop.service.ProductService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/** Trang Sale: sản phẩm đang giảm giá. Công khai, không cần đăng nhập. */
@Controller
@RequestMapping("/sale")
public class SaleController {

    private final ProductService productService;
    private final CouponRepository couponRepository;

    public SaleController(ProductService productService, CouponRepository couponRepository) {
        this.productService = productService;
        this.couponRepository = couponRepository;
    }

    @GetMapping
    public String sale(@RequestParam(required = false, defaultValue = "ALL") String gender,
                       @RequestParam(required = false, defaultValue = "discount-desc") String sort,
                       Model model) {
        // 1. Lấy tất cả sản phẩm đang giảm giá
        List<ProductCardDto> allSaleProducts = productService.getSaleProducts(100);

        // 2. Lọc theo giới tính
        List<ProductCardDto> filtered = new ArrayList<>(allSaleProducts);
        String currentGender = gender != null ? gender.trim().toUpperCase() : "ALL";
        if ("MALE".equals(currentGender)) {
            filtered = filtered.stream()
                    .filter(p -> p.gender() == Gender.MALE || p.gender() == Gender.UNISEX)
                    .toList();
        } else if ("FEMALE".equals(currentGender)) {
            filtered = filtered.stream()
                    .filter(p -> p.gender() == Gender.FEMALE || p.gender() == Gender.UNISEX)
                    .toList();
        } else if ("UNISEX".equals(currentGender)) {
            filtered = filtered.stream()
                    .filter(p -> p.gender() == Gender.UNISEX)
                    .toList();
        } else {
            currentGender = "ALL";
        }

        // 3. Sắp xếp
        List<ProductCardDto> sorted = new ArrayList<>(filtered);
        switch (sort) {
            case "discount-desc" -> sorted.sort(Comparator.comparingInt(ProductCardDto::discountPercent).reversed());
            case "price-asc" -> sorted.sort(Comparator.comparing(p -> p.salePrice() != null ? p.salePrice() : p.price()));
            case "price-desc" -> sorted.sort(Comparator.comparing((ProductCardDto p) -> p.salePrice() != null ? p.salePrice() : p.price()).reversed());
            default -> { /* Thứ tự mặc định: sản phẩm sale mới nhất */ }
        }

        // 4. Mức giảm giá cao nhất (hiển thị banner)
        int maxDiscount = allSaleProducts.stream()
                .mapToInt(ProductCardDto::discountPercent)
                .max()
                .orElse(0);

        // 5. Danh sách mã giảm giá đang kích hoạt
        List<Coupon> activeCoupons = List.of();
        try {
            activeCoupons = couponRepository.findActiveCoupons(CouponStatus.ACTIVE, LocalDateTime.now());
        } catch (Exception ignored) {
        }

        model.addAttribute("products", sorted);
        model.addAttribute("totalCount", sorted.size());
        model.addAttribute("currentGender", currentGender);
        model.addAttribute("currentSort", sort);
        model.addAttribute("maxDiscount", maxDiscount);
        model.addAttribute("coupons", activeCoupons);

        return "user/sale";
    }
}