package com.iuh.fashionshop.service.ai;

import java.util.function.Consumer;

/**
 * Giao diện trừu tượng cho các mô hình AI Chatbot (Ollama, Gemini, ...).
 * bất kỳ con AI nào muốn gắn vào shop thì bắt buộc phải có 2 hàm là
 * generate() (trả lời 1 cục) và stream() (trả lời từng chữ).
 * để sau này có dùng chatgpt hay claude gì đó để (kiểu như spring AI á)
 */
public interface ChatModelClient {

    /**
     * Sinh câu trả lời đồng bộ.
     *
     * @param systemPrompt Chỉ dẫn hệ thống
     * @param userPrompt   Nội dung prompt kèm ngữ cảnh từ người dùng
     * @return Chuỗi câu trả lời hoàn chỉnh
     */
    String generate(String systemPrompt, String userPrompt);

    /**
     * Sinh câu trả lời dạng stream (đẩy từng phần văn bản về consumer).
     *
     * @param systemPrompt Chỉ dẫn hệ thống
     * @param userPrompt   Nội dung prompt kèm ngữ cảnh từ người dùng
     * @param out          Consumer nhận từng đoạn văn bản
     */
    void stream(String systemPrompt, String userPrompt, Consumer<String> out);
}
