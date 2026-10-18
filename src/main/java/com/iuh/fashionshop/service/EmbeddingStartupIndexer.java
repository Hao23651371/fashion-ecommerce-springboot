package com.iuh.fashionshop.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/** Khi app khởi động: tự tạo vector cho các sản phẩm chưa có vector (nếu đã cấu hình khóa API). */
@Component
public class EmbeddingStartupIndexer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(EmbeddingStartupIndexer.class);

    private final ProductSearchService searchService;

    public EmbeddingStartupIndexer(ProductSearchService searchService) {
        this.searchService = searchService;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!searchService.isAvailable()) {
            log.warn("Bỏ qua tạo vector: chưa cấu hình ollama.base-url");
            return;
        }
        try {
            searchService.reindex(false);
        } catch (Exception e) {
            // Không để lỗi vector làm app không khởi động được
            log.error("Tạo vector khi khởi động thất bại: {}", e.getMessage());
        }
    }
}