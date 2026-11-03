package com.iuh.fashionshop.controller;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UncheckedIOException;
import java.io.Writer;
import java.nio.charset.StandardCharsets;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import com.iuh.fashionshop.service.ChatbotService;

@RestController
@RequestMapping("/api/chatbot")
public class ChatbotController {

    public record ChatRequest(String message) {}

    private final ChatbotService chatbotService;

    public ChatbotController(ChatbotService chatbotService) {
        this.chatbotService = chatbotService;
    }
// cái này thì xem có null hoặc rông kô, nếu quá 500 kí tự chỉ lấy đúng 500 kí tự đọc
    private static String clean(ChatRequest req) {
        String msg = (req == null || req.message() == null) ? "" : req.message().trim();
        return msg.length() > 500 ? msg.substring(0, 500) : msg;
    }

    /**
     * ENDPOINT CHAT STREAMING (POST /api/chatbot/stream):
     * - Trả chữ về màn hình theo thời gian thực, tức là trả lời cố gắng nhanh ko bắt người dùng đợi
     * - Cơ chế: Mở luồng StreamingResponseBody để đẩy từng từ (chunk) về trình duyệt ngay lập tức.
     * - Tối ưu: Tự động dừng gọi AI ngay nếu người dùng tắt trình duyệt hoặc đóng khung chat.
     */
    @PostMapping("/stream")
    public ResponseEntity<StreamingResponseBody> stream(@RequestBody ChatRequest req) {
        String msg = clean(req);
        StreamingResponseBody body = out -> {
            Writer w = new OutputStreamWriter(out, StandardCharsets.UTF_8);
            if (msg.isEmpty()) {
                w.write("Bạn muốn hỏi gì về sản phẩm nào ạ?");
                w.flush();
                return;
            }
            // chổ này đẩy tưng chữ ra màn hình này còn if trên nếu nó rổng thì nó tự đẩy câu kia á
            chatbotService.streamReply(msg, chunk -> {
                try {
                    w.write(chunk);
                    w.flush();   // Đẩy ngay từng chữ về màn hình khách hàng
                } catch (IOException e) {
                    throw new UncheckedIOException(e);   // Khách đóng khung chat thì dừng AI lại
                }
            });
        };
        return ResponseEntity.ok()
                .contentType(new MediaType("text", "plain", StandardCharsets.UTF_8))
                .header("Cache-Control", "no-cache")
                .body(body);
    }
}