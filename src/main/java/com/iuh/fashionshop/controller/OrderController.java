package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.OrderItem;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.repository.OrderRepository;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Trang "Đơn hàng của tôi": danh sách, lọc theo trạng thái, xem chi tiết và hủy
 * đơn hàng PENDING.
 */
@Controller
@RequestMapping("/orders")
public class OrderController {

    // Nhóm trạng thái cho từng tab
    private static final Map<String, List<String>> TABS = new LinkedHashMap<>();
    static {
        TABS.put("pending", List.of("PENDING"));
        TABS.put("confirmed", List.of("CONFIRMED", "PROCESSING"));
        TABS.put("shipping", List.of("SHIPPING"));
        TABS.put("completed", List.of("COMPLETED", "DELIVERED"));
        TABS.put("cancelled", List.of("CANCELLED"));
    }

    private final JdbcTemplate jdbc;
    private final OrderRepository orderRepository;
    private final UserProfileRepository userProfileRepository;
    private final ProductVariantRepository productVariantRepository;

    public OrderController(JdbcTemplate jdbc,
            OrderRepository orderRepository,
            UserProfileRepository userProfileRepository,
            ProductVariantRepository productVariantRepository) {
        this.jdbc = jdbc;
        this.orderRepository = orderRepository;
        this.userProfileRepository = userProfileRepository;
        this.productVariantRepository = productVariantRepository;
    }

    @GetMapping
    public String list(@RequestParam(defaultValue = "all") String status,
            Authentication auth, Model model) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }

        String tab = TABS.containsKey(status) ? status : "all";
        model.addAttribute("currentTab", tab);

        // Lấy profile của tài khoản đang đăng nhập
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT up.id AS profileId
                FROM account a JOIN user_profile up ON up.account_id = a.id
                WHERE a.email = ?
                """, auth.getName().trim().toLowerCase());
        Object profileId = rows.isEmpty() ? null : rows.get(0).get("profileId");

        long totalCount = 0, wishlistCount = 0;
        Map<String, Long> tabCounts = new LinkedHashMap<>();
        TABS.keySet().forEach(k -> tabCounts.put(k, 0L));
        List<Map<String, Object>> orders = new ArrayList<>();

        if (profileId != null) {
            // Đếm số đơn theo từng nhóm trạng thái
            for (Map<String, Object> r : jdbc.queryForList(
                    "SELECT status, COUNT(*) AS cnt FROM orders WHERE user_profile_id = ? GROUP BY status",
                    profileId)) {
                long cnt = ((Number) r.get("cnt")).longValue();
                totalCount += cnt;
                for (Map.Entry<String, List<String>> e : TABS.entrySet()) {
                    if (e.getValue().contains(String.valueOf(r.get("status")))) {
                        tabCounts.merge(e.getKey(), cnt, Long::sum);
                    }
                }
            }

            Long wl = jdbc.queryForObject("SELECT COUNT(*) FROM wishlist_item WHERE user_profile_id = ?", Long.class,
                    profileId);
            wishlistCount = wl == null ? 0 : wl;

            // Danh sách đơn theo tab
            String sql = """
                    SELECT id, order_code AS orderCode, status, total_amount AS totalAmount,
                           payment_method AS paymentMethod, DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') AS createdAt,
                           recipient_name AS recipientName, recipient_phone AS recipientPhone, shipping_address AS shippingAddress
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
                o.put("canCancel", "PENDING".equalsIgnoreCase(String.valueOf(o.get("status"))));
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

    @GetMapping("/{id}")
    public String detail(@PathVariable Long id,
            Authentication auth,
            Model model,
            RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        String email = auth.getName().trim().toLowerCase();
        UserProfile userProfile = userProfileRepository.findByAccountEmail(email).orElse(null);
        if (userProfile == null) {
            ra.addFlashAttribute("errorMessage", "Không tìm thấy thông tin tài khoản.");
            return "redirect:/orders";
        }

        Order order = orderRepository.findByIdWithDetails(id).orElse(null);
        if (order == null || !order.getUserProfile().getId().equals(userProfile.getId())) {
            ra.addFlashAttribute("errorMessage", "Không tìm thấy đơn hàng yêu cầu.");
            return "redirect:/orders";
        }

        long wishlistCount = jdbc.queryForObject("SELECT COUNT(*) FROM wishlist_item WHERE user_profile_id = ?",
                Long.class, userProfile.getId());
        long orderCount = orderRepository.countByUserProfileId(userProfile.getId());

        model.addAttribute("order", order);
        model.addAttribute("canCancel", order.canBeCancelled());
        model.addAttribute("orderCount", orderCount);
        model.addAttribute("wishlistCount", wishlistCount);
        return "user/order-detail";
    }

    @PostMapping("/cancel/{id}")
    @Transactional
    public String cancelOrder(@PathVariable Long id,
            @RequestParam(required = false, defaultValue = "Khách hàng tự hủy đơn") String reason,
            Authentication auth,
            RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        String email = auth.getName().trim().toLowerCase();
        UserProfile userProfile = userProfileRepository.findByAccountEmail(email).orElse(null);
        if (userProfile == null) {
            ra.addFlashAttribute("errorMessage", "Không tìm thấy thông tin tài khoản.");
            return "redirect:/orders";
        }

        Order order = orderRepository.findByIdWithDetails(id).orElse(null);
        if (order == null || !order.getUserProfile().getId().equals(userProfile.getId())) {
            ra.addFlashAttribute("errorMessage", "Không tìm thấy đơn hàng để hủy.");
            return "redirect:/orders";
        }

        if (!order.canBeCancelled()) {
            ra.addFlashAttribute("errorMessage",
                    "Đơn hàng đang ở trạng thái '" + order.getStatus() + "', không thể hủy.");
            return "redirect:/orders/" + id;
        }

        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledAt(LocalDateTime.now());
        order.setCancelReason(reason != null && !reason.isBlank() ? reason.trim() : "Khách hàng tự hủy đơn");

        // Hoàn lại tồn kho cho các biến thể
        for (OrderItem item : order.getItems()) {
            if (item.getVariant() != null) {
                item.getVariant().increaseStock(item.getQuantity());
                productVariantRepository.save(item.getVariant());
            }
        }

        orderRepository.save(order);
        ra.addFlashAttribute("successMessage", "Đã hủy đơn hàng #" + order.getOrderCode() + " thành công!");
        return "redirect:/orders/" + id;
    }
}
