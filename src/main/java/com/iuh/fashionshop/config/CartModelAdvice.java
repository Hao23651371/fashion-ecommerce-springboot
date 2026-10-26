package com.iuh.fashionshop.config;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

/**
 * Cung cấp số lượng sản phẩm trong giỏ hàng (cartCount) cho toàn bộ view Thymeleaf.
 */
@ControllerAdvice
public class CartModelAdvice {

    @ModelAttribute("cartCount")
    public int populateCartCount() {
        // TODO: người phụ trách giỏ hàng sẽ thay bằng số lượng thật
        return 0;
    }
}
