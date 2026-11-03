package com.iuh.fashionshop.service.ai;

import java.util.function.Consumer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Component;

/**
 * ============================================================================
 * CLASS NÀY DÙNG ĐỂ LÀM GÌ:
 * - Đây là lớp kết nối trực tiếp đến Google Gemini thông qua framework Spring AI.
 * - Giúp dự án FashionShop gửi câu hỏi của khách hàng lên Gemini và nhận câu trả lời về.
 * ============================================================================
 */
@Component
public class SpringAiGeminiChatClient implements ChatModelClient {

    private static final Logger log = LoggerFactory.getLogger(SpringAiGeminiChatClient.class);

    // Đối tượng chính của Spring AI chịu trách nhiệm gửi nhận tin nhắn với Gemini
    private final ChatClient chatClient;

    /**
     * PHƯƠNG THỨC KHỞI TẠO (Constructor):
     * - Tự động nhận cấu hình từ file application.properties (API key, model, URL của Gemini)
     *   để tạo ra đối tượng chatClient sẵn sàng sử dụng.
     */
    public SpringAiGeminiChatClient(ChatClient.Builder chatClientBuilder) {
        this.chatClient = chatClientBuilder.build();
    }

    /**
     * PHƯƠNG THỨC: generate(...)
     * ------------------------------------------------------------------------
     *  CÔNG DỤNG:
     *    Gửi câu hỏi và ĐỢI GEMINI TRẢ LỜI XONG HẾT cả câu mới lấy về một lần.
     *
     *  KHI NÀO DÙNG:
     *    Dùng cho các chức năng không cần hiệu ứng gõ chữ từng từ (ví dụ: tạo mô tả
     *    sản phẩm tự động, tóm tắt dữ liệu, hoặc gọi API thông thường).
     *
     *  CÁCH CHẠY:
     *    1. Đưa vai trò tư vấn viên vào (.system)
     *    2. Đưa câu hỏi và dữ liệu shop vào (.user)
     *    3. Gọi API Gemini và chờ (.call)
     *    4. Lấy nội dung câu trả lời ra (.content)
     */
    @Override
    public String generate(String systemPrompt, String userPrompt) {
        try {
            return chatClient.prompt()
                    .system(systemPrompt)
                    .user(userPrompt)
                    .call()
                    .content();
        } catch (Exception e) {
            log.error("Spring AI (Gemini) generate lỗi: {}", e.getMessage());
            throw new RuntimeException("Lỗi sinh câu trả lời từ Spring AI Gemini", e);
        }
    }

    /**
     * PHƯƠNG THỨC: stream(...)
     * ------------------------------------------------------------------------
     * 👉 CÔNG DỤNG:
     *    Gửi câu hỏi và NHẬN CHỮ TRẢ VỀ DẦN DẦN theo thời gian thực (như ChatGPT).
     *
     * 👉 KHI NÀO DÙNG:
     *    Dùng trực tiếp cho KHUNG CHATBOT ngoài giao diện web của khách hàng.
     *    Khách không phải chờ lâu, Gemini nghĩ ra từ nào là trên web hiện ra từ đó ngay.
     *
     * 👉 CÁCH CHẠY:
     *    1. Bật chế độ nhận liên tục (.stream().content())
     *    2. Cứ mỗi khi có một mẩu chữ (chunk) gửi về -> Đẩy ngay ra ngoài (out.accept)
     *       để giao diện web hiển thị tức thì cho người dùng thấy.
     */
    @Override
    public void stream(String systemPrompt, String userPrompt, Consumer<String> out) {
        try {
            chatClient.prompt()
                    .system(systemPrompt)
                    .user(userPrompt)
                    .stream()
                    .content()
                    .toStream()
                    .forEach(chunk -> {
                        if (chunk != null && !chunk.isEmpty()) {
                            out.accept(chunk);
                        }
                    });
        } catch (Exception e) {
            log.error("Spring AI (Gemini) stream gặp sự cố: {}", e.getMessage());
            throw new RuntimeException("Lỗi stream Spring AI Gemini", e);
        }
    }
}