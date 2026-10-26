-- =====================================================
-- FashionShop - FILE 3/5: DU LIEU MA GIAM GIA, GIO HANG + YEU THICH
-- MariaDB >= 11.7. File nay chi nap du lieu mau, KHONG tao bang va KHONG xoa database.
--
-- Phai chay fashion1.sql va fashion2.sql truoc. Chay file nay sau fashion2.sql.
-- File nap 6 ma giam gia, du lieu gio hang va danh sach san pham yeu thich de kiem thu.
--
-- Cach dung: mo trong HeidiSQL, Ctrl+A roi F9. DUNG chay trong IntelliJ (loi GSS-API).
-- =====================================================

SET NAMES utf8mb4;

USE fashionshop;

-- ================= MÃ GIẢM GIÁ (6 mã, đủ các trường hợp) =================
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status) VALUES
    -- Dùng được. Giảm 10%, trần 100.000đ, đơn từ 300.000đ. used_count = 1 vì đơn FS20261010001 (fashion4) đang dùng.
    ('GIAM10', 'Giảm 10% đơn từ 300K (tối đa 100K)', 'PERCENT', 10.00, 100000.00, 300000.00, 100, 1,
     DATE_SUB(NOW(6), INTERVAL 30 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE'),

    -- Dùng được. Giảm cố định 50.000đ, đơn từ 500.000đ. used_count = 1 vì đơn FS20261021001 (fashion4) đang dùng.
    ('GIAM50K', 'Giảm 50K đơn từ 500K', 'FIXED_AMOUNT', 50000.00, NULL, 500000.00, 50, 1,
     DATE_SUB(NOW(6), INTERVAL 30 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE'),

    -- Admin đã tạm ngừng (status INACTIVE) -> không được áp dụng dù còn hạn.
    ('TAMNGUNG', 'Mã đang tạm ngừng', 'PERCENT', 15.00, 150000.00, NULL, 100, 0,
     DATE_SUB(NOW(6), INTERVAL 30 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'INACTIVE'),

    -- Đã quá hạn (end_date là 10 ngày trước) -> báo mã hết hạn.
    ('HETHAN', 'Mã đã hết hạn', 'PERCENT', 20.00, 200000.00, NULL, 100, 0,
     DATE_SUB(NOW(6), INTERVAL 60 DAY), DATE_SUB(NOW(6), INTERVAL 10 DAY), 'ACTIVE'),

    -- Chưa tới ngày bắt đầu (start_date là 10 ngày sau) -> báo mã chưa có hiệu lực.
    ('CHUABATDAU', 'Mã sắp diễn ra', 'FIXED_AMOUNT', 100000.00, NULL, 1000000.00, 100, 0,
     DATE_ADD(NOW(6), INTERVAL 10 DAY), DATE_ADD(NOW(6), INTERVAL 40 DAY), 'ACTIVE'),

    -- Chỉ có 1 lượt và đã dùng hết (used_count = quantity). Lượt đó là của đơn FS20261002001 (fashion4).
    ('HETLUOT', 'Mã đã hết lượt dùng', 'FIXED_AMOUNT', 30000.00, NULL, NULL, 1, 1,
     DATE_SUB(NOW(6), INTERVAL 30 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE');


-- ================= GIỎ HÀNG =================
-- khach1: món cuối thuộc sản phẩm đang BỊ ẨN (cardigan) -> test giỏ có sản phẩm không còn bán.
-- khach2: món cuối đã HẾT HÀNG (tồn = 0)               -> test chặn thanh toán khi giỏ có món hết hàng.
-- khach3, khach4: không có dòng nào -> test giỏ hàng trống.
INSERT INTO cart_item (user_profile_id, variant_id, quantity, added_at) VALUES
    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     (SELECT id FROM product_variant WHERE sku = 'AT-BASIC-TR-L'), 2, DATE_SUB(NOW(6), INTERVAL 2 DAY)),
    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     (SELECT id FROM product_variant WHERE sku = 'CV-XEPLY-KEM-M'), 1, DATE_SUB(NOW(6), INTERVAL 2 DAY)),
    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     (SELECT id FROM product_variant WHERE sku = 'AL-CARDI-XAM-M'), 1, DATE_SUB(NOW(6), INTERVAL 1 DAY)),

    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
     (SELECT id FROM product_variant WHERE sku = 'QJ-ONGRONG-M'), 1, DATE_SUB(NOW(6), INTERVAL 3 DAY)),
    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
     (SELECT id FROM product_variant WHERE sku = 'AT-OVER-D-S'), 1, DATE_SUB(NOW(6), INTERVAL 3 DAY));


-- ================= YÊU THÍCH =================
-- khach1: sản phẩm cuối là cardigan đang BỊ ẨN -> test yêu thích có sản phẩm không còn bán.
-- khach3, khach4: không có dòng nào -> test danh sách yêu thích trống.
INSERT INTO wishlist_item (user_profile_id, product_id, added_at) VALUES
    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     (SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be'), DATE_SUB(NOW(6), INTERVAL 5 DAY)),
    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     (SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel'), DATE_SUB(NOW(6), INTERVAL 4 DAY)),
    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
     (SELECT id FROM product WHERE name = 'Áo len cardigan màu xám (đang ẩn)'), DATE_SUB(NOW(6), INTERVAL 1 DAY)),

    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
     (SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro'), DATE_SUB(NOW(6), INTERVAL 6 DAY)),
    ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
     (SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu'), DATE_SUB(NOW(6), INTERVAL 2 DAY));


-- ================= KIEM TRA SAU KHI CHAY (dung: 6, 5, 5) =================
SELECT COUNT(*) AS so_coupon   FROM coupon;
SELECT COUNT(*) AS so_gio_hang FROM cart_item;
SELECT COUNT(*) AS so_yeu_thich FROM wishlist_item;
