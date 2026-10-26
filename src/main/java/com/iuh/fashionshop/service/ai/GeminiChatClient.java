package com.iuh.fashionshop.service.ai;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

/**
 * Triển khai ChatModelClient gọi Google Gemini API qua RestClient thuần không phụ thuộc thư viện ngoài.
 */
@Component
public class GeminiChatClient implements ChatModelClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiChatClient.class);
    private static final String GEMINI_BASE_URL = "https://generativelanguage.googleapis.com";
    private static final Pattern PRODUCT_ID_PATTERN = Pattern.compile("\\[Mã (\\d+)\\]");

    private final RestClient restClient;
    private final String apiKey;
    private final String model;
    private final double temperature;
    private final int maxOutputTokens;
    private final int cooldownSeconds;
    private final int cacheSeconds;

    // Cache trong bộ nhớ: tối đa 200 mục, TTL theo cacheSeconds
    private record CacheEntry(String text, long expireAtMillis) {}
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

    // Thời điểm hết hạn cooldown khi gặp lỗi 429, 5xx hoặc timeout
    private final AtomicLong cooldownUntilMillis = new AtomicLong(0);

    public GeminiChatClient(@Value("${gemini.api-key:${GEMINI_API_KEY:}}") String apiKey,
                            @Value("${gemini.model:}") String model,
                            @Value("${gemini.timeout-seconds:15}") int timeoutSeconds,
                            @Value("${gemini.max-output-tokens:350}") int maxOutputTokens,
                            @Value("${gemini.temperature:0.3}") double temperature,
                            @Value("${gemini.cooldown-seconds:60}") int cooldownSeconds,
                            @Value("${gemini.cache-seconds:600}") int cacheSeconds) {
        this.apiKey = (apiKey == null) ? "" : apiKey.trim();
        this.model = (model == null) ? "" : model.trim();
        this.temperature = temperature;
        this.maxOutputTokens = maxOutputTokens;
        this.cooldownSeconds = cooldownSeconds;
        this.cacheSeconds = cacheSeconds;

        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(5));
        factory.setReadTimeout(Duration.ofSeconds(timeoutSeconds));

        this.restClient = RestClient.builder()
                .baseUrl(GEMINI_BASE_URL)
                .requestFactory(factory)
                .build();
    }

    public boolean isConfigured() {
        return !apiKey.isBlank() && !model.isBlank();
    }

    public boolean isInCooldown() {
        return System.currentTimeMillis() < cooldownUntilMillis.get();
    }

    @Override
    public String generate(String systemPrompt, String userPrompt) {
        StringBuilder sb = new StringBuilder();
        stream(systemPrompt, userPrompt, sb::append);
        return sb.toString().trim();
    }

    @Override
    public void stream(String systemPrompt, String userPrompt, Consumer<String> out) {
        if (!isConfigured()) {
            log.warn("Gemini chưa được cấu hình đầy đủ (thiếu gemini.api-key hoặc gemini.model). Chuyển sang phương án dự phòng.");
            throw new IllegalStateException("Gemini chưa được cấu hình đầy đủ");
        }

        long now = System.currentTimeMillis();
        long cooldownUntil = cooldownUntilMillis.get();
        if (now < cooldownUntil) {
            long remainingSeconds = (cooldownUntil - now) / 1000;
            log.warn("Gemini đang trong thời gian cooldown sau lỗi (còn khoảng {}s). Dùng phương án dự phòng.", remainingSeconds);
            throw new IllegalStateException("Gemini đang trong thời gian cooldown");
        }

        // 1. Kiểm tra cache
        String cacheKey = buildCacheKey(userPrompt);
        CacheEntry cached = cache.get(cacheKey);
        if (cached != null) {
            if (now <= cached.expireAtMillis()) {
                log.info("Gemini: trúng cache câu trả lời trong bộ nhớ, bỏ qua gọi API");
                out.accept(cached.text());
                return;
            } else {
                cache.remove(cacheKey);
            }
        }

        // 2. Tạo body theo format chính thức của Gemini API
        Map<String, Object> body = Map.of(
                "systemInstruction", Map.of(
                        "parts", List.of(Map.of("text", systemPrompt))
                ),
                "contents", List.of(
                        Map.of(
                                "role", "user",
                                "parts", List.of(Map.of("text", userPrompt))
                        )
                ),
                "generationConfig", Map.of(
                        "temperature", temperature,
                        "maxOutputTokens", maxOutputTokens
                )
        );

        StringBuilder fullText = new StringBuilder();

        try {
            String path = "/v1beta/models/" + model + ":streamGenerateContent?alt=sse";
            restClient.post()
                    .uri(path)
                    .header("x-goog-api-key", apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .exchange((req, res) -> {
                        int statusCode = res.getStatusCode().value();
                        if (res.getStatusCode().isError()) {
                            handleHttpError(statusCode);
                            throw new IllegalStateException("Gemini trả về mã lỗi HTTP " + statusCode);
                        }

                        try (BufferedReader reader = new BufferedReader(
                                new InputStreamReader(res.getBody(), StandardCharsets.UTF_8))) {
                            String line;
                            while ((line = reader.readLine()) != null) {
                                if (line.startsWith("data: ")) {
                                    String json = line.substring(6).trim();
                                    if (!json.isEmpty()) {
                                        List<String> pieces = extractTexts(json);
                                        for (String piece : pieces) {
                                            out.accept(piece);
                                            fullText.append(piece);
                                        }
                                    }
                                }
                            }
                        } catch (Exception e) {
                            throw new RuntimeException("Lỗi đọc dữ liệu stream từ Gemini: " + e.getMessage(), e);
                        }
                        return null;
                    });

            // Lưu cache nếu có kết quả trả về
            if (!fullText.isEmpty()) {
                saveCache(cacheKey, fullText.toString());
            }

        } catch (RestClientResponseException e) {
            handleHttpError(e.getStatusCode().value());
            throw new RuntimeException("Gemini API phản hồi lỗi HTTP " + e.getStatusCode().value(), e);
        } catch (ResourceAccessException e) {
            cooldownUntilMillis.set(System.currentTimeMillis() + (cooldownSeconds * 1000L));
            log.warn("Gemini hết thời gian chờ (timeout) hoặc lỗi mạng, kích hoạt cooldown {}s", cooldownSeconds);
            throw new RuntimeException("Gemini API timeout hoặc mạng gián đoạn", e);
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Lỗi không xác định khi gọi Gemini: " + e.getMessage(), e);
        }
    }

    private void handleHttpError(int statusCode) {
        if (statusCode == 429 || statusCode >= 500) {
            cooldownUntilMillis.set(System.currentTimeMillis() + (cooldownSeconds * 1000L));
            log.warn("Gemini trả về HTTP {}, kích hoạt cooldown {}s", statusCode, cooldownSeconds);
        } else {
            log.warn("Gemini trả về HTTP {}", statusCode);
        }
    }

    /**
     * Trích xuất các chuỗi "text": "..." từ JSON của Gemini mà không phụ thuộc thư viện Jackson/Gson.
     */
    private static List<String> extractTexts(String json) {
        List<String> results = new ArrayList<>();
        if (json == null) {
            return results;
        }

        String marker = "\"text\":";
        int idx = 0;
        while ((idx = json.indexOf(marker, idx)) != -1) {
            idx += marker.length();
            while (idx < json.length() && Character.isWhitespace(json.charAt(idx))) {
                idx++;
            }
            if (idx >= json.length() || json.charAt(idx) != '"') {
                continue;
            }
            idx++; // Bỏ qua dấu ngoặc kép mở
            StringBuilder sb = new StringBuilder();
            while (idx < json.length()) {
                char c = json.charAt(idx++);
                if (c == '"') {
                    break;
                }
                if (c == '\\' && idx < json.length()) {
                    char next = json.charAt(idx++);
                    switch (next) {
                        case 'n' -> sb.append('\n');
                        case 't' -> sb.append('\t');
                        case 'r' -> { }
                        case '"' -> sb.append('"');
                        case '\\' -> sb.append('\\');
                        case 'u' -> {
                            if (idx + 4 <= json.length()) {
                                try {
                                    sb.append((char) Integer.parseInt(json.substring(idx, idx + 4), 16));
                                    idx += 4;
                                } catch (NumberFormatException ignored) {
                                    sb.append(next);
                                }
                            } else {
                                sb.append(next);
                            }
                        }
                        default -> sb.append(next);
                    }
                } else {
                    sb.append(c);
                }
            }
            String text = sb.toString();
            if (!text.isEmpty()) {
                results.add(text);
            }
        }
        return results;
    }

    private String buildCacheKey(String userPrompt) {
        if (userPrompt == null) {
            return "";
        }
        List<String> productIds = new ArrayList<>();
        Matcher matcher = PRODUCT_ID_PATTERN.matcher(userPrompt);
        while (matcher.find()) {
            productIds.add(matcher.group(1));
        }

        String question = userPrompt;
        int idx = userPrompt.indexOf("CÂU HỎI CỦA KHÁCH:");
        if (idx >= 0) {
            question = userPrompt.substring(idx + "CÂU HỎI CỦA KHÁCH:".length());
        }

        return question.trim().toLowerCase(Locale.ROOT) + "|ids:" + String.join(",", productIds);
    }

    private void saveCache(String key, String response) {
        if (cacheSeconds <= 0 || key.isBlank() || response.isBlank()) {
            return;
        }
        long now = System.currentTimeMillis();
        long expireAt = now + (cacheSeconds * 1000L);

        if (cache.size() >= 200) {
            cache.entrySet().removeIf(entry -> entry.getValue().expireAtMillis() < now);
            if (cache.size() >= 200) {
                var it = cache.keySet().iterator();
                int removed = 0;
                while (it.hasNext() && removed < 50) {
                    it.next();
                    it.remove();
                    removed++;
                }
            }
        }
        cache.put(key, new CacheEntry(response, expireAt));
    }
}
