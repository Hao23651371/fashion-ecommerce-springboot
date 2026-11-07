package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.service.ProductService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

/** Trang chủ khách hàng: hỗ trợ hiển thị và phân trang sản phẩm mới nhất. */
@Controller
public class UserController {

    /** Số sản phẩm hiển thị trên 1 trang ở trang chủ (10 sản phẩm = 2 hàng x 5 cột). */
    private static final int DEFAULT_HOME_PAGE_SIZE = 10;

    private final ProductService productService;

    public UserController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping("/")
    public String home(@RequestParam(defaultValue = "1") int page,
                       @RequestParam(defaultValue = "" + DEFAULT_HOME_PAGE_SIZE) int size,
                       Model model) {
        // Lấy danh sách sản phẩm mới nhất đang active và visible
        List<ProductCardDto> all = productService.getLatestProducts(500);

        int totalItems = all.size();
        int pageSize = Math.max(1, size);
        int totalPages = Math.max(1, (int) Math.ceil((double) totalItems / pageSize));
        int currentPage = Math.max(1, Math.min(page, totalPages));
        int fromIndex = (currentPage - 1) * pageSize;
        int toIndex = Math.min(fromIndex + pageSize, totalItems);

        List<ProductCardDto> pagedProducts = totalItems > 0 && fromIndex < totalItems
                ? all.subList(fromIndex, toIndex)
                : (totalItems == 0 ? List.of() : all);

        model.addAttribute("latestProducts", pagedProducts);
        model.addAttribute("currentPage", currentPage);
        model.addAttribute("totalPages", totalPages);
        model.addAttribute("totalCount", totalItems);
        return "user/home";
    }
}
