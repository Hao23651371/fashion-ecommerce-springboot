
-- =====================================================
-- FashionShop - FILE 4/5: DU LIEU DON HANG + CHI TIET DON HANG
-- MariaDB >= 11.7. File nay chi nap du lieu mau, KHONG tao bang va KHONG xoa database.
--
-- Phai chay fashion1.sql, fashion2.sql va fashion3.sql truoc. Chay file nay sau fashion3.sql.
-- File nap 6 don hang o nhieu trang thai va 9 dong chi tiet de kiem thu thanh toan, ma giam gia.
--
-- Cach dung: mo trong HeidiSQL, Ctrl+A roi F9. DUNG chay trong IntelliJ (loi GSS-API).
-- =====================================================

SET NAMES utf8mb4;

USE fashionshop;

-- ================= ĐƠN HÀNG =================
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    cancel_reason, created_at, completed_at, cancelled_at,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note,
                    payment_method, payment_status, paid_at) VALUES

    -- Đơn 1: COMPLETED, COD đã trả lúc nhận hàng, dùng mã GIAM10 (10% = 87.000đ, chưa chạm trần), nhiều món.
    -- 870.000 - 87.000 + 30.000 = 813.000
    ('FS20261010001',
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     (SELECT id FROM coupon WHERE code = 'GIAM10'),
     'COMPLETED', 870000.00, 87000.00, 813000.00,
     NULL, DATE_SUB(NOW(6), INTERVAL 12 DAY), DATE_SUB(NOW(6), INTERVAL 8 DAY), NULL,
     'Trần Thị Mai', '0912000001', '12 Nguyễn Văn Bảo, Phường 4, Quận Gò Vấp, TP. Hồ Chí Minh', 30000.00, 'Giao giờ hành chính',
     'COD', 'PAID', DATE_SUB(NOW(6), INTERVAL 8 DAY)),

    -- Đơn 2: SHIPPING, chuyển khoản đã trả, không dùng mã, miễn phí ship (từ 1 triệu), nhiều món.
    -- 2.280.000 - 0 + 0 = 2.280.000
    ('FS20261019001',
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     NULL,
     'SHIPPING', 2280000.00, 0.00, 2280000.00,
     NULL, DATE_SUB(NOW(6), INTERVAL 3 DAY), NULL, NULL,
     'Trần Thị Mai', '0912000001', '45 Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh', 0.00, NULL,
     'BANK_TRANSFER', 'PAID', DATE_SUB(NOW(6), INTERVAL 3 DAY)),

    -- Đơn 3: PENDING, COD chưa trả, dùng mã GIAM50K (giảm cố định), đơn 1 món.
    -- 890.000 - 50.000 + 30.000 = 870.000
    ('FS20261021001',
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
     (SELECT id FROM coupon WHERE code = 'GIAM50K'),
     'PENDING', 890000.00, 50000.00, 870000.00,
     NULL, DATE_SUB(NOW(6), INTERVAL 1 DAY), NULL, NULL,
     'Lê Văn Hùng', '0912000002', '88 Trần Hưng Đạo, Phường 2, Quận 5, TP. Hồ Chí Minh', 30000.00, 'Gọi trước khi giao',
     'COD', 'UNPAID', NULL),

    -- Đơn 4: CANCELLED vì ví điện tử thanh toán lỗi (FAILED). Mã GIAM10 bị chạm trần: 10% = 235.000đ nhưng chỉ giảm 100.000đ.
    -- Đã hủy nên mã GIAM10 được trả lại lượt dùng. 2.350.000 - 100.000 + 0 = 2.250.000
    ('FS20261016001',
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
     (SELECT id FROM coupon WHERE code = 'GIAM10'),
     'CANCELLED', 2350000.00, 100000.00, 2250000.00,
     'Thanh toán ví điện tử thất bại', DATE_SUB(NOW(6), INTERVAL 6 DAY), NULL, DATE_SUB(NOW(6), INTERVAL 5 DAY),
     'Lê Văn Hùng', '0912000002', '88 Trần Hưng Đạo, Phường 2, Quận 5, TP. Hồ Chí Minh', 0.00, NULL,
     'E_WALLET', 'FAILED', NULL),

    -- Đơn 5: CANCELLED do khách tự hủy khi còn PENDING, COD nên vẫn UNPAID, không dùng mã.
    -- 1.390.000 - 0 + 0 = 1.390.000
    ('FS20261013001',
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     NULL,
     'CANCELLED', 1390000.00, 0.00, 1390000.00,
     'Khách đổi ý, muốn đặt lại size khác', DATE_SUB(NOW(6), INTERVAL 9 DAY), NULL, DATE_SUB(NOW(6), INTERVAL 8 DAY),
     'Trần Thị Mai', '0912000001', '12 Nguyễn Văn Bảo, Phường 4, Quận Gò Vấp, TP. Hồ Chí Minh', 0.00, NULL,
     'COD', 'UNPAID', NULL),

    -- Đơn 6: COMPLETED, ví điện tử đã trả, dùng mã HETLUOT (lượt duy nhất của mã này), nhiều món.
    -- 819.000 - 30.000 + 30.000 = 819.000
    ('FS20261002001',
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
     (SELECT id FROM coupon WHERE code = 'HETLUOT'),
     'COMPLETED', 819000.00, 30000.00, 819000.00,
     NULL, DATE_SUB(NOW(6), INTERVAL 20 DAY), DATE_SUB(NOW(6), INTERVAL 16 DAY), NULL,
     'Lê Văn Hùng', '0912000002', '88 Trần Hưng Đạo, Phường 2, Quận 5, TP. Hồ Chí Minh', 30000.00, NULL,
     'E_WALLET', 'PAID', DATE_SUB(NOW(6), INTERVAL 20 DAY));


-- ================= CHI TIẾT ĐƠN HÀNG =================
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
    -- Đơn 1 (870.000): 2 * 290.000 + 1 * 290.000
    ((SELECT id FROM orders WHERE order_code = 'FS20261010001'), (SELECT id FROM product_variant WHERE sku = 'AT-BASIC-TR-M'),
     'Áo thun cotton basic cổ tròn màu trắng', 'M', 'Trắng', 290000.00, 2),
    ((SELECT id FROM orders WHERE order_code = 'FS20261010001'), (SELECT id FROM product_variant WHERE sku = 'AT-BASIC-D-M'),
     'Áo thun cotton basic cổ tròn màu trắng', 'M', 'Đen', 290000.00, 1),

    -- Đơn 2 (2.280.000): đầm lụa đang giảm giá 1.590.000 + sơ mi linen 690.000
    ((SELECT id FROM orders WHERE order_code = 'FS20261019001'), (SELECT id FROM product_variant WHERE sku = 'DAM-LUA-BE-M'),
     'Đầm lụa dáng dài màu be', 'M', 'Be', 1590000.00, 1),
    ((SELECT id FROM orders WHERE order_code = 'FS20261019001'), (SELECT id FROM product_variant WHERE sku = 'SM-LINEN-TR-S'),
     'Áo sơ mi linen trắng tối giản', 'S', 'Trắng', 690000.00, 1),

    -- Đơn 3 (890.000): 1 món
    ((SELECT id FROM orders WHERE order_code = 'FS20261021001'), (SELECT id FROM product_variant WHERE sku = 'QT-ONGDUNG-D-M'),
     'Quần tây ống đứng màu đen', 'M', 'Đen', 890000.00, 1),

    -- Đơn 4 (2.350.000): 1 món
    ((SELECT id FROM orders WHERE order_code = 'FS20261016001'), (SELECT id FROM product_variant WHERE sku = 'BLAZER-NAM-XAM-L'),
     'Áo blazer nam màu xám tro', 'L', 'Xám tro', 2350000.00, 1),

    -- Đơn 5 (1.390.000): 1 món
    ((SELECT id FROM orders WHERE order_code = 'FS20261013001'), (SELECT id FROM product_variant WHERE sku = 'AK-DENIM-L'),
     'Áo khoác denim xanh dáng ngắn', 'L', 'Xanh denim', 1390000.00, 1),

    -- Đơn 6 (819.000): áo thun oversize đang giảm giá 329.000 + quần short 490.000
    ((SELECT id FROM orders WHERE order_code = 'FS20261002001'), (SELECT id FROM product_variant WHERE sku = 'AT-OVER-D-M'),
     'Áo thun oversize màu đen in chữ', 'M', 'Đen', 329000.00, 1),
    ((SELECT id FROM orders WHERE order_code = 'FS20261002001'), (SELECT id FROM product_variant WHERE sku = 'QS-KAKI-REU-L'),
     'Quần short kaki nam màu xanh rêu', 'L', 'Xanh rêu', 490000.00, 1);


-- ================= KIEM TRA SAU KHI CHAY (dung: 6, 9, 0) =================
SELECT COUNT(*) AS so_don_hang  FROM orders;
SELECT COUNT(*) AS so_dong_chi_tiet FROM order_item;
-- Kiểm tra tổng tiền từng đơn có đúng công thức không. PHẢI ra 0 dòng.
SELECT COUNT(*) AS so_don_sai_tong_tien
FROM orders o
WHERE o.subtotal <> (SELECT SUM(i.unit_price * i.quantity) FROM order_item i WHERE i.order_id = o.id)
   OR o.total_amount <> o.subtotal - o.discount_amount + o.shipping_fee;
