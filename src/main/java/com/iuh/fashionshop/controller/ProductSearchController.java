package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.service.ProductSearchService;
import com.iuh.fashionshop.service.ProductService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * API gợi ý sản phẩm cho ô tìm kiếm trên header.
 * 3 tầng: (1) khớp tên chính xác, (2) khớp không dấu, (3) khớp theo ý nghĩa bằng vector.
 * Tầng 3 chỉ chạy khi tầng 1 và 2 không ra kết quả nào. Không phân biệt hoa thường.
 */
@RestController
public class ProductSearchController {

    /** Ngưỡng khoảng cách cosine cho tầng vector: càng nhỏ càng khắt khe. Chỉnh sau khi thử. */
    private static final double VECTOR_MAX_DISTANCE = 1.0;

    /** Số món tối đa lấy từ tầng vector (tránh chèn quá nhiều món lạc đề). */
    private static final int VECTOR_MAX_RESULTS = 3;

    public record Suggestion(Long id, String name, String categoryName, String imageUrl,
                             BigDecimal price, BigDecimal salePrice, boolean onSale) {
    }

    private final ProductSearchService searchService;
    private final ProductService productService;

    public ProductSearchController(ProductSearchService searchService, ProductService productService) {
        this.searchService = searchService;
        this.productService = productService;
    }

    /** Thử: http://localhost:8080/api/products/search?q=quần */
    @GetMapping("/api/products/search")
    public List<Suggestion> search(@RequestParam("q") String q,
                                   @RequestParam(value = "limit", defaultValue = "6") int limit) {
        String kw = q == null ? "" : q.trim();
        if (kw.isEmpty()) {
            return List.of();
        }
        int max = Math.min(Math.max(limit, 1), 20);
        Map<Long, ProductCardDto> merged = new LinkedHashMap<>();

        // 1. Khớp tên chính xác (không phân biệt hoa thường, do query dùng lower())
        productService.searchByName(kw, max).forEach(c -> merged.put(c.id(), c));

        // 2. Khớp không dấu: quan -> Quần, dam -> Đầm
        if (merged.size() < max) {
            String plain = stripAccents(kw);
            for (ProductCardDto c : productService.getLatestProducts(500)) {
                if (stripAccents(c.name() + " " + c.categoryName()).contains(plain)) {
                    merged.putIfAbsent(c.id(), c);
                }
            }
        }

        // 3. Khớp theo ý nghĩa (vector): CHỈ khi tầng 1 và 2 không ra gì.
        //    Ollama lỗi thì search() trả rỗng, dropdown không hiện.
        if (merged.isEmpty() && kw.length() >= 2) {
            searchService.search(kw, VECTOR_MAX_RESULTS).stream()
                    .filter(r -> r.distance() <= VECTOR_MAX_DISTANCE)
                    .forEach(r -> merged.putIfAbsent(r.product().id(), r.product()));
        }

        return merged.values().stream().limit(max)
                .map(c -> new Suggestion(c.id(), c.name(), c.categoryName(), c.imageUrl(),
                        c.price(), c.salePrice(), c.onSale()))
                .toList();
    }

    /** Chỉ ADMIN (đã bị chặn bởi /admin/** trong SecurityConfig). Tạo lại vector cho TẤT CẢ sản phẩm. */
    @GetMapping(value = "/admin/embeddings/rebuild", produces = "text/plain;charset=UTF-8")
    public String rebuild() {
        if (!searchService.isAvailable()) {
            return "Ollama chưa chạy hoặc chưa cấu hình ollama.base-url";
        }
        return "Đã tạo lại vector cho " + searchService.reindex(true) + " sản phẩm";
    }

    /** Bỏ dấu tiếng Việt, đổi đ -> d, về chữ thường. */
    private static String stripAccents(String s) {
        return Normalizer.normalize(s, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .replace('đ', 'd').replace('Đ', 'D')
                .toLowerCase(Locale.ROOT);
    }
}