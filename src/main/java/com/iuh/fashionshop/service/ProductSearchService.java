package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.repository.iml.ProductEmbeddingRepository;
import com.iuh.fashionshop.repository.iml.ProductEmbeddingRepository.Hit;
import com.iuh.fashionshop.repository.iml.ProductEmbeddingRepository.ProductSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Tìm kiếm sản phẩm theo ý nghĩa (vector search) bằng MariaDB VECTOR + Ollama (bge-m3) embedding. */
@Service
public class ProductSearchService {

    private static final Logger log = LoggerFactory.getLogger(ProductSearchService.class);

    /** Một kết quả tìm kiếm: thẻ sản phẩm + khoảng cách (càng nhỏ càng giống). */
    public record SearchResult(ProductCardDto product, double distance) {
    }

    private final ProductEmbeddingRepository embeddingRepository;
    private final OllamaEmbeddingClient embeddingClient;
    private final ProductService productService;
    private final double maxDistance;

    public ProductSearchService(ProductEmbeddingRepository embeddingRepository,
                                OllamaEmbeddingClient embeddingClient,
                                ProductService productService,
                                @Value("${vector.search.max-distance:0.6}") double maxDistance) {
        this.embeddingRepository = embeddingRepository;
        this.embeddingClient = embeddingClient;
        this.productService = productService;
        this.maxDistance = maxDistance;
    }

    /** true khi đã cấu hình và Ollama đang chạy. */
    public boolean isAvailable() {
        return embeddingClient.isConfigured() && embeddingClient.isReachable();
    }

    /**
     * Tạo vector cho sản phẩm.
     * @param force true = tạo lại cho TẤT CẢ sản phẩm; false = chỉ sản phẩm chưa có vector
     * @return số sản phẩm đã được tạo vector
     */
    public int reindex(boolean force) {
        List<ProductSource> sources = embeddingRepository.findSources(!force);
        int done = 0;
        for (ProductSource s : sources) {
            try {
                List<Double> vector = embeddingClient.embed(buildText(s), OllamaEmbeddingClient.TASK_DOCUMENT);
                embeddingRepository.save(s.id(), toVectorText(vector));
                done++;
            } catch (Exception e) {
                log.error("Không tạo được vector cho sản phẩm id={} ({}): {}", s.id(), s.name(), e.getMessage());
            }
        }
        log.info("Đã tạo vector cho {}/{} sản phẩm", done, sources.size());
        return done;
    }

    /** Tìm tối đa `limit` sản phẩm gần nghĩa nhất với câu khách nhập, đã sắp xếp theo độ giống. */
    public List<SearchResult> search(String query, int limit) {
        if (query == null || query.isBlank()) {
            return List.of();
        }

        List<Double> queryVector;
        try {
            queryVector = embeddingClient.embed(query.trim(), OllamaEmbeddingClient.TASK_QUERY);
        } catch (Exception e) {
            log.warn("Vector search lỗi, bỏ qua: {}", e.getMessage());
            return List.of();
        }

        List<Hit> hits = embeddingRepository.searchNearest(toVectorText(queryVector), limit).stream()
                .filter(h -> h.distance() <= maxDistance)
                .toList();
        if (hits.isEmpty()) {
            return List.of();
        }

        List<Long> ids = hits.stream().map(Hit::productId).toList();
        Map<Long, ProductCardDto> cards = productService.getCardsByIds(ids).stream()
                .collect(Collectors.toMap(ProductCardDto::id, Function.identity()));

        List<SearchResult> results = new ArrayList<>();
        for (Hit h : hits) {
            ProductCardDto card = cards.get(h.productId());
            if (card != null) {
                results.add(new SearchResult(card, h.distance()));
            }
        }
        return results;
    }

    /** Ghép thông tin sản phẩm thành 1 đoạn văn để mô hình hiểu ý nghĩa. */
    private String buildText(ProductSource s) {
        StringBuilder sb = new StringBuilder();
        sb.append("Sản phẩm: ").append(s.name()).append(". ");
        sb.append("Danh mục: ").append(s.category()).append(". ");
        sb.append("Dành cho: ").append(genderLabel(s.gender())).append(". ");
        if (s.colors() != null && !s.colors().isBlank()) {
            sb.append("Màu sắc: ").append(s.colors()).append(". ");
        }
        if (s.sizes() != null && !s.sizes().isBlank()) {
            sb.append("Kích cỡ: ").append(s.sizes()).append(". ");
        }
        if (s.salePrice() != null && s.salePrice().signum() > 0 && s.salePrice().compareTo(s.price()) < 0) {
            sb.append("Đang giảm giá. ");
        }
        if (s.description() != null && !s.description().isBlank()) {
            sb.append("Mô tả: ").append(s.description());
        }
        return sb.toString();
    }

    private String genderLabel(String gender) {
        if (gender == null) {
            return "mọi người";
        }
        return switch (gender) {
            case "MALE" -> "nam";
            case "FEMALE" -> "nữ";
            default -> "cả nam và nữ (unisex)";
        };
    }

    private String toVectorText(List<Double> vector) {
        return vector.stream().map(String::valueOf).collect(Collectors.joining(",", "[", "]"));
    }
}