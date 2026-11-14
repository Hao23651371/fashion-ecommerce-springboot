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
import com.iuh.fashionshop.service.ProductSearchService;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/admin/products")
public class AdminProductController {

    private static final List<String> STANDARD_SIZES = List.of("XS", "S", "M", "L", "XL", "2XL", "3XL", "FREESIZE");
    private static final List<String> STANDARD_COLORS = List.of("Đen", "Trắng", "Be", "Xám", "Xanh navy", "Xanh nhạt", "Kem", "Camel", "Xanh denim", "Nâu");

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductSearchService searchService;

    public AdminProductController(ProductRepository productRepository,
                                  CategoryRepository categoryRepository,
                                  ProductSearchService searchService) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
        this.searchService = searchService;
    }

    @GetMapping
    public String list(@RequestParam(defaultValue = "0") int page,
                       @RequestParam(defaultValue = "10") int size,
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
        model.addAttribute("isEdit", false);
        model.addAttribute("product", new Product());
        model.addAttribute("categories", categoryRepository.findAll().stream()
                .filter(category -> category.getStatus() == CategoryStatus.VISIBLE).toList());
        model.addAttribute("sizes", STANDARD_SIZES);
        model.addAttribute("colors", STANDARD_COLORS);
        model.addAttribute("selectedSizes", java.util.List.of("M"));
        model.addAttribute("selectedColors", java.util.List.of("Đen"));
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
                || name == null || name.isBlank()
                || description == null || description.isBlank()
                || imageUrl == null || imageUrl.isBlank()
                || price == null || price.signum() <= 0
                || price.remainder(java.math.BigDecimal.valueOf(1000)).signum() != 0
                || (salePrice != null
                && salePrice.remainder(java.math.BigDecimal.valueOf(1000)).signum() != 0)
                || (salePrice != null
                && (salePrice.signum() < 0 || salePrice.compareTo(price) > 0))) {
            throw new IllegalArgumentException("Thông tin sản phẩm không hợp lệ");
        }

        if (salePrice == null) {
            salePrice = price;
        }

        Product product = new Product();
        product.setName(name.trim());
        product.setCategory(category);
        product.setGender(gender);
        product.setPrice(price);
        product.setSalePrice(salePrice);
        product.setDescription(description.trim());
        product.setImageUrl(imageUrl.trim());
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
        searchService.indexProductAsync(product.getId());
        redirectAttributes.addFlashAttribute("successMessage",
                "Đã thêm sản phẩm \"" + product.getName() + "\" thành công.");
        return "redirect:/admin/products";
    }

    @GetMapping("/edit/{id}")
    public String editForm(@PathVariable Long id, Model model, RedirectAttributes redirectAttributes) {
        Product product = productRepository.findByIdWithDetails(id).orElse(null);
        if (product == null) {
            redirectAttributes.addFlashAttribute("errorMessage", "Không tìm thấy sản phẩm có mã #" + id);
            return "redirect:/admin/products";
        }

        java.util.List<String> productSizes = product.getVariants().stream()
                .filter(v -> v.getStatus() == VariantStatus.ACTIVE)
                .map(ProductVariant::getSize)
                .distinct()
                .toList();
        if (productSizes.isEmpty()) {
            productSizes = product.getVariants().stream()
                    .map(ProductVariant::getSize)
                    .distinct()
                    .toList();
        }

        java.util.List<String> productColors = product.getVariants().stream()
                .filter(v -> v.getStatus() == VariantStatus.ACTIVE)
                .map(ProductVariant::getColor)
                .distinct()
                .toList();
        if (productColors.isEmpty()) {
            productColors = product.getVariants().stream()
                    .map(ProductVariant::getColor)
                    .distinct()
                    .toList();
        }

        java.util.List<String> allSizes = new java.util.ArrayList<>(STANDARD_SIZES);
        for (String s : productSizes) {
            if (!allSizes.contains(s)) {
                allSizes.add(s);
            }
        }

        java.util.List<String> allColors = new java.util.ArrayList<>(STANDARD_COLORS);
        for (String c : productColors) {
            if (!allColors.contains(c)) {
                allColors.add(c);
            }
        }

        model.addAttribute("pageTitle", "Chỉnh sửa sản phẩm");
        model.addAttribute("isEdit", true);
        model.addAttribute("product", product);
        model.addAttribute("categories", categoryRepository.findAll());
        model.addAttribute("sizes", allSizes);
        model.addAttribute("colors", allColors);
        model.addAttribute("selectedSizes", productSizes);
        model.addAttribute("selectedColors", productColors);
        return "admin/product-form";
    }

    @PostMapping("/edit/{id}")
    @org.springframework.transaction.annotation.Transactional
    public String update(@PathVariable Long id,
                         @RequestParam String name,
                         @RequestParam Long categoryId,
                         @RequestParam Gender gender,
                         @RequestParam java.math.BigDecimal price,
                         @RequestParam(required = false) java.math.BigDecimal salePrice,
                         @RequestParam(required = false) String description,
                         @RequestParam(required = false) String imageUrl,
                         @RequestParam(name = "sizes") java.util.List<String> sizes,
                         @RequestParam(name = "colors") java.util.List<String> colors,
                         RedirectAttributes redirectAttributes) {
        Product product = productRepository.findByIdWithDetails(id).orElse(null);
        if (product == null) {
            redirectAttributes.addFlashAttribute("errorMessage", "Không tìm thấy sản phẩm có mã #" + id);
            return "redirect:/admin/products";
        }

        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new IllegalArgumentException("Danh mục không tồn tại"));

        if (sizes.isEmpty() || colors.isEmpty()
                || name == null || name.isBlank()
                || description == null || description.isBlank()
                || imageUrl == null || imageUrl.isBlank()
                || price == null || price.signum() <= 0
                || price.remainder(java.math.BigDecimal.valueOf(1000)).signum() != 0
                || (salePrice != null
                && salePrice.remainder(java.math.BigDecimal.valueOf(1000)).signum() != 0)
                || (salePrice != null
                && (salePrice.signum() < 0 || salePrice.compareTo(price) > 0))) {
            throw new IllegalArgumentException("Thông tin sản phẩm không hợp lệ");
        }

        if (salePrice == null) {
            salePrice = price;
        }

        product.setName(name.trim());
        product.setCategory(category);
        product.setGender(gender);
        product.setPrice(price);
        product.setSalePrice(salePrice);
        product.setDescription(description.trim());
        product.setImageUrl(imageUrl.trim());

        // Cập nhật ảnh chính
        if (!product.getImages().isEmpty()) {
            ProductImage primary = product.getImages().stream()
                    .filter(ProductImage::isThumbnail)
                    .findFirst()
                    .orElse(product.getImages().get(0));
            primary.setImageUrl(imageUrl.trim());
        } else {
            product.getImages().add(new ProductImage(product, imageUrl.trim(), true, 0));
        }

        // Cập nhật biến thể
        java.util.Set<String> desiredPairs = new java.util.HashSet<>();
        for (String s : sizes) {
            for (String c : colors) {
                desiredPairs.add(s.trim().toUpperCase() + "___" + c.trim().toLowerCase());
            }
        }

        int maxVariantIndex = 0;
        for (ProductVariant v : product.getVariants()) {
            String pairKey = v.getSize().trim().toUpperCase() + "___" + v.getColor().trim().toLowerCase();
            if (desiredPairs.contains(pairKey)) {
                if (v.getStatus() == VariantStatus.INACTIVE) {
                    v.setStatus(VariantStatus.ACTIVE);
                }
            } else {
                v.setStatus(VariantStatus.INACTIVE);
            }

            try {
                if (v.getSku() != null && v.getSku().contains("-")) {
                    String[] parts = v.getSku().split("-");
                    int idx = Integer.parseInt(parts[parts.length - 1]);
                    if (idx > maxVariantIndex) maxVariantIndex = idx;
                }
            } catch (Exception ignored) {}
        }

        int nextIndex = maxVariantIndex + 1;
        for (String s : sizes) {
            String cleanSize = s.trim();
            for (String c : colors) {
                String cleanColor = c.trim();
                boolean exists = product.getVariants().stream()
                        .anyMatch(v -> v.getSize().equalsIgnoreCase(cleanSize) && v.getColor().equalsIgnoreCase(cleanColor));
                if (!exists) {
                    ProductVariant newVariant = new ProductVariant();
                    newVariant.setProduct(product);
                    newVariant.setSize(cleanSize);
                    newVariant.setColor(cleanColor);
                    newVariant.setSku(String.format("PRD-%05d-%03d", product.getId(), nextIndex++));
                    newVariant.setStockQuantity(0);
                    newVariant.setStatus(VariantStatus.ACTIVE);
                    product.getVariants().add(newVariant);
                }
            }
        }

        productRepository.save(product);
        searchService.indexProductAsync(product.getId());
        redirectAttributes.addFlashAttribute("successMessage",
                "Đã cập nhật sản phẩm \"" + product.getName() + "\" thành công.");
        return "redirect:/admin/products";
    }

    @PostMapping("/{id}/toggle-status")
    @org.springframework.transaction.annotation.Transactional
    public String toggleStatus(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        Product product = productRepository.findById(id).orElse(null);
        if (product == null) {
            redirectAttributes.addFlashAttribute("errorMessage", "Không tìm thấy sản phẩm.");
            return "redirect:/admin/products";
        }

        if (product.getStatus() == ProductStatus.ACTIVE) {
            product.setStatus(ProductStatus.INACTIVE);
            productRepository.save(product);
            searchService.indexProductAsync(product.getId());
            redirectAttributes.addFlashAttribute("successMessage",
                    "Đã ẩn sản phẩm \"" + product.getName() + "\" (Chuyển sang trạng thái Tạm dừng).");
        } else {
            if (product.getCategory().getStatus() == CategoryStatus.HIDDEN) {
                redirectAttributes.addFlashAttribute("errorMessage",
                        "Không thể hiển thị sản phẩm \"" + product.getName() + "\" vì danh mục \""
                                + product.getCategory().getName() + "\" đang bị ẩn. Vui lòng hiện danh mục trước.");
                return "redirect:/admin/products";
            }
            product.setStatus(ProductStatus.ACTIVE);
            productRepository.save(product);
            searchService.indexProductAsync(product.getId());
            redirectAttributes.addFlashAttribute("successMessage",
                    "Đã hiển thị sản phẩm \"" + product.getName() + "\" (Chuyển sang trạng thái Hoạt động).");
        }
        return "redirect:/admin/products";
    }

    @PostMapping("/delete/{id}")
    @org.springframework.transaction.annotation.Transactional
    public String delete(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        Product product = productRepository.findById(id).orElse(null);
        if (product == null) {
            redirectAttributes.addFlashAttribute("errorMessage", "Không tìm thấy sản phẩm cần xóa.");
            return "redirect:/admin/products";
        }

        long orderItemCount = productRepository.countOrderItemsByProductId(id);
        if (orderItemCount > 0) {
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Không thể xóa sản phẩm \"" + product.getName() + "\" vì đã có "
                            + orderItemCount + " đơn hàng liên kết trong hệ thống. Để ngừng kinh doanh sản phẩm này, vui lòng sử dụng chức năng \"Ẩn sản phẩm\".");
            return "redirect:/admin/products";
        }

        String productName = product.getName();
        try {
            productRepository.deleteWishlistItemsByProductId(id);
            productRepository.deleteCartItemsByProductId(id);
            productRepository.deleteStockHistoriesByProductId(id);

            productRepository.delete(product);
            productRepository.flush();
            searchService.removeProductAsync(id);

            redirectAttributes.addFlashAttribute("successMessage",
                    "Đã xóa vĩnh viễn sản phẩm \"" + productName + "\" khỏi cơ sở dữ liệu thành công!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Không thể xóa sản phẩm \"" + productName + "\": " + e.getMessage());
        }

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
        public boolean isActive() { return product.getStatus() == ProductStatus.ACTIVE; }
        public String getStatus() { return product.getStatus() == ProductStatus.ACTIVE ? "Hoạt động" : "Tạm dừng"; }
        public String getStatusClass() { return product.getStatus() == ProductStatus.ACTIVE ? "status-active" : "status-inactive"; }
        public String getStockClass() { return getStock() < 5 ? "stock-low" : "stock-ok"; }
        private static String format(java.math.BigDecimal value) {
            return NumberFormat.getNumberInstance(new Locale("vi", "VN")).format(value);
        }
    }
}
