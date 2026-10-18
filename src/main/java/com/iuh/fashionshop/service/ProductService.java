package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.dto.ProductCardDto.ColorOption;
import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.model.enums.ProductStatus;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.ProductRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class ProductService {

    /** Mã màu để tô chấm màu trên thẻ sản phẩm. Màu lạ sẽ dùng màu xám mặc định. */
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
            Map.entry("xanh navy", "#1f2a44")
    );
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
                .searchByName(keyword, ProductStatus.ACTIVE, CategoryStatus.VISIBLE, PageRequest.of(0, limit))
                .stream().map(this::toCard).toList();
    }

    /** Lấy thẻ sản phẩm theo danh sách id, GIỮ NGUYÊN thứ tự id truyền vào (dùng cho kết quả tìm kiếm). */
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
                soldOut
        );
    }

    private String hexOf(String colorName) {
        if (colorName == null) {
            return DEFAULT_HEX;
        }
        return COLOR_HEX.getOrDefault(colorName.trim().toLowerCase(), DEFAULT_HEX);
    }
}