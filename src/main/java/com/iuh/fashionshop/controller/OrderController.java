package com.iuh.fashionshop.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Trang "Đơn hàng của tôi": lấy đơn hàng thật theo tài khoản đang đăng nhập. */
@Controller
@RequestMapping("/orders")
public class OrderController {

    // Nhóm trạng thái cho từng tab. Sửa cho khớp với enum trạng thái đơn hàng của bạn.
    private static final Map<String, List<String>> TABS = new LinkedHashMap<>();
    static {
        TABS.put("processing", List.of("PENDING", "CONFIRMED", "PROCESSING"));
        TABS.put("shipping", List.of("SHIPPING"));
        TABS.put("completed", List.of("COMPLETED", "DELIVERED"));
        TABS.put("cancelled", List.of("CANCELLED"));
    }

    private final JdbcTemplate jdbc;

    public OrderController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping
    public String list(@RequestParam(defaultValue = "all") String status,
                       Authentication auth, Model model) {

        String tab = TABS.containsKey(status) ? status : "all";
        model.addAttribute("currentTab", tab);

        // Lấy profile của tài khoản đang đăng nhập
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT up.id AS profileId
                FROM account a JOIN user_profile up ON up.account_id = a.id
                WHERE a.email = ?
                """, auth.getName());
        Object profileId = rows.isEmpty() ? null : rows.get(0).get("profileId");

        long totalCount = 0, wishlistCount = 0;
        Map<String, Long> tabCounts = new LinkedHashMap<>();
        TABS.keySet().forEach(k -> tabCounts.put(k, 0L));
        List<Map<String, Object>> orders = new ArrayList<>();

        if (profileId != null) {
            // Đếm số đơn theo từng nhóm trạng thái
            for (Map<String, Object> r : jdbc.queryForList(
                    "SELECT status, COUNT(*) AS cnt FROM orders WHERE user_profile_id = ? GROUP BY status", profileId)) {
                long cnt = ((Number) r.get("cnt")).longValue();
                totalCount += cnt;
                for (Map.Entry<String, List<String>> e : TABS.entrySet()) {
                    if (e.getValue().contains(String.valueOf(r.get("status")))) {
                        tabCounts.merge(e.getKey(), cnt, Long::sum);
                    }
                }
            }

            Long wl = jdbc.queryForObject("SELECT COUNT(*) FROM wishlist_item WHERE user_profile_id = ?", Long.class, profileId);
            wishlistCount = wl == null ? 0 : wl;

            // Danh sách đơn theo tab (giá trị IN lấy từ hằng số ở trên, không lấy từ người dùng)
            String sql = """
                    SELECT id, order_code AS orderCode, status, total_amount AS totalAmount,
                           payment_method AS paymentMethod, DATE_FORMAT(created_at, '%d/%m/%Y') AS createdAt
                    FROM orders WHERE user_profile_id = ?
                    """;
            if (!tab.equals("all")) {
                String in = String.join(",", TABS.get(tab).stream().map(s -> "'" + s + "'").toList());
                sql += " AND status IN (" + in + ")";
            }
            sql += " ORDER BY created_at DESC";
            orders = jdbc.queryForList(sql, profileId);

            // Sản phẩm trong từng đơn
            for (Map<String, Object> o : orders) {
                o.put("items", jdbc.queryForList("""
                        SELECT oi.product_name AS productName, oi.size AS size, oi.color AS color,
                               oi.unit_price AS unitPrice, oi.quantity AS quantity, p.image_url AS imageUrl
                        FROM order_item oi
                        LEFT JOIN product_variant pv ON pv.id = oi.variant_id
                        LEFT JOIN product p ON p.id = pv.product_id
                        WHERE oi.order_id = ?
                        """, o.get("id")));
            }
        }

        model.addAttribute("orders", orders);
        model.addAttribute("totalCount", totalCount);
        model.addAttribute("tabCounts", tabCounts);
        model.addAttribute("orderCount", totalCount);
        model.addAttribute("wishlistCount", wishlistCount);
        return "user/orders";
    }
}