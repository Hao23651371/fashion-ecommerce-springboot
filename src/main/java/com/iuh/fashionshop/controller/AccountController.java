package com.iuh.fashionshop.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;
import java.util.Map;

/** Trang tài khoản khách hàng: lấy dữ liệu thật từ database theo email đang đăng nhập. */
@Controller
@RequestMapping("/account")
public class AccountController {

    // Các trạng thái được tính là "đang xử lý". Sửa cho khớp với enum trạng thái đơn hàng của bạn.
    private static final String IN_PROGRESS = "'PENDING','CONFIRMED','PROCESSING','SHIPPING'";

    private final JdbcTemplate jdbc;

    public AccountController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping
    public String account(Authentication auth, Model model) {
        String email = auth.getName();

        // 1. Thông tin cá nhân (account + user_profile)
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT up.id AS profileId, up.full_name AS fullName, up.phone_number AS phone,
                       DATE_FORMAT(up.birth_date, '%d/%m/%Y') AS birthDate, a.email AS email,
                       DATE_FORMAT(a.last_login_at, '%H:%i - %d/%m/%Y') AS lastLoginAt
                FROM account a
                LEFT JOIN user_profile up ON up.account_id = a.id
                WHERE a.email = ?
                """, email);

        Map<String, Object> profile = rows.isEmpty() ? null : rows.get(0);
        model.addAttribute("profile", profile);
        model.addAttribute("email", email);

        Object profileId = profile == null ? null : profile.get("profileId");

        long processingCount = 0, orderCount = 0, wishlistCount = 0;

        if (profileId != null) {
            // 2. Các con số thống kê (chưa có dữ liệu thì là 0)
            orderCount = count("SELECT COUNT(*) FROM orders WHERE user_profile_id = ?", profileId);
            processingCount = count("SELECT COUNT(*) FROM orders WHERE user_profile_id = ? AND status IN (" + IN_PROGRESS + ")", profileId);
            wishlistCount = count("SELECT COUNT(*) FROM wishlist_item WHERE user_profile_id = ?", profileId);

            // 3. Địa chỉ mặc định
            List<Map<String, Object>> addr = jdbc.queryForList("""
                    SELECT address FROM shipping_address
                    WHERE user_profile_id = ? AND default_address = 1
                    LIMIT 1
                    """, profileId);
            model.addAttribute("defaultAddress", addr.isEmpty() ? null : addr.get(0).get("address"));
        }

        model.addAttribute("processingCount", processingCount);
        model.addAttribute("orderCount", orderCount);
        model.addAttribute("wishlistCount", wishlistCount);
        return "user/account";
    }

    private long count(String sql, Object arg) {
        Long n = jdbc.queryForObject(sql, Long.class, arg);
        return n == null ? 0 : n;
    }
}