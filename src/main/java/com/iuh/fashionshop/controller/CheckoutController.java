package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.CartItem;
import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.OrderItem;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.ShippingAddress;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.CouponStatus;
import com.iuh.fashionshop.model.enums.CustomerTargetType;
import com.iuh.fashionshop.model.enums.DiscountType;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.model.enums.PaymentMethod;
import com.iuh.fashionshop.model.enums.PaymentStatus;
import com.iuh.fashionshop.model.enums.StockMovementType;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.CouponRepository;
import com.iuh.fashionshop.repository.OrderRepository;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import com.iuh.fashionshop.repository.ShippingAddressRepository;
import com.iuh.fashionshop.service.CartService;
import com.iuh.fashionshop.service.InventoryService;
import com.iuh.fashionshop.service.OrderService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Thanh toán. Cần đăng nhập (đã cấu hình trong SecurityConfig).
 *
 * Hai chế độ:
 *  - Mua ngay:  /checkout?variantId=...&quantity=...  -> chỉ thanh toán đúng 1 món đó,
 *               KHÔNG đụng tới giỏ hàng (không ghi gì vào bảng cart_item).
 *  - Từ giỏ:    /checkout                              -> thanh toán toàn bộ giỏ hàng.
 */
@Controller
@RequestMapping("/checkout")
public class CheckoutController {

    private static final BigDecimal SHIPPING_FEE = new BigDecimal("30000");

    private final CartService cartService;
    private final ProductVariantRepository productVariantRepository;
    private final OrderRepository orderRepository;
    private final CouponRepository couponRepository;
    private final ShippingAddressRepository shippingAddressRepository;
    private final OrderService orderService;
    private final InventoryService inventoryService;

    // Thông tin tài khoản nhận tiền (đổi trong application.properties, xem hướng dẫn)
    @Value("${shop.bank.id:MB}")
    private String bankId;
    @Value("${shop.bank.name:MB Bank (Ngân hàng Quân đội)}")
    private String bankName;
    @Value("${shop.bank.account:0000000000}")
    private String bankAccount;
    @Value("${shop.bank.holder:FASHION SHOP}")
    private String bankHolder;
    @Value("${shop.bank.memo:FASHIONSHOP}")
    private String bankMemo;

    public CheckoutController(CartService cartService,
                              ProductVariantRepository productVariantRepository,
                              OrderRepository orderRepository,
                              CouponRepository couponRepository,
                              ShippingAddressRepository shippingAddressRepository,
                              OrderService orderService,
                              InventoryService inventoryService) {
        this.cartService = cartService;
        this.productVariantRepository = productVariantRepository;
        this.orderRepository = orderRepository;
        this.couponRepository = couponRepository;
        this.shippingAddressRepository = shippingAddressRepository;
        this.orderService = orderService;
        this.inventoryService = inventoryService;
    }

    @GetMapping
    public String index(@RequestParam(required = false) Long variantId,
                        @RequestParam(required = false) Long productId,
                        @RequestParam(defaultValue = "1") int quantity,
                        Authentication auth,
                        Model model,
                        RedirectAttributes redirectAttributes) {

        if (variantId == null && productId != null) {
            List<ProductVariant> variants = productVariantRepository.findByProductId(productId);
            ProductVariant chosen = variants.stream()
                    .filter(v -> v.getStatus() == VariantStatus.ACTIVE && v.getStockQuantity() > 0)
                    .findFirst()
                    .orElse(null);
            if (chosen != null) {
                variantId = chosen.getId();
            } else {
                redirectAttributes.addFlashAttribute("errorMessage", "Sản phẩm này hiện đang tạm hết hàng hoặc chưa mở bán.");
                return "redirect:/shop/" + productId;
            }
        }

        List<CartItem> items;
        boolean buyNow = variantId != null;

        if (buyNow) {
            // ===== MUA NGAY: chỉ 1 sản phẩm, không dùng giỏ hàng =====
            ProductVariant variant = productVariantRepository.findByIdWithProduct(variantId).orElse(null);
            if (variant == null
                    || variant.getStatus() != VariantStatus.ACTIVE
                    || variant.getStockQuantity() <= 0) {
                redirectAttributes.addFlashAttribute("errorMessage", "Sản phẩm này hiện không thể mua.");
                return "redirect:/shop";
            }

            int qty = Math.max(1, Math.min(quantity, variant.getStockQuantity()));

            // CartItem tạm trong bộ nhớ (KHÔNG save) để tái sử dụng giao diện checkout
            CartItem temp = new CartItem();
            temp.setVariant(variant);
            temp.setQuantity(qty);
            items = List.of(temp);

            model.addAttribute("buyNow", true);
            model.addAttribute("buyNowVariantId", variant.getId());
            model.addAttribute("buyNowQuantity", qty);
            if (variant.getProduct() != null) {
                model.addAttribute("buyNowProductId", variant.getProduct().getId());
            } else if (productId != null) {
                model.addAttribute("buyNowProductId", productId);
            }
        } else {
            // ===== THANH TOÁN TỪ GIỎ HÀNG =====
            items = cartService.getCartItems(auth);
            if (items.isEmpty()) {
                return "redirect:/cart";
            }
            model.addAttribute("buyNow", false);
        }

        BigDecimal subtotal = BigDecimal.ZERO;
        for (CartItem item : items) {
            subtotal = subtotal.add(item.calculateSubtotal());
        }

        model.addAttribute("cartItems", items);
        model.addAttribute("cartSubtotal", subtotal);
        model.addAttribute("shippingFee", SHIPPING_FEE);
        model.addAttribute("grandTotal", subtotal.add(SHIPPING_FEE));

        // Thông tin + mã QR chuyển khoản (VietQR, đã điền sẵn số tiền & nội dung)
        model.addAttribute("bankName", bankName);
        model.addAttribute("bankAccount", bankAccount);
        model.addAttribute("bankHolder", bankHolder);
        model.addAttribute("bankMemo", bankMemo);
        model.addAttribute("bankQrUrl", buildQrUrl(subtotal.add(SHIPPING_FEE)));

        UserProfile profile = cartService.getOrCreateProfile(auth);
        model.addAttribute("profile", profile);

        // Danh sách mã giảm giá đang dùng được để khách chọn nhanh (đã kiểm tra lượt dùng của tài khoản)
        model.addAttribute("availableCoupons", buildCouponOptions(subtotal, profile, items));
        // Địa chỉ đã lưu: mặc định đứng đầu
        model.addAttribute("addresses", profile == null
                ? List.<ShippingAddress>of()
                : shippingAddressRepository.findByUserProfileIdOrderByDefaultAddressDescIdDesc(profile.getId()));
        return "user/checkout";
    }

    /**
     * Đặt hàng.
     *  - Có buyNowVariantId: chỉ tạo đơn từ đúng món đó, KHÔNG đụng tới giỏ hàng.
     *  - Không có: tạo đơn từ toàn bộ giỏ hàng rồi xoá giỏ.
     */
    @PostMapping
    @Transactional(noRollbackFor = {IllegalArgumentException.class})
    public String placeOrder(@RequestParam String recipientName,
                             @RequestParam String recipientPhone,
                             @RequestParam(required = false) String addressOption,   // id địa chỉ đã lưu, hoặc "new"
                             @RequestParam(required = false) String newAddress,      // nội dung nếu chọn "new"
                             @RequestParam(defaultValue = "false") boolean saveAsDefault,
                             @RequestParam(required = false) String note,
                             @RequestParam(defaultValue = "COD") String paymentMethod,
                             @RequestParam(required = false) String couponCode,
                             @RequestParam(required = false) Long buyNowVariantId,
                             @RequestParam(defaultValue = "1") int buyNowQuantity,
                             Authentication auth,
                             RedirectAttributes ra) {

        boolean buyNow = buyNowVariantId != null;
        String backUrl = buyNow
                ? "redirect:/checkout?variantId=" + buyNowVariantId + "&quantity=" + buyNowQuantity
                : "redirect:/checkout";

        UserProfile profile = cartService.getOrCreateProfile(auth);
        if (profile == null) {
            return "redirect:/login";
        }

        // ---- Kiểm tra thông tin giao hàng ----
        String name = recipientName == null ? "" : recipientName.trim();
        String phone = recipientPhone == null ? "" : recipientPhone.trim().replaceAll("\\s+", "");
        if (name.isEmpty()) {
            ra.addFlashAttribute("errorMessage", "Vui lòng nhập họ tên người nhận.");
            return backUrl;
        }

        // ---- Địa chỉ nhận hàng: chọn địa chỉ đã lưu hoặc nhập địa chỉ mới ----
        String address;
        boolean isNewAddress = "new".equals(addressOption);
        if (isNewAddress) {
            address = newAddress == null ? "" : newAddress.trim();
            if (address.isEmpty()) {
                ra.addFlashAttribute("errorMessage", "Vui lòng nhập địa chỉ nhận hàng mới.");
                return backUrl;
            }
            if (address.length() > 255) {
                ra.addFlashAttribute("errorMessage", "Địa chỉ quá dài (tối đa 255 ký tự).");
                return backUrl;
            }
        } else {
            ShippingAddress saved = null;
            try {
                saved = addressOption == null ? null
                        : shippingAddressRepository.findById(Long.valueOf(addressOption)).orElse(null);
            } catch (NumberFormatException ignored) {
                // để saved = null, báo lỗi bên dưới
            }
            // Chỉ cho dùng địa chỉ thuộc về chính tài khoản này
            if (saved == null || !saved.getUserProfile().getId().equals(profile.getId())) {
                ra.addFlashAttribute("errorMessage", "Vui lòng chọn địa chỉ nhận hàng.");
                return backUrl;
            }
            address = saved.getAddress();
        }
        if (!phone.matches("^\\+?[0-9]{9,14}$")) {
            ra.addFlashAttribute("errorMessage", "Số điện thoại không hợp lệ.");
            return backUrl;
        }

        PaymentMethod method;
        try {
            method = PaymentMethod.valueOf(paymentMethod);
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("errorMessage", "Phương thức thanh toán không hợp lệ.");
            return backUrl;
        }

        // ---- Lấy danh sách món cần mua: (variantId, quantity) ----
        List<ProductVariant> variants = new ArrayList<>();
        List<Integer> quantities = new ArrayList<>();

        if (buyNow) {
            ProductVariant v = productVariantRepository.findByIdWithProduct(buyNowVariantId).orElse(null);
            if (v == null) {
                ra.addFlashAttribute("errorMessage", "Sản phẩm không tồn tại.");
                return "redirect:/shop";
            }
            variants.add(v);
            quantities.add(Math.max(1, buyNowQuantity));
        } else {
            List<CartItem> cartItems = cartService.getCartItems(auth);
            if (cartItems.isEmpty()) {
                return "redirect:/cart";
            }
            for (CartItem ci : cartItems) {
                variants.add(ci.getVariant());
                quantities.add(ci.getQuantity());
            }
        }

        // ---- Tạo đơn hàng ----
        Order order = new Order();
        order.setOrderCode(generateOrderCode());
        order.setUserProfile(profile);
        order.setStatus(OrderStatus.PENDING);

        order.getShippingInfo().setRecipientName(name);
        order.getShippingInfo().setRecipientPhone(phone);
        order.getShippingInfo().setShippingAddress(address);
        order.getShippingInfo().setShippingFee(SHIPPING_FEE);
        order.getShippingInfo().setNote(note == null || note.isBlank() ? null : note.trim());
        order.getPaymentInfo().setPaymentMethod(method);

        for (int i = 0; i < variants.size(); i++) {
            ProductVariant v = variants.get(i);
            int qty = quantities.get(i);

            if (v.getStatus() != VariantStatus.ACTIVE || !v.isInStock(qty)) {
                ra.addFlashAttribute("errorMessage", "Sản phẩm \"" + v.getProduct().getName()
                        + "\" (" + v.getColor() + " - " + v.getSize() + ") không đủ hàng.");
                return buyNow ? "redirect:/shop" : "redirect:/cart";
            }

            OrderItem oi = new OrderItem();
            oi.setVariant(v);
            oi.setProductName(v.getProduct().getName());
            oi.setSize(v.getSize());
            oi.setColor(v.getColor());
            oi.setUnitPrice(v.getProduct().getCurrentPrice());
            oi.setQuantity(qty);
            order.addItem(oi);
        }

        // ---- Mã giảm giá (nếu có) ----
        BigDecimal subtotal = order.getItems().stream()
                .map(OrderItem::calculateSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        Coupon coupon = null;
        if (couponCode != null && !couponCode.isBlank()) {
            List<Long> catIds = variants.stream()
                    .filter(v -> v.getProduct() != null && v.getProduct().getCategory() != null)
                    .map(v -> v.getProduct().getCategory().getId())
                    .distinct()
                    .toList();
            try {
                coupon = orderService.validateCoupon(couponCode.trim(), subtotal, profile, catIds);
                order.setCoupon(coupon);
            } catch (Exception e) {
                ra.addFlashAttribute("errorMessage", e.getMessage());
                return backUrl;
            }
        }

        order.recalculateTotal();

        // ---- Trừ tồn kho (có @Version nên hai người mua cùng lúc sẽ không bị âm kho) ----
        try {
            for (OrderItem oi : order.getItems()) {
                ProductVariant v = oi.getVariant();
                v.decreaseStock(oi.getQuantity());
                productVariantRepository.saveAndFlush(v);
            }
        } catch (IllegalStateException | org.springframework.orm.ObjectOptimisticLockingFailureException e) {
            // Huỷ toàn bộ thay đổi tồn kho đã trừ trước đó trong giao dịch này
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
            ra.addFlashAttribute("errorMessage", "Sản phẩm vừa hết hàng hoặc có người khác vừa mua, vui lòng thử lại.");
            return buyNow ? "redirect:/shop" : "redirect:/cart";
        }

        if (coupon != null) {
            coupon.setUsedCount(coupon.getUsedCount() + 1);
            couponRepository.save(coupon);
        }

        // ---- Lưu địa chỉ mới vào tài khoản (sau khi mọi kiểm tra đã qua) ----
        if (isNewAddress) {
            saveNewAddress(profile, address, saveAsDefault);
        }

        Order saved = orderRepository.save(order);

        // Ghi lịch sử kho (SALE) cho từng sản phẩm trong đơn -> trang Kho sẽ có dữ liệu
        for (OrderItem oi : saved.getItems()) {
            inventoryService.recordOrderMovement(oi.getVariant(), StockMovementType.SALE,
                    -oi.getQuantity(), saved, "Bán hàng - đơn " + saved.getOrderCode());
        }

        // Chỉ xoá giỏ hàng khi thanh toán từ giỏ. Mua ngay thì giữ nguyên giỏ.
        if (!buyNow) {
            cartService.clearCart(auth);
        }

        // Ví điện tử: sang cổng thanh toán giả lập
        if (method == PaymentMethod.E_WALLET) {
            return "redirect:/checkout/payment/" + order.getId();
        }

        ra.addFlashAttribute("successMessage", "Đặt hàng thành công! Mã đơn: " + order.getOrderCode());
        return "redirect:/orders/" + order.getId();
    }

    // ================= Cổng thanh toán ví điện tử (GIẢ LẬP) =================

    /** Thời gian chờ thanh toán ví điện tử (phút). Quá hạn -> đơn tự huỷ khi khách mở lại trang. */
    private static final int WALLET_EXPIRE_MINUTES = 10;

    @GetMapping("/payment/{id}")
    public String paymentGateway(@PathVariable Long id,
                                 Authentication auth,
                                 Model model,
                                 RedirectAttributes ra) {
        UserProfile profile = cartService.getOrCreateProfile(auth);
        if (profile == null) {
            return "redirect:/login";
        }

        // Chỉ chủ đơn mới được vào cổng thanh toán của đơn đó
        Order order = orderRepository.findByIdWithDetails(id).orElse(null);
        if (order == null || !order.getUserProfile().getId().equals(profile.getId())) {
            ra.addFlashAttribute("errorMessage", "Không tìm thấy đơn hàng.");
            return "redirect:/orders";
        }

        // Đã thanh toán / đã huỷ / không phải ví điện tử -> không cần cổng thanh toán
        boolean payable = order.getPaymentInfo().getPaymentMethod() == PaymentMethod.E_WALLET
                && order.getPaymentInfo().getPaymentStatus() == PaymentStatus.UNPAID
                && order.getStatus() == OrderStatus.PENDING;
        if (!payable) {
            return "redirect:/orders/" + id;
        }

        // Quá hạn -> huỷ đơn (hoàn kho, hoàn mã giảm giá)
        long remaining = Duration.between(LocalDateTime.now(),
                order.getCreatedAt().plusMinutes(WALLET_EXPIRE_MINUTES)).getSeconds();
        if (remaining <= 0) {
            try {
                orderService.failOnlinePayment(id, auth);
            } catch (Exception ignored) {
                // đơn đã được xử lý ở nơi khác
            }
            ra.addFlashAttribute("errorMessage",
                    "Đơn " + order.getOrderCode() + " đã quá hạn thanh toán và bị hủy.");
            return "redirect:/orders/" + id;
        }

        model.addAttribute("order", order);
        model.addAttribute("orderId", id);
        model.addAttribute("remainingSeconds", remaining);
        model.addAttribute("expireMinutes", WALLET_EXPIRE_MINUTES);
        return "user/payment-gateway";
    }

    @PostMapping("/payment/{id}/success")
    public String paymentSuccess(@PathVariable Long id, Authentication auth, RedirectAttributes ra) {
        try {
            orderService.confirmOnlinePayment(id, auth);
            ra.addFlashAttribute("successMessage", "Thanh toán thành công (giả lập)!");
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/orders/" + id;
    }

    @PostMapping("/payment/{id}/fail")
    public String paymentFail(@PathVariable Long id, Authentication auth, RedirectAttributes ra) {
        try {
            orderService.failOnlinePayment(id, auth);
            ra.addFlashAttribute("errorMessage", "Thanh toán thất bại. Đơn hàng đã bị hủy.");
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/orders/" + id;
    }

    /** Một mã giảm giá hiển thị cho khách chọn nhanh ở trang thanh toán. */
    public static class CouponOption {
        private final String code;
        private final String name;
        private final String description;
        private final String expiry;
        private final boolean eligible;
        private final String reason;   // lý do chưa áp dụng được (nếu có)
        private final long discount;   // số tiền giảm ước tính cho đơn hiện tại
        private final DiscountType discountType;

        public CouponOption(String code, String name, String description, String expiry,
                            boolean eligible, String reason, long discount, DiscountType discountType) {
            this.code = code;
            this.name = name;
            this.description = description;
            this.expiry = expiry;
            this.eligible = eligible;
            this.reason = reason;
            this.discount = discount;
            this.discountType = discountType;
        }

        public String getCode() { return code; }
        public String getName() { return name; }
        public String getDescription() { return description; }
        public String getExpiry() { return expiry; }
        public boolean isEligible() { return eligible; }
        public String getReason() { return reason; }
        public long getDiscount() { return discount; }
        public DiscountType getDiscountType() { return discountType; }
    }

    private List<CouponOption> buildCouponOptions(BigDecimal subtotal, UserProfile profile,
                                                   List<CartItem> cartItems) {
        List<CouponOption> result = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        List<Coupon> activeCoupons = couponRepository.findActiveCoupons(CouponStatus.ACTIVE, now);

        for (Coupon c : activeCoupons) {
            boolean eligible = true;
            String reason = null;

            // 1. Kiểm tra số lượng mã toàn hệ thống
            if (c.getQuantity() > 0 && c.getUsedCount() >= c.getQuantity()) {
                eligible = false;
                reason = "Mã đã hết lượt sử dụng";
            }

            // 2. Kiểm tra giới hạn số lần dùng của từng khách hàng (per_user_limit)
            if (eligible && profile != null && profile.getId() != null) {
                int limit = c.getPerUserLimit() > 0 ? c.getPerUserLimit() : 1;
                long usedByUser = orderRepository.countByUserProfileIdAndCouponIdAndStatusNot(
                        profile.getId(), c.getId(), OrderStatus.CANCELLED);
                if (usedByUser >= limit) {
                    eligible = false;
                    reason = "Mã đã hết lượt sử dụng";
                }
            }

            // 3. Kiểm tra đối tượng khách hàng (CustomerTargetType)
            if (eligible && profile != null && profile.getId() != null) {
                if (c.getTargetCustomerType() == CustomerTargetType.NEW_CUSTOMER) {
                    long totalOrders = orderRepository.countByUserProfileId(profile.getId());
                    if (totalOrders > 0) {
                        eligible = false;
                        reason = "Chỉ cho khách hàng mới";
                    }
                }
            }

            // 4. Kiểm tra đơn hàng tối thiểu
            if (eligible && c.getMinOrderValue() != null && subtotal.compareTo(c.getMinOrderValue()) < 0) {
                eligible = false;
                reason = "Đơn tối thiểu " + money(c.getMinOrderValue());
            }

            // Mã giới hạn danh mục phải bị vô hiệu hóa ngay khi hiển thị nếu
            // giỏ hàng không có sản phẩm thuộc danh mục đó.
            BigDecimal eligibleSubtotal = subtotal;
            if (eligible && c.getApplicableCategory() != null) {
                Long targetCategoryId = c.getApplicableCategory().getId();
                eligibleSubtotal = cartItems.stream()
                        .filter(item -> item.getVariant() != null
                                && item.getVariant().getProduct() != null
                                && item.getVariant().getProduct().getCategory() != null
                                && targetCategoryId.equals(item.getVariant().getProduct().getCategory().getId()))
                        .map(CartItem::calculateSubtotal)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
                if (eligibleSubtotal.signum() <= 0) {
                    eligible = false;
                    reason = "Không áp dụng cho sản phẩm trong đơn";
                }
            }

            // 5. Kiểm tra thời gian bắt đầu
            if (eligible && c.getStartDate() != null && now.isBefore(c.getStartDate())) {
                eligible = false;
                reason = "Chưa đến thời gian áp dụng";
            }

            String desc;
            if (c.getDiscountType() == DiscountType.PERCENT) {
                desc = "Giảm " + c.getDiscountValue().stripTrailingZeros().toPlainString() + "%";
                if (c.getMaxDiscount() != null) {
                    desc += " (tối đa " + money(c.getMaxDiscount()) + ")";
                }
            } else if (c.getDiscountType() == DiscountType.FREESHIP) {
                if (c.getDiscountValue() == null || c.getDiscountValue().compareTo(BigDecimal.ZERO) <= 0) {
                    desc = "Freeship 100%";
                } else {
                    desc = "Freeship tối đa " + money(c.getDiscountValue());
                }
            } else {
                desc = "Giảm " + money(c.getDiscountValue());
            }

            if (eligible && c.getMinOrderValue() != null && c.getMinOrderValue().signum() > 0) {
                desc += " · đơn từ " + money(c.getMinOrderValue());
            }

            long discount = eligible
                    ? (c.getDiscountType() == DiscountType.FREESHIP
                        ? c.calculateShippingDiscount(SHIPPING_FEE).longValue()
                        : c.calculateDiscount(eligibleSubtotal).longValue())
                    : 0L;

            String expiry = "HSD " + c.getEndDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
            result.add(new CouponOption(c.getCode(), c.getName(), desc, expiry, eligible, reason, discount,
                    c.getDiscountType()));
        }
        // Mã dùng được lên trước, mã không dùng được xuống sau
        result.sort((a, b) -> Boolean.compare(b.isEligible(), a.isEligible()));
        return result;
    }

    private static String money(BigDecimal v) {
        return String.format(Locale.US, "%,d", v.longValue()) + " ₫";
    }

    /** Link ảnh QR VietQR có sẵn số tiền + nội dung chuyển khoản. */
    private String buildQrUrl(BigDecimal amount) {
        String memo = java.net.URLEncoder.encode(bankMemo, java.nio.charset.StandardCharsets.UTF_8);
        String holder = java.net.URLEncoder.encode(bankHolder, java.nio.charset.StandardCharsets.UTF_8);
        return "https://img.vietqr.io/image/" + bankId + "-" + bankAccount + "-compact2.png"
                + "?amount=" + amount.toBigInteger()
                + "&addInfo=" + memo
                + "&accountName=" + holder;
    }

    /** Lưu địa chỉ mới cho tài khoản. Địa chỉ đầu tiên luôn là mặc định; trùng địa chỉ cũ thì không lưu lại. */
    private void saveNewAddress(UserProfile profile, String address, boolean makeDefault) {
        List<ShippingAddress> existing =
                shippingAddressRepository.findByUserProfileIdOrderByDefaultAddressDescIdDesc(profile.getId());

        ShippingAddress duplicate = existing.stream()
                .filter(a -> a.getAddress().trim().equalsIgnoreCase(address))
                .findFirst().orElse(null);

        boolean becomeDefault = makeDefault || existing.isEmpty();
        if (duplicate != null) {
            if (makeDefault && !duplicate.isDefaultAddress()) {
                shippingAddressRepository.resetDefaultAddress(profile.getId());
                duplicate.setDefaultAddress(true);
                shippingAddressRepository.save(duplicate);
            }
            return;
        }

        if (becomeDefault) {
            shippingAddressRepository.resetDefaultAddress(profile.getId());
        }
        ShippingAddress addr = new ShippingAddress();
        addr.setUserProfile(profile);
        addr.setAddress(address);
        addr.setDefaultAddress(becomeDefault);
        shippingAddressRepository.save(addr);
    }

    private String generateOrderCode() {
        String time = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyMMddHHmmss"));
        int rnd = ThreadLocalRandom.current().nextInt(100, 1000);
        return "FS" + time + rnd;
    }
}