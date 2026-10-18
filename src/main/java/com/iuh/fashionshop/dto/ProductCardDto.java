package com.iuh.fashionshop.dto;

import com.iuh.fashionshop.model.enums.Gender;

import java.math.BigDecimal;
import java.util.List;

/** Dữ liệu gọn để hiển thị 1 thẻ sản phẩm (tránh lỗi lazy-loading ở view). */
public record ProductCardDto(
        Long id,
        String name,
        String categoryName,
        String imageUrl,
        BigDecimal price,
        BigDecimal salePrice,   // null nếu không giảm giá
        boolean onSale,
        int discountPercent,
        Gender gender,
        List<ColorOption> colors,
        boolean soldOut
) {
    /** Một chấm màu: tên màu + mã hex để tô. */
    public record ColorOption(String name, String hex) {
    }
}