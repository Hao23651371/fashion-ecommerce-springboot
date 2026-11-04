package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.model.enums.Gender;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.service.ProductService;
import com.iuh.fashionshop.service.WishlistService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/** Cửa hàng: danh sách, tìm kiếm, lọc, chi tiết sản phẩm. Công khai, không cần đăng nhập. */
@Controller
@RequestMapping("/shop")
public class ShopController {

    private final ProductService productService;
    private final CategoryRepository categoryRepository;
    private final WishlistService wishlistService;

    public ShopController(ProductService productService,
                          CategoryRepository categoryRepository,
                          WishlistService wishlistService) {
        this.productService = productService;
        this.categoryRepository = categoryRepository;
        this.wishlistService = wishlistService;
    }

    @GetMapping
    public String list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false, defaultValue = "ALL") String gender,
            @RequestParam(required = false) String priceRange,
            @RequestParam(required = false, defaultValue = "newest") String sort,
            @RequestParam(required = false, defaultValue = "false") boolean onSaleOnly,
            Model model) {

        // 1. Lấy toàn bộ sản phẩm active
        List<ProductCardDto> all;
        if (keyword != null && !keyword.isBlank()) {
            all = productService.searchByName(keyword.trim(), 500);
        } else {
            all = productService.getLatestProducts(500);
        }

        // 2. Lọc theo danh mục
        if (categoryId != null) {
            String catName = categoryRepository.findById(categoryId)
                    .map(Category::getName).orElse(null);
            if (catName != null) {
                final String cn = catName;
                all = all.stream()
                        .filter(p -> cn.equals(p.categoryName()))
                        .toList();
            }
        }

        // 3. Lọc theo giới tính
        String currentGender = gender != null ? gender.trim().toUpperCase() : "ALL";
        if ("MALE".equals(currentGender)) {
            all = all.stream()
                    .filter(p -> p.gender() == Gender.MALE || p.gender() == Gender.UNISEX)
                    .toList();
        } else if ("FEMALE".equals(currentGender)) {
            all = all.stream()
                    .filter(p -> p.gender() == Gender.FEMALE || p.gender() == Gender.UNISEX)
                    .toList();
        } else {
            currentGender = "ALL";
        }

        // 4. Lọc theo khoảng giá
        String currentPriceRange = priceRange != null ? priceRange : "";
        if (!currentPriceRange.isEmpty()) {
            all = switch (currentPriceRange) {
                case "under500" -> all.stream()
                        .filter(p -> effectivePrice(p).compareTo(new BigDecimal("500000")) < 0)
                        .toList();
                case "500to1m" -> all.stream()
                        .filter(p -> {
                            BigDecimal ep = effectivePrice(p);
                            return ep.compareTo(new BigDecimal("500000")) >= 0
                                    && ep.compareTo(new BigDecimal("1000000")) <= 0;
                        })
                        .toList();
                case "1mto2m" -> all.stream()
                        .filter(p -> {
                            BigDecimal ep = effectivePrice(p);
                            return ep.compareTo(new BigDecimal("1000000")) > 0
                                    && ep.compareTo(new BigDecimal("2000000")) <= 0;
                        })
                        .toList();
                case "above2m" -> all.stream()
                        .filter(p -> effectivePrice(p).compareTo(new BigDecimal("2000000")) > 0)
                        .toList();
                default -> all;
            };
        }

        // 5. Lọc chỉ đang giảm giá
        if (onSaleOnly) {
            all = all.stream().filter(ProductCardDto::onSale).toList();
        }

        // 6. Sắp xếp
        List<ProductCardDto> sorted = new ArrayList<>(all);
        switch (sort) {
            case "price-asc" -> sorted.sort(Comparator.comparing(p -> effectivePrice((ProductCardDto) p)));
            case "price-desc" -> sorted.sort(Comparator.comparing((ProductCardDto p) -> effectivePrice(p)).reversed());
            case "name-asc" -> sorted.sort(Comparator.comparing(ProductCardDto::name));
            case "discount-desc" -> sorted.sort(Comparator.comparingInt(ProductCardDto::discountPercent).reversed());
            default -> { /* newest = thứ tự mặc định từ query */ }
        }

        // 7. Danh mục visible để hiển thị sidebar
        List<Category> categories = categoryRepository.findByStatusOrderByNameAsc(CategoryStatus.VISIBLE);

        model.addAttribute("products", sorted);
        model.addAttribute("totalCount", sorted.size());
        model.addAttribute("categories", categories);
        model.addAttribute("selectedCategoryId", categoryId);
        model.addAttribute("currentGender", currentGender);
        model.addAttribute("currentSort", sort);
        model.addAttribute("currentPriceRange", currentPriceRange);
        model.addAttribute("onSaleOnly", onSaleOnly);
        model.addAttribute("keyword", keyword != null ? keyword : "");

        return "user/shop";
    }

    private static BigDecimal effectivePrice(ProductCardDto p) {
        return p.onSale() && p.salePrice() != null ? p.salePrice() : p.price();
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable Long id, Model model) {
        var product = productService.getProductDetail(id);
        if (product == null) {
            return "error/404";
        }
        model.addAttribute("product", product);
        model.addAttribute("relatedProducts", productService.getRelatedProducts(product.categoryId(), product.id(), 4));

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isWishlisted = wishlistService.isWishlisted(id, auth);
        model.addAttribute("isWishlisted", isWishlisted);

        return "user/detail";
    }
}
