-- ============================================================================
-- FASHION SHOP - MIGRATION CẬP NHẬT TÍNH NĂNG MÃ GIẢM GIÁ (COUPON NÂNG CAO)
-- Mục đích:
--   Bổ sung 4 cột mới và khóa ngoại cho bảng `coupon` để hỗ trợ:
--   1. Mã Freeship (Miễn phí vận chuyển)
--   2. Mã theo đối tượng khách hàng (Tất cả, Khách mới đặt đơn đầu, Khách VIP)
--   3. Giới hạn số lần áp dụng trên mỗi tài khoản khách hàng (per_user_limit)
--   4. Mã giới hạn theo danh mục sản phẩm (applicable_category_id)
--
-- DÀNH CHO: Những ai ĐÃ CÓ DATABASE và KHÔNG MUỐN reset/xóa dữ liệu cũ.
--           (Nếu tạo lại database từ đầu thì chỉ cần chạy từ fashion1.sql).
--
-- Cách dùng: Mở trong HeidiSQL hoặc DBeaver, chọn database `fashionshop`,
--            nhấn Ctrl+A rồi F9 để thực thi.
-- ============================================================================

USE fashionshop;

-- 1. Bổ sung các cột mới vào bảng `coupon` (nếu chưa có)
SET @exist_col := (SELECT COUNT(*) FROM information_schema.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                     AND TABLE_NAME = 'coupon' 
                     AND COLUMN_NAME = 'per_user_limit');

SET @sql_alter := IF(@exist_col = 0,
    'ALTER TABLE coupon
        ADD COLUMN description TEXT NULL AFTER name,
        ADD COLUMN per_user_limit INT NOT NULL DEFAULT 1 AFTER used_count,
        ADD COLUMN target_customer_type VARCHAR(20) NOT NULL DEFAULT \'ALL\' AFTER per_user_limit,
        ADD COLUMN applicable_category_id BIGINT NULL AFTER target_customer_type',
    'SELECT \'Cac cot moi da ton tai trong bang coupon.\' AS message');

PREPARE stmt FROM @sql_alter;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Thêm khóa ngoại liên kết tới bảng `category`
SET @exist_fk := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS 
                  WHERE CONSTRAINT_SCHEMA = DATABASE() 
                    AND TABLE_NAME = 'coupon' 
                    AND CONSTRAINT_NAME = 'fk_coupon_category');

SET @sql_fk := IF(@exist_fk = 0,
    'ALTER TABLE coupon 
        ADD CONSTRAINT fk_coupon_category 
        FOREIGN KEY (applicable_category_id) REFERENCES category(id) 
        ON DELETE SET NULL',
    'SELECT \'Khoa ngoai fk_coupon_category da ton tai.\' AS message');

PREPARE stmt_fk FROM @sql_fk;
EXECUTE stmt_fk;
DEALLOCATE PREPARE stmt_fk;

-- 3. Chuẩn hóa dữ liệu cho các mã giảm giá cũ đã có trong database
UPDATE coupon 
SET per_user_limit = 1 
WHERE per_user_limit IS NULL OR per_user_limit <= 0;

UPDATE coupon 
SET target_customer_type = 'ALL' 
WHERE target_customer_type IS NULL OR target_customer_type = '';

-- 4. Thêm 2 mã giảm giá mẫu để kiểm thử tính năng mới (FREESHIP & Khách mới)
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, per_user_limit, target_customer_type, applicable_category_id, start_date, end_date, status)
VALUES 
    ('FREESHIP', 'Miễn phí vận chuyển toàn quốc đơn từ 200K', 'FREESHIP', 0.00, NULL, 200000.00, 100, 0, 1, 'ALL', NULL, DATE_SUB(NOW(6), INTERVAL 5 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE'),
    ('KHACHMOI', 'Ưu đãi khách hàng mới giảm 20% (đơn đầu tiên)', 'PERCENT', 20.00, 100000.00, 150000.00, 100, 0, 1, 'NEW_CUSTOMER', NULL, DATE_SUB(NOW(6), INTERVAL 5 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE')
ON DUPLICATE KEY UPDATE name = VALUES(name);

SELECT 'MIGRATION THANH CONG! Bang coupon da duoc cap nhat day du tinh nang moi.' AS status;
