package com.iuh.fashionshop.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Gọi Ollama (chạy local) để biến văn bản thành vector. Mô hình mặc định: bge-m3 (1024 chiều). */
@Component
public class OllamaEmbeddingClient {

    // Giữ lại để code cũ không phải sửa; bge-m3 không phân biệt loại tác vụ.
    public static final String TASK_DOCUMENT = "RETRIEVAL_DOCUMENT";
    public static final String TASK_QUERY = "RETRIEVAL_QUERY";

    private final RestClient restClient;
    private final String baseUrl;
    private final String model;
    private final int dimensions;

    public OllamaEmbeddingClient(@Value("${ollama.base-url:http://localhost:11434}") String baseUrl,
                                 @Value("${ollama.embedding.model:bge-m3}") String model,
                                 @Value("${ollama.embedding.dimensions:1024}") int dimensions) {
        this.baseUrl = baseUrl == null ? "" : baseUrl.trim();
        this.model = model;
        this.dimensions = dimensions;

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(3));
        factory.setReadTimeout(Duration.ofSeconds(60)); // lần gọi đầu Ollama phải nạp mô hình nên chậm

        this.restClient = RestClient.builder()
                .baseUrl(this.baseUrl)
                .requestFactory(factory)
                .build();
    }

    public boolean isConfigured() {
        return !baseUrl.isBlank();
    }

    /** Kiểm tra Ollama có đang chạy không. */
    public boolean isReachable() {
        try {
            restClient.get().uri("/api/tags").retrieve().toBodilessEntity();
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public int getDimensions() {
        return dimensions;
    }

    @SuppressWarnings("unchecked")
    public List<Double> embed(String text, String taskType) {
        if (!isConfigured()) {
            throw new IllegalStateException("Chưa cấu hình ollama.base-url trong application-local.properties");
        }

        // 3 dòng này Đóng gói dữ liệu gửi đi (Request Body)
        //Tạo một đối tượng Map để Spring tự động chuyển thành chuỗi JSON gửi cho Ollama
        //ví dụ model: bge
        // input: áo thun màu đen đẹp
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", model);
        body.put("input", text);

        Map<String, Object> response;
        try {
            //Gửi HTTP POST tới endpoint /api/embed
            response = restClient.post()
                    .uri("/api/embed")
                    .contentType(MediaType.APPLICATION_JSON)//áo cho server Ollama biết dữ liệu gửi lên là định dạng JSOn
                    .body(body)// đưa map chưa model và input thì spring tự chuyển map thành chuỗi JSON
                    .retrieve()//gửi HTTP request thực sự sang Ollama và chờ nhận phản hồi
                    .body(new ParameterizedTypeReference<Map<String, Object>>() {});//Đọc chuỗi JSON kết quả mà Ollama trả về và chuyển ngược lại thành đối tượng
        } catch (RestClientException e) {
            throw new IllegalStateException("Không gọi được Ollama tại " + baseUrl
                    + " (đã bật Ollama và chạy 'ollama pull " + model + "' chưa?): " + e.getMessage(), e);
        }

        if (response == null || !(response.get("embeddings") instanceof List<?> all) || all.isEmpty()
                || !(all.get(0) instanceof List<?> values)) {
            throw new IllegalStateException("Phản hồi Ollama không có embeddings");
        }
        return ((List<Number>) values).stream().map(Number::doubleValue).toList();
    }
}