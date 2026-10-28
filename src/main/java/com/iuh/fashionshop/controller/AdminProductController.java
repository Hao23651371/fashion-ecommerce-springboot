package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.enums.ProductStatus;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.repository.ProductRepository;
import java.text.NumberFormat;
import java.util.Locale;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/admin/products")
public class AdminProductController {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;

    public AdminProductController(ProductRepository productRepository, CategoryRepository categoryRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
    }

    @GetMapping
    public String list(@org.springframework.web.bind.annotation.RequestParam(defaultValue = "0") int page,
                       @org.springframework.web.bind.annotation.RequestParam(defaultValue = "10") int size,
                       Model model) {
        Page<Product> productPage = productRepository.findAll(PageRequest.of(Math.max(0, page), Math.min(size, 50)));
        model.addAttribute("pageTitle", "Sản phẩm");
        model.addAttribute("products", productPage.map(ProductRow::new));
        model.addAttribute("categoryCount", categoryRepository.count());
        model.addAttribute("productCount", productRepository.count());
        model.addAttribute("lowStockCount", productRepository.findAll().stream()
                .filter(p -> new ProductRow(p).getStock() < 5).count());
        return "admin/products";
    }

    public static class ProductRow {
        private final Product product;
        public ProductRow(Product product) { this.product = product; }
        public Long getId() { return product.getId(); }
        public String getCode() { return String.format("#PRD-%03d", product.getId()); }
        public String getName() { return product.getName(); }
        public String getCategoryName() { return product.getCategory().getName(); }
        public String getImageUrl() {
            if (product.getImageUrl() != null && !product.getImageUrl().isBlank()) return product.getImageUrl();
            return product.getImages().stream().findFirst().map(i -> i.getImageUrl()).orElse("");
        }
        public String getPrice() { return format(product.getCurrentPrice()) + " đ"; }
        public String getOriginalPrice() { return product.isOnSale() ? format(product.getPrice()) + " đ" : ""; }
        public int getStock() { return product.getVariants().stream().mapToInt(ProductVariant::getStockQuantity).sum(); }
        public String getStatus() { return product.getStatus() == ProductStatus.ACTIVE ? "Hoạt động" : "Tạm dừng"; }
        public String getStatusClass() { return product.getStatus() == ProductStatus.ACTIVE ? "status-active" : "status-inactive"; }
        public String getStockClass() { return getStock() < 5 ? "stock-low" : "stock-ok"; }
        private static String format(java.math.BigDecimal value) {
            return NumberFormat.getNumberInstance(new Locale("vi", "VN")).format(value);
        }
    }
}
