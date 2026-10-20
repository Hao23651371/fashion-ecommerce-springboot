package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.ProductDetailDto;
import com.iuh.fashionshop.service.ProductService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

/** Cửa hàng: danh sách, tìm kiếm, lọc, chi tiết sản phẩm. Công khai, không cần đăng nhập. */
//trang danh sách sản phẩm
@Controller
@RequestMapping("/shop")
public class ShopController {

    private final ProductService productService;

    public ShopController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public String list(@RequestParam(required = false) String keyword, Model model) {
        model.addAttribute("keyword", keyword);
        return "user/shop";
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable Long id, Model model) {
        ProductDetailDto product = productService.getProductDetail(id);
        if (product == null) {
            return "error/404";
        }
        model.addAttribute("product", product);
        model.addAttribute("relatedProducts", productService.getRelatedProducts(product.categoryId(), product.id(), 4));
        return "user/detail";
    }
}

