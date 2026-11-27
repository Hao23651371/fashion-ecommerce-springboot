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

    //đóng vai trò là lớp giao tiếp trực tiếp với các bảng dưới MariaDB
    // (products, categories, product_variants, product_embedding chớ ko phải tạo vector
    private final ProductEmbeddingRepository embeddingRepository;

    private final OllamaEmbeddingClient embeddingClient;// cái này mới tạo vector
    private final ProductService productService;
    private final double maxDistance;

    public ProductSearchService(ProductEmbeddingRepository embeddingRepository,
                                OllamaEmbeddingClient embeddingClient,
                                ProductService productService,
                                //chổ này ngưỡng maxDistint
                                //0.0-2.0 thì 0.0 sát nghĩa nhất 100
                                //0.3-0.55 sát nghĩa
                                //0.6-0.8 thì nối lỏng ra
                                //còn 1.0 trở lên thì không liên quan
                                @Value("${vector.search.max-distance:0.6}") double maxDistance) {
        this.embeddingRepository = embeddingRepository;
        this.embeddingClient = embeddingClient;
        this.productService = productService;
        this.maxDistance = maxDistance;
    }

    /** true khi đã cấu hình và Ollama đang chạy. */
    //kiểu giúp để biết trước Ollama có đang chạy hay không
    public boolean isAvailable() {
        return embeddingClient.isConfigured() && embeddingClient.isReachable();
    }

    /**
     * Tạo vector cho sản phẩm.
     * @param force true = tạo lại cho TẤT CẢ sản phẩm; false = chỉ sản phẩm chưa có vector
     * @return số sản phẩm đã được tạo vector
     * Task_document là chuyển dữ liệu sản phẩm thành vector còn task_quẻry  thì là câu
     * truy vấn ngươì dùng thành vector
     */
    public int reindex(boolean force) {
        //dùng để lấy danh sách thông tin thô của các sản phẩm từ database để chuẩn bị tạo vector
        List<ProductSource> sources = embeddingRepository.findSources(!force);
        int done = 0;
        for (ProductSource s : sources) {
            try {
                //embeddingClient.embed(...)Gửi đoạn văn đó sang Ollama (bge-m3) để chuyển đổi thành mảng số vector
                //đoạn văn bản đang gửi vào là thông tin mô tả của một tài liệu/sản phẩm trong kho
                List<Double> vector = embeddingClient.embed(buildText(s), OllamaEmbeddingClient.TASK_DOCUMENT);
                //sau đó lưu xuống cơ sở dl
                embeddingRepository.save(s.id(), toVectorText(vector));
                done++;
            } catch (Exception e) {
                log.error("Không tạo được vector cho sản phẩm id={} ({}): {}", s.id(), s.name(), e.getMessage());
            }
        }
        log.info("Đã tạo vector cho {}/{} sản phẩm", done, sources.size());
        return done;
    }

    /**
     * Tạo hoặc cập nhật vector cho MỘT sản phẩm cụ thể (chạy đồng bộ).
     * @param productId id sản phẩm
     * @return true nếu xử lý thành công
     */
    //hi Admin thêm mới hoặc chỉnh sửa thông tin của 1 sản phẩm (đổi tên
    // , đổi mô tả, thêm màu/size mới, đổi danh mục, hoặc bật/tắt trạng thái hiển thị)
    public boolean indexProduct(Long productId) {
        if (productId == null || !isAvailable()) {
            return false;
        }
        try {
            // lấy thống tin kiểm tra sản phẩm có tồn tại không
            var optSource = embeddingRepository.findSourceById(productId);
            if (optSource.isPresent()) {
                ProductSource s = optSource.get();
                List<Double> vector = embeddingClient.embed(buildText(s), OllamaEmbeddingClient.TASK_DOCUMENT);
                embeddingRepository.save(s.id(), toVectorText(vector));
                log.info("Đã tạo/cập nhật vector cho sản phẩm id={} ({})", s.id(), s.name());
                return true;
            } else {
                // Sản phẩm bị ẩn, tạm dừng hoặc danh mục bị ẩn -> xóa vector
                embeddingRepository.delete(productId);
                log.info("Đã xóa vector cho sản phẩm id={} (không active hoặc danh mục bị ẩn)", productId);
                return true;
            }
        } catch (Exception e) {
            log.error("Lỗi khi tạo vector cho sản phẩm id={}: {}", productId, e.getMessage());
            return false;
        }
    }

    /**
     * Tạo hoặc cập nhật vector ngầm (Async qua Virtual Thread) cho MỘT sản phẩm.
     * Không chặn luồng xử lý chính của Admin, giúp UI phản hồi tức thì.
     * tức là -->này chạy ngay tại thời điểm Admin bấm nút Lưu (thêm mới hoặc sửa) 1 sản phẩm trên trang quản trị
     */
    public void indexProductAsync(Long productId) {
        if (productId == null) return;
        Thread.startVirtualThread(() -> {
            try {
                // Delay 400ms để đảm bảo transaction database đã commit xong dữ liệu
                Thread.sleep(400);
                indexProduct(productId);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                log.error("Lỗi chạy ngầm tạo vector sản phẩm id={}: {}", productId, e.getMessage());
            }
        });
    }

    /**
     * Xóa vector của một sản phẩm ngầm (Async qua Virtual Thread).
     */
    public void removeProductAsync(Long productId) {
        if (productId == null) return;
        Thread.startVirtualThread(() -> {
            try {
                embeddingRepository.delete(productId);
                log.info("Đã xóa vector sản phẩm id={}", productId);
            } catch (Exception e) {
                log.error("Lỗi xóa vector sản phẩm id={}: {}", productId, e.getMessage());
            }
        });
    }

    /**
     * Quét và tạo lại vector ngầm (Async) cho các sản phẩm chưa có vector.
     */
    public void reindexAsync(boolean force) {
        Thread.startVirtualThread(() -> {
            try {
                Thread.sleep(500);
                reindex(force);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                log.error("Lỗi chạy ngầm reindex vector: {}", e.getMessage());
            }
        });
    }

    /**
     * Xóa vector của toàn bộ sản phẩm thuộc 1 danh mục ngầm (Async).
     */
    public void removeByCategoryAsync(Long categoryId) {
        if (categoryId == null) return;
        Thread.startVirtualThread(() -> {
            try {
                embeddingRepository.deleteByCategoryId(categoryId);
                log.info("Đã xóa vector các sản phẩm thuộc danh mục id={}", categoryId);
            } catch (Exception e) {
                log.error("Lỗi xóa vector theo danh mục id={}: {}", categoryId, e.getMessage());
            }
        });
    }

    // hàm này quan trong để tìm kiếm sản phẩm đây
    /** Tìm tối đa `limit` sản phẩm gần nghĩa nhất với câu khách nhập, đã sắp xếp theo độ giống. */
    public List<SearchResult> search(String query, int limit) {
        if (query == null || query.isBlank()) {
            return List.of();
        }

        List<Double> queryVector;
        try {
            // biến câu hỏi người dùng thành vector
            queryVector = embeddingClient.embed(query.trim(), OllamaEmbeddingClient.TASK_QUERY);
        } catch (Exception e) {
            log.warn("Vector search lỗi, bỏ qua: {}", e.getMessage());
            return List.of();
        }

        //truy vấn trong MariaDB để tìm ra các sản phẩm có ý nghĩa giống nhất với câu hỏi
        //tovectorText là chuyển mảng số quẻyVector thành chuỗi "[0.12...]"
        //Gọi xuống MariaDB chạy hàm VEC_DISTANCE_COSINE để lấy về tối đa limit
        // sản phẩm gần nghĩa nhất, kèm theo chỉ số khoảng cách distance
        // (mỗi kết quả là một Hit gồm productId và distance
        List<Hit> hits = embeddingRepository.searchNearest(toVectorText(queryVector), limit).stream()

                .filter(h -> h.distance() <= maxDistance)//Lọc bỏ những sản phẩm có khoảng cách quá xa
                .toList();
        if (hits.isEmpty()) {
            return List.of();
        }
        //Hit chỉ mới có mỗi cái productId và distance (chưa có tên áo, giá tiền,
        // ảnh đại diện để hiện lên web), nên 2 dòng code của bạn làm nhiệm vụ
        // "tra cứu ngược lại thông tin đầy đủ của sản phẩm từ danh sách ID"
        List<Long> ids = hits.stream().map(Hit::productId).toList();//Rút riêng cột productId từ các Hit ra thành một danh sách ID
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
//dùng để dịch mã giới tính kỹ thuật trong database sang chữ tiếng Việt tự nhiên
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

    //này chuyển đoạn số vector thành chuỗi
    private String toVectorText(List<Double> vector) {
        return vector.stream().map(String::valueOf).collect(Collectors.joining(",", "[", "]"));
    }
}