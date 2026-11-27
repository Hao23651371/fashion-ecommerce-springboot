package com.iuh.fashionshop.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.OrderItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.Proxy;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Service
public class N8nWebhookService {

    private static final Logger log = LoggerFactory.getLogger(N8nWebhookService.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${n8n.webhook.enabled:true}")
    private boolean enabled;

    @Value("${n8n.webhook.order-url:http://127.0.0.1:5678/webhook/new-order}")
    private String orderWebhookUrl;

    @Value("${n8n.webhook.otp-url:}")
    private String otpWebhookUrl;

    /**
     * Gửi email OTP (đăng ký hoặc quên mật khẩu) qua webhook n8n để quản lý tự động hoàn toàn
     */
    public boolean sendOtpEmail(String eventType,
                                String toEmail,
                                String otpCode,
                                String recipientName,
                                String subject,
                                String actionText,
                                String htmlContent) {
        if (!enabled) {
            return false;
        }
        String targetUrl = resolveOtpWebhookUrl();
        if (targetUrl == null || targetUrl.isBlank()) {
            return false;
        }
        try {
            Map<String, Object> payload = new HashMap<>();
            payload.put("eventType", eventType);
            payload.put("toEmail", toEmail);
            payload.put("otpCode", otpCode);
            payload.put("recipientName", recipientName != null && !recipientName.isBlank() ? recipientName : "Quý khách");
            payload.put("subject", subject);
            payload.put("actionText", actionText);
            payload.put("htmlContent", htmlContent);

            String jsonBody = objectMapper.writeValueAsString(payload);
            return postJson(targetUrl, jsonBody, "OTP " + eventType + " -> " + toEmail);
        } catch (Exception e) {
            log.warn("Lỗi khi gửi OTP webhook sang n8n ({}): {}", toEmail, e.getMessage());
            return false;
        }
    }

    private String resolveOtpWebhookUrl() {
        if (otpWebhookUrl != null && !otpWebhookUrl.isBlank()) {
            return otpWebhookUrl.trim().replace("localhost", "127.0.0.1");
        }
        if (orderWebhookUrl != null && !orderWebhookUrl.isBlank()) {
            if (orderWebhookUrl.contains("/webhook/new-order")) {
                return orderWebhookUrl.trim().replace("localhost", "127.0.0.1").replace("/webhook/new-order", "/webhook/send-otp");
            }
            if (orderWebhookUrl.contains("/webhook-test/new-order")) {
                return orderWebhookUrl.trim().replace("localhost", "127.0.0.1").replace("/webhook-test/new-order", "/webhook-test/send-otp");
            }
        }
        return "http://127.0.0.1:5678/webhook/send-otp";
    }

    public void sendOrderNotification(Order order) {
        String defaultMsg = "Cảm ơn bạn đã đặt hàng tại FashionShop! Đơn hàng của bạn đã được ghi nhận và đang ở trạng thái CHỜ XÁC NHẬN.";
        sendOrderEvent(order, "ORDER_CREATED", defaultMsg, true);
    }

    //Gọi khi Admin đổi trạng thái đơn hàng (xác nhận, đang giao, hoàn tất, hủy)
    //gửi sự kiên qua ORDER_STATUS_UPDATED này
    public void sendOrderStatusUpdate(Order order, String actionMessage) {
        sendOrderEvent(order, "ORDER_STATUS_UPDATED", actionMessage, false);
    }

    // hàm chính gửi từng sự kiện
    private void sendOrderEvent(Order order, String eventType, String actionMessage, boolean notifyAdmin) {
        log.info("[N8N] sendOrderEvent() - Event: {} cho đơn: {}", eventType, (order != null ? order.getOrderCode() : "null"));
        if (!enabled || orderWebhookUrl == null || orderWebhookUrl.isBlank()) {
            log.info("[N8N] Webhook bị tắt hoặc chưa cấu hình URL (enabled={}, url={})", enabled, orderWebhookUrl);
            return;
        }

        try {
            Map<String, Object> payload = new HashMap<>();
            payload.put("eventType", eventType);
            payload.put("actionMessage", actionMessage);
            payload.put("notifyAdmin", notifyAdmin);
            payload.put("orderId", order.getId());
            payload.put("orderCode", order.getOrderCode());

            // Định dạng tiền tệ có dấu chấm phân cách hàng nghìn (ví dụ: 620.000)
            String formattedTotal = "0";
            if (order.getTotalAmount() != null) {
                formattedTotal = java.text.NumberFormat.getInstance(new java.util.Locale("vi", "VN")).format(order.getTotalAmount());
            }
            payload.put("totalAmount", formattedTotal);
            payload.put("totalAmountRaw", order.getTotalAmount());

            String customerEmail = "";
            if (order.getUserProfile() != null && order.getUserProfile().getAccount() != null) {
                customerEmail = order.getUserProfile().getAccount().getEmail();
            }
            payload.put("customerEmail", customerEmail);

            payload.put("recipientName", order.getShippingInfo() != null ? order.getShippingInfo().getRecipientName() : "");
            payload.put("recipientPhone", order.getShippingInfo() != null ? order.getShippingInfo().getRecipientPhone() : "");
            payload.put("shippingAddress", order.getShippingInfo() != null ? order.getShippingInfo().getShippingAddress() : "");

            // Thông tin thanh toán chi tiết
            com.iuh.fashionshop.model.enums.PaymentMethod method = order.getPaymentInfo() != null && order.getPaymentInfo().getPaymentMethod() != null
                    ? order.getPaymentInfo().getPaymentMethod() : com.iuh.fashionshop.model.enums.PaymentMethod.COD;
            payload.put("paymentMethod", method.name());
            String paymentMethodText = switch (method) {
                case BANK_TRANSFER -> "Chuyển khoản ngân hàng (QR VietQR)";
                case E_WALLET -> "Ví điện tử trực tuyến";
                default -> "Thanh toán khi nhận hàng (COD)";
            };
            payload.put("paymentMethodText", paymentMethodText);

            com.iuh.fashionshop.model.enums.PaymentStatus payStatus = order.getPaymentInfo() != null && order.getPaymentInfo().getPaymentStatus() != null
                    ? order.getPaymentInfo().getPaymentStatus() : com.iuh.fashionshop.model.enums.PaymentStatus.UNPAID;
            payload.put("paymentStatus", payStatus.name());
            payload.put("paymentStatusText", payStatus == com.iuh.fashionshop.model.enums.PaymentStatus.PAID ? "Đã thanh toán thành công" : "Chưa thanh toán (Thu tiền khi giao)");
            payload.put("isPaid", payStatus == com.iuh.fashionshop.model.enums.PaymentStatus.PAID);

            // Trạng thái đơn hàng
            com.iuh.fashionshop.model.enums.OrderStatus orderStatus = order.getStatus() != null ? order.getStatus() : com.iuh.fashionshop.model.enums.OrderStatus.PENDING;
            payload.put("orderStatus", orderStatus.name());
            String orderStatusText = switch (orderStatus) {
                case CONFIRMED -> "Đã xác nhận";
                case SHIPPING -> "Đang giao hàng";
                case COMPLETED -> "Giao hàng thành công";
                case CANCELLED -> "Đã hủy đơn";
                default -> "Chờ xác nhận";
            };
            payload.put("orderStatusText", orderStatusText);

            payload.put("createdAt", order.getCreatedAt() != null ? order.getCreatedAt().toString() : "");

            List<Map<String, Object>> items = order.getItems().stream().map(oi -> {
                Map<String, Object> itemMap = new HashMap<>();
                itemMap.put("productName", oi.getProductName());
                itemMap.put("size", oi.getSize());
                itemMap.put("color", oi.getColor());
                itemMap.put("quantity", oi.getQuantity());
                itemMap.put("unitPrice", oi.getUnitPrice());
                return itemMap;
            }).toList();
            payload.put("items", items);

            // Kiểm tra cảnh báo tồn kho thấp (nếu có biến thể nào trong đơn còn <= 5 sản phẩm)
            List<Map<String, Object>> lowStockItems = new ArrayList<>();
            for (OrderItem oi : order.getItems()) {
                if (oi.getVariant() != null && oi.getVariant().getStockQuantity() <= 5) {
                    Map<String, Object> ls = new HashMap<>();
                    ls.put("productName", oi.getProductName());
                    ls.put("size", oi.getSize());
                    ls.put("color", oi.getColor());
                    ls.put("remainingStock", oi.getVariant().getStockQuantity());
                    lowStockItems.add(ls);
                }
            }
            boolean hasLowStock = !lowStockItems.isEmpty();
            payload.put("hasLowStock", hasLowStock);
            payload.put("lowStockItems", lowStockItems);
            if (hasLowStock) {
                StringBuilder sb = new StringBuilder();
                for (Map<String, Object> ls : lowStockItems) {
                    sb.append("• <strong>").append(ls.get("productName")).append("</strong> (Màu: ").append(ls.get("color"))
                      .append(" - Size: ").append(ls.get("size")).append(") ➔ <span style='color: #dc2626; font-weight: bold;'>CHỈ CÒN ")
                      .append(ls.get("remainingStock")).append(" SẢN PHẨM</span><br>");
                }
                payload.put("lowStockHtml", sb.toString());
            } else {
                payload.put("lowStockHtml", "");
            }

            String jsonBody = objectMapper.writeValueAsString(payload);
            log.debug("[N8N] Chuẩn bị gửi payload: {}", jsonBody);

            // Tự động chuyển localhost sang 127.0.0.1 để tránh lỗi phân giải IPv6 (::1) trên Windows của Java
            String effectiveUrl = orderWebhookUrl.replace("localhost", "127.0.0.1");

            // Chỉ gửi DUY NHẤT 1 lần sang URL chính để không bị trùng lặp 2 email
            sendPost(effectiveUrl, jsonBody, order.getOrderCode(), false);
        } catch (Exception e) {
            log.warn("Lỗi khi chuẩn bị dữ liệu gửi sang n8n: {}", e.getMessage());
        }
    }

    private void sendPost(String urlStr, String jsonBody, String orderCode, boolean isTest) {
        CompletableFuture.runAsync(() -> {
            String label = (isTest ? "TEST " : "PROD ") + "đơn hàng " + orderCode;
            postJson(urlStr, jsonBody, label);
        });
    }

    private boolean postJson(String urlStr, String jsonBody, String contextLabel) {
        HttpURLConnection conn = null;
        try {
            log.debug("[N8N] Đang gửi POST tới: {}", urlStr);
            URL url = URI.create(urlStr).toURL();
            conn = (HttpURLConnection) url.openConnection(Proxy.NO_PROXY);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setRequestProperty("Accept", "application/json");
            conn.setRequestProperty("User-Agent", "FashionShop-Webhook/1.0");
            conn.setConnectTimeout(8000);
            conn.setReadTimeout(10000);
            conn.setDoOutput(true);

            byte[] bytes = jsonBody.getBytes(StandardCharsets.UTF_8);
            conn.setFixedLengthStreamingMode(bytes.length);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(bytes);
                os.flush();
            }

            int statusCode = conn.getResponseCode();
            String responseBody = "";
            try (InputStream is = (statusCode >= 200 && statusCode < 400) ? conn.getInputStream() : conn.getErrorStream()) {
                if (is != null) {
                    responseBody = new String(is.readAllBytes(), StandardCharsets.UTF_8);
                }
            }

            log.debug("[N8N] Kết quả từ {} -> HTTP {} | Body: {}", urlStr, statusCode, responseBody);
            if (statusCode >= 200 && statusCode < 300) {
                log.info("Đã gửi Webhook ({}) sang n8n thành công!", contextLabel);
                return true;
            }
            log.warn("n8n ({}) phản hồi status {}: {}", contextLabel, statusCode, responseBody);
            return false;
        } catch (Exception ex) {
            log.warn("Không thể kết nối tới n8n ({}): {}", urlStr, ex.getMessage());
            return false;
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }
}
