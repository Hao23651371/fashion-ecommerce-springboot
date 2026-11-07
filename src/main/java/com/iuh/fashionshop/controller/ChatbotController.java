package com.iuh.fashionshop.controller;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UncheckedIOException;
import java.io.Writer;
import java.nio.charset.StandardCharsets;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import java.util.Map;
import java.util.HashMap;
import java.text.NumberFormat;
import java.util.Locale;

import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import com.iuh.fashionshop.service.ChatbotService;

@RestController
@RequestMapping("/api/chatbot")
public class ChatbotController {

    public record ChatRequest(String message, Long productId) {}

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
        Long productId = req != null ? req.productId() : null;
        StreamingResponseBody body = out -> {
            Writer w = new OutputStreamWriter(out, StandardCharsets.UTF_8);
            if (msg.isEmpty()) {
                w.write("Bạn muốn hỏi gì về sản phẩm nào ạ?");
                w.flush();
                return;
            }
            // chổ này đẩy tưng chữ ra màn hình này còn if trên nếu nó rổng thì nó tự đẩy câu kia á
            chatbotService.streamReply(msg, productId, chunk -> {
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

    /**
     * API LẤY THÔNG TIN THẺ SẢN PHẨM PHỤC VỤ HIỂN THỊ TRONG CHATBOX:
     * - Trả về: Ảnh sản phẩm, tên, giá bán, giá gốc, % giảm, danh mục, tồn kho.
     * - Dùng để hiển thị card sản phẩm đẹp mắt (ảnh bên trái, thông tin bên phải, link bên dưới).
     */
    @GetMapping("/product/{id}")
    public ResponseEntity<?> getProductSummary(@PathVariable Long id) {
        var p = chatbotService.getProductDetail(id);
        if (p == null) {
            return ResponseEntity.notFound().build();
        }
        NumberFormat nf = NumberFormat.getIntegerInstance(Locale.of("vi", "VN"));
        Map<String, Object> data = new HashMap<>();
        data.put("id", p.id());
        data.put("name", p.name());
        data.put("categoryName", p.categoryName() != null ? p.categoryName() : "");
        data.put("imageUrl", p.imageUrl() != null ? p.imageUrl() : "");
        data.put("onSale", p.onSale());
        data.put("discountPercent", p.discountPercent());
        data.put("totalStock", p.totalStock());
        data.put("currentPrice", p.currentPrice());
        data.put("currentPriceFormatted", nf.format(p.currentPrice()) + "đ");
        if (p.onSale() && p.price() != null) {
            data.put("priceFormatted", nf.format(p.price()) + "đ");
        }
        return ResponseEntity.ok(data);
    }

}
