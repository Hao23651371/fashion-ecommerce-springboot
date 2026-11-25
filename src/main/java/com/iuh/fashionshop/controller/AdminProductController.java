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
import com.iuh.fashionshop.service.CloudinaryService;
import com.iuh.fashionshop.service.ProductSearchService;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/admin/products")
public class AdminProductController {

    private static final List<String> STANDARD_SIZES = List.of("XS", "S", "M", "L", "XL", "2XL", "3XL", "FREESIZE");
    private static final List<String> STANDARD_COLORS = List.of("Đen", "Trắng", "Be", "Xám", "Xanh navy", "Xanh nhạt", "Kem", "Camel", "Xanh denim", "Nâu");

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductSearchService searchService;
    private final CloudinaryService cloudinaryService;

    public AdminProductController(ProductRepository productRepository,
                                  CategoryRepository categoryRepository,
                                  ProductSearchService searchService,
                                  CloudinaryService cloudinaryService) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
        this.searchService = searchService;
        this.cloudinaryService = cloudinaryService;
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
                         @RequestParam(value = "image", required = false) MultipartFile image,
                         @RequestParam(name = "sizes") java.util.List<String> sizes,
                         @RequestParam(name = "colors") java.util.List<String> colors,
                         @RequestParam(name = "selectedVariants", required = false) java.util.List<String> selectedVariants,
                         @RequestParam(defaultValue = "0") int stockQuantity,
                         RedirectAttributes redirectAttributes) {
        Product product = createProductInternal(
                name, categoryId, gender, price, salePrice, description,
                imageUrl, image, sizes, colors, selectedVariants, stockQuantity);
        redirectAttributes.addFlashAttribute("savedImageUrl", product.getImageUrl());
        redirectAttributes.addFlashAttribute("successMessage",
                "Đã thêm sản phẩm \"" + product.getName() + "\" với " + product.getVariants().size() + " biến thể thành công.");
        return "redirect:/admin/products";
    }

    @PostMapping(value = "/new", headers = "Accept=application/json")
    @ResponseBody
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<Map<String, Object>> createJson(@RequestParam String name,
                                                          @RequestParam Long categoryId,
                                                          @RequestParam Gender gender,
                                                          @RequestParam java.math.BigDecimal price,
                                                          @RequestParam(required = false) java.math.BigDecimal salePrice,
                                                          @RequestParam(required = false) String description,
                                                          @RequestParam(required = false) String imageUrl,
                                                          @RequestParam(value = "image", required = false) MultipartFile image,
                                                          @RequestParam(name = "sizes") java.util.List<String> sizes,
                                                          @RequestParam(name = "colors") java.util.List<String> colors,
                                                          @RequestParam(name = "selectedVariants", required = false) java.util.List<String> selectedVariants,
                                                          @RequestParam(defaultValue = "0") int stockQuantity) {
        try {
            Product product = createProductInternal(
                    name, categoryId, gender, price, salePrice, description,
                    imageUrl, image, sizes, colors, selectedVariants, stockQuantity);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "id", product.getId(),
                    "name", product.getName(),
                    "imageUrl", product.getImageUrl(),
                    "variantCount", product.getVariants().size(),
                    "message", "Đã thêm sản phẩm \"" + product.getName() + "\" thành công."
            ));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    private Product createProductInternal(String name,
                                          Long categoryId,
                                          Gender gender,
                                          java.math.BigDecimal price,
                                          java.math.BigDecimal salePrice,
                                          String description,
                                          String imageUrl,
                                          MultipartFile image,
                                          java.util.List<String> sizes,
                                          java.util.List<String> colors,
                                          java.util.List<String> selectedVariants,
                                          int stockQuantity) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new IllegalArgumentException("Danh mục không tồn tại"));
        String resolvedImageUrl = resolveProductImageUrl(image, imageUrl, null);
        if (category.getStatus() != CategoryStatus.VISIBLE || sizes.isEmpty() || colors.isEmpty()
                || selectedVariants == null || selectedVariants.isEmpty()
                || name == null || name.isBlank()
                || description == null || description.isBlank()
                || resolvedImageUrl == null || resolvedImageUrl.isBlank()
                || price == null || price.signum() <= 0
                || price.remainder(java.math.BigDecimal.valueOf(1000)).signum() != 0
                || (salePrice != null
                && salePrice.remainder(java.math.BigDecimal.valueOf(1000)).signum() != 0)
                || (salePrice != null
                && (salePrice.signum() < 0 || salePrice.compareTo(price) > 0))) {
            throw new IllegalArgumentException("Thông tin sản phẩm không hợp lệ hoặc chưa chọn biến thể");
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
        product.setImageUrl(resolvedImageUrl);
        product.setStatus(ProductStatus.ACTIVE);
        productRepository.saveAndFlush(product);

        if (!product.getImageUrl().isBlank()) {
            product.getImages().add(new ProductImage(product, product.getImageUrl(), true, 0));
        }

        java.util.Set<String> chosenSet = new java.util.HashSet<>();
        for (String sv : selectedVariants) {
            if (sv != null && !sv.isBlank()) {
                chosenSet.add(sv.trim().toUpperCase());
            }
        }

        int variantIndex = 1;
        for (String size : sizes) {
            for (String color : colors) {
                String pairKey = size.trim().toUpperCase() + "___" + color.trim().toUpperCase();
                if (chosenSet.contains(pairKey)) {
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
        }
        productRepository.save(product);
        searchService.indexProductAsync(product.getId());
        return product;
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
        java.util.List<String> activeVariantKeys = product.getVariants().stream()
                .filter(v -> v.getStatus() == VariantStatus.ACTIVE)
                .map(v -> v.getSize().trim() + "___" + v.getColor().trim())
                .toList();
        model.addAttribute("activeVariantKeys", activeVariantKeys);
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
                         @RequestParam(value = "image", required = false) MultipartFile image,
                         @RequestParam(name = "sizes") java.util.List<String> sizes,
                         @RequestParam(name = "colors") java.util.List<String> colors,
                         @RequestParam(name = "selectedVariants", required = false) java.util.List<String> selectedVariants,
                         RedirectAttributes redirectAttributes) {
        Product product = productRepository.findByIdWithDetails(id).orElse(null);
        if (product == null) {
            redirectAttributes.addFlashAttribute("errorMessage", "Không tìm thấy sản phẩm có mã #" + id);
            return "redirect:/admin/products";
        }

        updateProductInternal(
                product, name, categoryId, gender, price, salePrice,
                description, imageUrl, image, sizes, colors, selectedVariants);

        redirectAttributes.addFlashAttribute("savedImageUrl", product.getImageUrl());
        redirectAttributes.addFlashAttribute("successMessage",
                "Đã cập nhật sản phẩm \"" + product.getName() + "\" thành công.");
        return "redirect:/admin/products";
    }

    @PostMapping(value = "/edit/{id}", headers = "Accept=application/json")
    @ResponseBody
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<Map<String, Object>> updateJson(@PathVariable Long id,
                                                          @RequestParam String name,
                                                          @RequestParam Long categoryId,
                                                          @RequestParam Gender gender,
                                                          @RequestParam java.math.BigDecimal price,
                                                          @RequestParam(required = false) java.math.BigDecimal salePrice,
                                                          @RequestParam(required = false) String description,
                                                          @RequestParam(required = false) String imageUrl,
                                                          @RequestParam(value = "image", required = false) MultipartFile image,
                                                          @RequestParam(name = "sizes") java.util.List<String> sizes,
                                                          @RequestParam(name = "colors") java.util.List<String> colors,
                                                          @RequestParam(name = "selectedVariants", required = false) java.util.List<String> selectedVariants) {
        Product product = productRepository.findByIdWithDetails(id).orElse(null);
        if (product == null) {
            return ResponseEntity.status(404).body(Map.of(
                    "success", false,
                    "message", "Không tìm thấy sản phẩm có mã #" + id
            ));
        }

        try {
            updateProductInternal(
                    product, name, categoryId, gender, price, salePrice,
                    description, imageUrl, image, sizes, colors, selectedVariants);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "id", product.getId(),
                    "name", product.getName(),
                    "imageUrl", product.getImageUrl(),
                    "message", "Đã cập nhật sản phẩm \"" + product.getName() + "\" thành công."
            ));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    private void updateProductInternal(Product product,
                                       String name,
                                       Long categoryId,
                                       Gender gender,
                                       java.math.BigDecimal price,
                                       java.math.BigDecimal salePrice,
                                       String description,
                                       String imageUrl,
                                       MultipartFile image,
                                       java.util.List<String> sizes,
                                       java.util.List<String> colors,
                                       java.util.List<String> selectedVariants) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new IllegalArgumentException("Danh mục không tồn tại"));

        String resolvedImageUrl = resolveProductImageUrl(image, imageUrl, product.getImageUrl());
        if (sizes.isEmpty() || colors.isEmpty()
                || selectedVariants == null || selectedVariants.isEmpty()
                || name == null || name.isBlank()
                || description == null || description.isBlank()
                || resolvedImageUrl == null || resolvedImageUrl.isBlank()
                || price == null || price.signum() <= 0
                || price.remainder(java.math.BigDecimal.valueOf(1000)).signum() != 0
                || (salePrice != null
                && salePrice.remainder(java.math.BigDecimal.valueOf(1000)).signum() != 0)
                || (salePrice != null
                && (salePrice.signum() < 0 || salePrice.compareTo(price) > 0))) {
            throw new IllegalArgumentException("Thông tin sản phẩm không hợp lệ hoặc chưa chọn biến thể");
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
        product.setImageUrl(resolvedImageUrl);

        // Cập nhật ảnh chính
        if (!product.getImages().isEmpty()) {
            ProductImage primary = product.getImages().stream()
                    .filter(ProductImage::isThumbnail)
                    .findFirst()
                    .orElse(product.getImages().get(0));
            primary.setImageUrl(resolvedImageUrl);
        } else {
            product.getImages().add(new ProductImage(product, resolvedImageUrl, true, 0));
        }

        // Cập nhật biến thể
        java.util.Set<String> desiredPairs = new java.util.HashSet<>();
        for (String sv : selectedVariants) {
            if (sv != null && !sv.isBlank()) {
                desiredPairs.add(sv.trim().toUpperCase());
            }
        }

        int maxVariantIndex = 0;
        for (ProductVariant v : product.getVariants()) {
            String pairKey = v.getSize().trim().toUpperCase() + "___" + v.getColor().trim().toUpperCase();
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
                String pairKey = cleanSize.toUpperCase() + "___" + cleanColor.toUpperCase();
                if (desiredPairs.contains(pairKey)) {
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
        }

        productRepository.save(product);
        searchService.indexProductAsync(product.getId());
    }

    /**
     * Ưu tiên upload file ảnh lên Cloudinary nếu có file mới;
     * nếu không có file thì dùng imageUrl nhập tay hoặc giữ nguyên URL cũ khi cập nhật.
     */
    private String resolveProductImageUrl(MultipartFile image, String imageUrl, String existingImageUrl) {
        if (image != null && !image.isEmpty()) {
            return cloudinaryService.uploadImage(image).secureUrl();
        }
        if (imageUrl != null && !imageUrl.isBlank()) {
            return imageUrl.trim();
        }
        if (existingImageUrl != null && !existingImageUrl.isBlank()) {
            return existingImageUrl.trim();
        }
        return null;
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
