
-- =====================================================
-- FashionShop - FILE 5/5: DU LIEU LICH SU KHO
-- MariaDB >= 11.7. File nay chi nap du lieu mau, KHONG tao bang va KHONG xoa database.
--
-- Phai chay fashion1.sql, fashion2.sql va fashion4.sql truoc. Chay file nay sau fashion4.sql.
-- File nap lich su nhap hang, ban hang, dieu chinh va hoan kho khi huy don de kiem thu ton kho.
--
-- Cach dung: mo trong HeidiSQL, Ctrl+A roi F9. DUNG chay trong IntelliJ (loi GSS-API).
-- =====================================================

SET NAMES utf8mb4;

USE fashionshop;

-- ================= LỊCH SỬ KHO =================
-- Mỗi biến thể được liệt kê theo thứ tự thời gian (cũ -> mới) để dễ đọc.
INSERT INTO stock_history (variant_id, type, quantity_change, stock_after, supplier, import_price, reason, order_id, performed_by_id, created_at) VALUES

    -- ---- Áo thun basic trắng M: nhập 42, bán 2 (đơn 1) -> còn 40 ----
    ((SELECT id FROM product_variant WHERE sku = 'AT-BASIC-TR-M'), 'IMPORT', 42, 42, 'Xưởng may Hòa Phát', 150000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'AT-BASIC-TR-M'), 'SALE', -2, 40, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261010001'), NULL, DATE_SUB(NOW(6), INTERVAL 12 DAY)),

    -- ---- Áo thun basic đen M: nhập 30, kiểm kê trừ 4 hàng lỗi, bán 1 (đơn 1) -> còn 25 ----
    ((SELECT id FROM product_variant WHERE sku = 'AT-BASIC-D-M'), 'IMPORT', 30, 30, 'Xưởng may Hòa Phát', 150000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'AT-BASIC-D-M'), 'ADJUSTMENT', -4, 26, NULL, NULL, 'Kiểm kê kho: phát hiện 4 áo bị lỗi đường may',
     NULL, (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin2@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 15 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'AT-BASIC-D-M'), 'SALE', -1, 25, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261010001'), NULL, DATE_SUB(NOW(6), INTERVAL 12 DAY)),

    -- ---- Đầm lụa be M: nhập 10, nhập thêm 6 (giá nhập khác), bán 1 (đơn 2) -> còn 15 ----
    ((SELECT id FROM product_variant WHERE sku = 'DAM-LUA-BE-M'), 'IMPORT', 10, 10, 'Công ty TNHH Dệt may Sài Gòn', 900000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'DAM-LUA-BE-M'), 'IMPORT', 6, 16, 'Công ty TNHH Dệt may Sài Gòn', 920000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 25 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'DAM-LUA-BE-M'), 'SALE', -1, 15, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261019001'), NULL, DATE_SUB(NOW(6), INTERVAL 3 DAY)),

    -- ---- Sơ mi linen trắng S: nhập 21, bán 1 (đơn 2) -> còn 20 ----
    ((SELECT id FROM product_variant WHERE sku = 'SM-LINEN-TR-S'), 'IMPORT', 21, 21, 'Công ty TNHH Dệt may Sài Gòn', 360000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'SM-LINEN-TR-S'), 'SALE', -1, 20, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261019001'), NULL, DATE_SUB(NOW(6), INTERVAL 3 DAY)),

    -- ---- Quần tây đen M: nhập 17, bán 1 (đơn 3, đang PENDING nhưng kho đã trừ) -> còn 16 ----
    ((SELECT id FROM product_variant WHERE sku = 'QT-ONGDUNG-D-M'), 'IMPORT', 17, 17, 'Xưởng may Tân Phú', 480000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'QT-ONGDUNG-D-M'), 'SALE', -1, 16, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261021001'), NULL, DATE_SUB(NOW(6), INTERVAL 1 DAY)),

    -- ---- Blazer nam xám L: nhập 9, bán 1 (đơn 4), đơn 4 bị hủy -> cộng lại, còn 9 ----
    ((SELECT id FROM product_variant WHERE sku = 'BLAZER-NAM-XAM-L'), 'IMPORT', 9, 9, 'Xưởng may Tân Phú', 1300000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'BLAZER-NAM-XAM-L'), 'SALE', -1, 8, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261016001'), NULL, DATE_SUB(NOW(6), INTERVAL 6 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'BLAZER-NAM-XAM-L'), 'CANCELLED_ORDER', 1, 9, NULL, NULL, 'Đơn FS20261016001 bị hủy: thanh toán ví điện tử thất bại',
     (SELECT id FROM orders WHERE order_code = 'FS20261016001'), NULL, DATE_SUB(NOW(6), INTERVAL 5 DAY)),

    -- ---- Áo khoác denim L: nhập 12, bán 1 (đơn 5), đơn 5 bị hủy -> cộng lại, còn 12 ----
    ((SELECT id FROM product_variant WHERE sku = 'AK-DENIM-L'), 'IMPORT', 12, 12, 'Xưởng may Tân Phú', 750000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'AK-DENIM-L'), 'SALE', -1, 11, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261013001'), NULL, DATE_SUB(NOW(6), INTERVAL 9 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'AK-DENIM-L'), 'CANCELLED_ORDER', 1, 12, NULL, NULL, 'Đơn FS20261013001 bị hủy: khách tự hủy',
     (SELECT id FROM orders WHERE order_code = 'FS20261013001'), NULL, DATE_SUB(NOW(6), INTERVAL 8 DAY)),

    -- ---- Áo thun oversize đen M: nhập 23, bán 1 (đơn 6) -> còn 22 ----
    ((SELECT id FROM product_variant WHERE sku = 'AT-OVER-D-M'), 'IMPORT', 23, 23, 'Xưởng may Hòa Phát', 180000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'AT-OVER-D-M'), 'SALE', -1, 22, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261002001'), NULL, DATE_SUB(NOW(6), INTERVAL 20 DAY)),

    -- ---- Quần short kaki xanh rêu L: nhập 17, bán 1 (đơn 6) -> còn 16 ----
    ((SELECT id FROM product_variant WHERE sku = 'QS-KAKI-REU-L'), 'IMPORT', 17, 17, 'Xưởng may Tân Phú', 260000.00, NULL, NULL,
     (SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'admin1@fashionshop.vn'), DATE_SUB(NOW(6), INTERVAL 40 DAY)),
    ((SELECT id FROM product_variant WHERE sku = 'QS-KAKI-REU-L'), 'SALE', -1, 16, NULL, NULL, NULL,
     (SELECT id FROM orders WHERE order_code = 'FS20261002001'), NULL, DATE_SUB(NOW(6), INTERVAL 20 DAY));


-- ================= KIEM TRA SAU KHI CHAY (dung: 22, 0) =================
SELECT COUNT(*) AS so_dong_lich_su FROM stock_history;
-- Dòng mới nhất của mỗi biến thể phải bằng tồn kho hiện tại. PHẢI ra 0 (nếu > 0 thì có biến thể bị lệch kho).
SELECT COUNT(*) AS so_bien_the_lech_kho
FROM product_variant v
JOIN stock_history h ON h.id = (SELECT MAX(id) FROM stock_history WHERE variant_id = v.id)
WHERE h.stock_after <> v.stock_quantity;
