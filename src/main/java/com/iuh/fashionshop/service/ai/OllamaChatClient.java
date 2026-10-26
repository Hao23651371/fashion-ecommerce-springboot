package com.iuh.fashionshop.service.ai;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Triển khai ChatModelClient gọi mô hình Ollama cục bộ qua REST API.
 */
@Component
public class OllamaChatClient implements ChatModelClient {

    private static final Logger log = LoggerFactory.getLogger(OllamaChatClient.class);

    private static final String KEEP_ALIVE = "60m";
    private static final Map<String, Object> CHAT_OPTIONS = Map.of(
            "temperature", 0.3,
            "num_ctx", 2048,
            "num_predict", 350
    );

    private final RestClient ollama;
    private final String chatModel;

    public OllamaChatClient(@Value("${ollama.base-url:http://localhost:11434}") String baseUrl,
                            @Value("${ollama.chat.model:qwen2.5:3b}") String chatModel,
                            @Value("${ollama.chat.timeout-seconds:120}") int timeoutSeconds) {
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(5));
        factory.setReadTimeout(Duration.ofSeconds(timeoutSeconds));
        this.ollama = RestClient.builder()
                .baseUrl(baseUrl == null ? "" : baseUrl.trim())
                .requestFactory(factory)
                .build();
        this.chatModel = chatModel;
    }

    public void warmUp() {
        try {
            ollama.post().uri("/api/chat")
                    .body(Map.of("model", chatModel, "keep_alive", KEEP_ALIVE, "options", CHAT_OPTIONS))
                    .retrieve().toBodilessEntity();
            log.info("Đã làm nóng model chat Ollama {}", chatModel);
        } catch (Exception e) {
            log.warn("Không làm nóng được model chat Ollama: {}", e.getMessage());
        }
    }

    @Override
    public String generate(String systemPrompt, String userPrompt) {
        StringBuilder sb = new StringBuilder();
        stream(systemPrompt, userPrompt, sb::append);
        return sb.toString().trim();
    }

    @Override
    public void stream(String systemPrompt, String userPrompt, Consumer<String> out) {
        Map<String, Object> body = Map.of(
                "model", chatModel,
                "stream", true,
                "keep_alive", KEEP_ALIVE,
                "options", CHAT_OPTIONS,
                "messages", List.of(
                        Map.of("role", "system", "content", systemPrompt),
                        Map.of("role", "user", "content", userPrompt)
                )
        );

        ollama.post().uri("/api/chat").body(body).exchange((req, res) -> {
            if (res.getStatusCode().isError()) {
                throw new IllegalStateException("Ollama trả về HTTP " + res.getStatusCode());
            }
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(res.getBody(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) {
                    if (line.isBlank()) {
                        continue;
                    }
                    String piece = extractContent(line);
                    if (piece != null && !piece.isEmpty()) {
                        String clean = piece.replaceAll("[\\p{IsHan}]+", "");
                        if (!clean.isEmpty()) {
                            out.accept(clean);
                        }
                    }
                    if (line.contains("\"done\":true")) {
                        break;
                    }
                }
            } catch (Exception e) {
                throw new RuntimeException("Lỗi đọc stream từ Ollama: " + e.getMessage(), e);
            }
            return null;
        });
    }

    private static String extractContent(String line) {
        String key = "\"content\":\"";
        int i = line.indexOf(key);
        if (i < 0) {
            return null;
        }
        i += key.length();
        StringBuilder sb = new StringBuilder();
        while (i < line.length()) {
            char c = line.charAt(i++);
            if (c == '"') {
                break;
            }
            if (c == '\\' && i < line.length()) {
                char n = line.charAt(i++);
                switch (n) {
                    case 'n' -> sb.append('\n');
                    case 't' -> sb.append('\t');
                    case 'r' -> { }
                    case 'u' -> {
                        if (i + 4 <= line.length()) {
                            sb.append((char) Integer.parseInt(line.substring(i, i + 4), 16));
                            i += 4;
                        }
                    }
                    default -> sb.append(n);
                }
            } else {
                sb.append(c);
            }
        }
        return sb.toString();
    }
}
