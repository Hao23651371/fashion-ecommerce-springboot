package com.iuh.fashionshop.dto;

import com.iuh.fashionshop.model.enums.Gender;
import com.iuh.fashionshop.model.enums.ProductStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Dữ liệu chi tiết sản phẩm phục vụ cho trang user/detail.html.
 * Chỉ chứa các trường và thông tin có thực từ CSDL (bảng product, category, product_variant).
 */
public record ProductDetailDto(
        Long id,
        String name,
        Long categoryId,
        String categoryName,
        String description,
        String imageUrl,
        BigDecimal price,
        BigDecimal salePrice,
        boolean onSale,
        int discountPercent,
        BigDecimal currentPrice,
        Gender gender,
        String genderLabel,
        ProductStatus status,
        LocalDateTime createdAt,
        int totalStock,
        boolean soldOut,
        List<VariantDto> variants,
        List<ColorDto> colors,
        List<String> sizes,
        List<String> imageUrls
) {
    /** Constructor tương thích ngược khi không truyền danh sách imageUrls */
    public ProductDetailDto(
            Long id,
            String name,
            Long categoryId,
            String categoryName,
            String description,
            String imageUrl,
            BigDecimal price,
            BigDecimal salePrice,
            boolean onSale,
            int discountPercent,
            BigDecimal currentPrice,
            Gender gender,
            String genderLabel,
            ProductStatus status,
            LocalDateTime createdAt,
            int totalStock,
            boolean soldOut,
            List<VariantDto> variants,
            List<ColorDto> colors,
            List<String> sizes
    ) {
        this(id, name, categoryId, categoryName, description, imageUrl, price, salePrice,
                onSale, discountPercent, currentPrice, gender, genderLabel, status, createdAt,
                totalStock, soldOut, variants, colors, sizes,
                imageUrl != null && !imageUrl.isBlank() ? List.of(imageUrl) : List.of());
    }
    /**
     * Dữ liệu một biến thể sản phẩm (Variant) từ bảng product_variant.
     */
    public record VariantDto(
            Long id,
            String size,
            String color,
            String sku,
            int stockQuantity,
            boolean inStock
    ) {
    }

    /**
     * Dữ liệu tùy chọn màu sắc với tên màu và mã hex tương ứng.
     */
    public record ColorDto(
            String name,
            String hex
    ) {
    }
}
