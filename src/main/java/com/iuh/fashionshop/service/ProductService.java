package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.dto.ProductCardDto.ColorOption;
import com.iuh.fashionshop.dto.ProductDetailDto;
import com.iuh.fashionshop.dto.ProductDetailDto.ColorDto;
import com.iuh.fashionshop.dto.ProductDetailDto.VariantDto;
import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.ProductImage;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.model.enums.Gender;
import com.iuh.fashionshop.model.enums.ProductStatus;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.ProductRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class ProductService {

        /** Thứ tự chuẩn kích cỡ thời trang để hiển thị nhất quán trên giao diện. */
        private static final List<String> STANDARD_SIZE_ORDER = List.of(
                        "XS", "S", "M", "L", "XL", "2XL", "3XL", "XXL", "FREESIZE");

        /**
         * Mã màu để tô chấm màu trên thẻ sản phẩm và nút chọn màu. Màu lạ sẽ dùng màu
         * xám mặc định.
         */
        private static final Map<String, String> COLOR_HEX = Map.ofEntries(
                        Map.entry("be", "#d8c3a5"),
                        Map.entry("trắng", "#ffffff"),
                        Map.entry("xanh nhạt", "#bcd4e6"),
                        Map.entry("đen", "#111111"),
                        Map.entry("camel", "#c19a6b"),
                        Map.entry("xám tro", "#8d9096"),
                        Map.entry("kem", "#f3ead3"),
                        Map.entry("xanh denim", "#4a6fa5"),
                        Map.entry("nâu", "#6f4e37"),
                        Map.entry("xanh rêu", "#6b7a3d"),
                        Map.entry("hồng phấn", "#f4c2c2"),
                        Map.entry("xanh navy", "#1f2a44"));
        private static final String DEFAULT_HEX = "#cfcfcf";

        private final ProductRepository productRepository;

        public ProductService(ProductRepository productRepository) {
                this.productRepository = productRepository;
        }

        @Transactional(readOnly = true)
        public List<ProductCardDto> getLatestProducts(int limit) {
                return productRepository
                                .findLatest(ProductStatus.ACTIVE, CategoryStatus.VISIBLE, PageRequest.of(0, limit))
                                .stream().map(this::toCard).toList();
        }

        @Transactional(readOnly = true)
        public List<ProductCardDto> getSaleProducts(int limit) {
                return productRepository
                                .findOnSale(ProductStatus.ACTIVE, CategoryStatus.VISIBLE, PageRequest.of(0, limit))
                                .stream().map(this::toCard).toList();
        }

        @Transactional(readOnly = true)
        public List<ProductCardDto> searchByName(String keyword, int limit) {
                return productRepository
                                .searchByName(keyword, ProductStatus.ACTIVE, CategoryStatus.VISIBLE,
                                                PageRequest.of(0, limit))
                                .stream().map(this::toCard).toList();
        }

        /**
         * Lấy thẻ sản phẩm theo danh sách id, GIỮ NGUYÊN thứ tự id truyền vào (dùng cho
         * kết quả tìm kiếm).
         */
        @Transactional(readOnly = true)
        public List<ProductCardDto> getCardsByIds(List<Long> ids) {
                Map<Long, Product> byId = productRepository.findAllById(ids).stream()
                                .collect(Collectors.toMap(Product::getId, Function.identity()));
                return ids.stream()
                                .map(byId::get)
                                .filter(Objects::nonNull)
                                .filter(p -> p.getStatus() == ProductStatus.ACTIVE)
                                .filter(p -> p.getCategory().getStatus() == CategoryStatus.VISIBLE)
                                .map(this::toCard)
                                .toList();
        }

        /** Lấy chi tiết sản phẩm theo ID để hiển thị trang chi tiết. */
        @Transactional(readOnly = true)
        public ProductDetailDto getProductDetail(Long id) {
                return productRepository.findByIdWithDetails(id)
                                .filter(p -> p.getStatus() == ProductStatus.ACTIVE)
                                .filter(p -> p.getCategory().getStatus() == CategoryStatus.VISIBLE)
                                .map(this::toDetailDto)
                                .orElse(null);
        }

        /** Lấy danh sách sản phẩm liên quan cùng danh mục. */
        @Transactional(readOnly = true)
        public List<ProductCardDto> getRelatedProducts(Long categoryId, Long productId, int limit) {
                return productRepository.findRelatedProducts(
                                categoryId,
                                productId,
                                ProductStatus.ACTIVE,
                                CategoryStatus.VISIBLE,
                                PageRequest.of(0, limit)).stream().map(this::toCard).toList();
        }

        /**
         * Lấy toàn bộ sản phẩm đang bán kèm chi tiết biến thể (size, màu, tồn kho) cho
         * Chatbot.
         */
        @Transactional(readOnly = true)
        public List<ProductDetailDto> getAllActiveDetails() {
                return productRepository.findAllActiveWithVariants(ProductStatus.ACTIVE, CategoryStatus.VISIBLE)
                                .stream().map(this::toDetailDto).toList();
        }

        /** Lấy chi tiết nhiều sản phẩm theo danh sách ID (giữ thứ tự). */
        @Transactional(readOnly = true)
        public List<ProductDetailDto> getDetailsByIds(List<Long> ids) {
                if (ids == null || ids.isEmpty())
                        return List.of();
                Map<Long, Product> map = productRepository.findAllById(ids).stream()
                                .filter(p -> p.getStatus() == ProductStatus.ACTIVE
                                                && p.getCategory().getStatus() == CategoryStatus.VISIBLE)
                                .collect(Collectors.toMap(Product::getId, Function.identity()));
                return ids.stream().map(map::get).filter(Objects::nonNull).map(this::toDetailDto).toList();
        }

        private ProductCardDto toCard(Product p) {
                List<ProductVariant> activeVariants = p.getVariants().stream()
                                .filter(v -> v.getStatus() == VariantStatus.ACTIVE)
                                .toList();

                Map<String, ColorOption> colors = new LinkedHashMap<>();
                for (ProductVariant v : activeVariants) {
                        colors.computeIfAbsent(v.getColor(), c -> new ColorOption(c, hexOf(c)));
                }

                boolean soldOut = activeVariants.stream().noneMatch(v -> v.getStockQuantity() > 0);

                boolean onSale = p.isOnSale();
                int percent = 0;
                if (onSale) {
                        percent = p.getPrice().subtract(p.getSalePrice())
                                        .multiply(BigDecimal.valueOf(100))
                                        .divide(p.getPrice(), 0, RoundingMode.HALF_UP)
                                        .intValue();
                }

                return new ProductCardDto(
                                p.getId(),
                                p.getName(),
                                p.getCategory().getName(),
                                p.getImageUrl(),
                                p.getPrice(),
                                onSale ? p.getSalePrice() : null,
                                onSale,
                                percent,
                                p.getGender(),
                                new ArrayList<>(colors.values()),
                                soldOut);
        }

        private ProductDetailDto toDetailDto(Product p) {
                List<ProductVariant> activeVariants = p.getVariants().stream()
                                .filter(v -> v.getStatus() == VariantStatus.ACTIVE)
                                .toList();

                int totalStock = activeVariants.stream()
                                .mapToInt(ProductVariant::getStockQuantity)
                                .sum();

                boolean soldOut = activeVariants.stream().noneMatch(v -> v.getStockQuantity() > 0);

                boolean onSale = p.isOnSale();
                int percent = 0;
                if (onSale) {
                        percent = p.getPrice().subtract(p.getSalePrice())
                                        .multiply(BigDecimal.valueOf(100))
                                        .divide(p.getPrice(), 0, RoundingMode.HALF_UP)
                                        .intValue();
                }

                List<VariantDto> variantDtos = activeVariants.stream()
                                .map(v -> new VariantDto(
                                                v.getId(),
                                                v.getSize(),
                                                v.getColor(),
                                                v.getSku(),
                                                v.getStockQuantity(),
                                                v.getStockQuantity() > 0))
                                .toList();

                Map<String, ColorDto> colorMap = new LinkedHashMap<>();
                for (ProductVariant v : activeVariants) {
                        colorMap.computeIfAbsent(v.getColor(), c -> new ColorDto(c, hexOf(c)));
                }

                // Lấy danh sách size duy nhất và sắp xếp chuẩn thời trang
                List<String> sortedSizes = activeVariants.stream()
                                .map(ProductVariant::getSize)
                                .distinct()
                                .sorted(Comparator.comparingInt(size -> {
                                        int index = STANDARD_SIZE_ORDER.indexOf(size.toUpperCase());
                                        return index >= 0 ? index : 999;
                                }))
                                .toList();

                String genderLabel = switch (p.getGender()) {
                        case MALE -> "Thời trang Nam";
                        case FEMALE -> "Thời trang Nữ";
                        case UNISEX -> "Dành cho Nam & Nữ (Unisex)";
                };

                // Thu thập danh sách ảnh sản phẩm (ảnh đại diện thumbnail trước, tiếp theo theo
                // thứ tự displayOrder)
                List<String> imageUrls = new ArrayList<>();
                if (p.getImages() != null && !p.getImages().isEmpty()) {
                        imageUrls.addAll(p.getImages().stream()
                                        .sorted(Comparator.comparing(ProductImage::isThumbnail).reversed()
                                                        .thenComparingInt(ProductImage::getDisplayOrder)
                                                        .thenComparing(ProductImage::getId))
                                        .map(ProductImage::getImageUrl)
                                        .filter(url -> url != null && !url.isBlank())
                                        .distinct()
                                        .toList());
                }
                if (imageUrls.isEmpty() && p.getImageUrl() != null && !p.getImageUrl().isBlank()) {
                        imageUrls.add(p.getImageUrl());
                }

                String mainImageUrl = imageUrls.isEmpty() ? p.getImageUrl() : imageUrls.get(0);

                return new ProductDetailDto(
                                p.getId(),
                                p.getName(),
                                p.getCategory().getId(),
                                p.getCategory().getName(),
                                p.getDescription(),
                                mainImageUrl,
                                p.getPrice(),
                                onSale ? p.getSalePrice() : null,
                                onSale,
                                percent,
                                p.getCurrentPrice(),
                                p.getGender(),
                                genderLabel,
                                p.getStatus(),
                                p.getCreatedAt(),
                                totalStock,
                                soldOut,
                                variantDtos,
                                new ArrayList<>(colorMap.values()),
                                sortedSizes,
                                imageUrls);
        }

        public String hexOf(String colorName) {
                if (colorName == null) {
                        return DEFAULT_HEX;
                }
                return COLOR_HEX.getOrDefault(colorName.trim().toLowerCase(), DEFAULT_HEX);
        }
}