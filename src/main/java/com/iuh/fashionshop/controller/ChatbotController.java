package com.iuh.fashionshop.controller;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UncheckedIOException;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.util.Map;

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

    private static String clean(ChatRequest req) {
        String msg = (req == null || req.message() == null) ? "" : req.message().trim();
        return msg.length() > 500 ? msg.substring(0, 500) : msg;
    }

    /** Endpoint cũ (không streaming), giữ lại để không hỏng chỗ nào đang gọi. */
    @PostMapping
    public Map<String, String> chat(@RequestBody ChatRequest req) {
        String msg = clean(req);
        if (msg.isEmpty()) {
            return Map.of("reply", "Bạn muốn hỏi gì về sản phẩm nào ạ?");
        }
        return Map.of("reply", chatbotService.reply(msg));
    }

    /** Endpoint mới: trả chữ về dần dần (text/plain, chunked). */
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
            chatbotService.streamReply(msg, chunk -> {
                try {
                    w.write(chunk);
                    w.flush();   // đẩy ngay về trình duyệt
                } catch (IOException e) {
                    throw new UncheckedIOException(e);   // người dùng đóng chat thì dừng
                }
            });
        };
        return ResponseEntity.ok()
                .contentType(new MediaType("text", "plain", StandardCharsets.UTF_8))
                .header("Cache-Control", "no-cache")
                .body(body);
    }
}