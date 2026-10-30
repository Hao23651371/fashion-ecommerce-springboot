package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.ProductImage;
import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.model.enums.Gender;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.model.enums.ProductStatus;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.repository.ProductRepository;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

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
                       @RequestParam(required = false) String keyword,
                       @RequestParam(required = false) Long categoryId,
                       @RequestParam(required = false) ProductStatus status,
                       @RequestParam(required = false) String stock,
                       Model model) {
        int safeSize = Math.min(Math.max(size, 1), 50);
        List<Product> filtered = productRepository.findAll().stream()
                .filter(product -> keyword == null || keyword.isBlank()
                        || product.getName().toLowerCase(Locale.ROOT).contains(keyword.trim().toLowerCase(Locale.ROOT))
                        || product.getId().toString().equals(keyword.trim())
                        || product.getCategory().getName().toLowerCase(Locale.ROOT)
                                .contains(keyword.trim().toLowerCase(Locale.ROOT)))
                .filter(product -> categoryId == null || product.getCategory().getId().equals(categoryId))
                .filter(product -> status == null || product.getStatus() == status)
                .filter(product -> matchesStock(product, stock))
                .toList();
        int safePage = Math.max(0, page);
        int from = Math.min(safePage * safeSize, filtered.size());
        int to = Math.min(from + safeSize, filtered.size());
        Page<Product> productPage = new PageImpl<>(filtered.subList(from, to),
                PageRequest.of(safePage, safeSize), filtered.size());
        long inventoryValue = productRepository.findAll().stream()
                .mapToLong(product -> new ProductRow(product).getInventoryValue())
                .sum();
        model.addAttribute("pageTitle", "Sản phẩm");
        model.addAttribute("products", productPage.map(ProductRow::new));
        model.addAttribute("categories", categoryRepository.findAll());
        model.addAttribute("categoryCount", categoryRepository.count());
        model.addAttribute("productCount", productRepository.count());
        model.addAttribute("inventoryValue", format(new java.math.BigDecimal(inventoryValue)) + " đ");
        model.addAttribute("keyword", keyword);
        model.addAttribute("selectedCategory", categoryId);
        model.addAttribute("selectedStatus", status);
        model.addAttribute("selectedStock", stock);
        model.addAttribute("lowStockCount", productRepository.findAll().stream()
                .filter(p -> new ProductRow(p).getStock() < 5).count());
        return "admin/products";
    }

    private static boolean matchesStock(Product product, String stock) {
        if (stock == null || stock.isBlank()) return true;
        int quantity = new ProductRow(product).getStock();
        return "LOW".equals(stock) ? quantity > 0 && quantity < 5
                : "OUT".equals(stock) ? quantity == 0 : "AVAILABLE".equals(stock) && quantity >= 5;
    }

    private static String format(java.math.BigDecimal value) {
        return NumberFormat.getNumberInstance(new Locale("vi", "VN")).format(value);
    }

    @GetMapping("/new")
    public String createForm(Model model) {
        model.addAttribute("pageTitle", "Thêm sản phẩm mới");
        model.addAttribute("categories", categoryRepository.findAll().stream()
                .filter(category -> category.getStatus() == CategoryStatus.VISIBLE).toList());
        model.addAttribute("sizes", java.util.List.of("XS", "S", "M", "L", "XL", "2XL", "FREESIZE"));
        model.addAttribute("colors", java.util.List.of("Đen", "Trắng", "Be", "Xám", "Xanh navy"));
        return "admin/product-form";
    }

    @PostMapping("/new")
    @org.springframework.transaction.annotation.Transactional
    public String create(@RequestParam String name,
                         @RequestParam Long categoryId,
                         @RequestParam Gender gender,
                         @RequestParam java.math.BigDecimal price,
                         @RequestParam(required = false) java.math.BigDecimal salePrice,
                         @RequestParam(required = false) String description,
                         @RequestParam(required = false) String imageUrl,
                         @RequestParam(name = "sizes") java.util.List<String> sizes,
                         @RequestParam(name = "colors") java.util.List<String> colors,
                         @RequestParam(defaultValue = "0") int stockQuantity,
                         RedirectAttributes redirectAttributes) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new IllegalArgumentException("Danh mục không tồn tại"));
        if (category.getStatus() != CategoryStatus.VISIBLE || sizes.isEmpty() || colors.isEmpty()
                || price.signum() < 0 || (salePrice != null
                && (salePrice.signum() < 0 || salePrice.compareTo(price) >= 0))) {
            throw new IllegalArgumentException("Thông tin sản phẩm không hợp lệ");
        }

        Product product = new Product();
        product.setName(name.trim());
        product.setCategory(category);
        product.setGender(gender);
        product.setPrice(price);
        product.setSalePrice(salePrice);
        product.setDescription(description == null ? "" : description.trim());
        product.setImageUrl(imageUrl == null ? "" : imageUrl.trim());
        product.setStatus(ProductStatus.ACTIVE);
        productRepository.saveAndFlush(product);

        if (!product.getImageUrl().isBlank()) {
            product.getImages().add(new ProductImage(product, product.getImageUrl(), true, 0));
        }
        int variantIndex = 1;
        for (String size : sizes) {
            for (String color : colors) {
                ProductVariant variant = new ProductVariant();
                variant.setProduct(product);
                variant.setSize(size.trim());
                variant.setColor(color.trim());
                variant.setSku(String.format("PRD-%05d-%03d", product.getId(), variantIndex++));
                variant.setStockQuantity(Math.max(0, stockQuantity));
                variant.setStatus(VariantStatus.ACTIVE);
                product.getVariants().add(variant);
            }
        }
        productRepository.save(product);
        redirectAttributes.addFlashAttribute("successMessage",
                "Đã thêm sản phẩm \"" + product.getName() + "\" thành công.");
        return "redirect:/admin/products";
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
        public long getInventoryValue() {
            return product.getCurrentPrice().multiply(java.math.BigDecimal.valueOf(getStock())).longValue();
        }
        public String getStatus() { return product.getStatus() == ProductStatus.ACTIVE ? "Hoạt động" : "Tạm dừng"; }
        public String getStatusClass() { return product.getStatus() == ProductStatus.ACTIVE ? "status-active" : "status-inactive"; }
        public String getStockClass() { return getStock() < 5 ? "stock-low" : "stock-ok"; }
        private static String format(java.math.BigDecimal value) {
            return NumberFormat.getNumberInstance(new Locale("vi", "VN")).format(value);
        }
    }
}
