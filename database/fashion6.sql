-- ============================================================================
-- FASHION SHOP - FILE DỮ LIỆU MỞ RỘNG (fashion6.sql)
-- Mục đích: Bổ sung dữ liệu lớn phục vụ trang Thống kê (/admin/statistics) và
--           quản lý Tài khoản, Danh mục, Sản phẩm (100% quần áo), Biến thể,
--           Mã giảm giá, Đơn hàng, Giỏ hàng, Yêu thích & Lịch sử kho.
-- Quy mô thêm mới trong fashion6.sql:
--   + 51 Tài khoản mới: 3 ADMIN, 6 STAFF, 42 CUSTOMER (phân chia 6 nhóm rõ ràng)
--     (Tổng DB sau khi chạy fashion1..5 + fashion6: 5 ADMIN, 8 STAFF, 46 CUSTOMER = 59)
--   + 4 Danh mục quần áo mới, 14 Sản phẩm quần áo mới, 31 Biến thể, 14 Ảnh (mỗi sản phẩm 1 ảnh chính)
--   + 6 Mã giảm giá, 50 Đơn hàng (20 tháng trước + 30 tháng này), lịch sử kho đồng bộ 100%
-- Điều kiện: Chạy SAU khi đã chạy xong fashion1.sql -> fashion5.sql.
-- Tương thích: MariaDB 10.6+ / 11.7+ (HeidiSQL: Ctrl+A -> F9).
-- ============================================================================

SET NAMES utf8mb4;
USE fashionshop;

-- ============================================================================
-- 0. CHUẨN BỊ BIẾN THAM CHIẾU DỮ LIỆU CŨ (KHÔNG PHỤ THUỘC CỨNG ID)
-- ============================================================================
SET @pw_admin := '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK'; -- Admin@123
SET @pw_khach := '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye'; -- Khach@123

SET @prev_m_last_day := DATE_SUB(CURDATE(), INTERVAL DAYOFMONTH(CURDATE()) DAY);
SET @cur_m_start     := STR_TO_DATE(DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00'), '%Y-%m-%d %H:%i:%s');
SET @cur_span        := GREATEST(TIMESTAMPDIFF(SECOND, @cur_m_start, NOW(6)), 60);

SELECT up.id INTO @prof_staff1 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'staff1@fashionshop.vn' LIMIT 1;
SELECT up.id INTO @prof_khach1 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach1@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach2 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach2@gmail.com' LIMIT 1;

SELECT id INTO @cat_dam    FROM category WHERE name = 'Đầm' LIMIT 1;
SELECT id INTO @cat_somi   FROM category WHERE name = 'Áo sơ mi' LIMIT 1;
SELECT id INTO @cat_quan   FROM category WHERE name = 'Quần' LIMIT 1;
SELECT id INTO @cat_khoac  FROM category WHERE name = 'Áo khoác' LIMIT 1;
SELECT id INTO @cat_thun   FROM category WHERE name = 'Áo thun' LIMIT 1;
SELECT id INTO @cat_hoodie FROM category WHERE name = 'Áo hoodie' LIMIT 1;
SELECT id INTO @cat_len    FROM category WHERE name = 'Áo len' LIMIT 1;

SELECT id INTO @var_dam_lua_be_s  FROM product_variant WHERE sku = 'DAM-LUA-BE-S' LIMIT 1;
SELECT id INTO @var_sm_linen_tr_m FROM product_variant WHERE sku = 'SM-LINEN-TR-M' LIMIT 1;
SELECT id INTO @var_at_basic_tr_l FROM product_variant WHERE sku = 'AT-BASIC-TR-L' LIMIT 1;
SELECT id INTO @var_cv_xeply_m    FROM product_variant WHERE sku = 'CV-XEPLY-KEM-M' LIMIT 1;

-- ============================================================================
-- MỤC 1: TÀI KHOẢN, HỒ SƠ & ĐỊA CHỈ GIAO HÀNG (51 tài khoản mới)
--   - 3 ADMIN mới (admin3 -> admin5): đều ACTIVE, email_verified = 1
--   - 6 STAFF mới (staff3 -> staff8): 5 ACTIVE + 1 BANNED (staff8 nghỉ việc)
--   - 42 CUSTOMER mới (khach5 -> khach46) phân thành 6 nhóm:
--       * Nhóm A (khach5 -> khach16, 12 khách): Khách VIP mua nhiều đơn (2+ đơn)
--       * Nhóm B (khach17 -> khach26, 10 khách): Khách mua 1-2 đơn thành công/đang xử lý
--       * Nhóm C (khach27 -> khach31, 5 khách): Khách có đơn hủy (kèm hoàn kho)
--       * Nhóm D (khach32 -> khach35, 4 khách): Khách mới chỉ có giỏ hàng/wishlist, 0 đơn
--       * Nhóm E (khach36 -> khach40, 5 khách): Tài khoản trống mới tạo (0 đơn, 0 giỏ, 0 wishlist, 0 địa chỉ)
--       * Nhóm F (khach41 -> khach46, 6 khách): 3 BANNED (khach41 từng mua, khach42 từng hủy, khach43 trắng) + 3 chưa xác thực OTP (khach44, khach45, khach46: email_verified = 0)
-- Mật khẩu mẫu: Admin@123 (ADMIN/STAFF) | Khach@123 (CUSTOMER)
-- ============================================================================

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('admin3@fashionshop.vn', @pw_admin, 'ADMIN', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 55 DAY), DATE_SUB(NOW(6), INTERVAL 12 HOUR));
SET @acc_admin3 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_admin3, 'Lê Minh Quản Trị', '0903000003', '1993-05-12');
SET @prof_admin3 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('admin4@fashionshop.vn', @pw_admin, 'ADMIN', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 52 DAY), DATE_SUB(NOW(6), INTERVAL 5 HOUR));
SET @acc_admin4 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_admin4, 'Nguyễn Thị Điều Hành', '0903000004', '1991-09-20');
SET @prof_admin4 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('admin5@fashionshop.vn', @pw_admin, 'ADMIN', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 48 DAY), DATE_SUB(NOW(6), INTERVAL 24 HOUR));
SET @acc_admin5 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_admin5, 'Trần Quốc Bảo', '0903000005', '1994-03-08');
SET @prof_admin5 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('staff3@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 45 DAY), DATE_SUB(NOW(6), INTERVAL 2 HOUR));
SET @acc_staff3 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_staff3, 'Phạm Thị Kho Vận', '0903000006', '1997-08-21');
SET @prof_staff3 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('staff4@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 42 DAY), DATE_SUB(NOW(6), INTERVAL 4 HOUR));
SET @acc_staff4 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_staff4, 'Trần Hoàng Chăm Sóc', '0903000007', '1998-11-04');
SET @prof_staff4 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('staff5@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 38 DAY), DATE_SUB(NOW(6), INTERVAL 8 HOUR));
SET @acc_staff5 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_staff5, 'Võ Minh Đóng Gói', '0903000008', '1999-01-17');
SET @prof_staff5 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('staff6@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 34 DAY), DATE_SUB(NOW(6), INTERVAL 16 HOUR));
SET @acc_staff6 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_staff6, 'Đặng Thị Kiểm Kê', '0903000009', '1996-06-29');
SET @prof_staff6 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('staff7@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 30 DAY), DATE_SUB(NOW(6), INTERVAL 6 HOUR));
SET @acc_staff7 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_staff7, 'Huỳnh Tấn Kế Toán', '0903000010', '1995-12-15');
SET @prof_staff7 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('staff8@fashionshop.vn', @pw_admin, 'STAFF', 'BANNED', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 60 DAY), DATE_SUB(NOW(6), INTERVAL 480 HOUR));
SET @acc_staff8 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_staff8, 'Ngô Văn Nghỉ Việc', '0903000011', '1997-04-02');
SET @prof_staff8 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach5@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 58 DAY), DATE_SUB(NOW(6), INTERVAL 3 HOUR));
SET @acc_khach5 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach5, 'Nguyễn Ngọc Lan', '0915000005', '1996-02-14');
SET @prof_khach5 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach6@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 55 DAY), DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach6 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach6, 'Trần Minh Tuấn', '0915000006', '1994-09-30');
SET @prof_khach6 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach7@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 52 DAY), DATE_SUB(NOW(6), INTERVAL 6 HOUR));
SET @acc_khach7 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach7, 'Lê Thị Thu Hà', '0915000007', '1999-07-19');
SET @prof_khach7 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach8@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 50 DAY), DATE_SUB(NOW(6), INTERVAL 12 HOUR));
SET @acc_khach8 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach8, 'Phạm Quốc Bảo', '0915000008', '1995-12-03');
SET @prof_khach8 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach9@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 49 DAY), DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach9 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach9, 'Võ Thị Mỹ Linh', '0915000009', '2000-04-25');
SET @prof_khach9 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach10@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 47 DAY), DATE_SUB(NOW(6), INTERVAL 4 HOUR));
SET @acc_khach10 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach10, 'Đặng Hoàng Nam', '0915000010', '1997-01-11');
SET @prof_khach10 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach11@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 46 DAY), DATE_SUB(NOW(6), INTERVAL 8 HOUR));
SET @acc_khach11 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach11, 'Bùi Thanh Thảo', '0915000011', '2001-06-18');
SET @prof_khach11 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach12@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 44 DAY), DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach12 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach12, 'Phan Văn Khánh', '0915000012', '1993-08-22');
SET @prof_khach12 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach13@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 43 DAY), DATE_SUB(NOW(6), INTERVAL 5 HOUR));
SET @acc_khach13 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach13, 'Đỗ Thị Kim Chi', '0915000013', '1998-03-10');
SET @prof_khach13 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach14@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 41 DAY), DATE_SUB(NOW(6), INTERVAL 9 HOUR));
SET @acc_khach14 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach14, 'Trương Công Minh', '0915000014', '1995-11-28');
SET @prof_khach14 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach15@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 40 DAY), DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach15 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach15, 'Hoàng Bảo Ngọc', '0915000015', '2000-09-05');
SET @prof_khach15 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach16@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 39 DAY), DATE_SUB(NOW(6), INTERVAL 14 HOUR));
SET @acc_khach16 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach16, 'Nguyễn Thanh Tùng', '0915000016', '1992-07-14');
SET @prof_khach16 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach17@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 38 DAY), DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach17 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach17, 'Lương Thị Thanh Mai', '0915000017', '1999-05-16');
SET @prof_khach17 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach18@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 36 DAY), DATE_SUB(NOW(6), INTERVAL 3 DAY));
SET @acc_khach18 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach18, 'Mai Xuân Trường', '0915000018', '1996-10-01');
SET @prof_khach18 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach19@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 35 DAY), DATE_SUB(NOW(6), INTERVAL 7 HOUR));
SET @acc_khach19 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach19, 'Tạ Thị Hồng Nhung', '0915000019', '2001-01-23');
SET @prof_khach19 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach20@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 33 DAY), DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach20 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach20, 'Vương Gia Huy', '0915000020', '1998-06-07');
SET @prof_khach20 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach21@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 31 DAY), DATE_SUB(NOW(6), INTERVAL 10 HOUR));
SET @acc_khach21 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach21, 'Châu Ngọc Bích', '0915000021', '2002-02-19');
SET @prof_khach21 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach22@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 29 DAY), DATE_SUB(NOW(6), INTERVAL 4 HOUR));
SET @acc_khach22 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach22, 'Lâm Đức Anh', '0915000022', '1994-12-27');
SET @prof_khach22 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach23@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 27 DAY), DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach23 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach23, 'Đoàn Thị Phương Thảo', '0915000023', '1997-04-12');
SET @prof_khach23 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach24@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 25 DAY), DATE_SUB(NOW(6), INTERVAL 3 DAY));
SET @acc_khach24 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach24, 'Kiều Minh Khoa', '0915000024', '1995-08-30');
SET @prof_khach24 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach25@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 24 DAY), DATE_SUB(NOW(6), INTERVAL 2 HOUR));
SET @acc_khach25 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach25, 'Hà Tuyết Nhi', '0915000025', '2000-11-11');
SET @prof_khach25 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach26@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 22 DAY), DATE_SUB(NOW(6), INTERVAL 5 DAY));
SET @acc_khach26 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach26, 'Cao Tấn Lộc', '0915000026', '1993-03-04');
SET @prof_khach26 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach27@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 37 DAY), DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach27 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach27, 'Phùng Thị Ánh Tuyết', '0915000027', '1998-07-08');
SET @prof_khach27 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach28@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 34 DAY), DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach28 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach28, 'Diệp Hoàng Long', '0915000028', '1996-09-14');
SET @prof_khach28 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach29@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 32 DAY), DATE_SUB(NOW(6), INTERVAL 4 DAY));
SET @acc_khach29 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach29, 'Từ Thị Thanh Hương', '0915000029', '1999-12-20');
SET @prof_khach29 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach30@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 20 DAY), DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach30 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach30, 'Tô Văn Hậu', '0915000030', '1997-02-02');
SET @prof_khach30 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach31@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 18 DAY), DATE_SUB(NOW(6), INTERVAL 12 HOUR));
SET @acc_khach31 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach31, 'Quách Mỹ Duyên', '0915000031', '2001-10-15');
SET @prof_khach31 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach32@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 16 DAY), DATE_SUB(NOW(6), INTERVAL 3 DAY));
SET @acc_khach32 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach32, 'Hồ Văn Hùng', '0915000032', '1992-10-08');
SET @prof_khach32 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach33@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 14 DAY), DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach33 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach33, 'Dương Ngọc Ánh', '0915000033', '2002-03-27');
SET @prof_khach33 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach34@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 12 DAY), DATE_SUB(NOW(6), INTERVAL 6 HOUR));
SET @acc_khach34 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach34, 'Nghiêm Bảo Trân', '0915000034', '2001-08-19');
SET @prof_khach34 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach35@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 10 DAY), DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach35 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach35, 'La Minh Triết', '0915000035', '1999-04-06');
SET @prof_khach35 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach36@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 6 DAY), NULL);
SET @acc_khach36 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach36, 'Ngô Tấn Phát', '0915000036', '1998-05-02');
SET @prof_khach36 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach37@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 5 DAY), NULL);
SET @acc_khach37 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach37, 'Lưu Thị Cẩm Tú', '0915000037', '2003-01-13');
SET @prof_khach37 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach38@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 4 DAY), DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach38 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach38, 'Bành Quốc Vinh', '0915000038', '2000-07-24');
SET @prof_khach38 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach39@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 3 DAY), NULL);
SET @acc_khach39 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach39, 'Trang Ngọc Hân', '0915000039', '2002-11-30');
SET @prof_khach39 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach40@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 1 DAY), NULL);
SET @acc_khach40 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach40, 'Tống Hải Đăng', '0915000040', '1997-06-15');
SET @prof_khach40 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach41@gmail.com', @pw_khach, 'CUSTOMER', 'BANNED', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 48 DAY), DATE_SUB(NOW(6), INTERVAL 15 DAY));
SET @acc_khach41 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach41, 'Lý Văn Khóa', '0915000041', '1991-11-22');
SET @prof_khach41 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach42@gmail.com', @pw_khach, 'CUSTOMER', 'BANNED', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 36 DAY), DATE_SUB(NOW(6), INTERVAL 10 DAY));
SET @acc_khach42 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach42, 'Mạc Văn Bom Hàng', '0915000042', '1995-03-19');
SET @prof_khach42 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach43@gmail.com', @pw_khach, 'CUSTOMER', 'BANNED', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 20 DAY), NULL);
SET @acc_khach43 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach43, 'Trịnh Thị Vi Phạm', '0915000043', '1996-08-14');
SET @prof_khach43 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach44@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 0, '849201', DATE_ADD(NOW(6), INTERVAL 24 HOUR), DATE_SUB(NOW(6), INTERVAL 1 DAY), NULL);
SET @acc_khach44 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach44, 'Vũ Đức Duy', '0915000044', '2003-09-09');
SET @prof_khach44 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach45@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 0, '371905', DATE_ADD(NOW(6), INTERVAL 5 MINUTE), DATE_SUB(NOW(6), INTERVAL 2 MINUTE), NULL);
SET @acc_khach45 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach45, 'Phạm Ngọc Huyền', '0915000045', '2002-05-18');
SET @prof_khach45 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach46@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 0, '604812', DATE_SUB(NOW(6), INTERVAL 1 HOUR), DATE_SUB(NOW(6), INTERVAL 2 HOUR), NULL);
SET @acc_khach46 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach46, 'Trần Gia Bảo', '0915000046', '2001-12-11');
SET @prof_khach46 := LAST_INSERT_ID();

-- Địa chỉ giao hàng mẫu (nhóm E tài khoản trống và khach43..khach46 không có địa chỉ)
INSERT INTO shipping_address (user_profile_id, address, default_address) VALUES
(@prof_khach5, '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 1),
(@prof_khach5, '45 Thảo Điền, Phường Thảo Điền, TP. Thủ Đức, TP.HCM', 0),
(@prof_khach6, '88 Lê Lợi, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 1),
(@prof_khach7, '215 Cầu Giấy, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 1),
(@prof_khach8, '14 Phan Văn Trị, Phường 7, Quận Gò Vấp, TP.HCM', 1),
(@prof_khach9, '302 Cách Mạng Tháng 8, Phường 10, Quận 3, TP.HCM', 1),
(@prof_khach10, '56 Nguyễn Văn Linh, Phường Tân Thuận Tây, Quận 7, TP.HCM', 1),
(@prof_khach11, '79 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM', 1),
(@prof_khach11, '19 Hoàng Văn Thụ, Phường 9, Quận Phú Nhuận, TP.HCM', 0),
(@prof_khach12, '240 Điện Biên Phủ, Phường 17, Quận Bình Thạnh, TP.HCM', 1),
(@prof_khach13, '64 Nguyễn Trãi, Phường Thượng Đình, Quận Thanh Xuân, Hà Nội', 1),
(@prof_khach14, '112 Trần Phú, Phường Lộc Thọ, TP. Nha Trang, Khánh Hòa', 1),
(@prof_khach15, '50 Lý Tự Trọng, Phường An Cư, Quận Ninh Kiều, Cần Thơ', 1),
(@prof_khach16, '18 Nguyễn Thị Minh Khai, Phường Đa Kao, Quận 1, TP.HCM', 1),
(@prof_khach17, '75 Hoàng Diệu, Phường Nam Dương, Quận Hải Châu, Đà Nẵng', 1),
(@prof_khach18, '27 Lê Văn Sỹ, Phường 13, Quận Phú Nhuận, TP.HCM', 1),
(@prof_khach19, '190 Quang Trung, Phường 10, Quận Gò Vấp, TP.HCM', 1),
(@prof_khach20, '41 Bà Triệu, Phường Hàng Bài, Quận Hoàn Kiếm, Hà Nội', 1),
(@prof_khach21, '155 Sư Vạn Hạnh, Phường 12, Quận 10, TP.HCM', 1),
(@prof_khach22, '90 Hùng Vương, Phường Phú Nhuận, TP. Huế', 1),
(@prof_khach23, '220 Cộng Hòa, Phường 12, Quận Tân Bình, TP.HCM', 1),
(@prof_khach24, '11 Nguyễn Ái Quốc, Phường Tân Phong, TP. Biên Hòa, Đồng Nai', 1),
(@prof_khach25, '68 Trường Chinh, Phường Tây Thạnh, Quận Tân Phú, TP.HCM', 1),
(@prof_khach26, '34 Đại lộ Bình Dương, TP. Thủ Dầu Một, Bình Dương', 1),
(@prof_khach27, '142 Lạc Long Quân, Phường 3, Quận 11, TP.HCM', 1),
(@prof_khach28, '58 Xô Viết Nghệ Tĩnh, Phường 19, Quận Bình Thạnh, TP.HCM', 1),
(@prof_khach29, '81 Kim Mã, Phường Kim Mã, Quận Ba Đình, Hà Nội', 1),
(@prof_khach30, '19 Hậu Giang, Phường 2, Quận 6, TP.HCM', 1),
(@prof_khach31, '44 Nguyễn Oanh, Phường 7, Quận Gò Vấp, TP.HCM', 1),
(@prof_khach32, '101 Trần Hưng Đạo, Phường An Phú, Quận Ninh Kiều, Cần Thơ', 1),
(@prof_khach33, '33 Võ Văn Ngân, Phường Linh Chiểu, TP. Thủ Đức, TP.HCM', 1),
(@prof_khach34, '77 Kinh Dương Vương, Phường 12, Quận 6, TP.HCM', 1),
(@prof_khach35, '128 Phan Đăng Lưu, Phường 3, Quận Phú Nhuận, TP.HCM', 1),
(@prof_khach41, '99 Tô Hiến Thành, Phường 13, Quận 10, TP.HCM', 1),
(@prof_khach42, '205 Âu Cơ, Phường 5, Quận 11, TP.HCM', 1);

-- ============================================================================
-- MỤC 2: DANH MỤC MỚI (4 danh mục quần áo) & SẢN PHẨM MỚI (14 sản phẩm quần áo)
-- GHI CHÚ PUBLIC ID ẢNH CLOUDINARY (https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/<public_id>):
--   1. sp-ao-polo-reu         -> Áo Polo Nam Dệt Kim Xanh Rêu
--   2. sp-ao-polo-nu-kem      -> Áo Polo Nữ Cổ Phối Trắng Kem
--   3. sp-dam-so-mi-pastel    -> Đầm Sơ Mi Lụa Pastel Tay Bồng
--   4. sp-dam-du-tiec-do      -> Đầm Dự Tiệc Satin Đỏ Đô
--   5. sp-so-mi-oxford-xanh   -> Áo Sơ Mi Oxford Nam Xanh Biển
--   6. sp-quan-culottes-trang -> Quần Culottes Ống Rộng Trắng Kem
--   7. sp-quan-jogger-xam     -> Quần Jogger Nỉ Unisex Xám Tiêu
--   8. sp-blazer-nu-den       -> Áo Khoác Blazer Nữ Đen Cổ Vest
--   9. sp-ao-thun-the-thao    -> Áo Thun Thể Thao Dry-Fit Đen
--  10. sp-ao-len-gile-kem     -> Áo Len Gile Cổ Tim Kem Sữa
--  11. sp-ao-vest-nam-den     -> Áo Vest Nam Công Sở Slimfit Đen
--  12. sp-ao-cardigan-kem     -> Áo Cardigan Len Mỏng Cổ Chữ V
--  13. sp-bo-tap-gym-nu       -> Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều
--  14. sp-ao-hoodie-ni-xam    -> Áo Hoodie Nỉ Bông Xám (INACTIVE, chưa bán)
-- ============================================================================

INSERT INTO category (name, status) VALUES ('Áo polo', 'VISIBLE');
SET @cat_polo := LAST_INSERT_ID();
INSERT INTO category (name, status) VALUES ('Áo vest', 'VISIBLE');
SET @cat_vest := LAST_INSERT_ID();
INSERT INTO category (name, status) VALUES ('Áo cardigan', 'VISIBLE');
SET @cat_cardigan := LAST_INSERT_ID();
INSERT INTO category (name, status) VALUES ('Đồ thể thao', 'VISIBLE');
SET @cat_thethao := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_polo, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'Áo polo nam chất liệu cotton dệt kim thoáng khí, form regular lịch sự phù hợp công sở và dạo phố.', 480000.00, 420000.00, 'MALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-polo-reu', DATE_SUB(NOW(6), INTERVAL 40 DAY));
SET @prod_polo_reu := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_polo_reu, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-polo-reu', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_polo_reu, 'M', 'Xanh rêu', 'PLO-REU-M', 25, 'ACTIVE', 0);
SET @var_plo_reu_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_polo_reu, 'L', 'Xanh rêu', 'PLO-REU-L', 18, 'ACTIVE', 0);
SET @var_plo_reu_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_polo_reu, 'XL', 'Xanh rêu', 'PLO-REU-XL', 4, 'ACTIVE', 0);
SET @var_plo_reu_xl := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_polo, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'Áo polo nữ cổ bẻ phối viền thanh lịch, chất liệu pique co giãn nhẹ thấm hút mồ hôi tốt.', 450000.00, NULL, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-polo-nu-kem', DATE_SUB(NOW(6), INTERVAL 39 DAY));
SET @prod_polo_kem := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_polo_kem, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-polo-nu-kem', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_polo_kem, 'S', 'Kem', 'PLO-KEM-S', 15, 'ACTIVE', 0);
SET @var_plo_kem_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_polo_kem, 'M', 'Kem', 'PLO-KEM-M', 20, 'ACTIVE', 0);
SET @var_plo_kem_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_dam, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'Đầm sơ mi dáng chữ A kèm đai eo vải, chất lụa tơ mềm rủ tôn dáng dịu dàng.', 1290000.00, 1090000.00, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-dam-so-mi-pastel', DATE_SUB(NOW(6), INTERVAL 38 DAY));
SET @prod_dam_pas := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_dam_pas, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-dam-so-mi-pastel', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_dam_pas, 'S', 'Hồng pastel', 'DAM-PAS-S', 10, 'ACTIVE', 0);
SET @var_dam_pas_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_dam_pas, 'M', 'Hồng pastel', 'DAM-PAS-M', 12, 'ACTIVE', 0);
SET @var_dam_pas_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_dam_pas, 'L', 'Hồng pastel', 'DAM-PAS-L', 0, 'INACTIVE', 0);
SET @var_dam_pas_l := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_dam, 'Đầm Dự Tiệc Satin Đỏ Đô', 'Đầm dự tiệc dài qua gối bằng lụa satin cao cấp, xẻ tà tinh tế tạo vẻ sang trọng.', 1890000.00, NULL, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-dam-du-tiec-do', DATE_SUB(NOW(6), INTERVAL 37 DAY));
SET @prod_dam_do := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_dam_do, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-dam-du-tiec-do', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_dam_do, 'S', 'Đỏ đô', 'DAM-DO-S', 6, 'ACTIVE', 0);
SET @var_dam_do_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_dam_do, 'M', 'Đỏ đô', 'DAM-DO-M', 8, 'ACTIVE', 0);
SET @var_dam_do_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_somi, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'Áo sơ mi dài tay vải Oxford dệt dày dặn, ít nhăn, đường may chuẩn form công sở.', 620000.00, 540000.00, 'MALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-so-mi-oxford-xanh', DATE_SUB(NOW(6), INTERVAL 36 DAY));
SET @prod_sm_oxf := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_sm_oxf, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-so-mi-oxford-xanh', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_sm_oxf, 'M', 'Xanh biển', 'SM-OXF-M', 22, 'ACTIVE', 0);
SET @var_sm_oxf_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_sm_oxf, 'L', 'Xanh biển', 'SM-OXF-L', 16, 'ACTIVE', 0);
SET @var_sm_oxf_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_sm_oxf, 'XL', 'Xanh biển', 'SM-OXF-XL', 9, 'ACTIVE', 0);
SET @var_sm_oxf_xl := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_quan, 'Quần Culottes Ống Rộng Trắng Kem', 'Quần culottes cạp cao khóa kéo bên hông, hack dáng chân dài, vải tuyết mưa đứng phom.', 720000.00, NULL, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-quan-culottes-trang', DATE_SUB(NOW(6), INTERVAL 35 DAY));
SET @prod_qn_cul := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_qn_cul, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-quan-culottes-trang', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_qn_cul, 'S', 'Trắng kem', 'QN-CUL-S', 14, 'ACTIVE', 0);
SET @var_qn_cul_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_qn_cul, 'M', 'Trắng kem', 'QN-CUL-M', 17, 'ACTIVE', 0);
SET @var_qn_cul_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_quan, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'Quần jogger bo gấu cạp chun dây rút, chất nỉ da cá 350gsm mềm mịn không xù lông.', 550000.00, 490000.00, 'UNISEX', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-quan-jogger-xam', DATE_SUB(NOW(6), INTERVAL 34 DAY));
SET @prod_qn_jog := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_qn_jog, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-quan-jogger-xam', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_qn_jog, 'M', 'Xám tiêu', 'QN-JOG-M', 20, 'ACTIVE', 0);
SET @var_qn_jog_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_qn_jog, 'L', 'Xám tiêu', 'QN-JOG-L', 3, 'ACTIVE', 0);
SET @var_qn_jog_l := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_khoac, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'Blazer nữ 2 lớp lót lụa mịn, đệm vai nhẹ chuẩn dáng thanh lịch cho nàng công sở.', 1450000.00, 1250000.00, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-blazer-nu-den', DATE_SUB(NOW(6), INTERVAL 33 DAY));
SET @prod_ak_blz := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_ak_blz, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-blazer-nu-den', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_ak_blz, 'S', 'Đen', 'AK-BLZ-S', 9, 'ACTIVE', 0);
SET @var_ak_blz_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_ak_blz, 'M', 'Đen', 'AK-BLZ-M', 11, 'ACTIVE', 0);
SET @var_ak_blz_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_thun, 'Áo Thun Thể Thao Dry-Fit Đen', 'Áo thun thể thao vải mè thoáng khí siêu nhẹ, khô nhanh khi vận động cường độ cao.', 360000.00, 310000.00, 'UNISEX', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-thun-the-thao', DATE_SUB(NOW(6), INTERVAL 32 DAY));
SET @prod_at_gym := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_at_gym, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-thun-the-thao', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_at_gym, 'M', 'Đen', 'AT-GYM-M', 30, 'ACTIVE', 0);
SET @var_at_gym_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_at_gym, 'L', 'Đen', 'AT-GYM-L', 25, 'ACTIVE', 0);
SET @var_at_gym_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_at_gym, 'XL', 'Đen', 'AT-GYM-XL', 12, 'ACTIVE', 0);
SET @var_at_gym_xl := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_len, 'Áo Len Gile Cổ Tim Kem Sữa', 'Áo len gile dệt thừng phong cách Hàn Quốc, dễ phối cùng áo sơ mi hoặc áo thun dài tay.', 590000.00, NULL, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-len-gile-kem', DATE_SUB(NOW(6), INTERVAL 31 DAY));
SET @prod_al_gil := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_al_gil, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-len-gile-kem', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_al_gil, 'S', 'Kem sữa', 'AL-GIL-S', 13, 'ACTIVE', 0);
SET @var_al_gil_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_al_gil, 'M', 'Kem sữa', 'AL-GIL-M', 16, 'ACTIVE', 0);
SET @var_al_gil_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_vest, 'Áo Vest Nam Công Sở Slimfit Đen', 'Áo vest nam 2 khuy form slimfit hiện đại, vải tuýt si đứng dáng ít nhăn phù hợp đi làm và dự tiệc.', 980000.00, 850000.00, 'MALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-vest-nam-den', DATE_SUB(NOW(6), INTERVAL 30 DAY));
SET @prod_vs_den := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_vs_den, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-vest-nam-den', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_vs_den, 'M', 'Đen', 'VS-DEN-M', 14, 'ACTIVE', 0);
SET @var_vs_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_vs_den, 'L', 'Xám than', 'VS-XAM-L', 7, 'ACTIVE', 0);
SET @var_vs_xam_l := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_cardigan, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'Áo khoác cardigan len dệt mịn nhẹ thoáng, cài khuy trước dễ phối cùng sơ mi hoặc áo thun.', 420000.00, NULL, 'UNISEX', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-cardigan-kem', DATE_SUB(NOW(6), INTERVAL 29 DAY));
SET @prod_cd_len := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_cd_len, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-cardigan-kem', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_cd_len, 'M', 'Nâu kem', 'CD-KEM-M', 20, 'ACTIVE', 0);
SET @var_cd_kem_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_cd_len, 'L', 'Đen', 'CD-DEN-L', 18, 'ACTIVE', 0);
SET @var_cd_den_l := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_thethao, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'Set áo croptop bra kèm quần legging cạp cao nâng dáng, vải poly-spandex co giãn 4 chiều.', 680000.00, 590000.00, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-bo-tap-gym-nu', DATE_SUB(NOW(6), INTERVAL 28 DAY));
SET @prod_tt_gym := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_tt_gym, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-bo-tap-gym-nu', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_tt_gym, 'S', 'Xám khói', 'TT-GYM-S', 15, 'ACTIVE', 0);
SET @var_tt_gym_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_tt_gym, 'M', 'Xám khói', 'TT-GYM-M', 0, 'ACTIVE', 0);
SET @var_tt_gym_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_hoodie, 'Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán)', 'Áo hoodie nỉ bông dày dặn giữ ấm mùa đông, hiện đang tạm ngừng kinh doanh.', 650000.00, NULL, 'UNISEX', 'INACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-hoodie-ni-xam', DATE_SUB(NOW(6), INTERVAL 50 DAY));
SET @prod_hd_xam := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES (@prod_hd_xam, 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-hoodie-ni-xam', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES (@prod_hd_xam, 'L', 'Xám', 'HD-XAM-L', 5, 'ACTIVE', 0);
SET @var_hd_xam_l := LAST_INSERT_ID();

-- ============================================================================
-- MỤC 3: MÃ GIẢM GIÁ MỚI (6 mã - used_count khớp chính xác số đơn không hủy)
-- ============================================================================
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('WELCOME15', 'Giảm 15% cho khách hàng mới (tối đa 150K)', 'PERCENT', 15.00, 150000.00, 400000.00, 200, 6, DATE_SUB(NOW(6), INTERVAL 60 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE');
SET @cp_welcome15 := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('FREESHIP30', 'Hỗ trợ phí vận chuyển 30K', 'FIXED_AMOUNT', 30000.00, NULL, 300000.00, 300, 5, DATE_SUB(NOW(6), INTERVAL 60 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE');
SET @cp_freeship30 := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('VIP200K', 'Ưu đãi đơn cao cấp giảm 200K', 'FIXED_AMOUNT', 200000.00, NULL, 1500000.00, 150, 6, DATE_SUB(NOW(6), INTERVAL 45 DAY), DATE_ADD(NOW(6), INTERVAL 45 DAY), 'ACTIVE');
SET @cp_vip200k := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('SALETET20', 'Siêu sale giảm 20% tối đa 300K', 'PERCENT', 20.00, 300000.00, 800000.00, 150, 5, DATE_SUB(NOW(6), INTERVAL 45 DAY), DATE_ADD(NOW(6), INTERVAL 30 DAY), 'ACTIVE');
SET @cp_saletet20 := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('THANGVANG', 'Tháng vàng mua sắm giảm ngay 100K', 'FIXED_AMOUNT', 100000.00, NULL, 700000.00, 150, 6, DATE_SUB(NOW(6), INTERVAL 35 DAY), DATE_ADD(NOW(6), INTERVAL 30 DAY), 'ACTIVE');
SET @cp_thangvang := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('NOEL2025', 'Giảm 25% mùa Giáng Sinh (Đã hết hạn)', 'PERCENT', 25.00, 250000.00, 500000.00, 40, 0, '2025-12-20 00:00:00', '2025-12-31 23:59:59', 'INACTIVE');
SET @cp_noel2025 := LAST_INSERT_ID();

-- ============================================================================
-- MỤC 4: ĐƠN HÀNG & CHI TIẾT ĐƠN HÀNG (50 đơn: 20 tháng trước + 30 tháng này)
-- ============================================================================

-- FS2026F701 | COMPLETED | BANK_TRANSFER + PAID | total=2,540,000
SET @t_f701 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 27 DAY), '09:15:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F701', @prof_khach5, @cp_vip200k, 'COMPLETED', 2740000.00, 200000.00, 2540000.00, 'Nguyễn Ngọc Lan', '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f701, INTERVAL 3 MINUTE), @t_f701, DATE_ADD(@t_f701, INTERVAL 2 DAY));
SET @ord_f701 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f701, @var_dam_do_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đỏ đô', 1890000.00, 1),
(@ord_f701, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1);

-- FS2026F702 | COMPLETED | COD + PAID | total=1,008,000
SET @t_f702 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 26 DAY), '14:20:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F702', @prof_khach6, @cp_saletet20, 'COMPLETED', 1260000.00, 252000.00, 1008000.00, 'Trần Minh Tuấn', '0915000006', '88 Lê Lợi, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'COD', 'PAID', DATE_ADD(@t_f702, INTERVAL 2 DAY), @t_f702, DATE_ADD(@t_f702, INTERVAL 2 DAY));
SET @ord_f702 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f702, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 2),
(@ord_f702, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS2026F703 | COMPLETED | E_WALLET + PAID | total=990,000
SET @t_f703 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 25 DAY), '19:45:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F703', @prof_khach7, @cp_thangvang, 'COMPLETED', 1090000.00, 100000.00, 990000.00, 'Lê Thị Thu Hà', '0915000007', '215 Cầu Giấy, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f703, INTERVAL 3 MINUTE), @t_f703, DATE_ADD(@t_f703, INTERVAL 2 DAY));
SET @ord_f703 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f703, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1);

-- FS2026F704 | COMPLETED | COD + PAID | total=752,500
SET @t_f704 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 24 DAY), '10:30:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F704', @prof_khach8, @cp_welcome15, 'COMPLETED', 850000.00, 127500.00, 752500.00, 'Phạm Quốc Bảo', '0915000008', '14 Phan Văn Trị, Phường 7, Quận Gò Vấp, TP.HCM', 30000.00, NULL, 'COD', 'PAID', DATE_ADD(@t_f704, INTERVAL 2 DAY), @t_f704, DATE_ADD(@t_f704, INTERVAL 2 DAY));
SET @ord_f704 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f704, @var_sm_oxf_l, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'L', 'Xanh biển', 540000.00, 1),
(@ord_f704, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 1);

-- FS2026F705 | COMPLETED | BANK_TRANSFER + PAID | total=1,770,000
SET @t_f705 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 22 DAY), '16:10:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F705', @prof_khach9, @cp_vip200k, 'COMPLETED', 1970000.00, 200000.00, 1770000.00, 'Võ Thị Mỹ Linh', '0915000009', '302 Cách Mạng Tháng 8, Phường 10, Quận 3, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f705, INTERVAL 3 MINUTE), @t_f705, DATE_ADD(@t_f705, INTERVAL 2 DAY));
SET @ord_f705 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f705, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1),
(@ord_f705, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1);

-- FS2026F706 | COMPLETED | E_WALLET + PAID | total=1,080,000
SET @t_f706 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 21 DAY), '11:05:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F706', @prof_khach10, NULL, 'COMPLETED', 1080000.00, 0.00, 1080000.00, 'Đặng Hoàng Nam', '0915000010', '56 Nguyễn Văn Linh, Phường Tân Thuận Tây, Quận 7, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f706, INTERVAL 3 MINUTE), @t_f706, DATE_ADD(@t_f706, INTERVAL 2 DAY));
SET @ord_f706 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f706, @var_tt_gym_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Xám khói', 590000.00, 1),
(@ord_f706, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS2026F707 | COMPLETED | COD + PAID | total=940,000
SET @t_f707 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 20 DAY), '20:15:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F707', @prof_khach11, @cp_thangvang, 'COMPLETED', 1040000.00, 100000.00, 940000.00, 'Bùi Thanh Thảo', '0915000011', '79 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'COD', 'PAID', DATE_ADD(@t_f707, INTERVAL 2 DAY), @t_f707, DATE_ADD(@t_f707, INTERVAL 2 DAY));
SET @ord_f707 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f707, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1),
(@ord_f707, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 1);

-- FS2026F708 | COMPLETED | COD + PAID | total=1,590,000
SET @t_f708 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 18 DAY), '13:40:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F708', @prof_khach41, NULL, 'COMPLETED', 1590000.00, 0.00, 1590000.00, 'Lý Văn Khóa', '0915000041', '99 Tô Hiến Thành, Phường 13, Quận 10, TP.HCM', 0.00, NULL, 'COD', 'PAID', DATE_ADD(@t_f708, INTERVAL 2 DAY), @t_f708, DATE_ADD(@t_f708, INTERVAL 2 DAY));
SET @ord_f708 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f708, @var_dam_lua_be_s, 'Đầm lụa dáng dài màu be', 'S', 'Be', 1590000.00, 1);

-- FS2026F709 | COMPLETED | BANK_TRANSFER + PAID | total=850,000
SET @t_f709 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 17 DAY), '15:25:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F709', @prof_khach12, @cp_freeship30, 'COMPLETED', 850000.00, 30000.00, 850000.00, 'Phan Văn Khánh', '0915000012', '240 Điện Biên Phủ, Phường 17, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f709, INTERVAL 3 MINUTE), @t_f709, DATE_ADD(@t_f709, INTERVAL 2 DAY));
SET @ord_f709 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f709, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1);

-- FS2026F710 | CANCELLED | COD + UNPAID | total=570,000
SET @t_f710 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 16 DAY), '17:50:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F710', @prof_khach6, NULL, 'CANCELLED', 540000.00, 0.00, 570000.00, 'Trần Minh Tuấn', '0915000006', '88 Lê Lợi, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f710, 'Khách muốn đổi sang size lớn hơn', DATE_ADD(@t_f710, INTERVAL 3 HOUR));
SET @ord_f710 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f710, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1);

-- FS2026F711 | COMPLETED | E_WALLET + PAID | total=872,000
SET @t_f711 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 14 DAY), '10:00:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F711', @prof_khach13, @cp_saletet20, 'COMPLETED', 1090000.00, 218000.00, 872000.00, 'Đỗ Thị Kim Chi', '0915000013', '64 Nguyễn Trãi, Phường Thượng Đình, Quận Thanh Xuân, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f711, INTERVAL 3 MINUTE), @t_f711, DATE_ADD(@t_f711, INTERVAL 2 DAY));
SET @ord_f711 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f711, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1);

-- FS2026F712 | COMPLETED | BANK_TRANSFER + PAID | total=752,500
SET @t_f712 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 12 DAY), '14:15:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F712', @prof_khach14, @cp_welcome15, 'COMPLETED', 850000.00, 127500.00, 752500.00, 'Trương Công Minh', '0915000014', '112 Trần Phú, Phường Lộc Thọ, TP. Nha Trang, Khánh Hòa', 30000.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f712, INTERVAL 3 MINUTE), @t_f712, DATE_ADD(@t_f712, INTERVAL 2 DAY));
SET @ord_f712 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f712, @var_sm_oxf_xl, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'XL', 'Xanh biển', 540000.00, 1),
(@ord_f712, @var_at_gym_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Đen', 310000.00, 1);

-- FS2026F713 | COMPLETED | COD + PAID | total=900,000
SET @t_f713 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 11 DAY), '09:40:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F713', @prof_khach15, @cp_freeship30, 'COMPLETED', 900000.00, 30000.00, 900000.00, 'Hoàng Bảo Ngọc', '0915000015', '50 Lý Tự Trọng, Phường An Cư, Quận Ninh Kiều, Cần Thơ', 30000.00, NULL, 'COD', 'PAID', DATE_ADD(@t_f713, INTERVAL 2 DAY), @t_f713, DATE_ADD(@t_f713, INTERVAL 2 DAY));
SET @ord_f713 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f713, @var_plo_kem_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Kem', 450000.00, 2);

-- FS2026F714 | COMPLETED | E_WALLET + PAID | total=1,690,000
SET @t_f714 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 9 DAY), '18:30:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F714', @prof_khach16, @cp_vip200k, 'COMPLETED', 1890000.00, 200000.00, 1690000.00, 'Nguyễn Thanh Tùng', '0915000016', '18 Nguyễn Thị Minh Khai, Phường Đa Kao, Quận 1, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f714, INTERVAL 3 MINUTE), @t_f714, DATE_ADD(@t_f714, INTERVAL 2 DAY));
SET @ord_f714 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f714, @var_dam_do_s, 'Đầm Dự Tiệc Satin Đỏ Đô', 'S', 'Đỏ đô', 1890000.00, 1);

-- FS2026F715 | COMPLETED | BANK_TRANSFER + PAID | total=1,210,000
SET @t_f715 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 8 DAY), '15:05:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F715', @prof_khach17, @cp_thangvang, 'COMPLETED', 1310000.00, 100000.00, 1210000.00, 'Lương Thị Thanh Mai', '0915000017', '75 Hoàng Diệu, Phường Nam Dương, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f715, INTERVAL 3 MINUTE), @t_f715, DATE_ADD(@t_f715, INTERVAL 2 DAY));
SET @ord_f715 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f715, @var_qn_cul_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Trắng kem', 720000.00, 1),
(@ord_f715, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1);

-- FS2026F716 | COMPLETED | COD + PAID | total=760,000
SET @t_f716 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 7 DAY), '12:20:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F716', @prof_khach18, NULL, 'COMPLETED', 730000.00, 0.00, 760000.00, 'Mai Xuân Trường', '0915000018', '27 Lê Văn Sỹ, Phường 13, Quận Phú Nhuận, TP.HCM', 30000.00, NULL, 'COD', 'PAID', DATE_ADD(@t_f716, INTERVAL 2 DAY), @t_f716, DATE_ADD(@t_f716, INTERVAL 2 DAY));
SET @ord_f716 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f716, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1),
(@ord_f716, @var_at_gym_xl, 'Áo Thun Thể Thao Dry-Fit Đen', 'XL', 'Đen', 310000.00, 1);

-- FS2026F717 | COMPLETED | BANK_TRANSFER + PAID | total=1,250,000
SET @t_f717 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 5 DAY), '16:45:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F717', @prof_khach27, NULL, 'COMPLETED', 1250000.00, 0.00, 1250000.00, 'Phùng Thị Ánh Tuyết', '0915000027', '142 Lạc Long Quân, Phường 3, Quận 11, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f717, INTERVAL 3 MINUTE), @t_f717, DATE_ADD(@t_f717, INTERVAL 2 DAY));
SET @ord_f717 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f717, @var_ak_blz_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Đen', 1250000.00, 1);

-- FS2026F718 | CANCELLED | COD + UNPAID | total=450,000
SET @t_f718 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 4 DAY), '11:10:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F718', @prof_khach29, NULL, 'CANCELLED', 420000.00, 0.00, 450000.00, 'Từ Thị Thanh Hương', '0915000029', '81 Kim Mã, Phường Kim Mã, Quận Ba Đình, Hà Nội', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f718, 'Khách đặt nhầm màu sắc', DATE_ADD(@t_f718, INTERVAL 3 HOUR));
SET @ord_f718 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f718, @var_plo_reu_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Xanh rêu', 420000.00, 1);

-- FS2026F719 | CANCELLED | COD + UNPAID | total=520,000
SET @t_f719 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 2 DAY), '19:00:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F719', @prof_khach42, NULL, 'CANCELLED', 490000.00, 0.00, 520000.00, 'Mạc Văn Bom Hàng', '0915000042', '205 Âu Cơ, Phường 5, Quận 11, TP.HCM', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f719, 'Không liên hệ được người nhận khi giao', DATE_ADD(@t_f719, INTERVAL 3 HOUR));
SET @ord_f719 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f719, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS2026F720 | CANCELLED | BANK_TRANSFER + FAILED | total=620,000
SET @t_f720 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 1 DAY), '21:15:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F720', @prof_khach28, NULL, 'CANCELLED', 590000.00, 0.00, 620000.00, 'Diệp Hoàng Long', '0915000028', '58 Xô Viết Nghệ Tĩnh, Phường 19, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'BANK_TRANSFER', 'FAILED', NULL, @t_f720, 'Thanh toán chuyển khoản quá hạn', DATE_ADD(@t_f720, INTERVAL 3 HOUR));
SET @ord_f720 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f720, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1);

-- FS2026F721 | COMPLETED | BANK_TRANSFER + PAID | total=2,840,000
SET @t_f721 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.03) SECOND);
SET @c_f721 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.06) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F721', @prof_khach5, @cp_saletet20, 'COMPLETED', 3140000.00, 300000.00, 2840000.00, 'Nguyễn Ngọc Lan', '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f721, INTERVAL 2 MINUTE), @t_f721, @c_f721);
SET @ord_f721 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f721, @var_dam_do_s, 'Đầm Dự Tiệc Satin Đỏ Đô', 'S', 'Đỏ đô', 1890000.00, 1),
(@ord_f721, @var_ak_blz_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Đen', 1250000.00, 1);

-- FS2026F722 | COMPLETED | E_WALLET + PAID | total=1,420,000
SET @t_f722 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.06) SECOND);
SET @c_f722 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.09) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F722', @prof_khach7, @cp_vip200k, 'COMPLETED', 1620000.00, 200000.00, 1420000.00, 'Lê Thị Thu Hà', '0915000007', '215 Cầu Giấy, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f722, INTERVAL 2 MINUTE), @t_f722, @c_f722);
SET @ord_f722 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f722, @var_plo_kem_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Kem', 450000.00, 2),
(@ord_f722, @var_qn_cul_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Trắng kem', 720000.00, 1);

-- FS2026F723 | COMPLETED | COD + PAID | total=1,110,000
SET @t_f723 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.09) SECOND);
SET @c_f723 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.12) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F723', @prof_khach8, @cp_welcome15, 'COMPLETED', 1260000.00, 150000.00, 1110000.00, 'Phạm Quốc Bảo', '0915000008', '14 Phan Văn Trị, Phường 7, Quận Gò Vấp, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_f723, @t_f723, @c_f723);
SET @ord_f723 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f723, @var_plo_reu_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Xanh rêu', 420000.00, 2),
(@ord_f723, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1);

-- FS2026F724 | COMPLETED | BANK_TRANSFER + PAID | total=1,580,000
SET @t_f724 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.12) SECOND);
SET @c_f724 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.15) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F724', @prof_khach9, @cp_thangvang, 'COMPLETED', 1680000.00, 100000.00, 1580000.00, 'Võ Thị Mỹ Linh', '0915000009', '302 Cách Mạng Tháng 8, Phường 10, Quận 3, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f724, INTERVAL 2 MINUTE), @t_f724, @c_f724);
SET @ord_f724 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f724, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1),
(@ord_f724, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1);

-- FS2026F725 | COMPLETED | E_WALLET + PAID | total=1,110,000
SET @t_f725 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.15) SECOND);
SET @c_f725 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.18) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F725', @prof_khach10, NULL, 'COMPLETED', 1110000.00, 0.00, 1110000.00, 'Đặng Hoàng Nam', '0915000010', '56 Nguyễn Văn Linh, Phường Tân Thuận Tây, Quận 7, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f725, INTERVAL 2 MINUTE), @t_f725, @c_f725);
SET @ord_f725 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f725, @var_at_gym_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Đen', 310000.00, 2),
(@ord_f725, @var_qn_jog_l, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'L', 'Xám tiêu', 490000.00, 1);

-- FS2026F726 | COMPLETED | BANK_TRANSFER + PAID | total=984,000
SET @t_f726 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.19) SECOND);
SET @c_f726 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.22) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F726', @prof_khach6, @cp_saletet20, 'COMPLETED', 1230000.00, 246000.00, 984000.00, 'Trần Minh Tuấn', '0915000006', '88 Lê Lợi, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f726, INTERVAL 2 MINUTE), @t_f726, @c_f726);
SET @ord_f726 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f726, @var_sm_linen_tr_m, 'Áo sơ mi linen trắng tối giản', 'M', 'Trắng', 690000.00, 1),
(@ord_f726, @var_sm_oxf_xl, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'XL', 'Xanh biển', 540000.00, 1);

-- FS2026F727 | COMPLETED | COD + PAID | total=1,440,000
SET @t_f727 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.22) SECOND);
SET @c_f727 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.25) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F727', @prof_khach11, @cp_vip200k, 'COMPLETED', 1640000.00, 200000.00, 1440000.00, 'Bùi Thanh Thảo', '0915000011', '79 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_f727, @t_f727, @c_f727);
SET @ord_f727 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f727, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1),
(@ord_f727, @var_cv_xeply_m, 'Chân váy midi xếp ly màu kem', 'M', 'Kem', 790000.00, 1);

-- FS2026F728 | COMPLETED | E_WALLET + PAID | total=1,180,000
SET @t_f728 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.25) SECOND);
SET @c_f728 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.28) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F728', @prof_khach1, NULL, 'COMPLETED', 1180000.00, 0.00, 1180000.00, 'Lê Văn Khách', '0902000001', '12 Nguyễn Văn Bảo, Gò Vấp, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f728, INTERVAL 2 MINUTE), @t_f728, @c_f728);
SET @ord_f728 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f728, @var_at_basic_tr_l, 'Áo thun cotton basic cổ tròn màu trắng', 'L', 'Trắng', 290000.00, 3),
(@ord_f728, @var_at_gym_xl, 'Áo Thun Thể Thao Dry-Fit Đen', 'XL', 'Đen', 310000.00, 1);

-- FS2026F729 | COMPLETED | BANK_TRANSFER + PAID | total=2,440,000
SET @t_f729 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.29) SECOND);
SET @c_f729 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.32) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F729', @prof_khach2, NULL, 'COMPLETED', 2440000.00, 0.00, 2440000.00, 'Phạm Thị Mai', '0902000002', '85 Lê Lợi, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f729, INTERVAL 2 MINUTE), @t_f729, @c_f729);
SET @ord_f729 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f729, @var_dam_lua_be_s, 'Đầm lụa dáng dài màu be', 'S', 'Be', 1590000.00, 1),
(@ord_f729, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1);

-- FS2026F730 | COMPLETED | E_WALLET + PAID | total=590,000
SET @t_f730 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.32) SECOND);
SET @c_f730 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.35) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F730', @prof_khach5, @cp_freeship30, 'COMPLETED', 590000.00, 30000.00, 590000.00, 'Nguyễn Ngọc Lan', '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f730, INTERVAL 2 MINUTE), @t_f730, @c_f730);
SET @ord_f730 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f730, @var_tt_gym_m, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'M', 'Xám khói', 590000.00, 1);

-- FS2026F731 | COMPLETED | COD + PAID | total=744,000
SET @t_f731 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.36) SECOND);
SET @c_f731 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.39) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F731', @prof_khach12, @cp_welcome15, 'COMPLETED', 840000.00, 126000.00, 744000.00, 'Phan Văn Khánh', '0915000012', '240 Điện Biên Phủ, Phường 17, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_f731, @t_f731, @c_f731);
SET @ord_f731 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f731, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 2);

-- FS2026F732 | COMPLETED | BANK_TRANSFER + PAID | total=1,070,000
SET @t_f732 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.39) SECOND);
SET @c_f732 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.42) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F732', @prof_khach13, @cp_thangvang, 'COMPLETED', 1170000.00, 100000.00, 1070000.00, 'Đỗ Thị Kim Chi', '0915000013', '64 Nguyễn Trãi, Phường Thượng Đình, Quận Thanh Xuân, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f732, INTERVAL 2 MINUTE), @t_f732, @c_f732);
SET @ord_f732 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f732, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1),
(@ord_f732, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 1);

-- FS2026F733 | COMPLETED | E_WALLET + PAID | total=1,080,000
SET @t_f733 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.43) SECOND);
SET @c_f733 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.46) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F733', @prof_khach14, NULL, 'COMPLETED', 1080000.00, 0.00, 1080000.00, 'Trương Công Minh', '0915000014', '112 Trần Phú, Phường Lộc Thọ, TP. Nha Trang, Khánh Hòa', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f733, INTERVAL 2 MINUTE), @t_f733, @c_f733);
SET @ord_f733 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f733, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 2);

-- FS2026F734 | COMPLETED | BANK_TRANSFER + PAID | total=1,690,000
SET @t_f734 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.46) SECOND);
SET @c_f734 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.49) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F734', @prof_khach15, @cp_vip200k, 'COMPLETED', 1890000.00, 200000.00, 1690000.00, 'Hoàng Bảo Ngọc', '0915000015', '50 Lý Tự Trọng, Phường An Cư, Quận Ninh Kiều, Cần Thơ', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f734, INTERVAL 2 MINUTE), @t_f734, @c_f734);
SET @ord_f734 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f734, @var_dam_do_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đỏ đô', 1890000.00, 1);

-- FS2026F735 | COMPLETED | COD + PAID | total=840,000
SET @t_f735 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.5) SECOND);
SET @c_f735 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.53) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F735', @prof_khach16, @cp_freeship30, 'COMPLETED', 840000.00, 30000.00, 840000.00, 'Nguyễn Thanh Tùng', '0915000016', '18 Nguyễn Thị Minh Khai, Phường Đa Kao, Quận 1, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_f735, @t_f735, @c_f735);
SET @ord_f735 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f735, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 2);

-- FS2026F736 | COMPLETED | E_WALLET + PAID | total=872,000
SET @t_f736 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.54) SECOND);
SET @c_f736 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.57) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F736', @prof_khach19, @cp_saletet20, 'COMPLETED', 1090000.00, 218000.00, 872000.00, 'Tạ Thị Hồng Nhung', '0915000019', '190 Quang Trung, Phường 10, Quận Gò Vấp, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f736, INTERVAL 2 MINUTE), @t_f736, @c_f736);
SET @ord_f736 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f736, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1);

-- FS2026F737 | COMPLETED | COD + PAID | total=880,000
SET @t_f737 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.58) SECOND);
SET @c_f737 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.61) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F737', @prof_khach20, @cp_welcome15, 'COMPLETED', 1030000.00, 150000.00, 880000.00, 'Vương Gia Huy', '0915000020', '41 Bà Triệu, Phường Hàng Bài, Quận Hoàn Kiếm, Hà Nội', 0.00, NULL, 'COD', 'PAID', @c_f737, @t_f737, @c_f737);
SET @ord_f737 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f737, @var_sm_oxf_l, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'L', 'Xanh biển', 540000.00, 1),
(@ord_f737, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS2026F738 | COMPLETED | BANK_TRANSFER + PAID | total=1,150,000
SET @t_f738 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.62) SECOND);
SET @c_f738 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.65) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F738', @prof_khach21, @cp_thangvang, 'COMPLETED', 1250000.00, 100000.00, 1150000.00, 'Châu Ngọc Bích', '0915000021', '155 Sư Vạn Hạnh, Phường 12, Quận 10, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f738, INTERVAL 2 MINUTE), @t_f738, @c_f738);
SET @ord_f738 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f738, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1);

-- FS2026F739 | COMPLETED | E_WALLET + PAID | total=1,180,000
SET @t_f739 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.66) SECOND);
SET @c_f739 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.69) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F739', @prof_khach23, NULL, 'COMPLETED', 1180000.00, 0.00, 1180000.00, 'Đoàn Thị Phương Thảo', '0915000023', '220 Cộng Hòa, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f739, INTERVAL 2 MINUTE), @t_f739, @c_f739);
SET @ord_f739 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f739, @var_tt_gym_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Xám khói', 590000.00, 1),
(@ord_f739, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1);

-- FS2026F740 | COMPLETED | COD + PAID | total=620,000
SET @t_f740 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.7) SECOND);
SET @c_f740 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.73) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F740', @prof_khach24, @cp_freeship30, 'COMPLETED', 620000.00, 30000.00, 620000.00, 'Kiều Minh Khoa', '0915000024', '11 Nguyễn Ái Quốc, Phường Tân Phong, TP. Biên Hòa, Đồng Nai', 30000.00, NULL, 'COD', 'PAID', @c_f740, @t_f740, @c_f740);
SET @ord_f740 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f740, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 2);

-- FS2026F741 | COMPLETED | BANK_TRANSFER + PAID | total=1,390,000
SET @t_f741 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.74) SECOND);
SET @c_f741 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.77) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F741', @prof_khach26, NULL, 'COMPLETED', 1390000.00, 0.00, 1390000.00, 'Cao Tấn Lộc', '0915000026', '34 Đại lộ Bình Dương, TP. Thủ Dầu Một, Bình Dương', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f741, INTERVAL 2 MINUTE), @t_f741, @c_f741);
SET @ord_f741 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f741, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1),
(@ord_f741, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1);

-- FS2026F742 | SHIPPING | BANK_TRANSFER + PAID | total=1,250,000
SET @t_f742 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.78) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at)
VALUES ('FS2026F742', @prof_khach7, NULL, 'SHIPPING', 1250000.00, 0.00, 1250000.00, 'Lê Thị Thu Hà', '0915000007', '215 Cầu Giấy, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f742, INTERVAL 2 MINUTE), @t_f742);
SET @ord_f742 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f742, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1);

-- FS2026F743 | SHIPPING | E_WALLET + PAID | total=1,090,000
SET @t_f743 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.81) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at)
VALUES ('FS2026F743', @prof_khach19, NULL, 'SHIPPING', 1090000.00, 0.00, 1090000.00, 'Tạ Thị Hồng Nhung', '0915000019', '190 Quang Trung, Phường 10, Quận Gò Vấp, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f743, INTERVAL 2 MINUTE), @t_f743);
SET @ord_f743 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f743, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1);

-- FS2026F744 | CONFIRMED | COD + UNPAID | total=744,000
SET @t_f744 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.84) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at)
VALUES ('FS2026F744', @prof_khach8, @cp_welcome15, 'CONFIRMED', 840000.00, 126000.00, 744000.00, 'Phạm Quốc Bảo', '0915000008', '14 Phan Văn Trị, Phường 7, Quận Gò Vấp, TP.HCM', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f744);
SET @ord_f744 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f744, @var_plo_reu_xl, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'XL', 'Xanh rêu', 420000.00, 1),
(@ord_f744, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS2026F745 | CONFIRMED | COD + UNPAID | total=880,000
SET @t_f745 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.87) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at)
VALUES ('FS2026F745', @prof_khach22, NULL, 'CONFIRMED', 850000.00, 0.00, 880000.00, 'Lâm Đức Anh', '0915000022', '90 Hùng Vương, Phường Phú Nhuận, TP. Huế', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f745);
SET @ord_f745 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f745, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1);

-- FS2026F746 | PENDING | E_WALLET + UNPAID | total=1,030,000
SET @t_f746 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.9) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at)
VALUES ('FS2026F746', @prof_khach10, NULL, 'PENDING', 1030000.00, 0.00, 1030000.00, 'Đặng Hoàng Nam', '0915000010', '56 Nguyễn Văn Linh, Phường Tân Thuận Tây, Quận 7, TP.HCM', 0.00, NULL, 'E_WALLET', 'UNPAID', NULL, @t_f746);
SET @ord_f746 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f746, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1),
(@ord_f746, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS2026F747 | PENDING | COD + UNPAID | total=1,040,000
SET @t_f747 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.92) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at)
VALUES ('FS2026F747', @prof_khach25, NULL, 'PENDING', 1040000.00, 0.00, 1040000.00, 'Hà Tuyết Nhi', '0915000025', '68 Trường Chinh, Phường Tây Thạnh, Quận Tân Phú, TP.HCM', 0.00, NULL, 'COD', 'UNPAID', NULL, @t_f747);
SET @ord_f747 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f747, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1),
(@ord_f747, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 1);

-- FS2026F748 | CANCELLED | BANK_TRANSFER + FAILED | total=620,000
SET @t_f748 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.94) SECOND);
SET @x_f748 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.97) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F748', @prof_khach11, NULL, 'CANCELLED', 590000.00, 0.00, 620000.00, 'Bùi Thanh Thảo', '0915000011', '79 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM', 30000.00, NULL, 'BANK_TRANSFER', 'FAILED', NULL, @t_f748, 'Lỗi giao dịch ngân hàng khi thanh toán', @x_f748);
SET @ord_f748 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f748, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1);

-- FS2026F749 | CANCELLED | COD + UNPAID | total=340,000
SET @t_f749 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.96) SECOND);
SET @x_f749 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.99) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F749', @prof_khach30, NULL, 'CANCELLED', 310000.00, 0.00, 340000.00, 'Tô Văn Hậu', '0915000030', '19 Hậu Giang, Phường 2, Quận 6, TP.HCM', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f749, 'Khách đổi ý không nhận hàng', @x_f749);
SET @ord_f749 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f749, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 1);

-- FS2026F750 | CANCELLED | E_WALLET + FAILED | total=750,000
SET @t_f750 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.98) SECOND);
SET @x_f750 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.99) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F750', @prof_khach31, NULL, 'CANCELLED', 720000.00, 0.00, 750000.00, 'Quách Mỹ Duyên', '0915000031', '44 Nguyễn Oanh, Phường 7, Quận Gò Vấp, TP.HCM', 30000.00, NULL, 'E_WALLET', 'FAILED', NULL, @t_f750, 'Khách hủy đơn để áp thêm mã giảm giá', @x_f750);
SET @ord_f750 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_f750, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1);

-- ============================================================================
-- MỤC 5: LỊCH SỬ KHO ĐỒNG BỘ 100% CHO CẢ 35 BIẾN THỂ
-- ============================================================================
INSERT INTO stock_history (variant_id, type, quantity_change, stock_after, supplier, import_price, reason, order_id, performed_by_id, created_at) VALUES
(@var_ak_blz_m, 'IMPORT', 14, 14, 'Xưởng may thời trang FashionShop', 650000.00, 'Nhập kho Áo Khoác Blazer Nữ Đen Cổ Vest (M - Đen)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_ak_blz_m, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F705', @ord_f705, @prof_staff3, @t_f705),
(@var_ak_blz_m, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS2026F738', @ord_f738, @prof_staff3, @t_f738),
(@var_ak_blz_m, 'SALE', -1, 11, NULL, NULL, 'Xuất kho theo đơn FS2026F742', @ord_f742, @prof_staff3, @t_f742),
(@var_ak_blz_s, 'IMPORT', 11, 11, 'Xưởng may thời trang FashionShop', 650000.00, 'Nhập kho Áo Khoác Blazer Nữ Đen Cổ Vest (S - Đen)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_ak_blz_s, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS2026F717', @ord_f717, @prof_staff3, @t_f717),
(@var_ak_blz_s, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS2026F721', @ord_f721, @prof_staff3, @t_f721),
(@var_al_gil_m, 'IMPORT', 18, 18, 'Xưởng may thời trang FashionShop', 307000.00, 'Nhập kho Áo Len Gile Cổ Tim Kem Sữa (M - Kem sữa)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_al_gil_m, 'SALE', -1, 17, NULL, NULL, 'Xuất kho theo đơn FS2026F707', @ord_f707, @prof_staff3, @t_f707),
(@var_al_gil_m, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F720', @ord_f720, @prof_staff3, @t_f720),
(@var_al_gil_m, 'CANCELLED_ORDER', 1, 17, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F720', @ord_f720, @prof_khach28, DATE_ADD(@t_f720, INTERVAL 3 HOUR)),
(@var_al_gil_m, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F739', @ord_f739, @prof_staff3, @t_f739),
(@var_al_gil_m, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F748', @ord_f748, @prof_staff3, @t_f748),
(@var_al_gil_m, 'CANCELLED_ORDER', 1, 16, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F748', @ord_f748, @prof_khach11, @x_f748),
(@var_al_gil_s, 'IMPORT', 16, 16, 'Xưởng may thời trang FashionShop', 307000.00, 'Nhập kho Áo Len Gile Cổ Tim Kem Sữa (S - Kem sữa)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_al_gil_s, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F715', @ord_f715, @prof_staff3, @t_f715),
(@var_al_gil_s, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS2026F724', @ord_f724, @prof_staff3, @t_f724),
(@var_al_gil_s, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F747', @ord_f747, @prof_staff3, @t_f747),
(@var_at_basic_tr_l, 'IMPORT', 38, 38, 'Xưởng dệt may Phong Phú', 140000.00, 'Nhập kho Áo thun cotton basic cổ tròn màu trắng (L - Trắng)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_at_basic_tr_l, 'SALE', -3, 35, NULL, NULL, 'Xuất kho theo đơn FS2026F728', @ord_f728, @prof_staff3, @t_f728),
(@var_at_gym_l, 'IMPORT', 28, 28, 'Xưởng may thời trang FashionShop', 161000.00, 'Nhập kho Áo Thun Thể Thao Dry-Fit Đen (L - Đen)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_at_gym_l, 'SALE', -1, 27, NULL, NULL, 'Xuất kho theo đơn FS2026F712', @ord_f712, @prof_staff3, @t_f712),
(@var_at_gym_l, 'SALE', -2, 25, NULL, NULL, 'Xuất kho theo đơn FS2026F725', @ord_f725, @prof_staff3, @t_f725),
(@var_at_gym_m, 'IMPORT', 33, 33, 'Xưởng may thời trang FashionShop', 161000.00, 'Nhập kho Áo Thun Thể Thao Dry-Fit Đen (M - Đen)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_at_gym_m, 'SALE', -1, 32, NULL, NULL, 'Xuất kho theo đơn FS2026F704', @ord_f704, @prof_staff3, @t_f704),
(@var_at_gym_m, 'SALE', -2, 30, NULL, NULL, 'Xuất kho theo đơn FS2026F740', @ord_f740, @prof_staff3, @t_f740),
(@var_at_gym_m, 'SALE', -1, 29, NULL, NULL, 'Xuất kho theo đơn FS2026F749', @ord_f749, @prof_staff3, @t_f749),
(@var_at_gym_m, 'CANCELLED_ORDER', 1, 30, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F749', @ord_f749, @prof_khach30, @x_f749),
(@var_at_gym_xl, 'IMPORT', 14, 14, 'Xưởng may thời trang FashionShop', 161000.00, 'Nhập kho Áo Thun Thể Thao Dry-Fit Đen (XL - Đen)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_at_gym_xl, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F716', @ord_f716, @prof_staff3, @t_f716),
(@var_at_gym_xl, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS2026F728', @ord_f728, @prof_staff3, @t_f728),
(@var_cd_den_l, 'IMPORT', 20, 20, 'Xưởng may thời trang FashionShop', 218000.00, 'Nhập kho Áo Cardigan Len Mỏng Cổ Chữ V (L - Đen)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_cd_den_l, 'SALE', -1, 19, NULL, NULL, 'Xuất kho theo đơn FS2026F716', @ord_f716, @prof_staff3, @t_f716),
(@var_cd_den_l, 'SALE', -1, 18, NULL, NULL, 'Xuất kho theo đơn FS2026F723', @ord_f723, @prof_staff3, @t_f723),
(@var_cd_kem_m, 'IMPORT', 24, 24, 'Xưởng may thời trang FashionShop', 218000.00, 'Nhập kho Áo Cardigan Len Mỏng Cổ Chữ V (M - Nâu kem)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_cd_kem_m, 'SALE', -1, 23, NULL, NULL, 'Xuất kho theo đơn FS2026F702', @ord_f702, @prof_staff3, @t_f702),
(@var_cd_kem_m, 'SALE', -2, 21, NULL, NULL, 'Xuất kho theo đơn FS2026F735', @ord_f735, @prof_staff3, @t_f735),
(@var_cd_kem_m, 'SALE', -1, 20, NULL, NULL, 'Xuất kho theo đơn FS2026F744', @ord_f744, @prof_staff3, @t_f744),
(@var_cv_xeply_m, 'IMPORT', 19, 19, 'Xưởng thiết kế Lam Boutique', 390000.00, 'Nhập kho Chân váy midi xếp ly màu kem (M - Kem)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_cv_xeply_m, 'SALE', -1, 18, NULL, NULL, 'Xuất kho theo đơn FS2026F727', @ord_f727, @prof_staff3, @t_f727),
(@var_dam_do_m, 'IMPORT', 10, 10, 'Xưởng may thời trang FashionShop', 983000.00, 'Nhập kho Đầm Dự Tiệc Satin Đỏ Đô (M - Đỏ đô)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_dam_do_m, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS2026F701', @ord_f701, @prof_staff3, @t_f701),
(@var_dam_do_m, 'SALE', -1, 8, NULL, NULL, 'Xuất kho theo đơn FS2026F734', @ord_f734, @prof_staff3, @t_f734),
(@var_dam_do_s, 'IMPORT', 8, 8, 'Xưởng may thời trang FashionShop', 983000.00, 'Nhập kho Đầm Dự Tiệc Satin Đỏ Đô (S - Đỏ đô)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_dam_do_s, 'SALE', -1, 7, NULL, NULL, 'Xuất kho theo đơn FS2026F714', @ord_f714, @prof_staff3, @t_f714),
(@var_dam_do_s, 'SALE', -1, 6, NULL, NULL, 'Xuất kho theo đơn FS2026F721', @ord_f721, @prof_staff3, @t_f721),
(@var_dam_lua_be_s, 'IMPORT', 14, 14, 'Xưởng thiết kế Lam Boutique', 820000.00, 'Nhập kho Đầm lụa dáng dài màu be (S - Be)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_dam_lua_be_s, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F708', @ord_f708, @prof_staff3, @t_f708),
(@var_dam_lua_be_s, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS2026F729', @ord_f729, @prof_staff3, @t_f729),
(@var_dam_pas_l, 'IMPORT', 4, 4, 'Xưởng may thời trang FashionShop', 567000.00, 'Nhập kho Đầm Sơ Mi Lụa Pastel Tay Bồng (L - Hồng pastel)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_dam_pas_l, 'ADJUSTMENT', -4, 0, NULL, NULL, 'Thu hồi 4 sản phẩm size L trả xưởng do lỗi đường chỉ', NULL, @prof_staff6, DATE_SUB(@prev_m_last_day, INTERVAL 20 DAY)),
(@var_dam_pas_m, 'IMPORT', 15, 15, 'Xưởng may thời trang FashionShop', 567000.00, 'Nhập kho Đầm Sơ Mi Lụa Pastel Tay Bồng (M - Hồng pastel)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_dam_pas_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS2026F711', @ord_f711, @prof_staff3, @t_f711),
(@var_dam_pas_m, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F724', @ord_f724, @prof_staff3, @t_f724),
(@var_dam_pas_m, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS2026F743', @ord_f743, @prof_staff3, @t_f743),
(@var_dam_pas_s, 'IMPORT', 12, 12, 'Xưởng may thời trang FashionShop', 567000.00, 'Nhập kho Đầm Sơ Mi Lụa Pastel Tay Bồng (S - Hồng pastel)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_dam_pas_s, 'SALE', -1, 11, NULL, NULL, 'Xuất kho theo đơn FS2026F703', @ord_f703, @prof_staff3, @t_f703),
(@var_dam_pas_s, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS2026F736', @ord_f736, @prof_staff3, @t_f736),
(@var_hd_xam_l, 'IMPORT', 5, 5, 'Xưởng may thời trang FashionShop', 338000.00, 'Nhập kho Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán) (L - Xám)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_plo_kem_m, 'IMPORT', 24, 24, 'Xưởng may thời trang FashionShop', 234000.00, 'Nhập kho Áo Polo Nữ Cổ Phối Trắng Kem (M - Kem)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_plo_kem_m, 'SALE', -2, 22, NULL, NULL, 'Xuất kho theo đơn FS2026F713', @ord_f713, @prof_staff3, @t_f713),
(@var_plo_kem_m, 'SALE', -2, 20, NULL, NULL, 'Xuất kho theo đơn FS2026F722', @ord_f722, @prof_staff3, @t_f722),
(@var_plo_kem_s, 'IMPORT', 18, 18, 'Xưởng may thời trang FashionShop', 234000.00, 'Nhập kho Áo Polo Nữ Cổ Phối Trắng Kem (S - Kem)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_plo_kem_s, 'SALE', -1, 17, NULL, NULL, 'Xuất kho theo đơn FS2026F707', @ord_f707, @prof_staff3, @t_f707),
(@var_plo_kem_s, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F732', @ord_f732, @prof_staff3, @t_f732),
(@var_plo_kem_s, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F747', @ord_f747, @prof_staff3, @t_f747),
(@var_plo_reu_l, 'IMPORT', 20, 20, 'Xưởng may thời trang FashionShop', 218000.00, 'Nhập kho Áo Polo Nam Dệt Kim Xanh Rêu (L - Xanh rêu)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_plo_reu_l, 'SALE', -1, 19, NULL, NULL, 'Xuất kho theo đơn FS2026F718', @ord_f718, @prof_staff3, @t_f718),
(@var_plo_reu_l, 'CANCELLED_ORDER', 1, 20, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F718', @ord_f718, @prof_khach29, DATE_ADD(@t_f718, INTERVAL 3 HOUR)),
(@var_plo_reu_l, 'SALE', -2, 18, NULL, NULL, 'Xuất kho theo đơn FS2026F723', @ord_f723, @prof_staff3, @t_f723),
(@var_plo_reu_m, 'IMPORT', 29, 29, 'Xưởng may thời trang FashionShop', 218000.00, 'Nhập kho Áo Polo Nam Dệt Kim Xanh Rêu (M - Xanh rêu)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_plo_reu_m, 'SALE', -2, 27, NULL, NULL, 'Xuất kho theo đơn FS2026F702', @ord_f702, @prof_staff3, @t_f702),
(@var_plo_reu_m, 'SALE', -2, 25, NULL, NULL, 'Xuất kho theo đơn FS2026F731', @ord_f731, @prof_staff3, @t_f731),
(@var_plo_reu_xl, 'IMPORT', 5, 5, 'Xưởng may thời trang FashionShop', 218000.00, 'Nhập kho Áo Polo Nam Dệt Kim Xanh Rêu (XL - Xanh rêu)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_plo_reu_xl, 'SALE', -1, 4, NULL, NULL, 'Xuất kho theo đơn FS2026F744', @ord_f744, @prof_staff3, @t_f744),
(@var_qn_cul_m, 'IMPORT', 19, 19, 'Xưởng may thời trang FashionShop', 374000.00, 'Nhập kho Quần Culottes Ống Rộng Trắng Kem (M - Trắng kem)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_qn_cul_m, 'SALE', -1, 18, NULL, NULL, 'Xuất kho theo đơn FS2026F715', @ord_f715, @prof_staff3, @t_f715),
(@var_qn_cul_m, 'SALE', -1, 17, NULL, NULL, 'Xuất kho theo đơn FS2026F722', @ord_f722, @prof_staff3, @t_f722),
(@var_qn_cul_s, 'IMPORT', 16, 16, 'Xưởng may thời trang FashionShop', 374000.00, 'Nhập kho Quần Culottes Ống Rộng Trắng Kem (S - Trắng kem)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_qn_cul_s, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F705', @ord_f705, @prof_staff3, @t_f705),
(@var_qn_cul_s, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS2026F732', @ord_f732, @prof_staff3, @t_f732),
(@var_qn_cul_s, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F750', @ord_f750, @prof_staff3, @t_f750),
(@var_qn_cul_s, 'CANCELLED_ORDER', 1, 14, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F750', @ord_f750, @prof_khach31, @x_f750),
(@var_qn_jog_l, 'IMPORT', 5, 5, 'Xưởng may thời trang FashionShop', 255000.00, 'Nhập kho Quần Jogger Nỉ Unisex Xám Tiêu (L - Xám tiêu)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_qn_jog_l, 'ADJUSTMENT', -1, 4, NULL, NULL, 'Kiểm kê định kỳ phát hiện thiếu 1 chiếc size L', NULL, @prof_staff6, DATE_SUB(@prev_m_last_day, INTERVAL 20 DAY)),
(@var_qn_jog_l, 'SALE', -1, 3, NULL, NULL, 'Xuất kho theo đơn FS2026F725', @ord_f725, @prof_staff3, @t_f725),
(@var_qn_jog_m, 'IMPORT', 23, 23, 'Xưởng may thời trang FashionShop', 255000.00, 'Nhập kho Quần Jogger Nỉ Unisex Xám Tiêu (M - Xám tiêu)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_qn_jog_m, 'SALE', -1, 22, NULL, NULL, 'Xuất kho theo đơn FS2026F706', @ord_f706, @prof_staff3, @t_f706),
(@var_qn_jog_m, 'SALE', -1, 21, NULL, NULL, 'Xuất kho theo đơn FS2026F719', @ord_f719, @prof_staff3, @t_f719),
(@var_qn_jog_m, 'CANCELLED_ORDER', 1, 22, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F719', @ord_f719, @prof_khach42, DATE_ADD(@t_f719, INTERVAL 3 HOUR)),
(@var_qn_jog_m, 'SALE', -1, 21, NULL, NULL, 'Xuất kho theo đơn FS2026F737', @ord_f737, @prof_staff3, @t_f737),
(@var_qn_jog_m, 'SALE', -1, 20, NULL, NULL, 'Xuất kho theo đơn FS2026F746', @ord_f746, @prof_staff3, @t_f746),
(@var_sm_linen_tr_m, 'IMPORT', 26, 26, 'Xưởng may Nhà Bè', 340000.00, 'Nhập kho Áo sơ mi linen trắng tối giản (M - Trắng)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_sm_linen_tr_m, 'SALE', -1, 25, NULL, NULL, 'Xuất kho theo đơn FS2026F726', @ord_f726, @prof_staff3, @t_f726),
(@var_sm_oxf_l, 'IMPORT', 18, 18, 'Xưởng may thời trang FashionShop', 281000.00, 'Nhập kho Áo Sơ Mi Oxford Nam Xanh Biển (L - Xanh biển)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_sm_oxf_l, 'SALE', -1, 17, NULL, NULL, 'Xuất kho theo đơn FS2026F704', @ord_f704, @prof_staff3, @t_f704),
(@var_sm_oxf_l, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F737', @ord_f737, @prof_staff3, @t_f737),
(@var_sm_oxf_m, 'IMPORT', 26, 26, 'Xưởng may thời trang FashionShop', 281000.00, 'Nhập kho Áo Sơ Mi Oxford Nam Xanh Biển (M - Xanh biển)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_sm_oxf_m, 'SALE', -1, 25, NULL, NULL, 'Xuất kho theo đơn FS2026F710', @ord_f710, @prof_staff3, @t_f710),
(@var_sm_oxf_m, 'CANCELLED_ORDER', 1, 26, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F710', @ord_f710, @prof_khach6, DATE_ADD(@t_f710, INTERVAL 3 HOUR)),
(@var_sm_oxf_m, 'SALE', -2, 24, NULL, NULL, 'Xuất kho theo đơn FS2026F733', @ord_f733, @prof_staff3, @t_f733),
(@var_sm_oxf_m, 'SALE', -1, 23, NULL, NULL, 'Xuất kho theo đơn FS2026F741', @ord_f741, @prof_staff3, @t_f741),
(@var_sm_oxf_m, 'SALE', -1, 22, NULL, NULL, 'Xuất kho theo đơn FS2026F746', @ord_f746, @prof_staff3, @t_f746),
(@var_sm_oxf_xl, 'IMPORT', 11, 11, 'Xưởng may thời trang FashionShop', 281000.00, 'Nhập kho Áo Sơ Mi Oxford Nam Xanh Biển (XL - Xanh biển)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_sm_oxf_xl, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS2026F712', @ord_f712, @prof_staff3, @t_f712),
(@var_sm_oxf_xl, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS2026F726', @ord_f726, @prof_staff3, @t_f726),
(@var_tt_gym_m, 'IMPORT', 1, 1, 'Xưởng may thời trang FashionShop', 307000.00, 'Nhập kho Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều (M - Xám khói)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_tt_gym_m, 'SALE', -1, 0, NULL, NULL, 'Xuất kho theo đơn FS2026F730', @ord_f730, @prof_staff3, @t_f730),
(@var_tt_gym_s, 'IMPORT', 17, 17, 'Xưởng may thời trang FashionShop', 307000.00, 'Nhập kho Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều (S - Xám khói)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_tt_gym_s, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F706', @ord_f706, @prof_staff3, @t_f706),
(@var_tt_gym_s, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F739', @ord_f739, @prof_staff3, @t_f739),
(@var_vs_den_m, 'IMPORT', 17, 17, 'Xưởng may thời trang FashionShop', 442000.00, 'Nhập kho Áo Vest Nam Công Sở Slimfit Đen (M - Đen)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_vs_den_m, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F701', @ord_f701, @prof_staff3, @t_f701),
(@var_vs_den_m, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F727', @ord_f727, @prof_staff3, @t_f727),
(@var_vs_den_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS2026F741', @ord_f741, @prof_staff3, @t_f741),
(@var_vs_xam_l, 'IMPORT', 10, 10, 'Xưởng may thời trang FashionShop', 442000.00, 'Nhập kho Áo Vest Nam Công Sở Slimfit Đen (L - Xám than)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
(@var_vs_xam_l, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS2026F709', @ord_f709, @prof_staff3, @t_f709),
(@var_vs_xam_l, 'SALE', -1, 8, NULL, NULL, 'Xuất kho theo đơn FS2026F729', @ord_f729, @prof_staff3, @t_f729),
(@var_vs_xam_l, 'SALE', -1, 7, NULL, NULL, 'Xuất kho theo đơn FS2026F745', @ord_f745, @prof_staff3, @t_f745);

-- ============================================================================
-- MỤC 6: GIỎ HÀNG (10 dòng) & YÊU THÍCH (14 dòng) - gồm nhóm D chưa từng đặt đơn
-- ============================================================================
INSERT INTO cart_item (user_profile_id, variant_id, quantity, added_at) VALUES
(@prof_khach5,  @var_dam_pas_s, 1, DATE_SUB(NOW(6), INTERVAL 2 DAY)),
(@prof_khach5,  @var_vs_xam_l,  1, DATE_SUB(NOW(6), INTERVAL 1 DAY)),
(@prof_khach6,  @var_plo_reu_l, 2, DATE_SUB(NOW(6), INTERVAL 3 DAY)),
(@prof_khach8,  @var_cd_den_l,  1, DATE_SUB(NOW(6), INTERVAL 12 HOUR)),
(@prof_khach10, @var_at_gym_m,  2, DATE_SUB(NOW(6), INTERVAL 6 HOUR)),
(@prof_khach32, @var_al_gil_s,  1, DATE_SUB(NOW(6), INTERVAL 5 DAY)),
(@prof_khach32, @var_qn_cul_m,  1, DATE_SUB(NOW(6), INTERVAL 4 DAY)),
(@prof_khach33, @var_plo_kem_m, 1, DATE_SUB(NOW(6), INTERVAL 2 DAY)),
(@prof_khach33, @var_sm_oxf_m,  1, DATE_SUB(NOW(6), INTERVAL 1 DAY)),
(@prof_khach35, @var_cd_kem_m,  1, DATE_SUB(NOW(6), INTERVAL 10 HOUR));

INSERT INTO wishlist_item (user_profile_id, product_id, added_at) VALUES
(@prof_khach5,  @prod_dam_do,   DATE_SUB(NOW(6), INTERVAL 15 DAY)),
(@prof_khach5,  @prod_ak_blz,   DATE_SUB(NOW(6), INTERVAL 10 DAY)),
(@prof_khach7,  @prod_dam_pas,  DATE_SUB(NOW(6), INTERVAL 12 DAY)),
(@prof_khach7,  @prod_vs_den,   DATE_SUB(NOW(6), INTERVAL 6 DAY)),
(@prof_khach9,  @prod_qn_cul,   DATE_SUB(NOW(6), INTERVAL 8 DAY)),
(@prof_khach9,  @prod_al_gil,   DATE_SUB(NOW(6), INTERVAL 4 DAY)),
(@prof_khach11, @prod_tt_gym,   DATE_SUB(NOW(6), INTERVAL 5 DAY)),
(@prof_khach11, @prod_polo_kem, DATE_SUB(NOW(6), INTERVAL 3 DAY)),
(@prof_khach34, @prod_polo_reu, DATE_SUB(NOW(6), INTERVAL 14 DAY)),
(@prof_khach34, @prod_sm_oxf,   DATE_SUB(NOW(6), INTERVAL 14 DAY)),
(@prof_khach34, @prod_cd_len,   DATE_SUB(NOW(6), INTERVAL 9 DAY)),
(@prof_khach34, @prod_qn_jog,   DATE_SUB(NOW(6), INTERVAL 7 DAY)),
(@prof_khach35, @prod_vs_den,   DATE_SUB(NOW(6), INTERVAL 5 DAY)),
(@prof_khach32, @prod_dam_do,   DATE_SUB(NOW(6), INTERVAL 3 DAY));

-- ============================================================================
-- MỤC 7: TRUY VẤN KIỂM CHỨNG TOÀN VẸN & TỔNG QUAN DỮ LIỆU
-- ============================================================================
SELECT
    (SELECT COUNT(*) FROM orders o
     WHERE o.subtotal <> (SELECT SUM(i.unit_price * i.quantity) FROM order_item i WHERE i.order_id = o.id)
        OR o.total_amount <> o.subtotal - o.discount_amount + o.shipping_fee) AS so_don_sai_tong_tien,
    (SELECT COUNT(*) FROM product_variant v
     JOIN stock_history h ON h.id = (SELECT MAX(id) FROM stock_history WHERE variant_id = v.id)
     WHERE h.stock_after <> v.stock_quantity) AS so_bien_the_lech_kho,
    (SELECT COUNT(*) FROM coupon c
     WHERE c.code IN ('WELCOME15', 'FREESHIP30', 'VIP200K', 'SALETET20', 'THANGVANG', 'NOEL2025')
       AND c.used_count <> (SELECT COUNT(*) FROM orders o WHERE o.coupon_id = c.id AND o.status <> 'CANCELLED')) AS so_coupon_lech_luot_dung;

SELECT role, status, COUNT(*) AS so_luong FROM account GROUP BY role, status ORDER BY role, status;

SELECT
    (SELECT COUNT(*) FROM account)          AS tong_tai_khoan,
    (SELECT COUNT(*) FROM category)         AS tong_danh_muc,
    (SELECT COUNT(*) FROM product)          AS tong_san_pham,
    (SELECT COUNT(*) FROM product_variant)  AS tong_bien_the,
    (SELECT COUNT(*) FROM coupon)           AS tong_ma_giam_gia,
    (SELECT COUNT(*) FROM orders)           AS tong_don_hang,
    (SELECT COUNT(*) FROM order_item)       AS tong_chi_tiet_don,
    (SELECT COUNT(*) FROM stock_history)    AS tong_lich_su_kho,
    (SELECT COUNT(*) FROM cart_item)        AS tong_gio_hang,
    (SELECT COUNT(*) FROM wishlist_item)    AS tong_yeu_thich;
