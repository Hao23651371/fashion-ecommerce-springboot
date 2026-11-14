package com.iuh.fashionshop.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.Normalizer;
import java.text.NumberFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import com.iuh.fashionshop.service.ai.SpringAiGeminiChatClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

import com.iuh.fashionshop.dto.ProductDetailDto;
import com.iuh.fashionshop.dto.ProductDetailDto.ColorDto;
import com.iuh.fashionshop.dto.ProductDetailDto.VariantDto;
import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.enums.CouponStatus;
import com.iuh.fashionshop.model.enums.DiscountType;
import com.iuh.fashionshop.repository.CouponRepository;
import com.iuh.fashionshop.service.ai.OllamaChatClient;

@Service
public class ChatbotService {
    private static final Logger log = LoggerFactory.getLogger(ChatbotService.class);

    /** Ngưỡng khoảng cách cosine: càng nhỏ càng khắt khe. */
    private static final double MAX_DISTANCE = 0.8;

    /** Số sản phẩm tối đa đưa vào prompt LLM. */
    private static final int MAX_PRODUCTS = 5;

    private static final String SYSTEM_PROMPT = """
        Bạn là chuyên viên tư vấn thời trang thông minh, tận tình của cửa hàng FashionShop.

        Phong cách trò chuyện:
        - Luôn trả lời bằng tiếng Việt thân thiện, tự nhiên như người thật trò chuyện, xưng hô 'mình' hoặc 'FashionShop' và gọi khách là 'bạn'.
        - Khéo léo chèn các icon/emoji thời trang phù hợp (👗, 👕, 👖, 🧥, 👠, ✨, 💖, 🌸, 🛍️, 📦, 💡, 🥰) để câu trả lời thêm sinh động và ấm áp.

        Quy tắc trình bày danh sách sản phẩm (BẮT BUỘC):
        - TUYỆT ĐỐI KHÔNG viết các sản phẩm dồn cục thành một đoạn văn xuôi dài liền nhau.
        - Mỗi sản phẩm BẮT BUỘC phải xuống dòng và trình bày trên từng mục riêng biệt rõ ràng (đầu dòng có biểu tượng như 👗, 👕, 🧥, ✨...).
        - Với mỗi sản phẩm được giới thiệu, PHẢI ghi rõ:
          + Tên sản phẩm in đậm: **Tên sản phẩm**
          + Giá bán hiện tại (nêu giá gốc và % giảm nếu đang sale), Kích cỡ (Size) có sẵn, Màu sắc.
          + Ngay dưới thông tin mỗi sản phẩm, BẮT BUỘC phải đính kèm đường link /shop/{id} trên một dòng riêng biệt để hệ thống web tự động hiển thị thẻ sản phẩm trực quan có nút 'Chi tiết' và 'Tiến hành thanh toán'.
        - TUYỆT ĐỐI KHÔNG hiển thị mã ID, số ID hay viết chữ (ID: ...), [ID: ...] trong câu trả lời. Khách hàng tuyệt đối không được nhìn thấy ID kỹ thuật của cơ sở dữ liệu.

        Ví dụ mẫu định dạng chuẩn bắt buộc làm theo khi giới thiệu sản phẩm:
        Dạ FashionShop gợi ý cho bạn các mẫu thời trang hot nhất đang có sẵn nè:

        👗 **Váy Maxi Hoa Nhí**
        - Giá bán: 450.000đ (Đang giảm 10%, giá gốc 500.000đ)
        - Kích cỡ: S, M, L | Màu sắc: Trắng, Xanh Pastel
        /shop/12

        👕 **Áo Polo Nam Dry-Fit**
        - Giá bán: 280.000đ
        - Kích cỡ: M, L, XL | Màu sắc: Đen, Trắng, Ghi
        /shop/25

        💬 Bạn có muốn mình tư vấn thêm về kích cỡ (size) hay chất liệu không ạ? 🥰

        Quy tắc khi khách hỏi số lượng lớn (ví dụ: "liệt kê 15 bộ", "cho mình 10 mẫu áo", "tìm 20 cái váy"):
        - Hệ thống shop gợi ý tối đa 5 sản phẩm đẹp và phù hợp nhất một lần để tránh làm dài khung chat.
        - Khi khách yêu cầu số lượng lớn hơn 5, câu đầu tiên BẮT BUỘC phải thông báo lịch sự cho khách:
          "Dạ hiện tại FashionShop xin phép gợi ý tối đa 5 mẫu tiêu biểu và đẹp nhất để bạn dễ tham khảo trước nhé! (Bạn có thể xem thêm tất cả sản phẩm tại mục Cửa hàng nha ✨)"
        - Sau đó liệt kê đúng tối đa 5 sản phẩm nổi bật, mỗi sản phẩm xuống dòng riêng biệt kèm link /shop/{id}.

        Quy tắc độ chính xác tuyệt đối:
        - CHỈ dùng thông tin trong mục "DỮ LIỆU CỬA HÀNG". Tuyệt đối KHÔNG tự bịa ra sản phẩm, giá cả, mã giảm giá, kích cỡ hay số lượng tồn kho.
        - Nếu khách hỏi về size, màu hoặc số lượng còn hàng, hãy trả lời chính xác dựa theo mục Tồn kho của từng sản phẩm trong dữ liệu.
        - Nếu dữ liệu không có sản phẩm khách cần, hãy thành thật báo hiện shop chưa có mẫu đó và gợi ý các mẫu tương tự đang có sẵn.
        - Tuyệt đối không dùng tiếng Trung hay ký tự Hán. Không trả lời các chủ đề ngoài phạm vi thời trang và cửa hàng.
        - DÒNG CUỐI CÙNG CỦA CÂU TRẢ LỜI: Luôn luôn kết thúc bằng một câu hỏi gợi mở thân thiện đặt ở dòng cuối cùng riêng biệt bắt đầu bằng biểu tượng 💬 để hỏi xem khách hàng có cần tư vấn thêm gì không (Ví dụ: "💬 Bạn có muốn mình tư vấn thêm về kích cỡ (size), chất liệu hay gợi ý cách phối đồ không ạ? 🥰" hoặc "💬 Bạn có muốn xem thêm mẫu nào khác nữa không nè? ✨").
        """;

    // --- Các dependency nghiệp vụ & AI Client ---
    private final ProductSearchService searchService;       // Tìm kiếm sản phẩm bằng vector embedding
    private final ProductService productService;           // Lấy chi tiết thông tin, biến thể và tồn kho sản phẩm
    private final CouponRepository couponRepository;       // Tra cứu mã giảm giá đang hoạt động
    private final OllamaChatClient ollamaChatClient;       // Client AI local qua Ollama (chạy offline / fallback)
    private final SpringAiGeminiChatClient springAiGeminiChatClient; // Client AI chính kết nối Gemini qua Spring AI
    private final String provider;                         // Bộ xử lý AI được chọn: "gemini" hoặc "ollama"
    private final boolean fallbackToOllama;                // Cờ cho phép tự động fallback sang Ollama khi Gemini lỗi

    public ChatbotService(ProductSearchService searchService,
                          ProductService productService,
                          CouponRepository couponRepository,
                          OllamaChatClient ollamaChatClient,
                          SpringAiGeminiChatClient springAiGeminiChatClient,
                          @Value("${chatbot.provider:ollama}") String provider,
                          @Value("${chatbot.fallback-to-ollama:false}") boolean fallbackToOllama) {
        this.searchService = searchService;
        this.productService = productService;
        this.couponRepository = couponRepository;
        this.ollamaChatClient = ollamaChatClient;
        this.springAiGeminiChatClient = springAiGeminiChatClient;
        this.provider = (provider == null) ? "ollama" : provider.trim().toLowerCase();
        this.fallbackToOllama = fallbackToOllama;
    }

    // ======================= LÀM NÓNG KHI KHỞI ĐỘNG =======================

    @EventListener(ApplicationReadyEvent.class)
    public void warmUp() {
        Thread.startVirtualThread(() -> {
            if ("ollama".equalsIgnoreCase(provider) || fallbackToOllama) {
                ollamaChatClient.warmUp();
            }
            try {
                searchService.search("áo", 1);
                log.info("Đã làm nóng model embedding");
            } catch (Exception e) {
                log.warn("Không làm nóng được embedding: {}", e.getMessage());
            }
        });
    }
    // ============================== API CHÍNH ==============================

    /** Endpoint không streaming. */
    public String reply(String userMessage) {
        StringBuilder sb = new StringBuilder();
        streamReply(userMessage, sb::append);
        return sb.toString().trim();
    }

    /** Bản streaming tương thích ngược khi không truyền productId. */
    public void streamReply(String userMessage, Consumer<String> out) {
        streamReply(userMessage, null, out);
    }

    /** Bản streaming chính thức: Hỗ trợ ngữ cảnh sản phẩm trang chi tiết (/shop/{id}). */
    public void streamReply(String userMessage, Long currentProductId, Consumer<String> out) {
        long t0 = System.currentTimeMillis();

        // 0. NẠP DỮ LIỆU SẢN PHẨM NẾU ĐANG Ở TRANG CHI TIẾT SẢN PHẨM (/shop/{id})
        ProductDetailDto currentProduct = null;
        if (currentProductId != null && currentProductId > 0) {
            try {
                currentProduct = productService.getProductDetail(currentProductId);
            } catch (Exception e) {
                log.warn("Không tìm thấy sản phẩm ID {}: {}", currentProductId, e.getMessage());
            }
        }

        // 1. NẾU ĐANG XEM SẢN PHẨM CỤ THỂ, KIỂM TRA TRẢ LỜI CHÍNH XÁC (SIZE, MÀU, TỒN KHO, GIÁ, CHẤT LIỆU)
        if (currentProduct != null) {
            String quickProductAnswer = tryAnswerForCurrentProduct(userMessage, currentProduct);
            if (quickProductAnswer != null) {
                out.accept(quickProductAnswer);
                log.info("Chatbot trả lời chính xác về sản phẩm đang mở ID {} trong {}ms", currentProductId, System.currentTimeMillis() - t0);
                return;
            }
        }

        // 2. NHÓM 1: CÁC INTENT TOÀN SHOP (CHÀO HỎI, MÃ GIẢM GIÁ, LỌC GIÁ, CHÍNH SÁCH...)
        String exactAnswer = handleGroupOneExact(userMessage);
        if (exactAnswer != null) {
            out.accept(exactAnswer);
            log.info("Chatbot trả lời Nhóm 1 (chính xác tuyệt đối) trong {}ms", System.currentTimeMillis() - t0);
            return;
        }

        // 3. NHÓM 2: CÂU HỎI MỞ / TƯ VẤN PHONG CÁCH / PHỐI ĐỒ -> DÙNG LLM KÈM CONTEXT SẢN PHẨM
        List<ProductDetailDto> products = findProductsWithDetails(userMessage);
        long t1 = System.currentTimeMillis();

        StringBuilder contextBuilder = new StringBuilder();
        if (currentProduct != null) {
            contextBuilder.append("=== SẢN PHẨM KHÁCH HÀNG ĐANG MỞ XEM TRÊN TRANG CHI TIẾT (Đường dẫn: /shop/").append(currentProduct.id()).append(") ===\n")
                    .append("• Tên sản phẩm: ").append(currentProduct.name()).append("\n")
                    .append("• Danh mục: ").append(currentProduct.categoryName()).append("\n")
                    .append("• Đối tượng: ").append(currentProduct.genderLabel()).append("\n")
                    .append("• Giá bán hiện tại: ").append(money(currentProduct.currentPrice()));
            if (currentProduct.onSale()) {
                contextBuilder.append(" (Đang sale giảm ").append(currentProduct.discountPercent()).append("%, giá gốc ").append(money(currentProduct.price())).append(")");
            }
            contextBuilder.append("\n• Kích cỡ có sẵn: ").append(String.join(", ", currentProduct.sizes())).append("\n");
            if (!currentProduct.colors().isEmpty()) {
                contextBuilder.append("• Màu sắc: ").append(currentProduct.colors().stream().map(ProductDetailDto.ColorDto::name).collect(Collectors.joining(", "))).append("\n");
            }
            contextBuilder.append("• Tồn kho: Còn ").append(currentProduct.totalStock()).append(" sản phẩm\n");
            if (currentProduct.description() != null && !currentProduct.description().isBlank()) {
                contextBuilder.append("• Mô tả / Chất liệu / Kiểu dáng: ").append(currentProduct.description().trim()).append("\n");
            }
            contextBuilder.append("👉 LƯU Ý BẮT BUỘC: Khách hàng đang đứng tại trang chi tiết của sản phẩm trên. Nếu khách hỏi về \"mẫu này\", \"sản phẩm này\", \"cái này\", \"áo này\", \"mặc đi đâu\", \"phối với gì\"... hãy trả lời chính xác dựa theo dữ liệu thực tế trên, TUYỆT ĐỐI KHÔNG BỊA ĐẶT thông tin sai lệch ngoài dữ liệu.\n\n");
        }

        // Kiểm tra nếu khách hỏi số lượng lớn (> 5 sản phẩm)
        int requestedQty = extractRequestedQuantity(userMessage);
        if (requestedQty > 5) {
            contextBuilder.append("⚠️ LƯU Ý BẮT BUỘC: Khách hàng đang hỏi số lượng lớn (").append(requestedQty).append(" sản phẩm).\n")
                    .append("Vì khung chat hiển thị giới hạn, bạn CHỈ ĐƯỢC PHÉP gợi ý tối đa 5 sản phẩm đẹp và phù hợp nhất.\n")
                    .append("CÂU ĐẦU TIÊN CỦA BẠN BẮT BUỘC PHẢI LÀ:\n")
                    .append("\"Dạ hiện tại FashionShop xin phép gợi ý tối đa 5 mẫu tiêu biểu và đẹp nhất để bạn dễ tham khảo trước nhé! (Bạn có thể xem thêm tất cả sản phẩm tại mục Cửa hàng nha ✨)\"\n")
                    .append("Sau câu thông báo trên, BẮT BUỘC phải xuống dòng và trình bày từng sản phẩm trên từng dòng riêng biệt, TUYỆT ĐỐI KHÔNG viết dồn cục thành một đoạn văn, và dưới mỗi sản phẩm BẮT BUỘC PHẢI đính kèm đường link /shop/{id} trên một dòng riêng để hệ thống hiển thị thẻ sản phẩm có nút Chi tiết và Tiến hành thanh toán.\n\n");
        }

        contextBuilder.append("DỮ LIỆU CÁC SẢN PHẨM KHÁC LIÊN QUAN TRONG KHO:\n").append(formatProducts(products));
        String userContent = contextBuilder.toString() + "\n\nCÂU HỎI CỦA KHÁCH: " + userMessage;

        AtomicBoolean sent = new AtomicBoolean(false);
        AtomicBoolean first = new AtomicBoolean(true);

        Consumer<String> streamConsumer = chunk -> {
            if (chunk != null && !chunk.isEmpty()) {
                if (first.compareAndSet(true, false)) {
                    log.info("Chatbot: vector {}ms, chữ đầu tiên sau {}ms",
                            t1 - t0, System.currentTimeMillis() - t0);
                }
                sent.set(true);
                out.accept(chunk);
            }
        };

        boolean success = false;
        if ("gemini".equalsIgnoreCase(provider) || "spring-ai-gemini".equalsIgnoreCase(provider)) {
            try {
                // Gọi thẳng Spring AI Gemini
                springAiGeminiChatClient.stream(SYSTEM_PROMPT, userContent, streamConsumer);
                success = true;
                log.info("Chatbot (Spring AI Gemini) hoàn tất sau {}ms", System.currentTimeMillis() - t0);
            } catch (Exception e) {
                log.warn("Chatbot: Spring AI Gemini gặp sự cố ({}), kiểm tra phương án dự phòng", e.getMessage());
                if (!sent.get() && fallbackToOllama) {
                    try {
                        log.info("Chatbot: Đang thử fallback sang Ollama...");
                        ollamaChatClient.stream(SYSTEM_PROMPT, userContent, streamConsumer);
                        success = true;
                        log.info("Chatbot (Fallback Ollama) hoàn tất sau {}ms", System.currentTimeMillis() - t0);
                    } catch (Exception ex) {
                        log.warn("Chatbot: Fallback Ollama cũng gặp sự cố: {}", ex.getMessage());
                    }
                }
            }
        } else {
            try {
                ollamaChatClient.stream(SYSTEM_PROMPT, userContent, streamConsumer);
                success = true;
                log.info("Chatbot (Ollama) hoàn tất sau {}ms", System.currentTimeMillis() - t0);
            } catch (Exception e) {
                log.warn("Chatbot: Ollama gặp sự cố: {}", e.getMessage());
            }
        }

        if (!success && !sent.get()) {
            if (products.isEmpty()) {
                out.accept("Dạ FashionShop rất tiếc hiện trợ lý AI đang bận một chút. Bạn có thể dùng ô tìm kiếm hoặc xem các danh mục thời trang trên menu nha! 🥰");
            } else {
                out.accept("Dạ FashionShop gợi ý bạn tham khảo các sản phẩm phù hợp này nhé:\n" + formatProducts(products));
            }
        }
    }

    // =========================================================================
    // XỬ LÝ RIÊNG KHI KHÁCH ĐANG Ở TRANG CHI TIẾT SẢN PHẨM (/shop/{id})
    // =========================================================================

    private String tryAnswerForCurrentProduct(String message, ProductDetailDto product) {
        if (message == null || product == null) return null;
        String norm = stripAccents(message).trim();

        // 1. Hỏi về Size / Kích cỡ của sản phẩm đang xem
        if (norm.contains("size") || norm.contains("kich co") || norm.contains("bang size")
                || norm.contains("vua khong") || norm.contains("co size")) {
            StringBuilder sb = new StringBuilder();
            sb.append("📏 **Kích cỡ & Tồn kho của mẫu \"").append(product.name()).append("\":**\n\n");
            if (product.soldOut() || product.totalStock() <= 0) {
                sb.append("Dạ rất tiếc hiện tại mẫu này đang **tạm hết hàng** trên hệ thống ạ.\n");
            } else {
                sb.append("• **Các size sẵn có**: ").append(String.join(", ", product.sizes())).append("\n");
                if (!product.colors().isEmpty()) {
                    sb.append("• **Màu sắc**: ").append(product.colors().stream().map(ProductDetailDto.ColorDto::name).collect(Collectors.joining(", "))).append("\n");
                }
                sb.append("• **Chi tiết tồn kho từng phân loại**:\n");
                for (ProductDetailDto.VariantDto v : product.variants()) {
                    sb.append("   - Màu ").append(v.color()).append(" | Size ").append(v.size()).append(": ");
                    if (v.stockQuantity() > 0) {
                        sb.append("Còn **").append(v.stockQuantity()).append("** cái (Sẵn hàng)\n");
                    } else {
                        sb.append("*Tạm hết size này*\n");
                    }
                }
                sb.append("\n💡 **Gợi ý**: Bạn có thể chọn size và màu yêu thích ngay trên màn hình để thêm vào giỏ hàng nhé!\n");
            }
            sb.append("\n💬 Bạn có muốn mình tư vấn chọn size theo chiều cao và cân nặng của bạn không ạ? 🥰");
            return sb.toString();
        }

        // 2. Hỏi về Màu sắc
        if (norm.contains("mau gi") || norm.contains("mau sac") || norm.contains("nhung mau nao")
                || norm.contains("co mau gi") || norm.contains("co mau nao") || norm.contains("co nhung mau")) {
            StringBuilder sb = new StringBuilder();
            sb.append("🎨 **Màu sắc của mẫu \"").append(product.name()).append("\":**\n\n");
            if (product.colors().isEmpty()) {
                sb.append("Mẫu này hiện có 1 màu chuẩn như hình hiển thị trên trang chi tiết ạ.\n");
            } else {
                sb.append("Mẫu này hiện đang có các màu sắc sau:\n");
                for (ProductDetailDto.ColorDto c : product.colors()) {
                    sb.append("• Màu **").append(c.name()).append("**\n");
                }
            }
            sb.append("\n💬 Bạn ưng ý màu sắc nào nhất để mình tư vấn chọn size cho bạn nhé? ✨");
            return sb.toString();
        }

        // 3. Hỏi về Tồn kho / Còn hàng không
        if (norm.contains("con hang khong") || norm.contains("con hang ko") || norm.contains("het hang")
                || norm.contains("con bao nhieu") || norm.contains("so luong con") || norm.contains("ton kho")) {
            StringBuilder sb = new StringBuilder();
            sb.append("📦 **Tình trạng hàng của mẫu \"").append(product.name()).append("\":**\n\n");
            if (product.soldOut() || product.totalStock() <= 0) {
                sb.append("Dạ rất tiếc hiện mẫu này đang **tạm hết hàng** ạ. Bạn có thể tham khảo các mẫu tương tự khác trên shop nhé!\n");
            } else {
                sb.append("• Hiện shop còn **").append(product.totalStock()).append("** sản phẩm sẵn sàng giao ngay.\n");
                sb.append("• Các size có thể đặt: **").append(String.join(", ", product.sizes())).append("**\n");
            }
            sb.append("\n💬 Bạn có muốn đặt giữ hàng mẫu này ngay trước khi hết size không nè? 🥰");
            return sb.toString();
        }

        // 4. Hỏi về Giá bán / Sale / Ưu đãi của sản phẩm này (không phải câu hỏi lọc chung chung kiểu "dưới 500k")
        if ((norm.contains("gia bao nhieu") || norm.contains("gia nhieu") || norm.contains("bao nhieu tien")
                || norm.contains("gia cua mau nay") || norm.contains("gia sp nay") || norm.contains("co giam gia khong")
                || norm.contains("co sale khong") || norm.equals("gia") || norm.equals("gia ban"))
                && !norm.contains("duoi") && !norm.contains("tren") && !norm.contains("tu")) {
            StringBuilder sb = new StringBuilder();
            sb.append("💰 **Giá bán của mẫu \"").append(product.name()).append("\":**\n\n");
            if (product.onSale()) {
                sb.append("🔥 Mẫu này đang có ưu đãi **Giảm ").append(product.discountPercent()).append("%**!\n")
                  .append("• Giá ưu đãi: **").append(money(product.currentPrice())).append("**\n")
                  .append("• Giá gốc: ~~").append(money(product.price())).append("~~\n");
            } else {
                sb.append("• Giá bán niêm yết: **").append(money(product.price())).append("**\n");
            }
            sb.append("• Tình trạng: ").append(product.soldOut() ? "Tạm hết hàng" : "Còn " + product.totalStock() + " sp").append("\n\n");
            sb.append("💡 Bạn nhớ áp dụng thêm mã giảm giá ở trang Thanh toán để được giá tốt nhất nha!\n");
            sb.append("\n💬 Bạn có cần mình tư vấn thêm về kích cỡ hay hướng dẫn đặt mua mẫu này không ạ? 🥰");
            return sb.toString();
        }

        // 5. Hỏi về Chất liệu / Form dáng / Mô tả
        if (norm.contains("chat lieu") || norm.contains("chat vai") || norm.contains("vai gi")
                || norm.contains("form dang") || norm.contains("form gi") || norm.contains("dang ao")
                || norm.contains("dang vay") || norm.contains("dang dam") || norm.contains("thong tin san pham")
                || norm.contains("mo ta")) {
            StringBuilder sb = new StringBuilder();
            sb.append("🧵 **Thông tin Chất liệu & Thiết kế của mẫu \"").append(product.name()).append("\":**\n\n");
            if (product.description() != null && !product.description().isBlank()) {
                sb.append(product.description().trim()).append("\n\n");
            }
            sb.append("• **Dòng thời trang**: ").append(product.categoryName()).append(" (").append(product.genderLabel()).append(")\n")
              .append("• **Giá bán**: **").append(money(product.currentPrice())).append("**");
            if (product.onSale()) sb.append(" (Đang giảm ").append(product.discountPercent()).append("%)");
            sb.append("\n\n💬 Bạn cần mình tư vấn thêm về cách phối đồ hay cách giặt ủi bảo quản trang phục này không ạ? ✨");
            return sb.toString();
        }

        return null;
    }

    // =========================================================================
    // NHÓM 1: BỘ XỬ LÝ INTENT CHÍNH XÁC TUYỆT ĐỐI (DETERMINISTIC / RULE-BASED)
    // =========================================================================

    private String handleGroupOneExact(String message) {
        if (message == null || message.isBlank()) {
            return "Dạ bạn cần tìm sản phẩm, kiểm tra size, lọc giá hay nhận mã giảm giá nào ạ? FashionShop sẵn sàng hỗ trợ bạn ngay nè! 🥰";
        }
        String norm = stripAccents(message).trim();

        // 1. CHÀO HỎI
        if (isGreeting(norm)) {
            return "👋 Xin chào bạn! Mình là trợ lý của **FashionShop** ✨\n\n"
                    + "Mình có thể hỗ trợ bạn:\n"
                    + "• 🎟️ Tra cứu **Mã giảm giá** & Ưu đãi hôm nay\n"
                    + "• 💰 **Lọc sản phẩm theo giá** (ví dụ: *\"dưới 500k\"*, *\"từ 300k đến 700k\"*)\n"
                    + "• 👗 Xem sản phẩm đang **Sale** theo loại (ví dụ: *\"đầm nào đang giảm giá?\"*)\n"
                    + "• 📦 Kiểm tra **Size, Màu sắc & Tồn kho** còn hàng\n\n"
                    + "Bạn đang quan tâm đến món đồ nào để mình tư vấn ngay nhé!\n\n💬 Bạn cần mình tư vấn chọn đồ theo phong cách hay tìm mẫu cụ thể nào không ạ? 🥰";
        }

        // 2. MÃ GIẢM GIÁ / COUPON / VOUCHER (BẮT ĐÚNG, KHÔNG BỊ NHẦM SANG SALE)
        if (isCouponInquiry(norm)) {
            return couponAnswer();
        }

        // 3. LỌC THEO MỨC GIÁ (VÍ DỤ: "DƯỚI 500K" -> KÊ ÍT NHẤT 5 MÓN)
        String priceFiltered = tryFilterByPrice(norm, message);
        if (priceFiltered != null) {
            return priceFiltered;
        }

        // 4. SẢN PHẨM GIẢM GIÁ THEO DANH MỤC CỤ THỂ (VÍ DỤ: "ĐẦM NÀO ĐANG GIẢM GIÁ?")
        String categorySale = tryCategorySale(norm, message);
        if (categorySale != null) {
            return categorySale;
        }

        // 5. TẤT CẢ SẢN PHẨM GIẢM GIÁ CHUNG (VÍ DỤ: "CÓ GÌ ĐANG GIẢM GIÁ?")
        if (isGeneralSaleInquiry(norm)) {
            return generalSaleAnswer();
        }

        // 6. HỎI VỀ SIZE, MÀU SẮC, TỒN KHO CỦA SẢN PHẨM
        String stockInfo = tryStockAndVariantInquiry(norm, message);
        if (stockInfo != null) {
            return stockInfo;
        }

        // 7. CHÍNH SÁCH CỬA HÀNG (ĐỔI TRẢ, VẬN CHUYỂN, ĐỊA CHỈ, HOTLINE)
        if (isStorePolicyInquiry(norm)) {
            return storePolicyAnswer();
        }

        // Không khớp intent Nhóm 1 -> Chuyển sang Nhóm 2 (LLM tư vấn)
        return null;
    }

    // ---------------------- 1. CHÀO HỎI ----------------------
    private boolean isGreeting(String norm) {
        return norm.matches("^(xin chao|chao|hello|hi|alo|helo)( shop| ban| ad| admin| bot)?([ !.?~]*)$")
                || norm.equals("hi") || norm.equals("hello") || norm.equals("chao shop");
    }

    // ------------------ 2. MÃ GIẢM GIÁ / COUPON ------------------
    private boolean isCouponInquiry(String norm) {
        // Nhận diện từ khóa về coupon / voucher / mã code
        if (norm.contains("ma giam gia") || norm.contains("coupon") || norm.contains("voucher")
                || norm.contains("code giam gia") || norm.contains("ma khuyen mai")
                || norm.contains("ma uu dai") || norm.contains("co ma giam") || norm.contains("co ma nao")
                || norm.contains("xin ma") || norm.contains("nhap ma") || norm.contains("ma giam")) {
            return true;
        }
        boolean hasCodeWord = norm.matches(".*\\b(ma|code|voucher|coupon)\\b.*");
        boolean hasDiscountWord = norm.contains("giam") || norm.contains("sale") || norm.contains("uu dai") || norm.contains("km");
        return hasCodeWord && hasDiscountWord;
    }

    private String couponAnswer() {
        try {
            List<Coupon> activeCoupons = couponRepository.findActiveCoupons(CouponStatus.ACTIVE, LocalDateTime.now());
            StringBuilder sb = new StringBuilder("🎟️ **FashionShop đang có các Mã Giảm Giá & Voucher siêu hời dành riêng cho bạn:**\n\n");

            if (!activeCoupons.isEmpty()) {
                DateTimeFormatter df = DateTimeFormatter.ofPattern("dd/MM/yyyy");
                for (Coupon c : activeCoupons) {
                    sb.append("✨ **Mã: ").append(c.getCode()).append("**\n");
                    sb.append("   • Tên chương trình: ").append(c.getName()).append("\n");
                    sb.append("   • Ưu đãi: ");
                    if (c.getDiscountType() == DiscountType.PERCENT) {
                        sb.append("Giảm ").append(c.getDiscountValue().stripTrailingZeros().toPlainString()).append("%");
                        if (c.getMaxDiscount() != null && c.getMaxDiscount().signum() > 0) {
                            sb.append(" (Tối đa ").append(money(c.getMaxDiscount())).append(")");
                        }
                    } else {
                        sb.append("Giảm ").append(money(c.getDiscountValue()));
                    }
                    sb.append("\n");

                    if (c.getMinOrderValue() != null && c.getMinOrderValue().signum() > 0) {
                        sb.append("   • Đơn tối thiểu: Áp dụng từ ").append(money(c.getMinOrderValue())).append("\n");
                    } else {
                        sb.append("   • Đơn tối thiểu: Áp dụng cho mọi đơn hàng\n");
                    }
                    sb.append("   • Hạn dùng: Đến ").append(c.getEndDate().format(df)).append("\n\n");
                }
            } else {
                // Nếu DB chưa có coupon kích hoạt, cung cấp các mã ưu đãi chính thức của shop
                sb.append("✨ **Mã: FASHION10**\n")
                        .append("   • Ưu đãi: Giảm **10%** (Tối đa 100.000đ)\n")
                        .append("   • Đơn tối thiểu: Áp dụng cho đơn từ 500.000đ\n\n");
                sb.append("🚚 **Mã: FREESHIP**\n")
                        .append("   • Ưu đãi: **Miễn phí giao hàng** toàn quốc\n")
                        .append("   • Đơn tối thiểu: Áp dụng cho đơn từ 499.000đ\n\n");
                sb.append("🎁 **Mã: WELCOME20**\n")
                        .append("   • Ưu đãi: Giảm ngay **20.000đ** cho khách hàng mới\n")
                        .append("   • Đơn tối thiểu: Áp dụng cho đơn từ 200.000đ\n\n");
            }

            sb.append("💡 **Cách áp dụng**: Bạn chỉ cần sao chép mã và nhập vào ô **\"Mã giảm giá\"** tại trang **Thanh toán (Checkout)** để được giảm ngay nha!\n\n💬 Bạn có muốn mình gợi ý một số mẫu đồ đẹp đang được áp dụng các mã giảm giá này để mua sắm ngay không nè? ✨");
            return sb.toString();
        } catch (Exception e) {
            log.warn("Lỗi tra cứu mã giảm giá: {}", e.getMessage());
            return "🎟️ Hiện FashionShop đang có mã **FASHION10** (giảm 10% đơn từ 500k) và **FREESHIP** (miễn phí vận chuyển từ 499k). Bạn nhập tại bước thanh toán để nhận ưu đãi nhé! ✨";
        }
    }

    // ------------------ 3. LỌC GIÁ CHÍNH XÁC (ÍT NHẤT 5 MÓN) ------------------
    private String tryFilterByPrice(String norm, String rawMessage) {
        // Nhận diện các mẫu câu giá:
        // - "dưới 500k", "< 500k", "dưới 500.000", "dưới 1 triệu", "dưới 1tr"
        // - "từ 200k đến 500k", "khoảng 300k - 600k"
        // - "trên 1 triệu", "trên 500k", "> 500k"
        // - "có áo 50k không", "có áo 50.000 không", "áo 50k", "tầm 50k", "giá 50k"
        // - "giá rẻ", "rẻ nhất", "bình dân", "sinh viên"
        BigDecimal minPrice = null;
        BigDecimal maxPrice = null;
        BigDecimal targetExactPrice = null;
        boolean hasPriceIntent = false;

        // 1. Khoảng giá: "từ X đến Y" hoặc "khoảng X - Y"
        Pattern rangePat = Pattern.compile("(?:tu|khoang|tam)\\s*(\\d+[\\d.,]*(?:k|tr|trieu|nghin|ngan)?)\\s*(?:den|-|toi)\\s*(\\d+[\\d.,]*(?:k|tr|trieu|nghin|ngan)?)");
        Matcher mRange = rangePat.matcher(norm);
        if (mRange.find()) {
            minPrice = parseMoneyString(mRange.group(1));
            maxPrice = parseMoneyString(mRange.group(2));
            hasPriceIntent = true;
        }

        // 2. Cận trên: "dưới X", "thấp hơn X", "< X", "X trở xuống"
        if (!hasPriceIntent) {
            Pattern underPat = Pattern.compile("(?:duoi|thap hon|nho hon|<|<=)\\s*(\\d+[\\d.,]*(?:k|tr|trieu|nghin|ngan)?)");
            Matcher mUnder = underPat.matcher(norm);
            if (mUnder.find()) {
                maxPrice = parseMoneyString(mUnder.group(1));
                hasPriceIntent = true;
            } else {
                Pattern downPat = Pattern.compile("(\\d+[\\d.,]*(?:k|tr|trieu|nghin|ngan)?)\\s*(?:tro xuong|do lai|tro ve)");
                Matcher mDown = downPat.matcher(norm);
                if (mDown.find()) {
                    maxPrice = parseMoneyString(mDown.group(1));
                    hasPriceIntent = true;
                }
            }
        }

        // 3. Cận dưới: "trên X", "lớn hơn X", "> X", "từ X trở lên"
        if (!hasPriceIntent) {
            Pattern abovePat = Pattern.compile("(?:tren|lon hon|cao hon|>|>=)\\s*(\\d+[\\d.,]*(?:k|tr|trieu|nghin|ngan)?)");
            Matcher mAbove = abovePat.matcher(norm);
            if (mAbove.find()) {
                minPrice = parseMoneyString(mAbove.group(1));
                hasPriceIntent = true;
            } else {
                Pattern upPat = Pattern.compile("(\\d+[\\d.,]*(?:k|tr|trieu|nghin|ngan)?)\\s*(?:tro len|tro di)");
                Matcher mUp = upPat.matcher(norm);
                if (mUp.find()) {
                    minPrice = parseMoneyString(mUp.group(1));
                    hasPriceIntent = true;
                }
            }
        }

        // 4. Mức giá cụ thể / đơn giá: "có áo 50k không", "có áo 50.000 không", "áo 50k", "tầm 50k", "giá 50k"
        if (!hasPriceIntent) {
            Pattern exactPat = Pattern.compile("(?:gia|tam|khoang|co|tim|\\b)\\s*(?:ao|quan|dam|vay|do|sp|san pham)?(?:\\s+nao)?\\s*(\\d+[\\d.,]*(?:k|tr|trieu|nghin|ngan|\\.000|000))(?:\\s*(?:d|đ|vnd|dong))?", Pattern.CASE_INSENSITIVE);
            Matcher mExact = exactPat.matcher(norm);
            if (mExact.find()) {
                BigDecimal parsed = parseMoneyString(mExact.group(1));
                if (parsed != null && parsed.compareTo(BigDecimal.valueOf(10000)) >= 0) {
                    targetExactPrice = parsed;
                    maxPrice = parsed;
                    hasPriceIntent = true;
                }
            }
        }

        // 5. Giá rẻ chung: "giá rẻ", "rẻ nhất", "sinh viên", "bình dân"
        if (!hasPriceIntent && (norm.contains("gia re") || norm.contains("re nhat")
                || norm.contains("binh dan") || norm.contains("sinh vien") || norm.contains("tiet kiem"))) {
            maxPrice = BigDecimal.valueOf(500000L);
            hasPriceIntent = true;
        }

        if (!hasPriceIntent || (minPrice == null && maxPrice == null && targetExactPrice == null)) {
            return null;
        }

        // Trích xuất danh mục nếu khách có nhắc đến (ví dụ: "áo dưới 500k", "quần dưới 500k")
        String catKeyword = extractCategoryKeyword(norm);

        List<ProductDetailDto> allProducts = productService.getAllActiveDetails();
        final BigDecimal fMin = minPrice;
        final BigDecimal fMax = maxPrice;
        final BigDecimal fTarget = targetExactPrice;

        // Lọc sản phẩm thỏa mãn điều kiện giá
        List<ProductDetailDto> matched;
        if (fTarget != null) {
            BigDecimal lower = fTarget.multiply(BigDecimal.valueOf(0.85));
            BigDecimal upper = fTarget.multiply(BigDecimal.valueOf(1.15));
            matched = allProducts.stream()
                    .filter(p -> catKeyword == null || matchesCategory(p, catKeyword))
                    .filter(p -> {
                        BigDecimal cur = p.currentPrice();
                        return (cur.compareTo(lower) >= 0 && cur.compareTo(upper) <= 0) || cur.compareTo(fTarget) <= 0;
                    })
                    .sorted(Comparator.comparing(p -> p.currentPrice().subtract(fTarget).abs()))
                    .toList();
        } else {
            matched = allProducts.stream()
                    .filter(p -> catKeyword == null || matchesCategory(p, catKeyword))
                    .filter(p -> {
                        BigDecimal cur = p.currentPrice();
                        if (fMax != null && cur.compareTo(fMax) > 0) return false;
                        if (fMin != null && cur.compareTo(fMin) < 0) return false;
                        return true;
                    })
                    .sorted(Comparator.comparing(ProductDetailDto::currentPrice))
                    .toList();
        }

        // ĐẢM BẢO YÊU CẦU: "KÊ ÍT NHẤT 5 MÓN ĐƯA RA CHO XEM"
        List<ProductDetailDto> displayList = new ArrayList<>(matched);
        if (displayList.size() < 5) {
            Set<Long> existingIds = matched.stream().map(ProductDetailDto::id).collect(Collectors.toSet());
            // Nếu các món thoả mãn nghiêm ngặt chưa đủ 5 món, bổ sung các món có giá xấp xỉ gần nhất
            List<ProductDetailDto> candidates = allProducts.stream()
                    .filter(p -> catKeyword == null || matchesCategory(p, catKeyword))
                    .filter(p -> !existingIds.contains(p.id()))
                    .sorted(Comparator.comparing(p -> {
                        if (fTarget != null) {
                            return p.currentPrice().subtract(fTarget).abs();
                        }
                        if (fMax != null) {
                            return p.currentPrice().subtract(fMax).abs();
                        }
                        if (fMin != null) {
                            return p.currentPrice().subtract(fMin).abs();
                        }
                        return p.currentPrice();
                    }))
                    .toList();
            for (ProductDetailDto c : candidates) {
                displayList.add(c);
                if (displayList.size() >= 5) break;
            }
        }

        // Tối đa 7 món để hiển thị đẹp mắt, không làm dài quá khung chat
        List<ProductDetailDto> finalDisplay = displayList.size() > 7 ? displayList.subList(0, 7) : displayList;

        StringBuilder sb = new StringBuilder();
        String priceDesc;
        if (fTarget != null) {
            priceDesc = "tầm " + money(fTarget);
        } else if (fMin != null && fMax != null) {
            priceDesc = "từ " + money(fMin) + " đến " + money(fMax);
        } else if (fMax != null) {
            priceDesc = "dưới " + money(fMax);
        } else {
            priceDesc = "trên " + money(fMin);
        }

        if (matched.isEmpty()) {
            sb.append("Dạ FashionShop rất tiếc hiện chưa có sản phẩm nào trong tầm giá **").append(priceDesc).append("**");
            if (catKeyword != null) {
                sb.append(" (dòng ").append(getCategoryDisplayName(catKeyword)).append(")");
            }
            sb.append(" ạ.\n");

            ProductDetailDto cheapest = allProducts.stream()
                    .filter(p -> catKeyword == null || matchesCategory(p, catKeyword))
                    .min(Comparator.comparing(ProductDetailDto::currentPrice))
                    .orElse(null);
            if (cheapest != null) {
                sb.append("💡 Mẫu có giá mềm và tiết kiệm nhất của shop hiện tại là **").append(cheapest.name())
                        .append("** với giá **").append(money(cheapest.currentPrice())).append("** nè.\n\n");
            }
            sb.append("✨ **Shop gợi ý bạn tham khảo các mẫu có mức giá tốt và gần với yêu cầu của bạn nhất nhé:**\n\n");

            for (int i = 0; i < finalDisplay.size(); i++) {
                ProductDetailDto p = finalDisplay.get(i);
                String icon = getCategoryIcon(p.categoryName());
                sb.append(i + 1).append(". ").append(icon).append(" **").append(p.name()).append("**\n")
                        .append("   • Giá bán: **").append(money(p.currentPrice())).append("**");
                if (p.onSale()) {
                    sb.append(" (🔥 Giảm ").append(p.discountPercent()).append("%, giá gốc ").append(money(p.price())).append(")");
                }
                sb.append("\n");
                if (!p.sizes().isEmpty()) {
                    sb.append("   • Kích cỡ (Size): ").append(String.join(", ", p.sizes())).append("\n");
                }
                if (!p.colors().isEmpty()) {
                    sb.append("   • Màu sắc: ").append(p.colors().stream().map(ColorDto::name).collect(Collectors.joining(", "))).append("\n");
                }
                sb.append("   • Tồn kho: Còn ").append(p.totalStock()).append(" sản phẩm\n")
                        .append("   👉 /shop/").append(p.id()).append("\n\n");
            }
        } else {
            sb.append("💰 **Dạ FashionShop đã tìm thấy các sản phẩm có mức giá ").append(priceDesc);
            if (catKeyword != null) {
                sb.append(" (dòng ").append(getCategoryDisplayName(catKeyword)).append(")");
            }
            sb.append(":**\n\n");

            // 1. Liệt kê các món hoàn toàn thỏa mãn khoảng giá
            for (int i = 0; i < matched.size() && i < finalDisplay.size(); i++) {
                ProductDetailDto p = matched.get(i);
                String icon = getCategoryIcon(p.categoryName());
                sb.append(i + 1).append(". ").append(icon).append(" **").append(p.name()).append("**\n")
                        .append("   • Giá bán: **").append(money(p.currentPrice())).append("**");
                if (p.onSale()) {
                    sb.append(" (🔥 Giảm ").append(p.discountPercent()).append("%, giá gốc ").append(money(p.price())).append(")");
                }
                sb.append("\n");
                if (!p.sizes().isEmpty()) {
                    sb.append("   • Kích cỡ (Size): ").append(String.join(", ", p.sizes())).append("\n");
                }
                if (!p.colors().isEmpty()) {
                    sb.append("   • Màu sắc: ").append(p.colors().stream().map(ColorDto::name).collect(Collectors.joining(", "))).append("\n");
                }
                sb.append("   • Tồn kho: Còn ").append(p.totalStock()).append(" sản phẩm\n")
                        .append("   👉 /shop/").append(p.id()).append("\n\n");
            }

            // 2. Nếu các món đúng giá ít hơn 5, gợi ý thêm các món xấp xỉ gần nhất để khách có ít nhất 5 lựa chọn
            List<ProductDetailDto> nearbyItems = finalDisplay.stream().filter(p -> !matched.contains(p)).toList();
            if (!nearbyItems.isEmpty()) {
                sb.append("✨ **Để bạn có thêm nhiều lựa chọn (đủ từ 5 món tham khảo), shop gợi ý thêm các mẫu hot có mức giá xấp xỉ gần nhất nè:**\n\n");
                for (int i = 0; i < nearbyItems.size(); i++) {
                    ProductDetailDto p = nearbyItems.get(i);
                    String icon = getCategoryIcon(p.categoryName());
                    int itemIndex = matched.size() + i + 1;
                    sb.append(itemIndex).append(". ").append(icon).append(" **").append(p.name()).append("** (Mức giá xấp xỉ)\n")
                            .append("   • Giá bán: **").append(money(p.currentPrice())).append("**");
                    if (p.onSale()) {
                        sb.append(" (🔥 Giảm ").append(p.discountPercent()).append("%, giá gốc ").append(money(p.price())).append(")");
                    }
                    sb.append("\n");
                    if (!p.sizes().isEmpty()) {
                        sb.append("   • Kích cỡ (Size): ").append(String.join(", ", p.sizes())).append("\n");
                    }
                    sb.append("   • Tồn kho: Còn ").append(p.totalStock()).append(" sản phẩm\n")
                            .append("   👉 /shop/").append(p.id()).append("\n\n");
                }
            }
        }
        sb.append("✨ Bạn có thể bấm vào từng món để xem ảnh chi tiết và đặt hàng nhé!\n\n💬 Bạn có muốn mình tư vấn thêm về bảng size, chất liệu hay muốn xem thêm tầm giá nào khác không ạ? 🥰");
        return sb.toString();
    }

    // ------------------ 4. GIẢM GIÁ THEO DANH MỤC CỤ THỂ ------------------
    private String tryCategorySale(String norm, String rawMessage) {
        boolean isSale = isSaleQuestion(norm);
        if (!isSale) {
            return null;
        }

        String catKeyword = extractCategoryKeyword(norm);
        if (catKeyword == null) {
            return null;   // Không chỉ định danh mục -> để mục 5 xử lý
        }

        List<ProductDetailDto> allProducts = productService.getAllActiveDetails();
        List<ProductDetailDto> onSaleInCat = allProducts.stream()
                .filter(ProductDetailDto::onSale)
                .filter(p -> matchesCategory(p, catKeyword))
                .sorted(Comparator.comparingInt(ProductDetailDto::discountPercent).reversed())
                .toList();

        String displayName = getCategoryDisplayName(catKeyword);
        String icon = getCategoryIcon(catKeyword);

        if (!onSaleInCat.isEmpty()) {
            StringBuilder sb = new StringBuilder();
            sb.append(icon).append(" **Dạ FashionShop đang có các mẫu ").append(displayName)
                    .append(" GIẢM GIÁ cực hấp dẫn dành cho bạn:**\n\n");

            for (int i = 0; i < onSaleInCat.size(); i++) {
                ProductDetailDto p = onSaleInCat.get(i);
                sb.append(i + 1).append(". **").append(p.name()).append("**\n")
                        .append("   • Giá ưu đãi: **").append(money(p.salePrice())).append("** ")
                        .append("(🔥 Giảm ").append(p.discountPercent()).append("%, giá gốc ").append(money(p.price())).append(")\n")
                        .append("   • Kích cỡ: ").append(String.join(", ", p.sizes())).append("\n")
                        .append("   • Màu sắc: ").append(p.colors().stream().map(ColorDto::name).collect(Collectors.joining(", "))).append("\n")
                        .append("   • Tồn kho: Còn ").append(p.totalStock()).append(" sản phẩm sẵn sàng giao\n")
                        .append("   👉 /shop/").append(p.id()).append("\n\n");
            }
            sb.append("✨ Bạn ưng ý mẫu nào cứ click link xem chi tiết nha, số lượng sale có hạn nè! 🥰");
            return sb.toString();
        } else {
            // Không có mẫu nào trong danh mục này đang sale
            StringBuilder sb = new StringBuilder();
            sb.append("Dạ hiện tại các mẫu **").append(displayName)
                    .append("** tại FashionShop đang bán đúng giá niêm yết và chưa có chương trình giảm giá riêng ạ.\n\n");

            // Gợi ý các sản phẩm sale hot khác
            List<ProductDetailDto> otherSales = allProducts.stream()
                    .filter(ProductDetailDto::onSale)
                    .sorted(Comparator.comparingInt(ProductDetailDto::discountPercent).reversed())
                    .limit(4)
                    .toList();

            if (!otherSales.isEmpty()) {
                sb.append("🔥 Tuy nhiên, shop đang có các mẫu thời trang khác **GIẢM GIÁ SIÊU SÂU** bạn xem thử nha:\n\n");
                for (ProductDetailDto p : otherSales) {
                    sb.append("• ").append(getCategoryIcon(p.categoryName())).append(" **").append(p.name()).append("**: **")
                            .append(money(p.salePrice())).append("** (Giảm ").append(p.discountPercent()).append("%)")
                            .append(" 👉 /shop/").append(p.id()).append("\n");
                }
            }
            sb.append("\nBạn có thể vào menu mục **Sale** trên thanh điều hướng để xem đầy đủ nhé! 💖");
            return sb.toString();
        }
    }

    // ------------------ 5. TẤT CẢ SẢN PHẨM GIẢM GIÁ CHUNG ------------------
    private boolean isGeneralSaleInquiry(String norm) {
        if (!isSaleQuestion(norm)) {
            return false;
        }
        // Nếu câu hỏi chung chung dưới 45 ký tự hoặc chứa cụm hỏi sale tổng quát
        return norm.length() <= 45 || norm.contains("co gi dang giam") || norm.contains("danh sach sale")
                || norm.contains("san pham giam gia") || norm.contains("cac mon giam gia");
    }

    private String generalSaleAnswer() {
        try {
            List<ProductDetailDto> all = productService.getAllActiveDetails();
            List<ProductDetailDto> sales = all.stream()
                    .filter(ProductDetailDto::onSale)
                    .sorted(Comparator.comparingInt(ProductDetailDto::discountPercent).reversed())
                    .limit(MAX_PRODUCTS)
                    .toList();

            if (sales.isEmpty()) {
                return "Dạ hiện tại FashionShop chưa có sản phẩm nào trong đợt giảm giá. Bạn quay lại sau hoặc xem các bộ sưu tập mới về nhé! 🥰";
            }

            StringBuilder sb = new StringBuilder("🔥 **FashionShop đang có các sản phẩm HOT SALE giảm giá sâu nhất hôm nay:**\n\n");
            for (int i = 0; i < sales.size(); i++) {
                ProductDetailDto p = sales.get(i);
                sb.append(i + 1).append(". ").append(getCategoryIcon(p.categoryName()))
                        .append(" **").append(p.name()).append("**\n")
                        .append("   • Giá ưu đãi: **").append(money(p.salePrice())).append("** ")
                        .append("(Giảm ").append(p.discountPercent()).append("%, giá gốc ").append(money(p.price())).append(")\n")
                        .append("   • Size có sẵn: ").append(String.join(", ", p.sizes())).append("\n")
                        .append("   • Tồn kho: Còn ").append(p.totalStock()).append(" sản phẩm\n")
                        .append("   👉 /shop/").append(p.id()).append("\n\n");
            }
            sb.append("💡 Bạn nhớ áp dụng thêm **Mã giảm giá** ở bước thanh toán để được trừ thêm tiền nhé! ✨");
            return sb.toString();
        } catch (Exception e) {
            log.warn("Lỗi lấy danh sách giảm giá chung: {}", e.getMessage());
            return "Dạ bạn xem nhanh các sản phẩm giảm giá tại mục **Sale** trên thanh menu nhé! ✨";
        }
    }

    // ------------------ 6. BIẾT SIZE, MÀU, TỒN KHO CỦA SẢN PHẨM ------------------
    private String tryStockAndVariantInquiry(String norm, String rawMessage) {
        boolean hasStockWord = norm.contains("size") || norm.contains("kich co") || norm.contains("kich thuoc")
                || norm.contains("mau sac") || norm.contains("mau gi") || norm.contains("con mau")
                || norm.contains("ton kho") || norm.contains("con hang") || norm.contains("het hang")
                || norm.contains("so luong") || norm.contains("con khong") || norm.contains("co size");

        if (!hasStockWord) {
            return null;
        }

        List<ProductDetailDto> all = productService.getAllActiveDetails();
        ProductDetailDto matched = findBestMatchingProduct(norm, all);

        if (matched != null) {
            StringBuilder sb = new StringBuilder();
            sb.append("📦 **Thông tin chi tiết Kích cỡ, Màu sắc & Tồn kho của: ").append(matched.name()).append("**\n\n");
            sb.append("💰 **Giá hiện tại**: **").append(money(matched.currentPrice())).append("**");
            if (matched.onSale()) {
                sb.append(" (🔥 Giảm ").append(matched.discountPercent()).append("%, giá gốc ").append(money(matched.price())).append(")");
            }
            sb.append("\n");

            sb.append("🎨 **Màu sắc có sẵn**: ").append(matched.colors().stream().map(ColorDto::name).collect(Collectors.joining(", "))).append("\n");
            sb.append("📏 **Kích cỡ có sẵn**: ").append(String.join(", ", matched.sizes())).append("\n\n");

            sb.append("📊 **Tình trạng phân loại tồn kho chi tiết**:\n");
            for (VariantDto v : matched.variants()) {
                sb.append("  • Màu ").append(v.color()).append(" - Size ").append(v.size()).append(": ");
                if (v.stockQuantity() > 0) {
                    sb.append("**Còn ").append(v.stockQuantity()).append(" cái** (Sẵn sàng giao)");
                } else {
                    sb.append("*Tạm hết hàng*");
                }
                sb.append("\n");
            }
            sb.append("\n✨ **Tổng tồn kho**: ").append(matched.totalStock()).append(" sản phẩm.\n");
            sb.append("👉 Bấm vào đây để chọn size và đặt mua ngay: /shop/").append(matched.id());
            return sb.toString();
        }

        // Nếu khách hỏi chung chung về size (ví dụ: "shop có size gì?", "còn size XL không?")
        if (norm.contains("size xl") || norm.contains("size 2xl") || norm.contains("size l") || norm.contains("size m") || norm.contains("size s")) {
            String targetSize = "M";
            if (norm.contains("size xl")) targetSize = "XL";
            else if (norm.contains("size 2xl")) targetSize = "2XL";
            else if (norm.contains("size l")) targetSize = "L";
            else if (norm.contains("size s")) targetSize = "S";

            final String fSize = targetSize;
            List<ProductDetailDto> withSize = all.stream()
                    .filter(p -> p.sizes().contains(fSize))
                    .limit(5)
                    .toList();

            if (!withSize.isEmpty()) {
                StringBuilder sb = new StringBuilder("📏 **FashionShop hiện có rất nhiều sản phẩm có Size ").append(targetSize).append(" sẵn hàng:**\n\n");
                for (ProductDetailDto p : withSize) {
                    sb.append("• ").append(getCategoryIcon(p.categoryName())).append(" **").append(p.name()).append("**: ")
                            .append(money(p.currentPrice())).append(" 👉 /shop/").append(p.id()).append("\n");
                }
                sb.append("\nBạn ưng mẫu nào có thể click link xem chi tiết hoặc nhắn mình tư vấn form dáng nhé! 🥰");
                return sb.toString();
            }
        }

        if (norm.contains("size") || norm.contains("kich co")) {
            return "📏 FashionShop có đầy đủ các size chuẩn thời trang từ **XS, S, M, L, XL** cho cả nam và nữ.\n"
                    + "Tất cả các sản phẩm trên website đều có bảng chọn size và số lượng tồn kho hiển thị trực tiếp.\n"
                    + "Bạn đang quan tâm đến sản phẩm cụ thể nào (ví dụ: *\"Áo sơ mi linen\"*, *\"Đầm lụa\"*, *\"Quần tây\"*) để mình kiểm tra số lượng tồn kho chính xác cho bạn nhé! 🥰";
        }

        return null;
    }

    // ------------------ 7. CHÍNH SÁCH CỬA HÀNG ------------------
    private boolean isStorePolicyInquiry(String norm) {
        return norm.contains("doi tra") || norm.contains("chinh sach") || norm.contains("phi ship")
                || norm.contains("freeship") || norm.contains("van chuyen") || norm.contains("giao hang")
                || norm.contains("dia chi") || norm.contains("hotline") || norm.contains("tong dai")
                || norm.contains("so dien thoai") || norm.contains("shop o dau") || norm.contains("o dau");
    }

    private String storePolicyAnswer() {
        return "🛍️ **Thông tin dịch vụ & Chính sách của FashionShop:**\n\n"
                + "• 🚚 **Vận chuyển**: Giao hàng toàn quốc (Nội thành 1-2 ngày, tỉnh khác 2-4 ngày). **Miễn phí ship** cho đơn từ 499k (Mã FREESHIP).\n"
                + "• 🔄 **Đổi trả dễ dàng**: Hỗ trợ đổi size/mẫu trong vòng **7 ngày** kể từ khi nhận hàng (sản phẩm còn nguyên tem mác).\n"
                + "• 📍 **Địa chỉ cửa hàng**: 12 Nguyễn Văn Bảo, Phường 4, Quận Gò Vấp, TP. Hồ Chí Minh.\n"
                + "• 📞 **Hotline hỗ trợ**: **1900 6868** (Hỗ trợ từ 8:00 - 22:00 hàng ngày).\n\n"
                + "✨ Bạn cần thêm thông tin gì cứ nhắn cho mình nhé! 🥰";
    }

    // =========================================================================
    // HỖ TRỢ TRÍCH XUẤT VÀ TÌM KIẾM
    // =========================================================================

    private boolean isSaleQuestion(String norm) {
        return norm.contains("giam gia") || norm.contains("khuyen mai")
                || norm.contains("uu dai") || norm.matches(".*\\bsale\\b.*")
                || norm.contains("ha gia") || norm.contains("giam");
    }

    private String extractCategoryKeyword(String norm) {
        if (norm.contains("dam") || norm.contains("vay dai") || norm.contains("vay da hoi")) return "dam";
        if (norm.contains("chan vay")) return "chan vay";
        if (norm.contains("ao so mi") || norm.contains("so mi")) return "so mi";
        if (norm.contains("ao khoac") || norm.contains("trench coat") || norm.contains("blazer")) return "ao khoac";
        if (norm.contains("ao len")) return "ao len";
        if (norm.contains("ao thun") || norm.contains("ao phong") || norm.contains("t-shirt")) return "ao thun";
        if (norm.contains("quan jean") || norm.contains("quan short") || norm.contains("quan tay") || norm.matches(".*\\bquan\\b.*")) return "quan";
        if (norm.matches(".*\\bao\\b.*")) return "ao";
        return null;
    }

    private boolean matchesCategory(ProductDetailDto p, String catKeyword) {
        if (catKeyword == null) return true;
        String pName = stripAccents(p.name());
        String pCat = stripAccents(p.categoryName());

        return switch (catKeyword) {
            case "dam" -> pCat.contains("dam") || pName.contains("dam");
            case "chan vay" -> pCat.contains("chan vay") || pName.contains("chan vay");
            case "so mi" -> pCat.contains("so mi") || pName.contains("so mi");
            case "ao khoac" -> pCat.contains("ao khoac") || pName.contains("khoac") || pName.contains("blazer") || pName.contains("trench");
            case "ao len" -> pCat.contains("ao len") || pName.contains("len");
            case "ao thun" -> pCat.contains("ao thun") || pName.contains("ao thun") || pName.contains("phong");
            case "quan" -> pCat.contains("quan") || pName.contains("quan");
            case "ao" -> pCat.toLowerCase(Locale.ROOT).contains("áo") || pName.contains("ao");
            default -> pCat.contains(catKeyword) || pName.contains(catKeyword);
        };
    }

    private String getCategoryDisplayName(String catKeyword) {
        if (catKeyword == null) return "thời trang";
        return switch (catKeyword) {
            case "dam" -> "Đầm / Váy";
            case "chan vay" -> "Chân váy";
            case "so mi" -> "Áo sơ mi";
            case "ao khoac" -> "Áo khoác / Blazer";
            case "ao len" -> "Áo len";
            case "ao thun" -> "Áo thun";
            case "quan" -> "Quần";
            case "ao" -> "Áo";
            default -> catKeyword;
        };
    }

    private String getCategoryIcon(String categoryName) {
        if (categoryName == null) return "✨";
        String norm = stripAccents(categoryName);
        if (norm.contains("dam")) return "👗";
        if (norm.contains("chan vay")) return "💃";
        if (norm.contains("so mi")) return "👔";
        if (norm.contains("khoac")) return "🧥";
        if (norm.contains("len")) return "🧶";
        if (norm.contains("thun")) return "👕";
        if (norm.contains("quan")) return "👖";
        return "✨";
    }

    private ProductDetailDto findBestMatchingProduct(String norm, List<ProductDetailDto> products) {
        ProductDetailDto best = null;
        int maxScore = 0;
        for (ProductDetailDto p : products) {
            String pNorm = stripAccents(p.name());
            int score = 0;
            // Tách các từ quan trọng
            String[] words = pNorm.split("\\s+");
            for (String w : words) {
                if (w.length() >= 3 && norm.contains(w)) {
                    score += 10;
                }
            }
            if (pNorm.length() > 5 && norm.contains(pNorm)) {
                score += 50;
            }
            if (score > maxScore && score >= 20) {
                maxScore = score;
                best = p;
            }
        }
        return best;
    }

    private BigDecimal parseMoneyString(String s) {
        if (s == null) return null;
        s = s.trim().toLowerCase(Locale.ROOT).replace(",", "").replace(".", "");
        try {
            if (s.endsWith("k")) {
                long val = Long.parseLong(s.substring(0, s.length() - 1).trim());
                return BigDecimal.valueOf(val * 1000L);
            }
            if (s.endsWith("tr") || s.endsWith("trieu")) {
                String num = s.replaceAll("[^0-9.]", "");
                double val = Double.parseDouble(num);
                return BigDecimal.valueOf((long) (val * 1_000_000L));
            }
            if (s.endsWith("nghin") || s.endsWith("ngan")) {
                String num = s.replaceAll("[^0-9.]", "");
                long val = Long.parseLong(num);
                return BigDecimal.valueOf(val * 1000L);
            }
            long val = Long.parseLong(s);
            if (val <= 1000 && val > 0) {
                val = val * 1000L;
            }
            return BigDecimal.valueOf(val);
        } catch (Exception e) {
            return null;
        }
    }

    // =========================================================================
    // TÌM SẢN PHẨM PHỤC VỤ LLM (NHÓM 2)
    // =========================================================================

    private List<ProductDetailDto> findProductsWithDetails(String question) {
        try {
            var searchResults = searchService.search(question, MAX_PRODUCTS);
            if (searchResults.isEmpty()) {
                return List.of();
            }
            List<Long> ids = searchResults.stream()
                    .filter(r -> r.distance() <= MAX_DISTANCE)
                    .map(r -> r.product().id())
                    .toList();
            if (ids.isEmpty()) {
                // Nếu khoảng cách khắt khe quá thì lấy top 3 kết quả gần nhất
                ids = searchResults.stream().limit(3).map(r -> r.product().id()).toList();
            }
            return productService.getDetailsByIds(ids);
        } catch (Exception e) {
            log.warn("Chatbot tìm sản phẩm cho LLM lỗi: {}", e.getMessage());
            return List.of();
        }
    }

    private String formatProducts(List<ProductDetailDto> list) {
        if (list.isEmpty()) {
            return "(Không tìm thấy sản phẩm phù hợp trong kho)";
        }
        StringBuilder sb = new StringBuilder();
        for (ProductDetailDto p : list) {
            sb.append("• Tên sản phẩm: ").append(p.name())
                    .append("\n  - Danh mục: ").append(p.categoryName());
            if (p.onSale()) {
                sb.append("\n  - Giá bán: ").append(money(p.salePrice()))
                        .append(" (Giá gốc: ").append(money(p.price()))
                        .append(", Giảm: ").append(p.discountPercent()).append("%)");
            } else {
                sb.append("\n  - Giá bán: ").append(money(p.price()));
            }
            sb.append("\n  - Kích cỡ có sẵn: ").append(String.join(", ", p.sizes()));
            sb.append("\n  - Màu sắc: ").append(p.colors().stream().map(ColorDto::name).collect(Collectors.joining(", ")));
            sb.append("\n  - Tồn kho: ").append(p.totalStock()).append(" sản phẩm");
            sb.append("\n  - Link xem và thanh toán (BẮT BUỘC chèn vào câu trả lời trên một dòng riêng): /shop/").append(p.id()).append("\n\n");
        }
        return sb.toString();
    }

    /**
     * Nhận diện số lượng sản phẩm khách hàng hỏi trong câu (ví dụ: "15 bộ", "10 cái", "20 mẫu", "8 chiếc")
     */
    private int extractRequestedQuantity(String message) {
        if (message == null || message.isBlank()) return 0;
        String norm = stripAccents(message).toLowerCase();
        // Tránh nhầm lẫn với giá tiền hoặc % giảm giá
        Pattern pat = Pattern.compile("(?<![\\d.,])(\\d{1,2})\\s*(?:cai|chiec|bo|mau|mon|sp|san pham|item|set|ao|quan|dam|vay)\\b(?![kKdDđĐ%])");
        Matcher m = pat.matcher(norm);
        if (m.find()) {
            try {
                return Integer.parseInt(m.group(1));
            } catch (NumberFormatException ignored) {}
        }
        return 0;
    }

    
    public ProductDetailDto getProductDetail(Long id) {
        return productService.getProductDetail(id);
    }

    // ============================== TIỆN ÍCH ==============================

    private static String stripAccents(String s) {
        return Normalizer.normalize(s == null ? "" : s, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .replace('đ', 'd').replace('Đ', 'D')
                .toLowerCase(Locale.ROOT);
    }

    private static String money(BigDecimal value) {
        if (value == null) {
            return "0đ";
        }
        NumberFormat nf = NumberFormat.getIntegerInstance(Locale.of("vi", "VN"));
        return nf.format(value) + "đ";
    }
}