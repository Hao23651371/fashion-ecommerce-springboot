-- ============================================================================
-- FASHION SHOP - FILE DỮ LIỆU MỞ RỘNG BIẾN THỂ & THỐNG KÊ ĐA NĂM (fashion7.sql)
-- Mục đích:
--   1. Bổ sung 208 biến thể (size + màu sắc) phân chia đầy đủ cho toàn bộ 30 sản phẩm
--      từ fashion2.sql & fashion6.sql (mỗi sản phẩm đều sử dụng đúng 1 ảnh chính hiện có).
--   2. Bổ sung 100 đơn hàng mua THÀNH CÔNG (COMPLETED + PAID) trải dài 3 năm liên tiếp
--      (Y-2, Y-1, Y) với mật độ theo ngày có chủ đích (ngày 0 đơn, ngày ít, ngày cao điểm)
--      phục vụ mọi bộ lọc Ngày / Tuần / Tháng / Năm trên trang /admin/statistics.
-- Quy mô thêm mới trong fashion7.sql:
--   + 208 Biến thể sản phẩm mới (trải đều khắp 30 sản phẩm)
--   + 10 Tài khoản khách hàng mới (khach47 -> khach56) + hồ sơ + địa chỉ giao hàng
--   + 3 Mã giảm giá theo năm (SALE2024, SALE2025, SALE2026)
--   + 100 Đơn hàng COMPLETED + PAID (24 đơn Y-2, 36 đơn Y-1, 40 đơn Y)
--   + Đầy đủ order_item (khớp 100% tên sản phẩm gốc) & stock_history đồng bộ 100% tồn kho
-- Điều kiện: Chạy SAU khi đã chạy xong fashion1.sql -> fashion6.sql.
-- Tương thích: MariaDB 10.6+ / 11.7+ (HeidiSQL: Ctrl+A -> F9).
-- ============================================================================

SET NAMES utf8mb4;
USE fashionshop;

-- ============================================================================
-- 0. BIẾN THỜI GIAN ĐỘNG THEO NĂM HIỆN TẠI & THAM CHIẾU DỮ LIỆU CÓ SẴN
-- ============================================================================
SET @pw_khach := '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye'; -- Khach@123
SET @y0_num := YEAR(CURDATE());
SET @y1_num := YEAR(CURDATE()) - 1;
SET @y2_num := YEAR(CURDATE()) - 2;

SET @y0_start := STR_TO_DATE(CONCAT(@y0_num, '-01-01 00:00:00'), '%Y-%m-%d %H:%i:%s');
SET @cur_m_start := STR_TO_DATE(DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00'), '%Y-%m-%d %H:%i:%s');
SET @ytd_prev_span := GREATEST(TIMESTAMPDIFF(SECOND, @y0_start, DATE_SUB(@cur_m_start, INTERVAL 1 DAY)), 86400);

SELECT up.id INTO @prof_staff3 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'staff3@fashionshop.vn' LIMIT 1;

SELECT up.id INTO @prof_khach5 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach5@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach6 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach6@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach7 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach7@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach8 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach8@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach9 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach9@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach10 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach10@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach11 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach11@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach12 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach12@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach13 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach13@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach14 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach14@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach15 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach15@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach16 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach16@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach17 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach17@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach18 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach18@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach19 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach19@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach20 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach20@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach21 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach21@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach22 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach22@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach23 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach23@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach24 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach24@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach25 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach25@gmail.com' LIMIT 1;
SELECT up.id INTO @prof_khach26 FROM user_profile up JOIN account a ON up.account_id = a.id WHERE a.email = 'khach26@gmail.com' LIMIT 1;

SELECT id, stock_quantity INTO @var_plo_reu_m, @base_plo_reu_m FROM product_variant WHERE sku = 'PLO-REU-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_plo_reu_l, @base_plo_reu_l FROM product_variant WHERE sku = 'PLO-REU-L' LIMIT 1;
SELECT id, stock_quantity INTO @var_plo_kem_s, @base_plo_kem_s FROM product_variant WHERE sku = 'PLO-KEM-S' LIMIT 1;
SELECT id, stock_quantity INTO @var_plo_kem_m, @base_plo_kem_m FROM product_variant WHERE sku = 'PLO-KEM-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_dam_pas_s, @base_dam_pas_s FROM product_variant WHERE sku = 'DAM-PAS-S' LIMIT 1;
SELECT id, stock_quantity INTO @var_dam_pas_m, @base_dam_pas_m FROM product_variant WHERE sku = 'DAM-PAS-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_dam_do_s, @base_dam_do_s FROM product_variant WHERE sku = 'DAM-DO-S' LIMIT 1;
SELECT id, stock_quantity INTO @var_dam_do_m, @base_dam_do_m FROM product_variant WHERE sku = 'DAM-DO-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_sm_oxf_m, @base_sm_oxf_m FROM product_variant WHERE sku = 'SM-OXF-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_sm_oxf_l, @base_sm_oxf_l FROM product_variant WHERE sku = 'SM-OXF-L' LIMIT 1;
SELECT id, stock_quantity INTO @var_qn_cul_s, @base_qn_cul_s FROM product_variant WHERE sku = 'QN-CUL-S' LIMIT 1;
SELECT id, stock_quantity INTO @var_qn_cul_m, @base_qn_cul_m FROM product_variant WHERE sku = 'QN-CUL-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_qn_jog_m, @base_qn_jog_m FROM product_variant WHERE sku = 'QN-JOG-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_ak_blz_s, @base_ak_blz_s FROM product_variant WHERE sku = 'AK-BLZ-S' LIMIT 1;
SELECT id, stock_quantity INTO @var_ak_blz_m, @base_ak_blz_m FROM product_variant WHERE sku = 'AK-BLZ-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_at_gym_m, @base_at_gym_m FROM product_variant WHERE sku = 'AT-GYM-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_at_gym_l, @base_at_gym_l FROM product_variant WHERE sku = 'AT-GYM-L' LIMIT 1;
SELECT id, stock_quantity INTO @var_al_gil_s, @base_al_gil_s FROM product_variant WHERE sku = 'AL-GIL-S' LIMIT 1;
SELECT id, stock_quantity INTO @var_al_gil_m, @base_al_gil_m FROM product_variant WHERE sku = 'AL-GIL-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_vs_den_m, @base_vs_den_m FROM product_variant WHERE sku = 'VS-DEN-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_vs_xam_l, @base_vs_xam_l FROM product_variant WHERE sku = 'VS-XAM-L' LIMIT 1;
SELECT id, stock_quantity INTO @var_cd_kem_m, @base_cd_kem_m FROM product_variant WHERE sku = 'CD-KEM-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_cd_den_l, @base_cd_den_l FROM product_variant WHERE sku = 'CD-DEN-L' LIMIT 1;
SELECT id, stock_quantity INTO @var_tt_gym_s, @base_tt_gym_s FROM product_variant WHERE sku = 'TT-GYM-S' LIMIT 1;
SELECT id, stock_quantity INTO @var_sm_linen_tr_m, @base_sm_linen_tr_m FROM product_variant WHERE sku = 'SM-LINEN-TR-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_at_basic_tr_l, @base_at_basic_tr_l FROM product_variant WHERE sku = 'AT-BASIC-TR-L' LIMIT 1;
SELECT id, stock_quantity INTO @var_cv_xeply_m, @base_cv_xeply_m FROM product_variant WHERE sku = 'CV-XEPLY-KEM-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_dam_lua_be_m, @base_dam_lua_be_m FROM product_variant WHERE sku = 'DAM-LUA-BE-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_trench_camel_m, @base_trench_camel_m FROM product_variant WHERE sku = 'TRENCH-CAMEL-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_blz_nam_xam_m, @base_blz_nam_xam_m FROM product_variant WHERE sku = 'BLAZER-NAM-XAM-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_qj_ongrong_m, @base_qj_ongrong_m FROM product_variant WHERE sku = 'QJ-ONGRONG-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_ak_denim_l, @base_ak_denim_l FROM product_variant WHERE sku = 'AK-DENIM-L' LIMIT 1;
SELECT id, stock_quantity INTO @var_al_colo_m, @base_al_colo_m FROM product_variant WHERE sku = 'AL-COLO-NAU-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_qs_kaki_m, @base_qs_kaki_m FROM product_variant WHERE sku = 'QS-KAKI-REU-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_dam_hoanhi_m, @base_dam_hoanhi_m FROM product_variant WHERE sku = 'DAM-HOANHI-HP-M' LIMIT 1;
SELECT id, stock_quantity INTO @var_sm_nam_ks_l, @base_sm_nam_ks_l FROM product_variant WHERE sku = 'SM-NAM-KS-L' LIMIT 1;

-- ============================================================================
-- MỤC 1: BỔ SUNG 208 BIẾN THỂ SẢN PHẨM (NHIỀU SIZE / MÀU CHO TOÀN BỘ 30 SẢN PHẨM)
-- ============================================================================
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be' LIMIT 1), 'XL', 'Be', 'DAM-LUA-BE-XL', 6, 'ACTIVE', 0);
SET @var_nv_dam_lua_be_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be' LIMIT 1), 'S', 'Vàng champagne', 'DAM-LUA-VC-S', 10, 'ACTIVE', 0);
SET @var_nv_dam_lua_vc_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be' LIMIT 1), 'M', 'Vàng champagne', 'DAM-LUA-VC-M', 14, 'ACTIVE', 0);
SET @var_nv_dam_lua_vc_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be' LIMIT 1), 'L', 'Vàng champagne', 'DAM-LUA-VC-L', 9, 'ACTIVE', 0);
SET @var_nv_dam_lua_vc_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be' LIMIT 1), 'S', 'Đen', 'DAM-LUA-DEN-S', 11, 'ACTIVE', 0);
SET @var_nv_dam_lua_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be' LIMIT 1), 'M', 'Đen', 'DAM-LUA-DEN-M', 15, 'ACTIVE', 0);
SET @var_nv_dam_lua_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be' LIMIT 1), 'L', 'Đen', 'DAM-LUA-DEN-L', 7, 'ACTIVE', 0);
SET @var_nv_dam_lua_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản' LIMIT 1), 'XL', 'Trắng', 'SM-LINEN-TR-XL', 12, 'ACTIVE', 0);
SET @var_nv_sm_linen_tr_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản' LIMIT 1), 'S', 'Xanh nhạt', 'SM-LINEN-XN-S', 14, 'ACTIVE', 0);
SET @var_nv_sm_linen_xn_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản' LIMIT 1), 'L', 'Xanh nhạt', 'SM-LINEN-XN-L', 16, 'ACTIVE', 0);
SET @var_nv_sm_linen_xn_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản' LIMIT 1), 'XL', 'Xanh nhạt', 'SM-LINEN-XN-XL', 8, 'ACTIVE', 0);
SET @var_nv_sm_linen_xn_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản' LIMIT 1), 'S', 'Kem be', 'SM-LINEN-KB-S', 15, 'ACTIVE', 0);
SET @var_nv_sm_linen_kb_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản' LIMIT 1), 'M', 'Kem be', 'SM-LINEN-KB-M', 20, 'ACTIVE', 0);
SET @var_nv_sm_linen_kb_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản' LIMIT 1), 'L', 'Kem be', 'SM-LINEN-KB-L', 14, 'ACTIVE', 0);
SET @var_nv_sm_linen_kb_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản' LIMIT 1), 'XL', 'Kem be', 'SM-LINEN-KB-XL', 9, 'ACTIVE', 0);
SET @var_nv_sm_linen_kb_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen' LIMIT 1), 'XL', 'Đen', 'QT-ONGDUNG-D-XL', 7, 'ACTIVE', 0);
SET @var_nv_qt_ongdung_d_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen' LIMIT 1), 'S', 'Xám khói', 'QT-ONGDUNG-XK-S', 12, 'ACTIVE', 0);
SET @var_nv_qt_ongdung_xk_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen' LIMIT 1), 'M', 'Xám khói', 'QT-ONGDUNG-XK-M', 15, 'ACTIVE', 0);
SET @var_nv_qt_ongdung_xk_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen' LIMIT 1), 'L', 'Xám khói', 'QT-ONGDUNG-XK-L', 10, 'ACTIVE', 0);
SET @var_nv_qt_ongdung_xk_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen' LIMIT 1), 'S', 'Be nâu', 'QT-ONGDUNG-BN-S', 11, 'ACTIVE', 0);
SET @var_nv_qt_ongdung_bn_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen' LIMIT 1), 'M', 'Be nâu', 'QT-ONGDUNG-BN-M', 14, 'ACTIVE', 0);
SET @var_nv_qt_ongdung_bn_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen' LIMIT 1), 'L', 'Be nâu', 'QT-ONGDUNG-BN-L', 8, 'ACTIVE', 0);
SET @var_nv_qt_ongdung_bn_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel' LIMIT 1), 'XL', 'Camel', 'TRENCH-CAMEL-XL', 4, 'ACTIVE', 0);
SET @var_nv_trench_camel_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel' LIMIT 1), 'S', 'Đen', 'TRENCH-DEN-S', 6, 'ACTIVE', 0);
SET @var_nv_trench_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel' LIMIT 1), 'M', 'Đen', 'TRENCH-DEN-M', 9, 'ACTIVE', 0);
SET @var_nv_trench_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel' LIMIT 1), 'L', 'Đen', 'TRENCH-DEN-L', 5, 'ACTIVE', 0);
SET @var_nv_trench_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel' LIMIT 1), 'S', 'Be nhạt', 'TRENCH-BE-S', 7, 'ACTIVE', 0);
SET @var_nv_trench_be_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel' LIMIT 1), 'M', 'Be nhạt', 'TRENCH-BE-M', 10, 'ACTIVE', 0);
SET @var_nv_trench_be_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel' LIMIT 1), 'L', 'Be nhạt', 'TRENCH-BE-L', 6, 'ACTIVE', 0);
SET @var_nv_trench_be_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro' LIMIT 1), 'S', 'Xám tro', 'BLAZER-NAM-XAM-S', 6, 'ACTIVE', 0);
SET @var_nv_blazer_nam_xam_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro' LIMIT 1), 'XXL', 'Xám tro', 'BLAZER-NAM-XAM-XXL', 3, 'ACTIVE', 0);
SET @var_nv_blazer_nam_xam_xxl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro' LIMIT 1), 'M', 'Xanh navy', 'BLAZER-NAM-NV-M', 8, 'ACTIVE', 0);
SET @var_nv_blazer_nam_nv_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro' LIMIT 1), 'L', 'Xanh navy', 'BLAZER-NAM-NV-L', 10, 'ACTIVE', 0);
SET @var_nv_blazer_nam_nv_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro' LIMIT 1), 'XL', 'Xanh navy', 'BLAZER-NAM-NV-XL', 5, 'ACTIVE', 0);
SET @var_nv_blazer_nam_nv_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro' LIMIT 1), 'M', 'Đen', 'BLAZER-NAM-DEN-M', 9, 'ACTIVE', 0);
SET @var_nv_blazer_nam_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro' LIMIT 1), 'L', 'Đen', 'BLAZER-NAM-DEN-L', 11, 'ACTIVE', 0);
SET @var_nv_blazer_nam_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro' LIMIT 1), 'XL', 'Đen', 'BLAZER-NAM-DEN-XL', 6, 'ACTIVE', 0);
SET @var_nv_blazer_nam_den_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem' LIMIT 1), 'S', 'Đen', 'CV-XEPLY-DEN-S', 12, 'ACTIVE', 0);
SET @var_nv_cv_xeply_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem' LIMIT 1), 'M', 'Đen', 'CV-XEPLY-DEN-M', 16, 'ACTIVE', 0);
SET @var_nv_cv_xeply_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem' LIMIT 1), 'L', 'Đen', 'CV-XEPLY-DEN-L', 10, 'ACTIVE', 0);
SET @var_nv_cv_xeply_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem' LIMIT 1), 'S', 'Nâu tây', 'CV-XEPLY-NAU-S', 10, 'ACTIVE', 0);
SET @var_nv_cv_xeply_nau_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem' LIMIT 1), 'M', 'Nâu tây', 'CV-XEPLY-NAU-M', 14, 'ACTIVE', 0);
SET @var_nv_cv_xeply_nau_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem' LIMIT 1), 'L', 'Nâu tây', 'CV-XEPLY-NAU-L', 8, 'ACTIVE', 0);
SET @var_nv_cv_xeply_nau_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh' LIMIT 1), 'S', 'Xanh nhạt', 'CV-CHUA-XN-S', 10, 'ACTIVE', 0);
SET @var_nv_cv_chua_xn_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh' LIMIT 1), 'M', 'Xanh nhạt', 'CV-CHUA-XN-M', 14, 'ACTIVE', 0);
SET @var_nv_cv_chua_xn_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh' LIMIT 1), 'L', 'Xanh nhạt', 'CV-CHUA-XN-L', 9, 'ACTIVE', 0);
SET @var_nv_cv_chua_xn_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh' LIMIT 1), 'S', 'Đen wash', 'CV-CHUA-DEN-S', 9, 'ACTIVE', 0);
SET @var_nv_cv_chua_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh' LIMIT 1), 'M', 'Đen wash', 'CV-CHUA-DEN-M', 12, 'ACTIVE', 0);
SET @var_nv_cv_chua_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh' LIMIT 1), 'L', 'Đen wash', 'CV-CHUA-DEN-L', 7, 'ACTIVE', 0);
SET @var_nv_cv_chua_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'S', 'Đen', 'AT-BASIC-D-S', 22, 'ACTIVE', 0);
SET @var_nv_at_basic_d_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'L', 'Đen', 'AT-BASIC-D-L', 28, 'ACTIVE', 0);
SET @var_nv_at_basic_d_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'XL', 'Đen', 'AT-BASIC-D-XL', 16, 'ACTIVE', 0);
SET @var_nv_at_basic_d_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'S', 'Xám tiêu', 'AT-BASIC-XT-S', 18, 'ACTIVE', 0);
SET @var_nv_at_basic_xt_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'M', 'Xám tiêu', 'AT-BASIC-XT-M', 24, 'ACTIVE', 0);
SET @var_nv_at_basic_xt_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'L', 'Xám tiêu', 'AT-BASIC-XT-L', 20, 'ACTIVE', 0);
SET @var_nv_at_basic_xt_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'XL', 'Xám tiêu', 'AT-BASIC-XT-XL', 12, 'ACTIVE', 0);
SET @var_nv_at_basic_xt_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'M', 'Xanh navy', 'AT-BASIC-NV-M', 20, 'ACTIVE', 0);
SET @var_nv_at_basic_nv_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'L', 'Xanh navy', 'AT-BASIC-NV-L', 18, 'ACTIVE', 0);
SET @var_nv_at_basic_nv_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng' LIMIT 1), 'XL', 'Xanh navy', 'AT-BASIC-NV-XL', 10, 'ACTIVE', 0);
SET @var_nv_at_basic_nv_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ' LIMIT 1), 'S', 'Trắng', 'AT-OVER-TR-S', 14, 'ACTIVE', 0);
SET @var_nv_at_over_tr_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ' LIMIT 1), 'M', 'Trắng', 'AT-OVER-TR-M', 20, 'ACTIVE', 0);
SET @var_nv_at_over_tr_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ' LIMIT 1), 'L', 'Trắng', 'AT-OVER-TR-L', 22, 'ACTIVE', 0);
SET @var_nv_at_over_tr_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ' LIMIT 1), 'XL', 'Trắng', 'AT-OVER-TR-XL', 12, 'ACTIVE', 0);
SET @var_nv_at_over_tr_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ' LIMIT 1), 'M', 'Nâu socola', 'AT-OVER-NAU-M', 16, 'ACTIVE', 0);
SET @var_nv_at_over_nau_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ' LIMIT 1), 'L', 'Nâu socola', 'AT-OVER-NAU-L', 18, 'ACTIVE', 0);
SET @var_nv_at_over_nau_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ' LIMIT 1), 'XL', 'Nâu socola', 'AT-OVER-NAU-XL', 9, 'ACTIVE', 0);
SET @var_nv_at_over_nau_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê' LIMIT 1), 'S', 'Kem', 'AL-COLO-KEM-S', 10, 'ACTIVE', 0);
SET @var_nv_al_colo_kem_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê' LIMIT 1), 'M', 'Kem', 'AL-COLO-KEM-M', 14, 'ACTIVE', 0);
SET @var_nv_al_colo_kem_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê' LIMIT 1), 'L', 'Kem', 'AL-COLO-KEM-L', 9, 'ACTIVE', 0);
SET @var_nv_al_colo_kem_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê' LIMIT 1), 'S', 'Đen', 'AL-COLO-DEN-S', 11, 'ACTIVE', 0);
SET @var_nv_al_colo_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê' LIMIT 1), 'M', 'Đen', 'AL-COLO-DEN-M', 15, 'ACTIVE', 0);
SET @var_nv_al_colo_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê' LIMIT 1), 'L', 'Đen', 'AL-COLO-DEN-L', 10, 'ACTIVE', 0);
SET @var_nv_al_colo_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm' LIMIT 1), 'XL', 'Xanh denim', 'QJ-ONGRONG-XL', 8, 'ACTIVE', 0);
SET @var_nv_qj_ongrong_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm' LIMIT 1), 'S', 'Xanh nhạt', 'QJ-ONGRONG-XN-S', 11, 'ACTIVE', 0);
SET @var_nv_qj_ongrong_xn_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm' LIMIT 1), 'M', 'Xanh nhạt', 'QJ-ONGRONG-XN-M', 15, 'ACTIVE', 0);
SET @var_nv_qj_ongrong_xn_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm' LIMIT 1), 'L', 'Xanh nhạt', 'QJ-ONGRONG-XN-L', 10, 'ACTIVE', 0);
SET @var_nv_qj_ongrong_xn_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm' LIMIT 1), 'S', 'Đen wash', 'QJ-ONGRONG-DEN-S', 9, 'ACTIVE', 0);
SET @var_nv_qj_ongrong_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm' LIMIT 1), 'M', 'Đen wash', 'QJ-ONGRONG-DEN-M', 14, 'ACTIVE', 0);
SET @var_nv_qj_ongrong_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm' LIMIT 1), 'L', 'Đen wash', 'QJ-ONGRONG-DEN-L', 9, 'ACTIVE', 0);
SET @var_nv_qj_ongrong_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu' LIMIT 1), 'S', 'Xanh rêu', 'QS-KAKI-REU-S', 10, 'ACTIVE', 0);
SET @var_nv_qs_kaki_reu_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu' LIMIT 1), 'M', 'Be kaki', 'QS-KAKI-BE-M', 16, 'ACTIVE', 0);
SET @var_nv_qs_kaki_be_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu' LIMIT 1), 'L', 'Be kaki', 'QS-KAKI-BE-L', 18, 'ACTIVE', 0);
SET @var_nv_qs_kaki_be_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu' LIMIT 1), 'XL', 'Be kaki', 'QS-KAKI-BE-XL', 10, 'ACTIVE', 0);
SET @var_nv_qs_kaki_be_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu' LIMIT 1), 'M', 'Đen', 'QS-KAKI-DEN-M', 14, 'ACTIVE', 0);
SET @var_nv_qs_kaki_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu' LIMIT 1), 'L', 'Đen', 'QS-KAKI-DEN-L', 15, 'ACTIVE', 0);
SET @var_nv_qs_kaki_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu' LIMIT 1), 'XL', 'Đen', 'QS-KAKI-DEN-XL', 8, 'ACTIVE', 0);
SET @var_nv_qs_kaki_den_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm midi hoa nhí màu hồng phấn' LIMIT 1), 'S', 'Vàng kem', 'DAM-HOANHI-VK-S', 9, 'ACTIVE', 0);
SET @var_nv_dam_hoanhi_vk_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm midi hoa nhí màu hồng phấn' LIMIT 1), 'M', 'Vàng kem', 'DAM-HOANHI-VK-M', 12, 'ACTIVE', 0);
SET @var_nv_dam_hoanhi_vk_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm midi hoa nhí màu hồng phấn' LIMIT 1), 'L', 'Vàng kem', 'DAM-HOANHI-VK-L', 7, 'ACTIVE', 0);
SET @var_nv_dam_hoanhi_vk_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm midi hoa nhí màu hồng phấn' LIMIT 1), 'S', 'Xanh bơ', 'DAM-HOANHI-XB-S', 8, 'ACTIVE', 0);
SET @var_nv_dam_hoanhi_xb_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm midi hoa nhí màu hồng phấn' LIMIT 1), 'M', 'Xanh bơ', 'DAM-HOANHI-XB-M', 11, 'ACTIVE', 0);
SET @var_nv_dam_hoanhi_xb_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn' LIMIT 1), 'S', 'Xanh denim', 'AK-DENIM-S', 8, 'ACTIVE', 0);
SET @var_nv_ak_denim_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn' LIMIT 1), 'S', 'Đen wash', 'AK-DENIM-DEN-S', 7, 'ACTIVE', 0);
SET @var_nv_ak_denim_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn' LIMIT 1), 'M', 'Đen wash', 'AK-DENIM-DEN-M', 11, 'ACTIVE', 0);
SET @var_nv_ak_denim_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn' LIMIT 1), 'L', 'Đen wash', 'AK-DENIM-DEN-L', 9, 'ACTIVE', 0);
SET @var_nv_ak_denim_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn' LIMIT 1), 'M', 'Trắng kem', 'AK-DENIM-TK-M', 8, 'ACTIVE', 0);
SET @var_nv_ak_denim_tk_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn' LIMIT 1), 'L', 'Trắng kem', 'AK-DENIM-TK-L', 6, 'ACTIVE', 0);
SET @var_nv_ak_denim_tk_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo len cardigan màu xám (đang ẩn)' LIMIT 1), 'S', 'Xám', 'AL-CARDI-XAM-S', 6, 'ACTIVE', 0);
SET @var_nv_al_cardi_xam_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo len cardigan màu xám (đang ẩn)' LIMIT 1), 'XL', 'Xám', 'AL-CARDI-XAM-XL', 4, 'ACTIVE', 0);
SET @var_nv_al_cardi_xam_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy' LIMIT 1), 'S', 'Xanh navy', 'SM-NAM-KS-S', 10, 'ACTIVE', 0);
SET @var_nv_sm_nam_ks_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy' LIMIT 1), 'XXL', 'Xanh navy', 'SM-NAM-KS-XXL', 5, 'ACTIVE', 0);
SET @var_nv_sm_nam_ks_xxl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy' LIMIT 1), 'M', 'Trắng sọc xanh', 'SM-NAM-TSX-M', 14, 'ACTIVE', 0);
SET @var_nv_sm_nam_tsx_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy' LIMIT 1), 'L', 'Trắng sọc xanh', 'SM-NAM-TSX-L', 16, 'ACTIVE', 0);
SET @var_nv_sm_nam_tsx_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy' LIMIT 1), 'XL', 'Trắng sọc xanh', 'SM-NAM-TSX-XL', 9, 'ACTIVE', 0);
SET @var_nv_sm_nam_tsx_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nam Dệt Kim Xanh Rêu' LIMIT 1), 'S', 'Xanh rêu', 'PLO-REU-S', 12, 'ACTIVE', 0);
SET @var_nv_plo_reu_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nam Dệt Kim Xanh Rêu' LIMIT 1), 'M', 'Trắng', 'PLO-TR-M', 20, 'ACTIVE', 0);
SET @var_nv_plo_tr_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nam Dệt Kim Xanh Rêu' LIMIT 1), 'L', 'Trắng', 'PLO-TR-L', 18, 'ACTIVE', 0);
SET @var_nv_plo_tr_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nam Dệt Kim Xanh Rêu' LIMIT 1), 'XL', 'Trắng', 'PLO-TR-XL', 10, 'ACTIVE', 0);
SET @var_nv_plo_tr_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nam Dệt Kim Xanh Rêu' LIMIT 1), 'M', 'Đen', 'PLO-DEN-M', 22, 'ACTIVE', 0);
SET @var_nv_plo_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nam Dệt Kim Xanh Rêu' LIMIT 1), 'L', 'Đen', 'PLO-DEN-L', 16, 'ACTIVE', 0);
SET @var_nv_plo_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nam Dệt Kim Xanh Rêu' LIMIT 1), 'XL', 'Đen', 'PLO-DEN-XL', 9, 'ACTIVE', 0);
SET @var_nv_plo_den_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nữ Cổ Phối Trắng Kem' LIMIT 1), 'L', 'Kem', 'PLO-KEM-L', 14, 'ACTIVE', 0);
SET @var_nv_plo_kem_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nữ Cổ Phối Trắng Kem' LIMIT 1), 'XL', 'Kem', 'PLO-KEM-XL', 6, 'ACTIVE', 0);
SET @var_nv_plo_kem_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nữ Cổ Phối Trắng Kem' LIMIT 1), 'S', 'Xanh pastel', 'PLO-XPA-S', 15, 'ACTIVE', 0);
SET @var_nv_plo_xpa_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nữ Cổ Phối Trắng Kem' LIMIT 1), 'M', 'Xanh pastel', 'PLO-XPA-M', 18, 'ACTIVE', 0);
SET @var_nv_plo_xpa_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nữ Cổ Phối Trắng Kem' LIMIT 1), 'L', 'Xanh pastel', 'PLO-XPA-L', 10, 'ACTIVE', 0);
SET @var_nv_plo_xpa_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nữ Cổ Phối Trắng Kem' LIMIT 1), 'S', 'Đen phối trắng', 'PLO-DPT-S', 12, 'ACTIVE', 0);
SET @var_nv_plo_dpt_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nữ Cổ Phối Trắng Kem' LIMIT 1), 'M', 'Đen phối trắng', 'PLO-DPT-M', 16, 'ACTIVE', 0);
SET @var_nv_plo_dpt_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Polo Nữ Cổ Phối Trắng Kem' LIMIT 1), 'L', 'Đen phối trắng', 'PLO-DPT-L', 9, 'ACTIVE', 0);
SET @var_nv_plo_dpt_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Sơ Mi Lụa Pastel Tay Bồng' LIMIT 1), 'S', 'Xanh mint', 'DAM-MINT-S', 10, 'ACTIVE', 0);
SET @var_nv_dam_mint_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Sơ Mi Lụa Pastel Tay Bồng' LIMIT 1), 'M', 'Xanh mint', 'DAM-MINT-M', 14, 'ACTIVE', 0);
SET @var_nv_dam_mint_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Sơ Mi Lụa Pastel Tay Bồng' LIMIT 1), 'L', 'Xanh mint', 'DAM-MINT-L', 8, 'ACTIVE', 0);
SET @var_nv_dam_mint_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Sơ Mi Lụa Pastel Tay Bồng' LIMIT 1), 'S', 'Kem sữa', 'DAM-KEMS-S', 11, 'ACTIVE', 0);
SET @var_nv_dam_kems_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Sơ Mi Lụa Pastel Tay Bồng' LIMIT 1), 'M', 'Kem sữa', 'DAM-KEMS-M', 15, 'ACTIVE', 0);
SET @var_nv_dam_kems_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Sơ Mi Lụa Pastel Tay Bồng' LIMIT 1), 'L', 'Kem sữa', 'DAM-KEMS-L', 9, 'ACTIVE', 0);
SET @var_nv_dam_kems_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Dự Tiệc Satin Đỏ Đô' LIMIT 1), 'L', 'Đỏ đô', 'DAM-DO-L', 6, 'ACTIVE', 0);
SET @var_nv_dam_do_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Dự Tiệc Satin Đỏ Đô' LIMIT 1), 'S', 'Đen tuyền', 'DAM-DT-S', 8, 'ACTIVE', 0);
SET @var_nv_dam_dt_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Dự Tiệc Satin Đỏ Đô' LIMIT 1), 'M', 'Đen tuyền', 'DAM-DT-M', 11, 'ACTIVE', 0);
SET @var_nv_dam_dt_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Dự Tiệc Satin Đỏ Đô' LIMIT 1), 'L', 'Đen tuyền', 'DAM-DT-L', 5, 'ACTIVE', 0);
SET @var_nv_dam_dt_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Dự Tiệc Satin Đỏ Đô' LIMIT 1), 'S', 'Xanh ngọc lục bảo', 'DAM-XNL-S', 6, 'ACTIVE', 0);
SET @var_nv_dam_xnl_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Đầm Dự Tiệc Satin Đỏ Đô' LIMIT 1), 'M', 'Xanh ngọc lục bảo', 'DAM-XNL-M', 8, 'ACTIVE', 0);
SET @var_nv_dam_xnl_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'S', 'Xanh biển', 'SM-OXF-S', 12, 'ACTIVE', 0);
SET @var_nv_sm_oxf_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'XXL', 'Xanh biển', 'SM-OXF-XXL', 5, 'ACTIVE', 0);
SET @var_nv_sm_oxf_xxl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'S', 'Trắng', 'SM-OXF-TR-S', 14, 'ACTIVE', 0);
SET @var_nv_sm_oxf_tr_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'M', 'Trắng', 'SM-OXF-TR-M', 22, 'ACTIVE', 0);
SET @var_nv_sm_oxf_tr_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'L', 'Trắng', 'SM-OXF-TR-L', 18, 'ACTIVE', 0);
SET @var_nv_sm_oxf_tr_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'XL', 'Trắng', 'SM-OXF-TR-XL', 10, 'ACTIVE', 0);
SET @var_nv_sm_oxf_tr_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'M', 'Xám nhạt', 'SM-OXF-XN-M', 16, 'ACTIVE', 0);
SET @var_nv_sm_oxf_xn_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'L', 'Xám nhạt', 'SM-OXF-XN-L', 14, 'ACTIVE', 0);
SET @var_nv_sm_oxf_xn_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Sơ Mi Oxford Nam Xanh Biển' LIMIT 1), 'XL', 'Xám nhạt', 'SM-OXF-XN-XL', 8, 'ACTIVE', 0);
SET @var_nv_sm_oxf_xn_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'L', 'Trắng kem', 'QN-CUL-L', 12, 'ACTIVE', 0);
SET @var_nv_qn_cul_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'XL', 'Trắng kem', 'QN-CUL-XL', 6, 'ACTIVE', 0);
SET @var_nv_qn_cul_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'S', 'Đen', 'QN-CUL-DEN-S', 14, 'ACTIVE', 0);
SET @var_nv_qn_cul_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'M', 'Đen', 'QN-CUL-DEN-M', 18, 'ACTIVE', 0);
SET @var_nv_qn_cul_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'L', 'Đen', 'QN-CUL-DEN-L', 13, 'ACTIVE', 0);
SET @var_nv_qn_cul_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'XL', 'Đen', 'QN-CUL-DEN-XL', 7, 'ACTIVE', 0);
SET @var_nv_qn_cul_den_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'S', 'Be cát', 'QN-CUL-BE-S', 10, 'ACTIVE', 0);
SET @var_nv_qn_cul_be_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'M', 'Be cát', 'QN-CUL-BE-M', 14, 'ACTIVE', 0);
SET @var_nv_qn_cul_be_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Culottes Ống Rộng Trắng Kem' LIMIT 1), 'L', 'Be cát', 'QN-CUL-BE-L', 9, 'ACTIVE', 0);
SET @var_nv_qn_cul_be_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Jogger Nỉ Unisex Xám Tiêu' LIMIT 1), 'S', 'Xám tiêu', 'QN-JOG-S', 12, 'ACTIVE', 0);
SET @var_nv_qn_jog_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Jogger Nỉ Unisex Xám Tiêu' LIMIT 1), 'XL', 'Xám tiêu', 'QN-JOG-XL', 9, 'ACTIVE', 0);
SET @var_nv_qn_jog_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Jogger Nỉ Unisex Xám Tiêu' LIMIT 1), 'S', 'Đen', 'QN-JOG-DEN-S', 14, 'ACTIVE', 0);
SET @var_nv_qn_jog_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Jogger Nỉ Unisex Xám Tiêu' LIMIT 1), 'M', 'Đen', 'QN-JOG-DEN-M', 22, 'ACTIVE', 0);
SET @var_nv_qn_jog_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Jogger Nỉ Unisex Xám Tiêu' LIMIT 1), 'L', 'Đen', 'QN-JOG-DEN-L', 18, 'ACTIVE', 0);
SET @var_nv_qn_jog_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Jogger Nỉ Unisex Xám Tiêu' LIMIT 1), 'XL', 'Đen', 'QN-JOG-DEN-XL', 11, 'ACTIVE', 0);
SET @var_nv_qn_jog_den_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Jogger Nỉ Unisex Xám Tiêu' LIMIT 1), 'M', 'Xanh rêu', 'QN-JOG-REU-M', 13, 'ACTIVE', 0);
SET @var_nv_qn_jog_reu_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Quần Jogger Nỉ Unisex Xám Tiêu' LIMIT 1), 'L', 'Xanh rêu', 'QN-JOG-REU-L', 10, 'ACTIVE', 0);
SET @var_nv_qn_jog_reu_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Khoác Blazer Nữ Đen Cổ Vest' LIMIT 1), 'L', 'Đen', 'AK-BLZ-L', 9, 'ACTIVE', 0);
SET @var_nv_ak_blz_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Khoác Blazer Nữ Đen Cổ Vest' LIMIT 1), 'XL', 'Đen', 'AK-BLZ-XL', 4, 'ACTIVE', 0);
SET @var_nv_ak_blz_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Khoác Blazer Nữ Đen Cổ Vest' LIMIT 1), 'S', 'Kem be', 'AK-BLZ-KB-S', 10, 'ACTIVE', 0);
SET @var_nv_ak_blz_kb_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Khoác Blazer Nữ Đen Cổ Vest' LIMIT 1), 'M', 'Kem be', 'AK-BLZ-KB-M', 13, 'ACTIVE', 0);
SET @var_nv_ak_blz_kb_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Khoác Blazer Nữ Đen Cổ Vest' LIMIT 1), 'L', 'Kem be', 'AK-BLZ-KB-L', 8, 'ACTIVE', 0);
SET @var_nv_ak_blz_kb_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Khoác Blazer Nữ Đen Cổ Vest' LIMIT 1), 'S', 'Nâu tây', 'AK-BLZ-NAU-S', 8, 'ACTIVE', 0);
SET @var_nv_ak_blz_nau_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Khoác Blazer Nữ Đen Cổ Vest' LIMIT 1), 'M', 'Nâu tây', 'AK-BLZ-NAU-M', 11, 'ACTIVE', 0);
SET @var_nv_ak_blz_nau_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Khoác Blazer Nữ Đen Cổ Vest' LIMIT 1), 'L', 'Nâu tây', 'AK-BLZ-NAU-L', 7, 'ACTIVE', 0);
SET @var_nv_ak_blz_nau_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Thun Thể Thao Dry-Fit Đen' LIMIT 1), 'S', 'Đen', 'AT-GYM-S', 18, 'ACTIVE', 0);
SET @var_nv_at_gym_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Thun Thể Thao Dry-Fit Đen' LIMIT 1), 'XXL', 'Đen', 'AT-GYM-XXL', 8, 'ACTIVE', 0);
SET @var_nv_at_gym_xxl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Thun Thể Thao Dry-Fit Đen' LIMIT 1), 'M', 'Xanh than', 'AT-GYM-XT-M', 24, 'ACTIVE', 0);
SET @var_nv_at_gym_xt_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Thun Thể Thao Dry-Fit Đen' LIMIT 1), 'L', 'Xanh than', 'AT-GYM-XT-L', 20, 'ACTIVE', 0);
SET @var_nv_at_gym_xt_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Thun Thể Thao Dry-Fit Đen' LIMIT 1), 'XL', 'Xanh than', 'AT-GYM-XT-XL', 11, 'ACTIVE', 0);
SET @var_nv_at_gym_xt_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Thun Thể Thao Dry-Fit Đen' LIMIT 1), 'M', 'Xám khói', 'AT-GYM-XK-M', 22, 'ACTIVE', 0);
SET @var_nv_at_gym_xk_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Thun Thể Thao Dry-Fit Đen' LIMIT 1), 'L', 'Xám khói', 'AT-GYM-XK-L', 18, 'ACTIVE', 0);
SET @var_nv_at_gym_xk_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Thun Thể Thao Dry-Fit Đen' LIMIT 1), 'XL', 'Xám khói', 'AT-GYM-XK-XL', 9, 'ACTIVE', 0);
SET @var_nv_at_gym_xk_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Len Gile Cổ Tim Kem Sữa' LIMIT 1), 'L', 'Kem sữa', 'AL-GIL-L', 11, 'ACTIVE', 0);
SET @var_nv_al_gil_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Len Gile Cổ Tim Kem Sữa' LIMIT 1), 'S', 'Nâu hạt dẻ', 'AL-GIL-NHD-S', 12, 'ACTIVE', 0);
SET @var_nv_al_gil_nhd_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Len Gile Cổ Tim Kem Sữa' LIMIT 1), 'M', 'Nâu hạt dẻ', 'AL-GIL-NHD-M', 15, 'ACTIVE', 0);
SET @var_nv_al_gil_nhd_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Len Gile Cổ Tim Kem Sữa' LIMIT 1), 'L', 'Nâu hạt dẻ', 'AL-GIL-NHD-L', 9, 'ACTIVE', 0);
SET @var_nv_al_gil_nhd_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Len Gile Cổ Tim Kem Sữa' LIMIT 1), 'S', 'Xanh navy', 'AL-GIL-NV-S', 10, 'ACTIVE', 0);
SET @var_nv_al_gil_nv_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Len Gile Cổ Tim Kem Sữa' LIMIT 1), 'M', 'Xanh navy', 'AL-GIL-NV-M', 14, 'ACTIVE', 0);
SET @var_nv_al_gil_nv_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Len Gile Cổ Tim Kem Sữa' LIMIT 1), 'L', 'Xanh navy', 'AL-GIL-NV-L', 8, 'ACTIVE', 0);
SET @var_nv_al_gil_nv_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Vest Nam Công Sở Slimfit Đen' LIMIT 1), 'S', 'Đen', 'VS-DEN-S', 8, 'ACTIVE', 0);
SET @var_nv_vs_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Vest Nam Công Sở Slimfit Đen' LIMIT 1), 'L', 'Đen', 'VS-DEN-L', 12, 'ACTIVE', 0);
SET @var_nv_vs_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Vest Nam Công Sở Slimfit Đen' LIMIT 1), 'XL', 'Đen', 'VS-DEN-XL', 6, 'ACTIVE', 0);
SET @var_nv_vs_den_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Vest Nam Công Sở Slimfit Đen' LIMIT 1), 'M', 'Xám than', 'VS-XAM-M', 10, 'ACTIVE', 0);
SET @var_nv_vs_xam_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Vest Nam Công Sở Slimfit Đen' LIMIT 1), 'XL', 'Xám than', 'VS-XAM-XL', 5, 'ACTIVE', 0);
SET @var_nv_vs_xam_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Vest Nam Công Sở Slimfit Đen' LIMIT 1), 'M', 'Xanh navy', 'VS-NV-M', 11, 'ACTIVE', 0);
SET @var_nv_vs_nv_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Vest Nam Công Sở Slimfit Đen' LIMIT 1), 'L', 'Xanh navy', 'VS-NV-L', 9, 'ACTIVE', 0);
SET @var_nv_vs_nv_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Vest Nam Công Sở Slimfit Đen' LIMIT 1), 'XL', 'Xanh navy', 'VS-NV-XL', 4, 'ACTIVE', 0);
SET @var_nv_vs_nv_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Cardigan Len Mỏng Cổ Chữ V' LIMIT 1), 'S', 'Nâu kem', 'CD-KEM-S', 14, 'ACTIVE', 0);
SET @var_nv_cd_kem_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Cardigan Len Mỏng Cổ Chữ V' LIMIT 1), 'L', 'Nâu kem', 'CD-KEM-L', 15, 'ACTIVE', 0);
SET @var_nv_cd_kem_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Cardigan Len Mỏng Cổ Chữ V' LIMIT 1), 'XL', 'Nâu kem', 'CD-KEM-XL', 8, 'ACTIVE', 0);
SET @var_nv_cd_kem_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Cardigan Len Mỏng Cổ Chữ V' LIMIT 1), 'S', 'Đen', 'CD-DEN-S', 12, 'ACTIVE', 0);
SET @var_nv_cd_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Cardigan Len Mỏng Cổ Chữ V' LIMIT 1), 'M', 'Đen', 'CD-DEN-M', 18, 'ACTIVE', 0);
SET @var_nv_cd_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Cardigan Len Mỏng Cổ Chữ V' LIMIT 1), 'XL', 'Đen', 'CD-DEN-XL', 9, 'ACTIVE', 0);
SET @var_nv_cd_den_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Cardigan Len Mỏng Cổ Chữ V' LIMIT 1), 'M', 'Xanh rêu', 'CD-REU-M', 14, 'ACTIVE', 0);
SET @var_nv_cd_reu_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Cardigan Len Mỏng Cổ Chữ V' LIMIT 1), 'L', 'Xanh rêu', 'CD-REU-L', 11, 'ACTIVE', 0);
SET @var_nv_cd_reu_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều' LIMIT 1), 'L', 'Xám khói', 'TT-GYM-L', 10, 'ACTIVE', 0);
SET @var_nv_tt_gym_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều' LIMIT 1), 'S', 'Đen', 'TT-GYM-DEN-S', 16, 'ACTIVE', 0);
SET @var_nv_tt_gym_den_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều' LIMIT 1), 'M', 'Đen', 'TT-GYM-DEN-M', 18, 'ACTIVE', 0);
SET @var_nv_tt_gym_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều' LIMIT 1), 'L', 'Đen', 'TT-GYM-DEN-L', 12, 'ACTIVE', 0);
SET @var_nv_tt_gym_den_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều' LIMIT 1), 'S', 'Hồng đất', 'TT-GYM-HD-S', 14, 'ACTIVE', 0);
SET @var_nv_tt_gym_hd_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều' LIMIT 1), 'M', 'Hồng đất', 'TT-GYM-HD-M', 15, 'ACTIVE', 0);
SET @var_nv_tt_gym_hd_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều' LIMIT 1), 'L', 'Hồng đất', 'TT-GYM-HD-L', 9, 'ACTIVE', 0);
SET @var_nv_tt_gym_hd_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán)' LIMIT 1), 'S', 'Xám', 'HD-XAM-S', 4, 'ACTIVE', 0);
SET @var_nv_hd_xam_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán)' LIMIT 1), 'M', 'Xám', 'HD-XAM-M', 6, 'ACTIVE', 0);
SET @var_nv_hd_xam_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán)' LIMIT 1), 'XL', 'Xám', 'HD-XAM-XL', 3, 'ACTIVE', 0);
SET @var_nv_hd_xam_xl := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán)' LIMIT 1), 'M', 'Đen', 'HD-DEN-M', 5, 'ACTIVE', 0);
SET @var_nv_hd_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES ((SELECT id FROM product WHERE name = 'Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán)' LIMIT 1), 'L', 'Đen', 'HD-DEN-L', 4, 'ACTIVE', 0);
SET @var_nv_hd_den_l := LAST_INSERT_ID();

-- ============================================================================
-- MỤC 2: THÊM 10 TÀI KHOẢN KHÁCH HÀNG MỚI (khach47 -> khach56)
-- ============================================================================
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach47@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 900 DAY), DATE_SUB(NOW(6), INTERVAL 12 HOUR));
SET @acc_khach47 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach47, 'Nguyễn Hải Yến', '0916000047', '1996-04-12');
SET @prof_khach47 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach48@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 860 DAY), DATE_SUB(NOW(6), INTERVAL 24 HOUR));
SET @acc_khach48 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach48, 'Trần Văn Phúc', '0916000048', '1994-11-05');
SET @prof_khach48 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach49@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 820 DAY), DATE_SUB(NOW(6), INTERVAL 8 HOUR));
SET @acc_khach49 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach49, 'Lê Hoàng Minh Anh', '0916000049', '1999-02-28');
SET @prof_khach49 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach50@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 780 DAY), DATE_SUB(NOW(6), INTERVAL 5 HOUR));
SET @acc_khach50 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach50, 'Phạm Tấn Đạt', '0916000050', '1995-07-19');
SET @prof_khach50 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach51@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 720 DAY), DATE_SUB(NOW(6), INTERVAL 16 HOUR));
SET @acc_khach51 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach51, 'Võ Thị Thanh Ngân', '0916000051', '2000-09-14');
SET @prof_khach51 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach52@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 640 DAY), DATE_SUB(NOW(6), INTERVAL 3 HOUR));
SET @acc_khach52 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach52, 'Đặng Quang Khải', '0916000052', '1993-01-30');
SET @prof_khach52 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach53@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 520 DAY), DATE_SUB(NOW(6), INTERVAL 10 HOUR));
SET @acc_khach53 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach53, 'Bùi Ngọc Diệp', '0916000053', '1998-06-22');
SET @prof_khach53 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach54@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 410 DAY), DATE_SUB(NOW(6), INTERVAL 6 HOUR));
SET @acc_khach54 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach54, 'Hồ Trung Hiếu', '0916000054', '1997-10-08');
SET @prof_khach54 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach55@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 280 DAY), DATE_SUB(NOW(6), INTERVAL 18 HOUR));
SET @acc_khach55 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach55, 'Đỗ Minh Thư', '0916000055', '2001-03-17');
SET @prof_khach55 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at, last_login_at)
VALUES ('khach56@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 150 DAY), DATE_SUB(NOW(6), INTERVAL 2 HOUR));
SET @acc_khach56 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date) VALUES (@acc_khach56, 'Huỳnh Gia Bảo', '0916000056', '1996-12-09');
SET @prof_khach56 := LAST_INSERT_ID();

INSERT INTO shipping_address (user_profile_id, address, default_address) VALUES
(@prof_khach47, '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 1),
(@prof_khach48, '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 1),
(@prof_khach49, '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 1),
(@prof_khach50, '75 Lê Quang Định, Phường 14, Quận Bình Thạnh, TP.HCM', 1),
(@prof_khach51, '19 Nguyễn Văn Cừ, Phường An Bình, Quận Ninh Kiều, Cần Thơ', 1),
(@prof_khach52, '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 1),
(@prof_khach53, '88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM', 1),
(@prof_khach54, '51 Trần Quốc Toản, Phường 8, Quận 3, TP.HCM', 1),
(@prof_khach55, '163 Lê Hồng Phong, Phường Phước Hải, TP. Nha Trang, Khánh Hòa', 1),
(@prof_khach56, '29 Nguyễn Chí Thanh, Phường Láng Hạ, Quận Đống Đa, Hà Nội', 1);

-- ============================================================================
-- MỤC 3: 3 MÃ GIẢM GIÁ THEO NĂM (SALE2024, SALE2025, SALE2026)
-- ============================================================================
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('SALE2024', 'Ưu đãi thành viên năm 2024 (10%, tối đa 150K)', 'PERCENT', 10.00, 150000.00, 800000.00, 200, 10, STR_TO_DATE(CONCAT(@y2_num, '-01-01 00:00:00'), '%Y-%m-%d %H:%i:%s'), STR_TO_DATE(CONCAT(@y2_num, '-12-31 23:59:59'), '%Y-%m-%d %H:%i:%s'), 'INACTIVE');
SET @cp_sale2024 := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('SALE2025', 'Siêu hội thời trang năm 2025 (15%, tối đa 200K)', 'PERCENT', 15.00, 200000.00, 800000.00, 200, 16, STR_TO_DATE(CONCAT(@y1_num, '-01-01 00:00:00'), '%Y-%m-%d %H:%i:%s'), STR_TO_DATE(CONCAT(@y1_num, '-12-31 23:59:59'), '%Y-%m-%d %H:%i:%s'), 'INACTIVE');
SET @cp_sale2025 := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, start_date, end_date, status)
VALUES ('SALE2026', 'Ưu đãi khách hàng thân thiết 2026 (12%, tối đa 180K)', 'PERCENT', 12.00, 180000.00, 800000.00, 300, 15, @y0_start, STR_TO_DATE(CONCAT(@y0_num, '-12-31 23:59:59'), '%Y-%m-%d %H:%i:%s'), 'ACTIVE');
SET @cp_sale2026 := LAST_INSERT_ID();

-- ============================================================================
-- MỤC 4: 100 ĐƠN HÀNG THÀNH CÔNG (COMPLETED + PAID) THEO TỪNG NGÀY/THÁNG/NĂM
-- ============================================================================

-- FS7Y2401 [Y-2] | COMPLETED + PAID | total=740,000
SET @t_fs7y2401 := STR_TO_DATE(CONCAT(@y2_num, '-01-12 09:30:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2401 := DATE_ADD(@t_fs7y2401, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2401', @prof_khach47, NULL, 'COMPLETED', 710000.00, 0.00, 740000.00, 'Nguyễn Hải Yến', '0916000047', '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2401, @t_fs7y2401, @c_fs7y2401);
SET @ord_fs7y2401 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2401, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 1),
(@ord_fs7y2401, @var_nv_at_basic_d_l, 'Áo thun cotton basic cổ tròn màu trắng', 'L', 'Đen', 290000.00, 1);

-- FS7Y2402 [Y-2] | COMPLETED + PAID | total=894,000
SET @t_fs7y2402 := STR_TO_DATE(CONCAT(@y2_num, '-01-25 15:10:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2402 := DATE_ADD(@t_fs7y2402, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2402', @prof_khach48, @cp_sale2024, 'COMPLETED', 960000.00, 96000.00, 894000.00, 'Trần Văn Phúc', '0916000048', '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 30000.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2402, INTERVAL 3 MINUTE), @t_fs7y2402, @c_fs7y2402);
SET @ord_fs7y2402 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2402, @var_nv_sm_oxf_tr_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Trắng', 540000.00, 1),
(@ord_fs7y2402, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS7Y2403 [Y-2] | COMPLETED + PAID | total=1,090,000
SET @t_fs7y2403 := STR_TO_DATE(CONCAT(@y2_num, '-02-14 11:20:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2403 := DATE_ADD(@t_fs7y2403, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2403', @prof_khach49, NULL, 'COMPLETED', 1090000.00, 0.00, 1090000.00, 'Lê Hoàng Minh Anh', '0916000049', '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2403, INTERVAL 3 MINUTE), @t_fs7y2403, @c_fs7y2403);
SET @ord_fs7y2403 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2403, @var_nv_dam_mint_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Xanh mint', 1090000.00, 1);

-- FS7Y2404 [Y-2] | COMPLETED + PAID | total=1,740,000
SET @t_fs7y2404 := STR_TO_DATE(CONCAT(@y2_num, '-03-08 10:05:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2404 := DATE_ADD(@t_fs7y2404, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2404', @prof_khach5, @cp_sale2024, 'COMPLETED', 1890000.00, 150000.00, 1740000.00, 'Nguyễn Ngọc Lan', '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2404, INTERVAL 3 MINUTE), @t_fs7y2404, @c_fs7y2404);
SET @ord_fs7y2404 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2404, @var_dam_do_s, 'Đầm Dự Tiệc Satin Đỏ Đô', 'S', 'Đỏ đô', 1890000.00, 1);

-- FS7Y2405 [Y-2] | COMPLETED + PAID | total=1,250,000
SET @t_fs7y2405 := STR_TO_DATE(CONCAT(@y2_num, '-03-08 16:40:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2405 := DATE_ADD(@t_fs7y2405, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2405', @prof_khach49, NULL, 'COMPLETED', 1250000.00, 0.00, 1250000.00, 'Lê Hoàng Minh Anh', '0916000049', '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2405, INTERVAL 3 MINUTE), @t_fs7y2405, @c_fs7y2405);
SET @ord_fs7y2405 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2405, @var_nv_ak_blz_kb_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Kem be', 1250000.00, 1);

-- FS7Y2406 [Y-2] | COMPLETED + PAID | total=1,170,000
SET @t_fs7y2406 := STR_TO_DATE(CONCAT(@y2_num, '-04-19 14:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2406 := DATE_ADD(@t_fs7y2406, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2406', @prof_khach50, NULL, 'COMPLETED', 1170000.00, 0.00, 1170000.00, 'Phạm Tấn Đạt', '0916000050', '75 Lê Quang Định, Phường 14, Quận Bình Thạnh, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2406, @t_fs7y2406, @c_fs7y2406);
SET @ord_fs7y2406 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2406, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 1),
(@ord_fs7y2406, @var_nv_qn_cul_den_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Đen', 720000.00, 1);

-- FS7Y2407 [Y-2] | COMPLETED + PAID | total=1,390,000
SET @t_fs7y2407 := STR_TO_DATE(CONCAT(@y2_num, '-05-07 18:25:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2407 := DATE_ADD(@t_fs7y2407, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2407', @prof_khach6, @cp_sale2024, 'COMPLETED', 1540000.00, 150000.00, 1390000.00, 'Trần Minh Tuấn', '0915000006', '88 Lê Lợi, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'COD', 'PAID', @c_fs7y2407, @t_fs7y2407, @c_fs7y2407);
SET @ord_fs7y2407 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2407, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1),
(@ord_fs7y2407, @var_sm_linen_tr_m, 'Áo sơ mi linen trắng tối giản', 'M', 'Trắng', 690000.00, 1);

-- FS7Y2408 [Y-2] | COMPLETED + PAID | total=620,000
SET @t_fs7y2408 := STR_TO_DATE(CONCAT(@y2_num, '-05-22 09:50:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2408 := DATE_ADD(@t_fs7y2408, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2408', @prof_khach51, NULL, 'COMPLETED', 590000.00, 0.00, 620000.00, 'Võ Thị Thanh Ngân', '0916000051', '19 Nguyễn Văn Cừ, Phường An Bình, Quận Ninh Kiều, Cần Thơ', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2408, INTERVAL 3 MINUTE), @t_fs7y2408, @c_fs7y2408);
SET @ord_fs7y2408 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2408, @var_nv_tt_gym_den_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Đen', 590000.00, 1);

-- FS7Y2409 [Y-2] | COMPLETED + PAID | total=1,530,000
SET @t_fs7y2409 := STR_TO_DATE(CONCAT(@y2_num, '-06-11 13:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2409 := DATE_ADD(@t_fs7y2409, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2409', @prof_khach47, @cp_sale2024, 'COMPLETED', 1680000.00, 150000.00, 1530000.00, 'Nguyễn Hải Yến', '0916000047', '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2409, INTERVAL 3 MINUTE), @t_fs7y2409, @c_fs7y2409);
SET @ord_fs7y2409 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2409, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1),
(@ord_fs7y2409, @var_nv_al_gil_nhd_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Nâu hạt dẻ', 590000.00, 1);

-- FS7Y2410 [Y-2] | COMPLETED + PAID | total=650,000
SET @t_fs7y2410 := STR_TO_DATE(CONCAT(@y2_num, '-06-26 20:00:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2410 := DATE_ADD(@t_fs7y2410, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2410', @prof_khach52, NULL, 'COMPLETED', 620000.00, 0.00, 650000.00, 'Đặng Quang Khải', '0916000052', '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2410, @t_fs7y2410, @c_fs7y2410);
SET @ord_fs7y2410 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2410, @var_nv_at_gym_xt_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Xanh than', 310000.00, 2);

-- FS7Y2411 [Y-2] | COMPLETED + PAID | total=1,170,000
SET @t_fs7y2411 := STR_TO_DATE(CONCAT(@y2_num, '-07-15 11:45:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2411 := DATE_ADD(@t_fs7y2411, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2411', @prof_khach7, NULL, 'COMPLETED', 1170000.00, 0.00, 1170000.00, 'Lê Thị Thu Hà', '0915000007', '215 Cầu Giấy, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2411, INTERVAL 3 MINUTE), @t_fs7y2411, @c_fs7y2411);
SET @ord_fs7y2411 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2411, @var_qn_cul_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Trắng kem', 720000.00, 1),
(@ord_fs7y2411, @var_nv_plo_xpa_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Xanh pastel', 450000.00, 1);

-- FS7Y2412 [Y-2] | COMPLETED + PAID | total=880,000
SET @t_fs7y2412 := STR_TO_DATE(CONCAT(@y2_num, '-08-09 16:20:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2412 := DATE_ADD(@t_fs7y2412, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2412', @prof_khach48, NULL, 'COMPLETED', 850000.00, 0.00, 880000.00, 'Trần Văn Phúc', '0916000048', '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 30000.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2412, INTERVAL 3 MINUTE), @t_fs7y2412, @c_fs7y2412);
SET @ord_fs7y2412 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2412, @var_nv_vs_nv_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xanh navy', 850000.00, 1);

-- FS7Y2413 [Y-2] | COMPLETED + PAID | total=1,740,000
SET @t_fs7y2413 := STR_TO_DATE(CONCAT(@y2_num, '-08-24 19:10:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2413 := DATE_ADD(@t_fs7y2413, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2413', @prof_khach53, @cp_sale2024, 'COMPLETED', 1890000.00, 150000.00, 1740000.00, 'Bùi Ngọc Diệp', '0916000053', '88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2413, @t_fs7y2413, @c_fs7y2413);
SET @ord_fs7y2413 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2413, @var_nv_dam_dt_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đen tuyền', 1890000.00, 1);

-- FS7Y2414 [Y-2] | COMPLETED + PAID | total=1,197,000
SET @t_fs7y2414 := STR_TO_DATE(CONCAT(@y2_num, '-09-09 08:40:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2414 := DATE_ADD(@t_fs7y2414, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2414', @prof_khach50, @cp_sale2024, 'COMPLETED', 1330000.00, 133000.00, 1197000.00, 'Phạm Tấn Đạt', '0916000050', '75 Lê Quang Định, Phường 14, Quận Bình Thạnh, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2414, INTERVAL 3 MINUTE), @t_fs7y2414, @c_fs7y2414);
SET @ord_fs7y2414 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2414, @var_nv_plo_den_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Đen', 420000.00, 2),
(@ord_fs7y2414, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS7Y2415 [Y-2] | COMPLETED + PAID | total=820,000
SET @t_fs7y2415 := STR_TO_DATE(CONCAT(@y2_num, '-09-09 21:05:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2415 := DATE_ADD(@t_fs7y2415, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2415', @prof_khach11, NULL, 'COMPLETED', 790000.00, 0.00, 820000.00, 'Bùi Thanh Thảo', '0915000011', '79 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM', 30000.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2415, INTERVAL 3 MINUTE), @t_fs7y2415, @c_fs7y2415);
SET @ord_fs7y2415 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2415, @var_cv_xeply_m, 'Chân váy midi xếp ly màu kem', 'M', 'Kem', 790000.00, 1);

-- FS7Y2416 [Y-2] | COMPLETED + PAID | total=990,000
SET @t_fs7y2416 := STR_TO_DATE(CONCAT(@y2_num, '-10-10 12:30:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2416 := DATE_ADD(@t_fs7y2416, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2416', @prof_khach51, NULL, 'COMPLETED', 960000.00, 0.00, 990000.00, 'Võ Thị Thanh Ngân', '0916000051', '19 Nguyễn Văn Cừ, Phường An Bình, Quận Ninh Kiều, Cần Thơ', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2416, @t_fs7y2416, @c_fs7y2416);
SET @ord_fs7y2416 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2416, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1),
(@ord_fs7y2416, @var_sm_oxf_l, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'L', 'Xanh biển', 540000.00, 1);

-- FS7Y2417 [Y-2] | COMPLETED + PAID | total=650,000
SET @t_fs7y2417 := STR_TO_DATE(CONCAT(@y2_num, '-10-27 17:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2417 := DATE_ADD(@t_fs7y2417, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2417', @prof_khach14, NULL, 'COMPLETED', 620000.00, 0.00, 650000.00, 'Trương Công Minh', '0915000014', '112 Trần Phú, Phường Lộc Thọ, TP. Nha Trang, Khánh Hòa', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2417, INTERVAL 3 MINUTE), @t_fs7y2417, @c_fs7y2417);
SET @ord_fs7y2417 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2417, @var_at_gym_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Đen', 310000.00, 2);

-- FS7Y2418 [Y-2] | COMPLETED + PAID | total=2,190,000
SET @t_fs7y2418 := STR_TO_DATE(CONCAT(@y2_num, '-11-11 09:10:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2418 := DATE_ADD(@t_fs7y2418, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2418', @prof_khach47, @cp_sale2024, 'COMPLETED', 2340000.00, 150000.00, 2190000.00, 'Nguyễn Hải Yến', '0916000047', '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2418, INTERVAL 3 MINUTE), @t_fs7y2418, @c_fs7y2418);
SET @ord_fs7y2418 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2418, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1),
(@ord_fs7y2418, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1);

-- FS7Y2419 [Y-2] | COMPLETED + PAID | total=880,000
SET @t_fs7y2419 := STR_TO_DATE(CONCAT(@y2_num, '-11-11 14:55:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2419 := DATE_ADD(@t_fs7y2419, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2419', @prof_khach52, NULL, 'COMPLETED', 850000.00, 0.00, 880000.00, 'Đặng Quang Khải', '0916000052', '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2419, INTERVAL 3 MINUTE), @t_fs7y2419, @c_fs7y2419);
SET @ord_fs7y2419 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2419, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1);

-- FS7Y2420 [Y-2] | COMPLETED + PAID | total=909,000
SET @t_fs7y2420 := STR_TO_DATE(CONCAT(@y2_num, '-11-29 19:30:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2420 := DATE_ADD(@t_fs7y2420, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2420', @prof_khach53, @cp_sale2024, 'COMPLETED', 1010000.00, 101000.00, 909000.00, 'Bùi Ngọc Diệp', '0916000053', '88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2420, @t_fs7y2420, @c_fs7y2420);
SET @ord_fs7y2420 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2420, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1),
(@ord_fs7y2420, @var_nv_cd_reu_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Xanh rêu', 420000.00, 1);

-- FS7Y2421 [Y-2] | COMPLETED + PAID | total=2,690,000
SET @t_fs7y2421 := STR_TO_DATE(CONCAT(@y2_num, '-12-12 10:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2421 := DATE_ADD(@t_fs7y2421, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2421', @prof_khach49, @cp_sale2024, 'COMPLETED', 2840000.00, 150000.00, 2690000.00, 'Lê Hoàng Minh Anh', '0916000049', '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2421, INTERVAL 3 MINUTE), @t_fs7y2421, @c_fs7y2421);
SET @ord_fs7y2421 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2421, @var_dam_lua_be_m, 'Đầm lụa dáng dài màu be', 'M', 'Be', 1590000.00, 1),
(@ord_fs7y2421, @var_ak_blz_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Đen', 1250000.00, 1);

-- FS7Y2422 [Y-2] | COMPLETED + PAID | total=1,080,000
SET @t_fs7y2422 := STR_TO_DATE(CONCAT(@y2_num, '-12-12 15:45:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2422 := DATE_ADD(@t_fs7y2422, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2422', @prof_khach54, NULL, 'COMPLETED', 1080000.00, 0.00, 1080000.00, 'Hồ Trung Hiếu', '0916000054', '51 Trần Quốc Toản, Phường 8, Quận 3, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2422, INTERVAL 3 MINUTE), @t_fs7y2422, @c_fs7y2422);
SET @ord_fs7y2422 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2422, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 2);

-- FS7Y2423 [Y-2] | COMPLETED + PAID | total=940,000
SET @t_fs7y2423 := STR_TO_DATE(CONCAT(@y2_num, '-12-20 11:20:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2423 := DATE_ADD(@t_fs7y2423, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2423', @prof_khach48, NULL, 'COMPLETED', 910000.00, 0.00, 940000.00, 'Trần Văn Phúc', '0916000048', '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2423, @t_fs7y2423, @c_fs7y2423);
SET @ord_fs7y2423 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2423, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 1),
(@ord_fs7y2423, @var_nv_qn_jog_den_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Đen', 490000.00, 1);

-- FS7Y2424 [Y-2] | COMPLETED + PAID | total=3,130,000
SET @t_fs7y2424 := STR_TO_DATE(CONCAT(@y2_num, '-12-24 20:10:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2424 := DATE_ADD(@t_fs7y2424, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2424', @prof_khach5, @cp_sale2024, 'COMPLETED', 3280000.00, 150000.00, 3130000.00, 'Nguyễn Ngọc Lan', '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2424, INTERVAL 3 MINUTE), @t_fs7y2424, @c_fs7y2424);
SET @ord_fs7y2424 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2424, @var_trench_camel_m, 'Áo trench coat dáng dài màu camel', 'M', 'Camel', 2490000.00, 1),
(@ord_fs7y2424, @var_nv_cv_xeply_den_m, 'Chân váy midi xếp ly màu kem', 'M', 'Đen', 790000.00, 1);

-- FS7Y2501 [Y-1] | COMPLETED + PAID | total=1,010,000
SET @t_fs7y2501 := STR_TO_DATE(CONCAT(@y1_num, '-01-06 10:20:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2501 := DATE_ADD(@t_fs7y2501, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2501', @prof_khach47, NULL, 'COMPLETED', 1010000.00, 0.00, 1010000.00, 'Nguyễn Hải Yến', '0916000047', '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2501, INTERVAL 3 MINUTE), @t_fs7y2501, @c_fs7y2501);
SET @ord_fs7y2501 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2501, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1),
(@ord_fs7y2501, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1);

-- FS7Y2502 [Y-1] | COMPLETED + PAID | total=1,190,000
SET @t_fs7y2502 := STR_TO_DATE(CONCAT(@y1_num, '-01-18 15:00:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2502 := DATE_ADD(@t_fs7y2502, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2502', @prof_khach52, @cp_sale2025, 'COMPLETED', 1390000.00, 200000.00, 1190000.00, 'Đặng Quang Khải', '0916000052', '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2502, @t_fs7y2502, @c_fs7y2502);
SET @ord_fs7y2502 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2502, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1),
(@ord_fs7y2502, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1);

-- FS7Y2503 [Y-1] | COMPLETED + PAID | total=1,250,000
SET @t_fs7y2503 := STR_TO_DATE(CONCAT(@y1_num, '-01-18 19:40:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2503 := DATE_ADD(@t_fs7y2503, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2503', @prof_khach13, NULL, 'COMPLETED', 1250000.00, 0.00, 1250000.00, 'Đỗ Thị Kim Chi', '0915000013', '64 Nguyễn Trãi, Phường Thượng Đình, Quận Thanh Xuân, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2503, INTERVAL 3 MINUTE), @t_fs7y2503, @c_fs7y2503);
SET @ord_fs7y2503 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2503, @var_ak_blz_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Đen', 1250000.00, 1);

-- FS7Y2504 [Y-1] | COMPLETED + PAID | total=930,000
SET @t_fs7y2504 := STR_TO_DATE(CONCAT(@y1_num, '-02-10 11:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2504 := DATE_ADD(@t_fs7y2504, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2504', @prof_khach49, NULL, 'COMPLETED', 900000.00, 0.00, 930000.00, 'Lê Hoàng Minh Anh', '0916000049', '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2504, @t_fs7y2504, @c_fs7y2504);
SET @ord_fs7y2504 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2504, @var_plo_kem_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Kem', 450000.00, 2);

-- FS7Y2505 [Y-1] | COMPLETED + PAID | total=926,500
SET @t_fs7y2505 := STR_TO_DATE(CONCAT(@y1_num, '-02-21 16:30:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2505 := DATE_ADD(@t_fs7y2505, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2505', @prof_khach54, @cp_sale2025, 'COMPLETED', 1090000.00, 163500.00, 926500.00, 'Hồ Trung Hiếu', '0916000054', '51 Trần Quốc Toản, Phường 8, Quận 3, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2505, INTERVAL 3 MINUTE), @t_fs7y2505, @c_fs7y2505);
SET @ord_fs7y2505 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2505, @var_nv_dam_kems_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Kem sữa', 1090000.00, 1);

-- FS7Y2506 [Y-1] | COMPLETED + PAID | total=2,940,000
SET @t_fs7y2506 := STR_TO_DATE(CONCAT(@y1_num, '-03-08 08:50:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2506 := DATE_ADD(@t_fs7y2506, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2506', @prof_khach5, @cp_sale2025, 'COMPLETED', 3140000.00, 200000.00, 2940000.00, 'Nguyễn Ngọc Lan', '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2506, INTERVAL 3 MINUTE), @t_fs7y2506, @c_fs7y2506);
SET @ord_fs7y2506 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2506, @var_dam_do_s, 'Đầm Dự Tiệc Satin Đỏ Đô', 'S', 'Đỏ đô', 1890000.00, 1),
(@ord_fs7y2506, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1);

-- FS7Y2507 [Y-1] | COMPLETED + PAID | total=1,090,000
SET @t_fs7y2507 := STR_TO_DATE(CONCAT(@y1_num, '-03-08 13:25:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2507 := DATE_ADD(@t_fs7y2507, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2507', @prof_khach49, NULL, 'COMPLETED', 1090000.00, 0.00, 1090000.00, 'Lê Hoàng Minh Anh', '0916000049', '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2507, INTERVAL 3 MINUTE), @t_fs7y2507, @c_fs7y2507);
SET @ord_fs7y2507 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2507, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1);

-- FS7Y2508 [Y-1] | COMPLETED + PAID | total=1,113,500
SET @t_fs7y2508 := STR_TO_DATE(CONCAT(@y1_num, '-03-08 20:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2508 := DATE_ADD(@t_fs7y2508, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2508', @prof_khach51, @cp_sale2025, 'COMPLETED', 1310000.00, 196500.00, 1113500.00, 'Võ Thị Thanh Ngân', '0916000051', '19 Nguyễn Văn Cừ, Phường An Bình, Quận Ninh Kiều, Cần Thơ', 0.00, NULL, 'COD', 'PAID', @c_fs7y2508, @t_fs7y2508, @c_fs7y2508);
SET @ord_fs7y2508 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2508, @var_qn_cul_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Trắng kem', 720000.00, 1),
(@ord_fs7y2508, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1);

-- FS7Y2509 [Y-1] | COMPLETED + PAID | total=1,110,000
SET @t_fs7y2509 := STR_TO_DATE(CONCAT(@y1_num, '-04-14 09:40:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2509 := DATE_ADD(@t_fs7y2509, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2509', @prof_khach50, NULL, 'COMPLETED', 1110000.00, 0.00, 1110000.00, 'Phạm Tấn Đạt', '0916000050', '75 Lê Quang Định, Phường 14, Quận Bình Thạnh, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2509, @t_fs7y2509, @c_fs7y2509);
SET @ord_fs7y2509 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2509, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 2),
(@ord_fs7y2509, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS7Y2510 [Y-1] | COMPLETED + PAID | total=1,340,000
SET @t_fs7y2510 := STR_TO_DATE(CONCAT(@y1_num, '-04-26 17:10:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2510 := DATE_ADD(@t_fs7y2510, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2510', @prof_khach16, @cp_sale2025, 'COMPLETED', 1540000.00, 200000.00, 1340000.00, 'Nguyễn Thanh Tùng', '0915000016', '18 Nguyễn Thị Minh Khai, Phường Đa Kao, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2510, INTERVAL 3 MINUTE), @t_fs7y2510, @c_fs7y2510);
SET @ord_fs7y2510 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2510, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1),
(@ord_fs7y2510, @var_nv_sm_linen_kb_m, 'Áo sơ mi linen trắng tối giản', 'M', 'Kem be', 690000.00, 1);

-- FS7Y2511 [Y-1] | COMPLETED + PAID | total=930,000
SET @t_fs7y2511 := STR_TO_DATE(CONCAT(@y1_num, '-05-12 10:55:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2511 := DATE_ADD(@t_fs7y2511, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2511', @prof_khach53, NULL, 'COMPLETED', 900000.00, 0.00, 930000.00, 'Bùi Ngọc Diệp', '0916000053', '88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2511, INTERVAL 3 MINUTE), @t_fs7y2511, @c_fs7y2511);
SET @ord_fs7y2511 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2511, @var_nv_plo_dpt_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Đen phối trắng', 450000.00, 2);

-- FS7Y2512 [Y-1] | COMPLETED + PAID | total=1,071,000
SET @t_fs7y2512 := STR_TO_DATE(CONCAT(@y1_num, '-05-25 14:35:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2512 := DATE_ADD(@t_fs7y2512, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2512', @prof_khach8, @cp_sale2025, 'COMPLETED', 1260000.00, 189000.00, 1071000.00, 'Phạm Quốc Bảo', '0915000008', '14 Phan Văn Trị, Phường 7, Quận Gò Vấp, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2512, @t_fs7y2512, @c_fs7y2512);
SET @ord_fs7y2512 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2512, @var_plo_reu_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Xanh rêu', 420000.00, 2),
(@ord_fs7y2512, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS7Y2513 [Y-1] | COMPLETED + PAID | total=930,000
SET @t_fs7y2513 := STR_TO_DATE(CONCAT(@y1_num, '-06-06 11:20:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2513 := DATE_ADD(@t_fs7y2513, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2513', @prof_khach55, NULL, 'COMPLETED', 900000.00, 0.00, 930000.00, 'Đỗ Minh Thư', '0916000055', '163 Lê Hồng Phong, Phường Phước Hải, TP. Nha Trang, Khánh Hòa', 30000.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2513, INTERVAL 3 MINUTE), @t_fs7y2513, @c_fs7y2513);
SET @ord_fs7y2513 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2513, @var_tt_gym_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Xám khói', 590000.00, 1),
(@ord_fs7y2513, @var_nv_at_gym_xk_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Xám khói', 310000.00, 1);

-- FS7Y2514 [Y-1] | COMPLETED + PAID | total=610,000
SET @t_fs7y2514 := STR_TO_DATE(CONCAT(@y1_num, '-06-06 18:45:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2514 := DATE_ADD(@t_fs7y2514, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2514', @prof_khach18, NULL, 'COMPLETED', 580000.00, 0.00, 610000.00, 'Mai Xuân Trường', '0915000018', '27 Lê Văn Sỹ, Phường 13, Quận Phú Nhuận, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2514, @t_fs7y2514, @c_fs7y2514);
SET @ord_fs7y2514 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2514, @var_at_basic_tr_l, 'Áo thun cotton basic cổ tròn màu trắng', 'L', 'Trắng', 290000.00, 2);

-- FS7Y2515 [Y-1] | COMPLETED + PAID | total=918,000
SET @t_fs7y2515 := STR_TO_DATE(CONCAT(@y1_num, '-06-21 16:05:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2515 := DATE_ADD(@t_fs7y2515, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2515', @prof_khach52, @cp_sale2025, 'COMPLETED', 1080000.00, 162000.00, 918000.00, 'Đặng Quang Khải', '0916000052', '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2515, INTERVAL 3 MINUTE), @t_fs7y2515, @c_fs7y2515);
SET @ord_fs7y2515 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2515, @var_sm_oxf_l, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'L', 'Xanh biển', 540000.00, 2);

-- FS7Y2516 [Y-1] | COMPLETED + PAID | total=870,000
SET @t_fs7y2516 := STR_TO_DATE(CONCAT(@y1_num, '-07-14 12:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2516 := DATE_ADD(@t_fs7y2516, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2516', @prof_khach48, NULL, 'COMPLETED', 840000.00, 0.00, 870000.00, 'Trần Văn Phúc', '0916000048', '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2516, @t_fs7y2516, @c_fs7y2516);
SET @ord_fs7y2516 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2516, @var_nv_plo_tr_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Trắng', 420000.00, 2);

-- FS7Y2517 [Y-1] | COMPLETED + PAID | total=1,270,000
SET @t_fs7y2517 := STR_TO_DATE(CONCAT(@y1_num, '-07-27 19:50:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2517 := DATE_ADD(@t_fs7y2517, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2517', @prof_khach54, NULL, 'COMPLETED', 1270000.00, 0.00, 1270000.00, 'Hồ Trung Hiếu', '0916000054', '51 Trần Quốc Toản, Phường 8, Quận 3, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2517, INTERVAL 3 MINUTE), @t_fs7y2517, @c_fs7y2517);
SET @ord_fs7y2517 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2517, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1),
(@ord_fs7y2517, @var_nv_qj_ongrong_den_m, 'Quần jean ống rộng màu xanh đậm', 'M', 'Đen wash', 850000.00, 1);

-- FS7Y2518 [Y-1] | COMPLETED + PAID | total=1,690,000
SET @t_fs7y2518 := STR_TO_DATE(CONCAT(@y1_num, '-08-08 09:30:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2518 := DATE_ADD(@t_fs7y2518, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2518', @prof_khach15, @cp_sale2025, 'COMPLETED', 1890000.00, 200000.00, 1690000.00, 'Hoàng Bảo Ngọc', '0915000015', '50 Lý Tự Trọng, Phường An Cư, Quận Ninh Kiều, Cần Thơ', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2518, INTERVAL 3 MINUTE), @t_fs7y2518, @c_fs7y2518);
SET @ord_fs7y2518 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2518, @var_dam_do_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đỏ đô', 1890000.00, 1);

-- FS7Y2519 [Y-1] | COMPLETED + PAID | total=1,240,000
SET @t_fs7y2519 := STR_TO_DATE(CONCAT(@y1_num, '-08-19 15:20:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2519 := DATE_ADD(@t_fs7y2519, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2519', @prof_khach55, NULL, 'COMPLETED', 1240000.00, 0.00, 1240000.00, 'Đỗ Minh Thư', '0916000055', '163 Lê Hồng Phong, Phường Phước Hải, TP. Nha Trang, Khánh Hòa', 0.00, NULL, 'COD', 'PAID', @c_fs7y2519, @t_fs7y2519, @c_fs7y2519);
SET @ord_fs7y2519 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2519, @var_cv_xeply_m, 'Chân váy midi xếp ly màu kem', 'M', 'Kem', 790000.00, 1),
(@ord_fs7y2519, @var_plo_kem_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Kem', 450000.00, 1);

-- FS7Y2520 [Y-1] | COMPLETED + PAID | total=2,890,000
SET @t_fs7y2520 := STR_TO_DATE(CONCAT(@y1_num, '-08-30 21:10:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2520 := DATE_ADD(@t_fs7y2520, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2520', @prof_khach20, NULL, 'COMPLETED', 2890000.00, 0.00, 2890000.00, 'Vương Gia Huy', '0915000020', '41 Bà Triệu, Phường Hàng Bài, Quận Hoàn Kiếm, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2520, INTERVAL 3 MINUTE), @t_fs7y2520, @c_fs7y2520);
SET @ord_fs7y2520 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2520, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1),
(@ord_fs7y2520, @var_blz_nam_xam_m, 'Áo blazer nam màu xám tro', 'M', 'Xám tro', 2350000.00, 1);

-- FS7Y2521 [Y-1] | COMPLETED + PAID | total=1,770,000
SET @t_fs7y2521 := STR_TO_DATE(CONCAT(@y1_num, '-09-09 08:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2521 := DATE_ADD(@t_fs7y2521, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2521', @prof_khach50, @cp_sale2025, 'COMPLETED', 1970000.00, 200000.00, 1770000.00, 'Phạm Tấn Đạt', '0916000050', '75 Lê Quang Định, Phường 14, Quận Bình Thạnh, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2521, INTERVAL 3 MINUTE), @t_fs7y2521, @c_fs7y2521);
SET @ord_fs7y2521 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2521, @var_nv_ak_blz_nau_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Nâu tây', 1250000.00, 1),
(@ord_fs7y2521, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1);

-- FS7Y2522 [Y-1] | COMPLETED + PAID | total=1,090,000
SET @t_fs7y2522 := STR_TO_DATE(CONCAT(@y1_num, '-09-09 14:00:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2522 := DATE_ADD(@t_fs7y2522, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2522', @prof_khach53, NULL, 'COMPLETED', 1090000.00, 0.00, 1090000.00, 'Bùi Ngọc Diệp', '0916000053', '88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2522, INTERVAL 3 MINUTE), @t_fs7y2522, @c_fs7y2522);
SET @ord_fs7y2522 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2522, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1);

-- FS7Y2523 [Y-1] | COMPLETED + PAID | total=1,040,000
SET @t_fs7y2523 := STR_TO_DATE(CONCAT(@y1_num, '-09-09 20:30:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2523 := DATE_ADD(@t_fs7y2523, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2523', @prof_khach56, NULL, 'COMPLETED', 1040000.00, 0.00, 1040000.00, 'Huỳnh Gia Bảo', '0916000056', '29 Nguyễn Chí Thanh, Phường Láng Hạ, Quận Đống Đa, Hà Nội', 0.00, NULL, 'COD', 'PAID', @c_fs7y2523, @t_fs7y2523, @c_fs7y2523);
SET @ord_fs7y2523 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2523, @var_at_gym_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Đen', 310000.00, 2),
(@ord_fs7y2523, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 1);

-- FS7Y2524 [Y-1] | COMPLETED + PAID | total=1,010,000
SET @t_fs7y2524 := STR_TO_DATE(CONCAT(@y1_num, '-10-10 10:40:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2524 := DATE_ADD(@t_fs7y2524, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2524', @prof_khach51, NULL, 'COMPLETED', 1010000.00, 0.00, 1010000.00, 'Võ Thị Thanh Ngân', '0916000051', '19 Nguyễn Văn Cừ, Phường An Bình, Quận Ninh Kiều, Cần Thơ', 0.00, NULL, 'COD', 'PAID', @c_fs7y2524, @t_fs7y2524, @c_fs7y2524);
SET @ord_fs7y2524 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2524, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1),
(@ord_fs7y2524, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS7Y2525 [Y-1] | COMPLETED + PAID | total=871,500
SET @t_fs7y2525 := STR_TO_DATE(CONCAT(@y1_num, '-10-20 16:50:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2525 := DATE_ADD(@t_fs7y2525, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2525', @prof_khach9, @cp_sale2025, 'COMPLETED', 990000.00, 148500.00, 871500.00, 'Võ Thị Mỹ Linh', '0915000009', '302 Cách Mạng Tháng 8, Phường 10, Quận 3, TP.HCM', 30000.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2525, INTERVAL 3 MINUTE), @t_fs7y2525, @c_fs7y2525);
SET @ord_fs7y2525 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2525, @var_dam_hoanhi_m, 'Đầm midi hoa nhí màu hồng phấn', 'M', 'Hồng phấn', 990000.00, 1);

-- FS7Y2526 [Y-1] | COMPLETED + PAID | total=750,000
SET @t_fs7y2526 := STR_TO_DATE(CONCAT(@y1_num, '-10-20 19:20:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2526 := DATE_ADD(@t_fs7y2526, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2526', @prof_khach19, NULL, 'COMPLETED', 720000.00, 0.00, 750000.00, 'Tạ Thị Hồng Nhung', '0915000019', '190 Quang Trung, Phường 10, Quận Gò Vấp, TP.HCM', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2526, INTERVAL 3 MINUTE), @t_fs7y2526, @c_fs7y2526);
SET @ord_fs7y2526 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2526, @var_nv_qn_cul_be_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Be cát', 720000.00, 1);

-- FS7Y2527 [Y-1] | COMPLETED + PAID | total=2,140,000
SET @t_fs7y2527 := STR_TO_DATE(CONCAT(@y1_num, '-11-11 07:45:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2527 := DATE_ADD(@t_fs7y2527, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2527', @prof_khach47, @cp_sale2025, 'COMPLETED', 2340000.00, 200000.00, 2140000.00, 'Nguyễn Hải Yến', '0916000047', '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2527, INTERVAL 3 MINUTE), @t_fs7y2527, @c_fs7y2527);
SET @ord_fs7y2527 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2527, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1),
(@ord_fs7y2527, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1);

-- FS7Y2528 [Y-1] | COMPLETED + PAID | total=1,880,000
SET @t_fs7y2528 := STR_TO_DATE(CONCAT(@y1_num, '-11-11 11:30:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2528 := DATE_ADD(@t_fs7y2528, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2528', @prof_khach48, @cp_sale2025, 'COMPLETED', 2080000.00, 200000.00, 1880000.00, 'Trần Văn Phúc', '0916000048', '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2528, INTERVAL 3 MINUTE), @t_fs7y2528, @c_fs7y2528);
SET @ord_fs7y2528 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2528, @var_ak_denim_l, 'Áo khoác denim xanh dáng ngắn', 'L', 'Xanh denim', 1390000.00, 1),
(@ord_fs7y2528, @var_sm_linen_tr_m, 'Áo sơ mi linen trắng tối giản', 'M', 'Trắng', 690000.00, 1);

-- FS7Y2529 [Y-1] | COMPLETED + PAID | total=870,000
SET @t_fs7y2529 := STR_TO_DATE(CONCAT(@y1_num, '-11-11 16:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2529 := DATE_ADD(@t_fs7y2529, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2529', @prof_khach52, NULL, 'COMPLETED', 840000.00, 0.00, 870000.00, 'Đặng Quang Khải', '0916000052', '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2529, @t_fs7y2529, @c_fs7y2529);
SET @ord_fs7y2529 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2529, @var_plo_reu_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Xanh rêu', 420000.00, 2);

-- FS7Y2530 [Y-1] | COMPLETED + PAID | total=1,690,000
SET @t_fs7y2530 := STR_TO_DATE(CONCAT(@y1_num, '-11-11 22:05:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2530 := DATE_ADD(@t_fs7y2530, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2530', @prof_khach55, @cp_sale2025, 'COMPLETED', 1890000.00, 200000.00, 1690000.00, 'Đỗ Minh Thư', '0916000055', '163 Lê Hồng Phong, Phường Phước Hải, TP. Nha Trang, Khánh Hòa', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2530, INTERVAL 3 MINUTE), @t_fs7y2530, @c_fs7y2530);
SET @ord_fs7y2530 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2530, @var_nv_dam_xnl_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Xanh ngọc lục bảo', 1890000.00, 1);

-- FS7Y2531 [Y-1] | COMPLETED + PAID | total=1,010,000
SET @t_fs7y2531 := STR_TO_DATE(CONCAT(@y1_num, '-11-28 15:10:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2531 := DATE_ADD(@t_fs7y2531, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2531', @prof_khach22, NULL, 'COMPLETED', 980000.00, 0.00, 1010000.00, 'Lâm Đức Anh', '0915000022', '90 Hùng Vương, Phường Phú Nhuận, TP. Huế', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2531, @t_fs7y2531, @c_fs7y2531);
SET @ord_fs7y2531 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2531, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 2);

-- FS7Y2532 [Y-1] | COMPLETED + PAID | total=2,640,000
SET @t_fs7y2532 := STR_TO_DATE(CONCAT(@y1_num, '-12-12 09:20:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2532 := DATE_ADD(@t_fs7y2532, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2532', @prof_khach5, @cp_sale2025, 'COMPLETED', 2840000.00, 200000.00, 2640000.00, 'Nguyễn Ngọc Lan', '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2532, INTERVAL 3 MINUTE), @t_fs7y2532, @c_fs7y2532);
SET @ord_fs7y2532 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2532, @var_dam_do_s, 'Đầm Dự Tiệc Satin Đỏ Đô', 'S', 'Đỏ đô', 1890000.00, 1),
(@ord_fs7y2532, @var_al_colo_m, 'Áo len cổ lọ màu nâu cà phê', 'M', 'Nâu', 950000.00, 1);

-- FS7Y2533 [Y-1] | COMPLETED + PAID | total=1,079,500
SET @t_fs7y2533 := STR_TO_DATE(CONCAT(@y1_num, '-12-12 13:50:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2533 := DATE_ADD(@t_fs7y2533, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2533', @prof_khach54, @cp_sale2025, 'COMPLETED', 1270000.00, 190500.00, 1079500.00, 'Hồ Trung Hiếu', '0916000054', '51 Trần Quốc Toản, Phường 8, Quận 3, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2533, INTERVAL 3 MINUTE), @t_fs7y2533, @c_fs7y2533);
SET @ord_fs7y2533 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2533, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1),
(@ord_fs7y2533, @var_nv_cd_kem_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Nâu kem', 420000.00, 1);

-- FS7Y2534 [Y-1] | COMPLETED + PAID | total=1,340,000
SET @t_fs7y2534 := STR_TO_DATE(CONCAT(@y1_num, '-12-12 20:40:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2534 := DATE_ADD(@t_fs7y2534, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2534', @prof_khach56, NULL, 'COMPLETED', 1340000.00, 0.00, 1340000.00, 'Huỳnh Gia Bảo', '0916000056', '29 Nguyễn Chí Thanh, Phường Láng Hạ, Quận Đống Đa, Hà Nội', 0.00, NULL, 'COD', 'PAID', @c_fs7y2534, @t_fs7y2534, @c_fs7y2534);
SET @ord_fs7y2534 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2534, @var_nv_al_gil_nv_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Xanh navy', 590000.00, 1),
(@ord_fs7y2534, @var_sm_nam_ks_l, 'Áo sơ mi nam kẻ sọc xanh navy', 'L', 'Xanh navy', 750000.00, 1);

-- FS7Y2535 [Y-1] | COMPLETED + PAID | total=1,210,000
SET @t_fs7y2535 := STR_TO_DATE(CONCAT(@y1_num, '-12-23 14:15:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2535 := DATE_ADD(@t_fs7y2535, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2535', @prof_khach10, NULL, 'COMPLETED', 1210000.00, 0.00, 1210000.00, 'Đặng Hoàng Nam', '0915000010', '56 Nguyễn Văn Linh, Phường Tân Thuận Tây, Quận 7, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2535, INTERVAL 3 MINUTE), @t_fs7y2535, @c_fs7y2535);
SET @ord_fs7y2535 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2535, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 2),
(@ord_fs7y2535, @var_nv_tt_gym_hd_m, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'M', 'Hồng đất', 590000.00, 1);

-- FS7Y2536 [Y-1] | COMPLETED + PAID | total=1,062,500
SET @t_fs7y2536 := STR_TO_DATE(CONCAT(@y1_num, '-12-29 18:00:00'), '%Y-%m-%d %H:%i:%s');
SET @c_fs7y2536 := DATE_ADD(@t_fs7y2536, INTERVAL 2 DAY);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2536', @prof_khach26, @cp_sale2025, 'COMPLETED', 1250000.00, 187500.00, 1062500.00, 'Cao Tấn Lộc', '0915000026', '34 Đại lộ Bình Dương, TP. Thủ Dầu Một, Bình Dương', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2536, INTERVAL 3 MINUTE), @t_fs7y2536, @c_fs7y2536);
SET @ord_fs7y2536 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2536, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1);

-- FS7Y2601 [Y-0 YTD] | COMPLETED + PAID | total=2,960,000
SET @t_fs7y2601 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.02) SECOND);
SET @c_fs7y2601 := LEAST(DATE_ADD(@t_fs7y2601, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2601', @prof_khach47, @cp_sale2026, 'COMPLETED', 3140000.00, 180000.00, 2960000.00, 'Nguyễn Hải Yến', '0916000047', '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2601, INTERVAL 3 MINUTE), @t_fs7y2601, @c_fs7y2601);
SET @ord_fs7y2601 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2601, @var_dam_do_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đỏ đô', 1890000.00, 1),
(@ord_fs7y2601, @var_ak_blz_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Đen', 1250000.00, 1);

-- FS7Y2602 [Y-0 YTD] | COMPLETED + PAID | total=1,390,000
SET @t_fs7y2602 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.05) SECOND);
SET @c_fs7y2602 := LEAST(DATE_ADD(@t_fs7y2602, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2602', @prof_khach48, NULL, 'COMPLETED', 1390000.00, 0.00, 1390000.00, 'Trần Văn Phúc', '0916000048', '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'COD', 'PAID', @c_fs7y2602, @t_fs7y2602, @c_fs7y2602);
SET @ord_fs7y2602 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2602, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1),
(@ord_fs7y2602, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1);

-- FS7Y2603 [Y-0 YTD] | COMPLETED + PAID | total=930,000
SET @t_fs7y2603 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.09) SECOND);
SET @c_fs7y2603 := LEAST(DATE_ADD(@t_fs7y2603, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2603', @prof_khach49, NULL, 'COMPLETED', 900000.00, 0.00, 930000.00, 'Lê Hoàng Minh Anh', '0916000049', '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2603, INTERVAL 3 MINUTE), @t_fs7y2603, @c_fs7y2603);
SET @ord_fs7y2603 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2603, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 2);

-- FS7Y2604 [Y-0 YTD] | COMPLETED + PAID | total=892,400
SET @t_fs7y2604 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.12) SECOND);
SET @c_fs7y2604 := LEAST(DATE_ADD(@t_fs7y2604, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2604', @prof_khach50, @cp_sale2026, 'COMPLETED', 980000.00, 117600.00, 892400.00, 'Phạm Tấn Đạt', '0916000050', '75 Lê Quang Định, Phường 14, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2604, @t_fs7y2604, @c_fs7y2604);
SET @ord_fs7y2604 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2604, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 2);

-- FS7Y2605 [Y-0 YTD] | COMPLETED + PAID | total=1,680,000
SET @t_fs7y2605 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.16) SECOND);
SET @c_fs7y2605 := LEAST(DATE_ADD(@t_fs7y2605, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2605', @prof_khach51, NULL, 'COMPLETED', 1680000.00, 0.00, 1680000.00, 'Võ Thị Thanh Ngân', '0916000051', '19 Nguyễn Văn Cừ, Phường An Bình, Quận Ninh Kiều, Cần Thơ', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2605, INTERVAL 3 MINUTE), @t_fs7y2605, @c_fs7y2605);
SET @ord_fs7y2605 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2605, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1),
(@ord_fs7y2605, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1);

-- FS7Y2606 [Y-0 YTD] | COMPLETED + PAID | total=1,117,600
SET @t_fs7y2606 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.2) SECOND);
SET @c_fs7y2606 := LEAST(DATE_ADD(@t_fs7y2606, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2606', @prof_khach52, @cp_sale2026, 'COMPLETED', 1270000.00, 152400.00, 1117600.00, 'Đặng Quang Khải', '0916000052', '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2606, INTERVAL 3 MINUTE), @t_fs7y2606, @c_fs7y2606);
SET @ord_fs7y2606 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2606, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1),
(@ord_fs7y2606, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1);

-- FS7Y2607 [Y-0 YTD] | COMPLETED + PAID | total=1,170,000
SET @t_fs7y2607 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.23) SECOND);
SET @c_fs7y2607 := LEAST(DATE_ADD(@t_fs7y2607, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2607', @prof_khach53, NULL, 'COMPLETED', 1170000.00, 0.00, 1170000.00, 'Bùi Ngọc Diệp', '0916000053', '88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2607, @t_fs7y2607, @c_fs7y2607);
SET @ord_fs7y2607 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2607, @var_qn_cul_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Trắng kem', 720000.00, 1),
(@ord_fs7y2607, @var_plo_kem_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Kem', 450000.00, 1);

-- FS7Y2608 [Y-0 YTD] | COMPLETED + PAID | total=1,080,000
SET @t_fs7y2608 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.23) SECOND);
SET @c_fs7y2608 := LEAST(DATE_ADD(@t_fs7y2608, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2608', @prof_khach12, NULL, 'COMPLETED', 1080000.00, 0.00, 1080000.00, 'Phan Văn Khánh', '0915000012', '240 Điện Biên Phủ, Phường 17, Quận Bình Thạnh, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2608, INTERVAL 3 MINUTE), @t_fs7y2608, @c_fs7y2608);
SET @ord_fs7y2608 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2608, @var_nv_sm_oxf_xn_l, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'L', 'Xám nhạt', 540000.00, 2);

-- FS7Y2609 [Y-0 YTD] | COMPLETED + PAID | total=1,064,800
SET @t_fs7y2609 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.28) SECOND);
SET @c_fs7y2609 := LEAST(DATE_ADD(@t_fs7y2609, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2609', @prof_khach54, @cp_sale2026, 'COMPLETED', 1210000.00, 145200.00, 1064800.00, 'Hồ Trung Hiếu', '0916000054', '51 Trần Quốc Toản, Phường 8, Quận 3, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2609, INTERVAL 3 MINUTE), @t_fs7y2609, @c_fs7y2609);
SET @ord_fs7y2609 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2609, @var_at_gym_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Đen', 310000.00, 2),
(@ord_fs7y2609, @var_tt_gym_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Xám khói', 590000.00, 1);

-- FS7Y2610 [Y-0 YTD] | COMPLETED + PAID | total=1,080,000
SET @t_fs7y2610 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.33) SECOND);
SET @c_fs7y2610 := LEAST(DATE_ADD(@t_fs7y2610, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2610', @prof_khach55, NULL, 'COMPLETED', 1080000.00, 0.00, 1080000.00, 'Đỗ Minh Thư', '0916000055', '163 Lê Hồng Phong, Phường Phước Hải, TP. Nha Trang, Khánh Hòa', 0.00, NULL, 'COD', 'PAID', @c_fs7y2610, @t_fs7y2610, @c_fs7y2610);
SET @ord_fs7y2610 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2610, @var_nv_cv_chua_den_m, 'Chân váy chữ A denim xanh', 'M', 'Đen wash', 590000.00, 1),
(@ord_fs7y2610, @var_qs_kaki_m, 'Quần short kaki nam màu xanh rêu', 'M', 'Xanh rêu', 490000.00, 1);

-- FS7Y2611 [Y-0 YTD] | COMPLETED + PAID | total=2,160,000
SET @t_fs7y2611 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.37) SECOND);
SET @c_fs7y2611 := LEAST(DATE_ADD(@t_fs7y2611, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2611', @prof_khach56, @cp_sale2026, 'COMPLETED', 2340000.00, 180000.00, 2160000.00, 'Huỳnh Gia Bảo', '0916000056', '29 Nguyễn Chí Thanh, Phường Láng Hạ, Quận Đống Đa, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2611, INTERVAL 3 MINUTE), @t_fs7y2611, @c_fs7y2611);
SET @ord_fs7y2611 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2611, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1),
(@ord_fs7y2611, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1);

-- FS7Y2612 [Y-0 YTD] | COMPLETED + PAID | total=1,010,000
SET @t_fs7y2612 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.41) SECOND);
SET @c_fs7y2612 := LEAST(DATE_ADD(@t_fs7y2612, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2612', @prof_khach47, NULL, 'COMPLETED', 1010000.00, 0.00, 1010000.00, 'Nguyễn Hải Yến', '0916000047', '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2612, INTERVAL 3 MINUTE), @t_fs7y2612, @c_fs7y2612);
SET @ord_fs7y2612 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2612, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1),
(@ord_fs7y2612, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS7Y2613 [Y-0 YTD] | COMPLETED + PAID | total=870,000
SET @t_fs7y2613 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.45) SECOND);
SET @c_fs7y2613 := LEAST(DATE_ADD(@t_fs7y2613, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2613', @prof_khach15, NULL, 'COMPLETED', 840000.00, 0.00, 870000.00, 'Hoàng Bảo Ngọc', '0915000015', '50 Lý Tự Trọng, Phường An Cư, Quận Ninh Kiều, Cần Thơ', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2613, @t_fs7y2613, @c_fs7y2613);
SET @ord_fs7y2613 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2613, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 2);

-- FS7Y2614 [Y-0 YTD] | COMPLETED + PAID | total=1,410,000
SET @t_fs7y2614 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.5) SECOND);
SET @c_fs7y2614 := LEAST(DATE_ADD(@t_fs7y2614, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2614', @prof_khach49, @cp_sale2026, 'COMPLETED', 1590000.00, 180000.00, 1410000.00, 'Lê Hoàng Minh Anh', '0916000049', '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2614, INTERVAL 3 MINUTE), @t_fs7y2614, @c_fs7y2614);
SET @ord_fs7y2614 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2614, @var_nv_dam_lua_vc_m, 'Đầm lụa dáng dài màu be', 'M', 'Vàng champagne', 1590000.00, 1);

-- FS7Y2615 [Y-0 YTD] | COMPLETED + PAID | total=1,049,000
SET @t_fs7y2615 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.5) SECOND);
SET @c_fs7y2615 := LEAST(DATE_ADD(@t_fs7y2615, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2615', @prof_khach51, NULL, 'COMPLETED', 1049000.00, 0.00, 1049000.00, 'Võ Thị Thanh Ngân', '0916000051', '19 Nguyễn Văn Cừ, Phường An Bình, Quận Ninh Kiều, Cần Thơ', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2615, INTERVAL 3 MINUTE), @t_fs7y2615, @c_fs7y2615);
SET @ord_fs7y2615 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2615, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1),
(@ord_fs7y2615, @var_nv_at_over_tr_m, 'Áo thun oversize màu đen in chữ', 'M', 'Trắng', 329000.00, 1);

-- FS7Y2616 [Y-0 YTD] | COMPLETED + PAID | total=1,110,000
SET @t_fs7y2616 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.55) SECOND);
SET @c_fs7y2616 := LEAST(DATE_ADD(@t_fs7y2616, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2616', @prof_khach53, NULL, 'COMPLETED', 1110000.00, 0.00, 1110000.00, 'Bùi Ngọc Diệp', '0916000053', '88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2616, @t_fs7y2616, @c_fs7y2616);
SET @ord_fs7y2616 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2616, @var_sm_linen_tr_m, 'Áo sơ mi linen trắng tối giản', 'M', 'Trắng', 690000.00, 1),
(@ord_fs7y2616, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1);

-- FS7Y2617 [Y-0 YTD] | COMPLETED + PAID | total=1,117,600
SET @t_fs7y2617 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.6) SECOND);
SET @c_fs7y2617 := LEAST(DATE_ADD(@t_fs7y2617, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2617', @prof_khach54, @cp_sale2026, 'COMPLETED', 1270000.00, 152400.00, 1117600.00, 'Hồ Trung Hiếu', '0916000054', '51 Trần Quốc Toản, Phường 8, Quận 3, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2617, INTERVAL 3 MINUTE), @t_fs7y2617, @c_fs7y2617);
SET @ord_fs7y2617 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2617, @var_nv_vs_den_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Đen', 850000.00, 1),
(@ord_fs7y2617, @var_plo_reu_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Xanh rêu', 420000.00, 1);

-- FS7Y2618 [Y-0 YTD] | COMPLETED + PAID | total=900,000
SET @t_fs7y2618 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.64) SECOND);
SET @c_fs7y2618 := LEAST(DATE_ADD(@t_fs7y2618, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2618', @prof_khach17, NULL, 'COMPLETED', 870000.00, 0.00, 900000.00, 'Lương Thị Thanh Mai', '0915000017', '75 Hoàng Diệu, Phường Nam Dương, Quận Hải Châu, Đà Nẵng', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2618, INTERVAL 3 MINUTE), @t_fs7y2618, @c_fs7y2618);
SET @ord_fs7y2618 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2618, @var_at_basic_tr_l, 'Áo thun cotton basic cổ tròn màu trắng', 'L', 'Trắng', 290000.00, 3);

-- FS7Y2619 [Y-0 YTD] | COMPLETED + PAID | total=813,200
SET @t_fs7y2619 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.68) SECOND);
SET @c_fs7y2619 := LEAST(DATE_ADD(@t_fs7y2619, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2619', @prof_khach56, @cp_sale2026, 'COMPLETED', 890000.00, 106800.00, 813200.00, 'Huỳnh Gia Bảo', '0916000056', '29 Nguyễn Chí Thanh, Phường Láng Hạ, Quận Đống Đa, Hà Nội', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2619, @t_fs7y2619, @c_fs7y2619);
SET @ord_fs7y2619 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2619, @var_nv_qt_ongdung_xk_m, 'Quần tây ống đứng màu đen', 'M', 'Xám khói', 890000.00, 1);

-- FS7Y2620 [Y-0 YTD] | COMPLETED + PAID | total=2,040,000
SET @t_fs7y2620 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.73) SECOND);
SET @c_fs7y2620 := LEAST(DATE_ADD(@t_fs7y2620, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2620', @prof_khach48, NULL, 'COMPLETED', 2040000.00, 0.00, 2040000.00, 'Trần Văn Phúc', '0916000048', '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2620, INTERVAL 3 MINUTE), @t_fs7y2620, @c_fs7y2620);
SET @ord_fs7y2620 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2620, @var_ak_blz_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Đen', 1250000.00, 1),
(@ord_fs7y2620, @var_cv_xeply_m, 'Chân váy midi xếp ly màu kem', 'M', 'Kem', 790000.00, 1);

-- FS7Y2621 [Y-0 YTD] | COMPLETED + PAID | total=830,000
SET @t_fs7y2621 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.77) SECOND);
SET @c_fs7y2621 := LEAST(DATE_ADD(@t_fs7y2621, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2621', @prof_khach50, NULL, 'COMPLETED', 800000.00, 0.00, 830000.00, 'Phạm Tấn Đạt', '0916000050', '75 Lê Quang Định, Phường 14, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2621, INTERVAL 3 MINUTE), @t_fs7y2621, @c_fs7y2621);
SET @ord_fs7y2621 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2621, @var_nv_qn_jog_reu_l, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'L', 'Xanh rêu', 490000.00, 1),
(@ord_fs7y2621, @var_at_gym_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Đen', 310000.00, 1);

-- FS7Y2622 [Y-0 YTD] | COMPLETED + PAID | total=1,223,200
SET @t_fs7y2622 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.81) SECOND);
SET @c_fs7y2622 := LEAST(DATE_ADD(@t_fs7y2622, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2622', @prof_khach52, @cp_sale2026, 'COMPLETED', 1390000.00, 166800.00, 1223200.00, 'Đặng Quang Khải', '0916000052', '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2622, @t_fs7y2622, @c_fs7y2622);
SET @ord_fs7y2622 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2622, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1),
(@ord_fs7y2622, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1);

-- FS7Y2623 [Y-0 YTD] | COMPLETED + PAID | total=1,890,000
SET @t_fs7y2623 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.81) SECOND);
SET @c_fs7y2623 := LEAST(DATE_ADD(@t_fs7y2623, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2623', @prof_khach55, NULL, 'COMPLETED', 1890000.00, 0.00, 1890000.00, 'Đỗ Minh Thư', '0916000055', '163 Lê Hồng Phong, Phường Phước Hải, TP. Nha Trang, Khánh Hòa', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2623, INTERVAL 3 MINUTE), @t_fs7y2623, @c_fs7y2623);
SET @ord_fs7y2623 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2623, @var_dam_do_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đỏ đô', 1890000.00, 1);

-- FS7Y2624 [Y-0 YTD] | COMPLETED + PAID | total=1,040,000
SET @t_fs7y2624 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.86) SECOND);
SET @c_fs7y2624 := LEAST(DATE_ADD(@t_fs7y2624, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2624', @prof_khach21, NULL, 'COMPLETED', 1040000.00, 0.00, 1040000.00, 'Châu Ngọc Bích', '0915000021', '155 Sư Vạn Hạnh, Phường 12, Quận 10, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2624, INTERVAL 3 MINUTE), @t_fs7y2624, @c_fs7y2624);
SET @ord_fs7y2624 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2624, @var_plo_kem_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Kem', 450000.00, 1),
(@ord_fs7y2624, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1);

-- FS7Y2625 [Y-0 YTD] | COMPLETED + PAID | total=1,152,800
SET @t_fs7y2625 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.9) SECOND);
SET @c_fs7y2625 := LEAST(DATE_ADD(@t_fs7y2625, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2625', @prof_khach23, @cp_sale2026, 'COMPLETED', 1310000.00, 157200.00, 1152800.00, 'Đoàn Thị Phương Thảo', '0915000023', '220 Cộng Hòa, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2625, @t_fs7y2625, @c_fs7y2625);
SET @ord_fs7y2625 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2625, @var_tt_gym_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Xám khói', 590000.00, 1),
(@ord_fs7y2625, @var_qn_cul_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Trắng kem', 720000.00, 1);

-- FS7Y2626 [Y-0 YTD] | COMPLETED + PAID | total=990,000
SET @t_fs7y2626 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.93) SECOND);
SET @c_fs7y2626 := LEAST(DATE_ADD(@t_fs7y2626, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2626', @prof_khach24, NULL, 'COMPLETED', 960000.00, 0.00, 990000.00, 'Kiều Minh Khoa', '0915000024', '11 Nguyễn Ái Quốc, Phường Tân Phong, TP. Biên Hòa, Đồng Nai', 30000.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2626, INTERVAL 3 MINUTE), @t_fs7y2626, @c_fs7y2626);
SET @ord_fs7y2626 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2626, @var_sm_oxf_l, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'L', 'Xanh biển', 540000.00, 1),
(@ord_fs7y2626, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS7Y2627 [Y-0 YTD] | COMPLETED + PAID | total=2,310,000
SET @t_fs7y2627 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.96) SECOND);
SET @c_fs7y2627 := LEAST(DATE_ADD(@t_fs7y2627, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2627', @prof_khach25, @cp_sale2026, 'COMPLETED', 2490000.00, 180000.00, 2310000.00, 'Hà Tuyết Nhi', '0915000025', '68 Trường Chinh, Phường Tây Thạnh, Quận Tân Phú, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2627, INTERVAL 3 MINUTE), @t_fs7y2627, @c_fs7y2627);
SET @ord_fs7y2627 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2627, @var_nv_trench_den_m, 'Áo trench coat dáng dài màu camel', 'M', 'Đen', 2490000.00, 1);

-- FS7Y2628 [Y-0 YTD] | COMPLETED + PAID | total=1,440,000
SET @t_fs7y2628 := DATE_ADD(@y0_start, INTERVAL FLOOR(@ytd_prev_span * 0.98) SECOND);
SET @c_fs7y2628 := LEAST(DATE_ADD(@t_fs7y2628, INTERVAL 2 DAY), DATE_SUB(@cur_m_start, INTERVAL 1 HOUR));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2628', @prof_khach26, NULL, 'COMPLETED', 1440000.00, 0.00, 1440000.00, 'Cao Tấn Lộc', '0915000026', '34 Đại lộ Bình Dương, TP. Thủ Dầu Một, Bình Dương', 0.00, NULL, 'COD', 'PAID', @c_fs7y2628, @t_fs7y2628, @c_fs7y2628);
SET @ord_fs7y2628 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2628, @var_qj_ongrong_m, 'Quần jean ống rộng màu xanh đậm', 'M', 'Xanh denim', 850000.00, 1),
(@ord_fs7y2628, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1);

-- FS7Y2629 [Y-0 -8d] | COMPLETED + PAID | total=870,000
SET @t_fs7y2629 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 8 DAY), '11:20:00'), @y0_start), NOW(6));
SET @c_fs7y2629 := LEAST(DATE_ADD(@t_fs7y2629, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2629', @prof_khach47, NULL, 'COMPLETED', 840000.00, 0.00, 870000.00, 'Nguyễn Hải Yến', '0916000047', '118 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_fs7y2629, @t_fs7y2629, @c_fs7y2629);
SET @ord_fs7y2629 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2629, @var_plo_reu_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Xanh rêu', 420000.00, 1),
(@ord_fs7y2629, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS7Y2630 [Y-0 -6d] | COMPLETED + PAID | total=750,000
SET @t_fs7y2630 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 6 DAY), '15:40:00'), @y0_start), NOW(6));
SET @c_fs7y2630 := LEAST(DATE_ADD(@t_fs7y2630, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2630', @prof_khach51, NULL, 'COMPLETED', 720000.00, 0.00, 750000.00, 'Võ Thị Thanh Ngân', '0916000051', '19 Nguyễn Văn Cừ, Phường An Bình, Quận Ninh Kiều, Cần Thơ', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2630, INTERVAL 3 MINUTE), @t_fs7y2630, @c_fs7y2630);
SET @ord_fs7y2630 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2630, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1);

-- FS7Y2631 [Y-0 -5d] | COMPLETED + PAID | total=1,710,000
SET @t_fs7y2631 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 5 DAY), '09:15:00'), @y0_start), NOW(6));
SET @c_fs7y2631 := LEAST(DATE_ADD(@t_fs7y2631, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2631', @prof_khach49, @cp_sale2026, 'COMPLETED', 1890000.00, 180000.00, 1710000.00, 'Lê Hoàng Minh Anh', '0916000049', '204 Phố Huế, Phường Phố Huế, Quận Hai Bà Trưng, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2631, INTERVAL 3 MINUTE), @t_fs7y2631, @c_fs7y2631);
SET @ord_fs7y2631 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2631, @var_dam_do_s, 'Đầm Dự Tiệc Satin Đỏ Đô', 'S', 'Đỏ đô', 1890000.00, 1);

-- FS7Y2632 [Y-0 -5d] | COMPLETED + PAID | total=1,110,000
SET @t_fs7y2632 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 5 DAY), '20:05:00'), @y0_start), NOW(6));
SET @c_fs7y2632 := LEAST(DATE_ADD(@t_fs7y2632, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2632', @prof_khach53, NULL, 'COMPLETED', 1110000.00, 0.00, 1110000.00, 'Bùi Ngọc Diệp', '0916000053', '88 Hoàng Hoa Thám, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2632, @t_fs7y2632, @c_fs7y2632);
SET @ord_fs7y2632 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2632, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 2),
(@ord_fs7y2632, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS7Y2633 [Y-0 -3d] | COMPLETED + PAID | total=2,960,000
SET @t_fs7y2633 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '08:30:00'), @y0_start), NOW(6));
SET @c_fs7y2633 := LEAST(DATE_ADD(@t_fs7y2633, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2633', @prof_khach5, @cp_sale2026, 'COMPLETED', 3140000.00, 180000.00, 2960000.00, 'Nguyễn Ngọc Lan', '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2633, INTERVAL 3 MINUTE), @t_fs7y2633, @c_fs7y2633);
SET @ord_fs7y2633 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2633, @var_dam_do_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đỏ đô', 1890000.00, 1),
(@ord_fs7y2633, @var_nv_ak_blz_kb_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Kem be', 1250000.00, 1);

-- FS7Y2634 [Y-0 -3d] | COMPLETED + PAID | total=880,000
SET @t_fs7y2634 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '11:45:00'), @y0_start), NOW(6));
SET @c_fs7y2634 := LEAST(DATE_ADD(@t_fs7y2634, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2634', @prof_khach50, NULL, 'COMPLETED', 850000.00, 0.00, 880000.00, 'Phạm Tấn Đạt', '0916000050', '75 Lê Quang Định, Phường 14, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2634, INTERVAL 3 MINUTE), @t_fs7y2634, @c_fs7y2634);
SET @ord_fs7y2634 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2634, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1);

-- FS7Y2635 [Y-0 -3d] | COMPLETED + PAID | total=1,320,000
SET @t_fs7y2635 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '16:20:00'), @y0_start), NOW(6));
SET @c_fs7y2635 := LEAST(DATE_ADD(@t_fs7y2635, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2635', @prof_khach54, @cp_sale2026, 'COMPLETED', 1500000.00, 180000.00, 1320000.00, 'Hồ Trung Hiếu', '0916000054', '51 Trần Quốc Toản, Phường 8, Quận 3, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_fs7y2635, @t_fs7y2635, @c_fs7y2635);
SET @ord_fs7y2635 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2635, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 2),
(@ord_fs7y2635, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 1);

-- FS7Y2636 [Y-0 -3d] | COMPLETED + PAID | total=1,880,000
SET @t_fs7y2636 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '21:10:00'), @y0_start), NOW(6));
SET @c_fs7y2636 := LEAST(DATE_ADD(@t_fs7y2636, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2636', @prof_khach56, NULL, 'COMPLETED', 1880000.00, 0.00, 1880000.00, 'Huỳnh Gia Bảo', '0916000056', '29 Nguyễn Chí Thanh, Phường Láng Hạ, Quận Đống Đa, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2636, INTERVAL 3 MINUTE), @t_fs7y2636, @c_fs7y2636);
SET @ord_fs7y2636 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2636, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1),
(@ord_fs7y2636, @var_cv_xeply_m, 'Chân váy midi xếp ly màu kem', 'M', 'Kem', 790000.00, 1);

-- FS7Y2637 [Y-0 -1d] | COMPLETED + PAID | total=1,040,000
SET @t_fs7y2637 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '10:15:00'), @y0_start), NOW(6));
SET @c_fs7y2637 := LEAST(DATE_ADD(@t_fs7y2637, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2637', @prof_khach52, NULL, 'COMPLETED', 1040000.00, 0.00, 1040000.00, 'Đặng Quang Khải', '0916000052', '310 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2637, INTERVAL 3 MINUTE), @t_fs7y2637, @c_fs7y2637);
SET @ord_fs7y2637 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2637, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1),
(@ord_fs7y2637, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 1);

-- FS7Y2638 [Y-0 -0d] | COMPLETED + PAID | total=1,920,000
SET @t_fs7y2638 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 0 DAY), '01:15:00'), @y0_start), NOW(6));
SET @c_fs7y2638 := LEAST(DATE_ADD(@t_fs7y2638, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2638', @prof_khach48, @cp_sale2026, 'COMPLETED', 2100000.00, 180000.00, 1920000.00, 'Trần Văn Phúc', '0916000048', '42 Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_fs7y2638, INTERVAL 3 MINUTE), @t_fs7y2638, @c_fs7y2638);
SET @ord_fs7y2638 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2638, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1),
(@ord_fs7y2638, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1);

-- FS7Y2639 [Y-0 -0d] | COMPLETED + PAID | total=1,090,000
SET @t_fs7y2639 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 0 DAY), '04:30:00'), @y0_start), NOW(6));
SET @c_fs7y2639 := LEAST(DATE_ADD(@t_fs7y2639, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2639', @prof_khach55, NULL, 'COMPLETED', 1090000.00, 0.00, 1090000.00, 'Đỗ Minh Thư', '0916000055', '163 Lê Hồng Phong, Phường Phước Hải, TP. Nha Trang, Khánh Hòa', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_fs7y2639, INTERVAL 3 MINUTE), @t_fs7y2639, @c_fs7y2639);
SET @ord_fs7y2639 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2639, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1);

-- FS7Y2640 [Y-0 -0d] | COMPLETED + PAID | total=1,010,000
SET @t_fs7y2640 := LEAST(GREATEST(TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 0 DAY), '07:45:00'), @y0_start), NOW(6));
SET @c_fs7y2640 := LEAST(DATE_ADD(@t_fs7y2640, INTERVAL 12 HOUR), NOW(6));
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount, recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method, payment_status, paid_at, created_at, completed_at)
VALUES ('FS7Y2640', @prof_khach22, NULL, 'COMPLETED', 1010000.00, 0.00, 1010000.00, 'Lâm Đức Anh', '0915000022', '90 Hùng Vương, Phường Phú Nhuận, TP. Huế', 0.00, NULL, 'COD', 'PAID', @c_fs7y2640, @t_fs7y2640, @c_fs7y2640);
SET @ord_fs7y2640 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity) VALUES
(@ord_fs7y2640, @var_tt_gym_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Xám khói', 590000.00, 1),
(@ord_fs7y2640, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1);

-- ============================================================================
-- MỤC 5: LỊCH SỬ KHO ĐỒNG BỘ 100% CHO TOÀN BỘ BIẾN THỂ MỚI & CÁC ĐƠN HÀNG
-- ============================================================================
INSERT INTO stock_history (variant_id, type, quantity_change, stock_after, supplier, import_price, reason, order_id, performed_by_id, created_at) VALUES
(@var_plo_reu_m, 'IMPORT', 6, @base_plo_reu_m + 6, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập bổ sung nguồn hàng đa năm (PLO-REU-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_plo_reu_m, 'SALE', -1, @base_plo_reu_m + 5, NULL, NULL, 'Xuất kho theo đơn FS7Y2401', @ord_fs7y2401, @prof_staff3, @t_fs7y2401),
(@var_plo_reu_m, 'SALE', -1, @base_plo_reu_m + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2423', @ord_fs7y2423, @prof_staff3, @t_fs7y2423),
(@var_plo_reu_m, 'SALE', -1, @base_plo_reu_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2523', @ord_fs7y2523, @prof_staff3, @t_fs7y2523),
(@var_plo_reu_m, 'SALE', -2, @base_plo_reu_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2613', @ord_fs7y2613, @prof_staff3, @t_fs7y2613),
(@var_plo_reu_m, 'SALE', -1, @base_plo_reu_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2635', @ord_fs7y2635, @prof_staff3, @t_fs7y2635),
(@var_plo_reu_l, 'IMPORT', 6, @base_plo_reu_l + 6, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập bổ sung nguồn hàng đa năm (PLO-REU-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_plo_reu_l, 'SALE', -2, @base_plo_reu_l + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2512', @ord_fs7y2512, @prof_staff3, @t_fs7y2512),
(@var_plo_reu_l, 'SALE', -2, @base_plo_reu_l + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2529', @ord_fs7y2529, @prof_staff3, @t_fs7y2529),
(@var_plo_reu_l, 'SALE', -1, @base_plo_reu_l + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2617', @ord_fs7y2617, @prof_staff3, @t_fs7y2617),
(@var_plo_reu_l, 'SALE', -1, @base_plo_reu_l + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2629', @ord_fs7y2629, @prof_staff3, @t_fs7y2629),
(@var_plo_kem_s, 'IMPORT', 4, @base_plo_kem_s + 4, 'Xưởng may Việt Tiến', 234000.00, 'Nhập bổ sung nguồn hàng đa năm (PLO-KEM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_plo_kem_s, 'SALE', -1, @base_plo_kem_s + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2406', @ord_fs7y2406, @prof_staff3, @t_fs7y2406),
(@var_plo_kem_s, 'SALE', -2, @base_plo_kem_s + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2603', @ord_fs7y2603, @prof_staff3, @t_fs7y2603),
(@var_plo_kem_s, 'SALE', -1, @base_plo_kem_s + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2637', @ord_fs7y2637, @prof_staff3, @t_fs7y2637),
(@var_plo_kem_m, 'IMPORT', 5, @base_plo_kem_m + 5, 'Xưởng may Việt Tiến', 234000.00, 'Nhập bổ sung nguồn hàng đa năm (PLO-KEM-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_plo_kem_m, 'SALE', -2, @base_plo_kem_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2504', @ord_fs7y2504, @prof_staff3, @t_fs7y2504),
(@var_plo_kem_m, 'SALE', -1, @base_plo_kem_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2519', @ord_fs7y2519, @prof_staff3, @t_fs7y2519),
(@var_plo_kem_m, 'SALE', -1, @base_plo_kem_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2607', @ord_fs7y2607, @prof_staff3, @t_fs7y2607),
(@var_plo_kem_m, 'SALE', -1, @base_plo_kem_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2624', @ord_fs7y2624, @prof_staff3, @t_fs7y2624),
(@var_dam_pas_s, 'IMPORT', 5, @base_dam_pas_s + 5, 'Xưởng thiết kế Lam Boutique', 567000.00, 'Nhập bổ sung nguồn hàng đa năm (DAM-PAS-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_dam_pas_s, 'SALE', -1, @base_dam_pas_s + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2418', @ord_fs7y2418, @prof_staff3, @t_fs7y2418),
(@var_dam_pas_s, 'SALE', -1, @base_dam_pas_s + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2507', @ord_fs7y2507, @prof_staff3, @t_fs7y2507),
(@var_dam_pas_s, 'SALE', -1, @base_dam_pas_s + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2527', @ord_fs7y2527, @prof_staff3, @t_fs7y2527),
(@var_dam_pas_s, 'SALE', -1, @base_dam_pas_s + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2605', @ord_fs7y2605, @prof_staff3, @t_fs7y2605),
(@var_dam_pas_s, 'SALE', -1, @base_dam_pas_s + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2639', @ord_fs7y2639, @prof_staff3, @t_fs7y2639),
(@var_dam_pas_m, 'IMPORT', 4, @base_dam_pas_m + 4, 'Xưởng thiết kế Lam Boutique', 567000.00, 'Nhập bổ sung nguồn hàng đa năm (DAM-PAS-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_dam_pas_m, 'SALE', -1, @base_dam_pas_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2409', @ord_fs7y2409, @prof_staff3, @t_fs7y2409),
(@var_dam_pas_m, 'SALE', -1, @base_dam_pas_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2522', @ord_fs7y2522, @prof_staff3, @t_fs7y2522),
(@var_dam_pas_m, 'SALE', -1, @base_dam_pas_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2611', @ord_fs7y2611, @prof_staff3, @t_fs7y2611),
(@var_dam_pas_m, 'SALE', -1, @base_dam_pas_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2636', @ord_fs7y2636, @prof_staff3, @t_fs7y2636),
(@var_dam_do_s, 'IMPORT', 4, @base_dam_do_s + 4, 'Xưởng thiết kế Lam Boutique', 983000.00, 'Nhập bổ sung nguồn hàng đa năm (DAM-DO-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_dam_do_s, 'SALE', -1, @base_dam_do_s + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2404', @ord_fs7y2404, @prof_staff3, @t_fs7y2404),
(@var_dam_do_s, 'SALE', -1, @base_dam_do_s + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2506', @ord_fs7y2506, @prof_staff3, @t_fs7y2506),
(@var_dam_do_s, 'SALE', -1, @base_dam_do_s + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2532', @ord_fs7y2532, @prof_staff3, @t_fs7y2532),
(@var_dam_do_s, 'SALE', -1, @base_dam_do_s + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2631', @ord_fs7y2631, @prof_staff3, @t_fs7y2631),
(@var_dam_do_m, 'IMPORT', 4, @base_dam_do_m + 4, 'Xưởng thiết kế Lam Boutique', 983000.00, 'Nhập bổ sung nguồn hàng đa năm (DAM-DO-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_dam_do_m, 'SALE', -1, @base_dam_do_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2518', @ord_fs7y2518, @prof_staff3, @t_fs7y2518),
(@var_dam_do_m, 'SALE', -1, @base_dam_do_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2601', @ord_fs7y2601, @prof_staff3, @t_fs7y2601),
(@var_dam_do_m, 'SALE', -1, @base_dam_do_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2623', @ord_fs7y2623, @prof_staff3, @t_fs7y2623),
(@var_dam_do_m, 'SALE', -1, @base_dam_do_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2633', @ord_fs7y2633, @prof_staff3, @t_fs7y2633),
(@var_sm_oxf_m, 'IMPORT', 8, @base_sm_oxf_m + 8, 'Xưởng may Nhà Bè', 281000.00, 'Nhập bổ sung nguồn hàng đa năm (SM-OXF-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_sm_oxf_m, 'SALE', -2, @base_sm_oxf_m + 6, NULL, NULL, 'Xuất kho theo đơn FS7Y2422', @ord_fs7y2422, @prof_staff3, @t_fs7y2422),
(@var_sm_oxf_m, 'SALE', -1, @base_sm_oxf_m + 5, NULL, NULL, 'Xuất kho theo đơn FS7Y2502', @ord_fs7y2502, @prof_staff3, @t_fs7y2502),
(@var_sm_oxf_m, 'SALE', -1, @base_sm_oxf_m + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2520', @ord_fs7y2520, @prof_staff3, @t_fs7y2520),
(@var_sm_oxf_m, 'SALE', -1, @base_sm_oxf_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2602', @ord_fs7y2602, @prof_staff3, @t_fs7y2602),
(@var_sm_oxf_m, 'SALE', -1, @base_sm_oxf_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2622', @ord_fs7y2622, @prof_staff3, @t_fs7y2622),
(@var_sm_oxf_m, 'SALE', -2, @base_sm_oxf_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2635', @ord_fs7y2635, @prof_staff3, @t_fs7y2635),
(@var_sm_oxf_l, 'IMPORT', 4, @base_sm_oxf_l + 4, 'Xưởng may Nhà Bè', 281000.00, 'Nhập bổ sung nguồn hàng đa năm (SM-OXF-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_sm_oxf_l, 'SALE', -1, @base_sm_oxf_l + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2416', @ord_fs7y2416, @prof_staff3, @t_fs7y2416),
(@var_sm_oxf_l, 'SALE', -2, @base_sm_oxf_l + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2515', @ord_fs7y2515, @prof_staff3, @t_fs7y2515),
(@var_sm_oxf_l, 'SALE', -1, @base_sm_oxf_l + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2626', @ord_fs7y2626, @prof_staff3, @t_fs7y2626),
(@var_qn_cul_s, 'IMPORT', 3, @base_qn_cul_s + 3, 'Xưởng may Bình Minh', 374000.00, 'Nhập bổ sung nguồn hàng đa năm (QN-CUL-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_qn_cul_s, 'SALE', -1, @base_qn_cul_s + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2521', @ord_fs7y2521, @prof_staff3, @t_fs7y2521),
(@var_qn_cul_s, 'SALE', -1, @base_qn_cul_s + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2615', @ord_fs7y2615, @prof_staff3, @t_fs7y2615),
(@var_qn_cul_s, 'SALE', -1, @base_qn_cul_s + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2630', @ord_fs7y2630, @prof_staff3, @t_fs7y2630),
(@var_qn_cul_m, 'IMPORT', 4, @base_qn_cul_m + 4, 'Xưởng may Bình Minh', 374000.00, 'Nhập bổ sung nguồn hàng đa năm (QN-CUL-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_qn_cul_m, 'SALE', -1, @base_qn_cul_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2411', @ord_fs7y2411, @prof_staff3, @t_fs7y2411),
(@var_qn_cul_m, 'SALE', -1, @base_qn_cul_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2508', @ord_fs7y2508, @prof_staff3, @t_fs7y2508),
(@var_qn_cul_m, 'SALE', -1, @base_qn_cul_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2607', @ord_fs7y2607, @prof_staff3, @t_fs7y2607),
(@var_qn_cul_m, 'SALE', -1, @base_qn_cul_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2625', @ord_fs7y2625, @prof_staff3, @t_fs7y2625),
(@var_qn_jog_m, 'IMPORT', 7, @base_qn_jog_m + 7, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập bổ sung nguồn hàng đa năm (QN-JOG-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_qn_jog_m, 'SALE', -1, @base_qn_jog_m + 6, NULL, NULL, 'Xuất kho theo đơn FS7Y2414', @ord_fs7y2414, @prof_staff3, @t_fs7y2414),
(@var_qn_jog_m, 'SALE', -1, @base_qn_jog_m + 5, NULL, NULL, 'Xuất kho theo đơn FS7Y2509', @ord_fs7y2509, @prof_staff3, @t_fs7y2509),
(@var_qn_jog_m, 'SALE', -2, @base_qn_jog_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2531', @ord_fs7y2531, @prof_staff3, @t_fs7y2531),
(@var_qn_jog_m, 'SALE', -2, @base_qn_jog_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2604', @ord_fs7y2604, @prof_staff3, @t_fs7y2604),
(@var_qn_jog_m, 'SALE', -1, @base_qn_jog_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2632', @ord_fs7y2632, @prof_staff3, @t_fs7y2632),
(@var_ak_blz_s, 'IMPORT', 4, @base_ak_blz_s + 4, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập bổ sung nguồn hàng đa năm (AK-BLZ-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_ak_blz_s, 'SALE', -1, @base_ak_blz_s + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2421', @ord_fs7y2421, @prof_staff3, @t_fs7y2421),
(@var_ak_blz_s, 'SALE', -1, @base_ak_blz_s + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2503', @ord_fs7y2503, @prof_staff3, @t_fs7y2503),
(@var_ak_blz_s, 'SALE', -1, @base_ak_blz_s + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2601', @ord_fs7y2601, @prof_staff3, @t_fs7y2601),
(@var_ak_blz_s, 'SALE', -1, @base_ak_blz_s + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2620', @ord_fs7y2620, @prof_staff3, @t_fs7y2620),
(@var_ak_blz_m, 'IMPORT', 6, @base_ak_blz_m + 6, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập bổ sung nguồn hàng đa năm (AK-BLZ-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_ak_blz_m, 'SALE', -1, @base_ak_blz_m + 5, NULL, NULL, 'Xuất kho theo đơn FS7Y2418', @ord_fs7y2418, @prof_staff3, @t_fs7y2418),
(@var_ak_blz_m, 'SALE', -1, @base_ak_blz_m + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2506', @ord_fs7y2506, @prof_staff3, @t_fs7y2506),
(@var_ak_blz_m, 'SALE', -1, @base_ak_blz_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2527', @ord_fs7y2527, @prof_staff3, @t_fs7y2527),
(@var_ak_blz_m, 'SALE', -1, @base_ak_blz_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2536', @ord_fs7y2536, @prof_staff3, @t_fs7y2536),
(@var_ak_blz_m, 'SALE', -1, @base_ak_blz_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2611', @ord_fs7y2611, @prof_staff3, @t_fs7y2611),
(@var_ak_blz_m, 'SALE', -1, @base_ak_blz_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2638', @ord_fs7y2638, @prof_staff3, @t_fs7y2638),
(@var_at_gym_m, 'IMPORT', 6, @base_at_gym_m + 6, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập bổ sung nguồn hàng đa năm (AT-GYM-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_at_gym_m, 'SALE', -2, @base_at_gym_m + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2509', @ord_fs7y2509, @prof_staff3, @t_fs7y2509),
(@var_at_gym_m, 'SALE', -2, @base_at_gym_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2535', @ord_fs7y2535, @prof_staff3, @t_fs7y2535),
(@var_at_gym_m, 'SALE', -2, @base_at_gym_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2632', @ord_fs7y2632, @prof_staff3, @t_fs7y2632),
(@var_at_gym_l, 'IMPORT', 7, @base_at_gym_l + 7, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập bổ sung nguồn hàng đa năm (AT-GYM-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_at_gym_l, 'SALE', -2, @base_at_gym_l + 5, NULL, NULL, 'Xuất kho theo đơn FS7Y2417', @ord_fs7y2417, @prof_staff3, @t_fs7y2417),
(@var_at_gym_l, 'SALE', -2, @base_at_gym_l + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2523', @ord_fs7y2523, @prof_staff3, @t_fs7y2523),
(@var_at_gym_l, 'SALE', -2, @base_at_gym_l + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2609', @ord_fs7y2609, @prof_staff3, @t_fs7y2609),
(@var_at_gym_l, 'SALE', -1, @base_at_gym_l + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2621', @ord_fs7y2621, @prof_staff3, @t_fs7y2621),
(@var_al_gil_s, 'IMPORT', 5, @base_al_gil_s + 5, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập bổ sung nguồn hàng đa năm (AL-GIL-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_al_gil_s, 'SALE', -1, @base_al_gil_s + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2508', @ord_fs7y2508, @prof_staff3, @t_fs7y2508),
(@var_al_gil_s, 'SALE', -1, @base_al_gil_s + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2524', @ord_fs7y2524, @prof_staff3, @t_fs7y2524),
(@var_al_gil_s, 'SALE', -1, @base_al_gil_s + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2605', @ord_fs7y2605, @prof_staff3, @t_fs7y2605),
(@var_al_gil_s, 'SALE', -1, @base_al_gil_s + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2624', @ord_fs7y2624, @prof_staff3, @t_fs7y2624),
(@var_al_gil_s, 'SALE', -1, @base_al_gil_s + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2637', @ord_fs7y2637, @prof_staff3, @t_fs7y2637),
(@var_al_gil_m, 'IMPORT', 4, @base_al_gil_m + 4, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập bổ sung nguồn hàng đa năm (AL-GIL-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_al_gil_m, 'SALE', -1, @base_al_gil_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2420', @ord_fs7y2420, @prof_staff3, @t_fs7y2420),
(@var_al_gil_m, 'SALE', -1, @base_al_gil_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2501', @ord_fs7y2501, @prof_staff3, @t_fs7y2501),
(@var_al_gil_m, 'SALE', -1, @base_al_gil_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2612', @ord_fs7y2612, @prof_staff3, @t_fs7y2612),
(@var_al_gil_m, 'SALE', -1, @base_al_gil_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2628', @ord_fs7y2628, @prof_staff3, @t_fs7y2628),
(@var_vs_den_m, 'IMPORT', 5, @base_vs_den_m + 5, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập bổ sung nguồn hàng đa năm (VS-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_vs_den_m, 'SALE', -1, @base_vs_den_m + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2407', @ord_fs7y2407, @prof_staff3, @t_fs7y2407),
(@var_vs_den_m, 'SALE', -1, @base_vs_den_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2419', @ord_fs7y2419, @prof_staff3, @t_fs7y2419),
(@var_vs_den_m, 'SALE', -1, @base_vs_den_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2502', @ord_fs7y2502, @prof_staff3, @t_fs7y2502),
(@var_vs_den_m, 'SALE', -1, @base_vs_den_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2602', @ord_fs7y2602, @prof_staff3, @t_fs7y2602),
(@var_vs_den_m, 'SALE', -1, @base_vs_den_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2634', @ord_fs7y2634, @prof_staff3, @t_fs7y2634),
(@var_vs_xam_l, 'IMPORT', 5, @base_vs_xam_l + 5, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập bổ sung nguồn hàng đa năm (VS-XAM-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_vs_xam_l, 'SALE', -1, @base_vs_xam_l + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2510', @ord_fs7y2510, @prof_staff3, @t_fs7y2510),
(@var_vs_xam_l, 'SALE', -1, @base_vs_xam_l + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2533', @ord_fs7y2533, @prof_staff3, @t_fs7y2533),
(@var_vs_xam_l, 'SALE', -1, @base_vs_xam_l + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2606', @ord_fs7y2606, @prof_staff3, @t_fs7y2606),
(@var_vs_xam_l, 'SALE', -1, @base_vs_xam_l + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2622', @ord_fs7y2622, @prof_staff3, @t_fs7y2622),
(@var_vs_xam_l, 'SALE', -1, @base_vs_xam_l + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2638', @ord_fs7y2638, @prof_staff3, @t_fs7y2638),
(@var_cd_kem_m, 'IMPORT', 6, @base_cd_kem_m + 6, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập bổ sung nguồn hàng đa năm (CD-KEM-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_cd_kem_m, 'SALE', -1, @base_cd_kem_m + 5, NULL, NULL, 'Xuất kho theo đơn FS7Y2402', @ord_fs7y2402, @prof_staff3, @t_fs7y2402),
(@var_cd_kem_m, 'SALE', -1, @base_cd_kem_m + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2512', @ord_fs7y2512, @prof_staff3, @t_fs7y2512),
(@var_cd_kem_m, 'SALE', -1, @base_cd_kem_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2524', @ord_fs7y2524, @prof_staff3, @t_fs7y2524),
(@var_cd_kem_m, 'SALE', -1, @base_cd_kem_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2612', @ord_fs7y2612, @prof_staff3, @t_fs7y2612),
(@var_cd_kem_m, 'SALE', -1, @base_cd_kem_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2626', @ord_fs7y2626, @prof_staff3, @t_fs7y2626),
(@var_cd_kem_m, 'SALE', -1, @base_cd_kem_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2629', @ord_fs7y2629, @prof_staff3, @t_fs7y2629),
(@var_cd_den_l, 'IMPORT', 6, @base_cd_den_l + 6, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập bổ sung nguồn hàng đa năm (CD-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_cd_den_l, 'SALE', -1, @base_cd_den_l + 5, NULL, NULL, 'Xuất kho theo đơn FS7Y2416', @ord_fs7y2416, @prof_staff3, @t_fs7y2416),
(@var_cd_den_l, 'SALE', -1, @base_cd_den_l + 4, NULL, NULL, 'Xuất kho theo đơn FS7Y2501', @ord_fs7y2501, @prof_staff3, @t_fs7y2501),
(@var_cd_den_l, 'SALE', -1, @base_cd_den_l + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2517', @ord_fs7y2517, @prof_staff3, @t_fs7y2517),
(@var_cd_den_l, 'SALE', -1, @base_cd_den_l + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2606', @ord_fs7y2606, @prof_staff3, @t_fs7y2606),
(@var_cd_den_l, 'SALE', -1, @base_cd_den_l + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2616', @ord_fs7y2616, @prof_staff3, @t_fs7y2616),
(@var_cd_den_l, 'SALE', -1, @base_cd_den_l + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2640', @ord_fs7y2640, @prof_staff3, @t_fs7y2640),
(@var_tt_gym_s, 'IMPORT', 4, @base_tt_gym_s + 4, 'Xưởng đồ thể thao ActiveVN', 307000.00, 'Nhập bổ sung nguồn hàng đa năm (TT-GYM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_tt_gym_s, 'SALE', -1, @base_tt_gym_s + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2513', @ord_fs7y2513, @prof_staff3, @t_fs7y2513),
(@var_tt_gym_s, 'SALE', -1, @base_tt_gym_s + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2609', @ord_fs7y2609, @prof_staff3, @t_fs7y2609),
(@var_tt_gym_s, 'SALE', -1, @base_tt_gym_s + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2625', @ord_fs7y2625, @prof_staff3, @t_fs7y2625),
(@var_tt_gym_s, 'SALE', -1, @base_tt_gym_s + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2640', @ord_fs7y2640, @prof_staff3, @t_fs7y2640),
(@var_sm_linen_tr_m, 'IMPORT', 3, @base_sm_linen_tr_m + 3, 'Xưởng may Nhà Bè', 359000.00, 'Nhập bổ sung nguồn hàng đa năm (SM-LINEN-TR-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_sm_linen_tr_m, 'SALE', -1, @base_sm_linen_tr_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2407', @ord_fs7y2407, @prof_staff3, @t_fs7y2407),
(@var_sm_linen_tr_m, 'SALE', -1, @base_sm_linen_tr_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2528', @ord_fs7y2528, @prof_staff3, @t_fs7y2528),
(@var_sm_linen_tr_m, 'SALE', -1, @base_sm_linen_tr_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2616', @ord_fs7y2616, @prof_staff3, @t_fs7y2616),
(@var_at_basic_tr_l, 'IMPORT', 5, @base_at_basic_tr_l + 5, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập bổ sung nguồn hàng đa năm (AT-BASIC-TR-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_at_basic_tr_l, 'SALE', -2, @base_at_basic_tr_l + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2514', @ord_fs7y2514, @prof_staff3, @t_fs7y2514),
(@var_at_basic_tr_l, 'SALE', -3, @base_at_basic_tr_l + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2618', @ord_fs7y2618, @prof_staff3, @t_fs7y2618),
(@var_cv_xeply_m, 'IMPORT', 4, @base_cv_xeply_m + 4, 'Xưởng thiết kế Lam Boutique', 411000.00, 'Nhập bổ sung nguồn hàng đa năm (CV-XEPLY-KEM-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_cv_xeply_m, 'SALE', -1, @base_cv_xeply_m + 3, NULL, NULL, 'Xuất kho theo đơn FS7Y2415', @ord_fs7y2415, @prof_staff3, @t_fs7y2415),
(@var_cv_xeply_m, 'SALE', -1, @base_cv_xeply_m + 2, NULL, NULL, 'Xuất kho theo đơn FS7Y2519', @ord_fs7y2519, @prof_staff3, @t_fs7y2519),
(@var_cv_xeply_m, 'SALE', -1, @base_cv_xeply_m + 1, NULL, NULL, 'Xuất kho theo đơn FS7Y2620', @ord_fs7y2620, @prof_staff3, @t_fs7y2620),
(@var_cv_xeply_m, 'SALE', -1, @base_cv_xeply_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2636', @ord_fs7y2636, @prof_staff3, @t_fs7y2636),
(@var_dam_lua_be_m, 'IMPORT', 1, @base_dam_lua_be_m + 1, 'Xưởng thiết kế Lam Boutique', 827000.00, 'Nhập bổ sung nguồn hàng đa năm (DAM-LUA-BE-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_dam_lua_be_m, 'SALE', -1, @base_dam_lua_be_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2421', @ord_fs7y2421, @prof_staff3, @t_fs7y2421),
(@var_trench_camel_m, 'IMPORT', 1, @base_trench_camel_m + 1, 'Xưởng veston Hoàng Gia', 1295000.00, 'Nhập bổ sung nguồn hàng đa năm (TRENCH-CAMEL-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_trench_camel_m, 'SALE', -1, @base_trench_camel_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2424', @ord_fs7y2424, @prof_staff3, @t_fs7y2424),
(@var_blz_nam_xam_m, 'IMPORT', 1, @base_blz_nam_xam_m + 1, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập bổ sung nguồn hàng đa năm (BLAZER-NAM-XAM-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_blz_nam_xam_m, 'SALE', -1, @base_blz_nam_xam_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2520', @ord_fs7y2520, @prof_staff3, @t_fs7y2520),
(@var_qj_ongrong_m, 'IMPORT', 1, @base_qj_ongrong_m + 1, 'Xưởng may Bình Minh', 442000.00, 'Nhập bổ sung nguồn hàng đa năm (QJ-ONGRONG-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_qj_ongrong_m, 'SALE', -1, @base_qj_ongrong_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2628', @ord_fs7y2628, @prof_staff3, @t_fs7y2628),
(@var_ak_denim_l, 'IMPORT', 1, @base_ak_denim_l + 1, 'Xưởng may Bình Minh', 723000.00, 'Nhập bổ sung nguồn hàng đa năm (AK-DENIM-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_ak_denim_l, 'SALE', -1, @base_ak_denim_l + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2528', @ord_fs7y2528, @prof_staff3, @t_fs7y2528),
(@var_al_colo_m, 'IMPORT', 1, @base_al_colo_m + 1, 'Xưởng len Đà Lạt Knit', 494000.00, 'Nhập bổ sung nguồn hàng đa năm (AL-COLO-NAU-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_al_colo_m, 'SALE', -1, @base_al_colo_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2532', @ord_fs7y2532, @prof_staff3, @t_fs7y2532),
(@var_qs_kaki_m, 'IMPORT', 1, @base_qs_kaki_m + 1, 'Xưởng may Việt Tiến', 255000.00, 'Nhập bổ sung nguồn hàng đa năm (QS-KAKI-REU-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_qs_kaki_m, 'SALE', -1, @base_qs_kaki_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2610', @ord_fs7y2610, @prof_staff3, @t_fs7y2610),
(@var_dam_hoanhi_m, 'IMPORT', 1, @base_dam_hoanhi_m + 1, 'Xưởng thiết kế Lam Boutique', 515000.00, 'Nhập bổ sung nguồn hàng đa năm (DAM-HOANHI-HP-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_dam_hoanhi_m, 'SALE', -1, @base_dam_hoanhi_m + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2525', @ord_fs7y2525, @prof_staff3, @t_fs7y2525),
(@var_sm_nam_ks_l, 'IMPORT', 1, @base_sm_nam_ks_l + 1, 'Xưởng may Nhà Bè', 390000.00, 'Nhập bổ sung nguồn hàng đa năm (SM-NAM-KS-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_sm_nam_ks_l, 'SALE', -1, @base_sm_nam_ks_l + 0, NULL, NULL, 'Xuất kho theo đơn FS7Y2534', @ord_fs7y2534, @prof_staff3, @t_fs7y2534),
(@var_nv_dam_lua_be_xl, 'IMPORT', 6, 6, 'Xưởng thiết kế Lam Boutique', 827000.00, 'Nhập kho biến thể mới (DAM-LUA-BE-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_lua_vc_s, 'IMPORT', 10, 10, 'Xưởng thiết kế Lam Boutique', 827000.00, 'Nhập kho biến thể mới (DAM-LUA-VC-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_lua_vc_m, 'IMPORT', 15, 15, 'Xưởng thiết kế Lam Boutique', 827000.00, 'Nhập kho biến thể mới (DAM-LUA-VC-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_lua_vc_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS7Y2614', @ord_fs7y2614, @prof_staff3, @t_fs7y2614),
(@var_nv_dam_lua_vc_l, 'IMPORT', 9, 9, 'Xưởng thiết kế Lam Boutique', 827000.00, 'Nhập kho biến thể mới (DAM-LUA-VC-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_lua_den_s, 'IMPORT', 11, 11, 'Xưởng thiết kế Lam Boutique', 827000.00, 'Nhập kho biến thể mới (DAM-LUA-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_lua_den_m, 'IMPORT', 15, 15, 'Xưởng thiết kế Lam Boutique', 827000.00, 'Nhập kho biến thể mới (DAM-LUA-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_lua_den_l, 'IMPORT', 7, 7, 'Xưởng thiết kế Lam Boutique', 827000.00, 'Nhập kho biến thể mới (DAM-LUA-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_linen_tr_xl, 'IMPORT', 12, 12, 'Xưởng may Nhà Bè', 359000.00, 'Nhập kho biến thể mới (SM-LINEN-TR-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_linen_xn_s, 'IMPORT', 14, 14, 'Xưởng may Nhà Bè', 359000.00, 'Nhập kho biến thể mới (SM-LINEN-XN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_linen_xn_l, 'IMPORT', 16, 16, 'Xưởng may Nhà Bè', 359000.00, 'Nhập kho biến thể mới (SM-LINEN-XN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_linen_xn_xl, 'IMPORT', 8, 8, 'Xưởng may Nhà Bè', 359000.00, 'Nhập kho biến thể mới (SM-LINEN-XN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_linen_kb_s, 'IMPORT', 15, 15, 'Xưởng may Nhà Bè', 359000.00, 'Nhập kho biến thể mới (SM-LINEN-KB-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_linen_kb_m, 'IMPORT', 21, 21, 'Xưởng may Nhà Bè', 359000.00, 'Nhập kho biến thể mới (SM-LINEN-KB-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_linen_kb_m, 'SALE', -1, 20, NULL, NULL, 'Xuất kho theo đơn FS7Y2510', @ord_fs7y2510, @prof_staff3, @t_fs7y2510),
(@var_nv_sm_linen_kb_l, 'IMPORT', 14, 14, 'Xưởng may Nhà Bè', 359000.00, 'Nhập kho biến thể mới (SM-LINEN-KB-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_linen_kb_xl, 'IMPORT', 9, 9, 'Xưởng may Nhà Bè', 359000.00, 'Nhập kho biến thể mới (SM-LINEN-KB-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qt_ongdung_d_xl, 'IMPORT', 7, 7, 'Xưởng may Bình Minh', 463000.00, 'Nhập kho biến thể mới (QT-ONGDUNG-D-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qt_ongdung_xk_s, 'IMPORT', 12, 12, 'Xưởng may Bình Minh', 463000.00, 'Nhập kho biến thể mới (QT-ONGDUNG-XK-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qt_ongdung_xk_m, 'IMPORT', 16, 16, 'Xưởng may Bình Minh', 463000.00, 'Nhập kho biến thể mới (QT-ONGDUNG-XK-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qt_ongdung_xk_m, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS7Y2619', @ord_fs7y2619, @prof_staff3, @t_fs7y2619),
(@var_nv_qt_ongdung_xk_l, 'IMPORT', 10, 10, 'Xưởng may Bình Minh', 463000.00, 'Nhập kho biến thể mới (QT-ONGDUNG-XK-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qt_ongdung_bn_s, 'IMPORT', 11, 11, 'Xưởng may Bình Minh', 463000.00, 'Nhập kho biến thể mới (QT-ONGDUNG-BN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qt_ongdung_bn_m, 'IMPORT', 14, 14, 'Xưởng may Bình Minh', 463000.00, 'Nhập kho biến thể mới (QT-ONGDUNG-BN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qt_ongdung_bn_l, 'IMPORT', 8, 8, 'Xưởng may Bình Minh', 463000.00, 'Nhập kho biến thể mới (QT-ONGDUNG-BN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_trench_camel_xl, 'IMPORT', 4, 4, 'Xưởng veston Hoàng Gia', 1295000.00, 'Nhập kho biến thể mới (TRENCH-CAMEL-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_trench_den_s, 'IMPORT', 6, 6, 'Xưởng veston Hoàng Gia', 1295000.00, 'Nhập kho biến thể mới (TRENCH-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_trench_den_m, 'IMPORT', 10, 10, 'Xưởng veston Hoàng Gia', 1295000.00, 'Nhập kho biến thể mới (TRENCH-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_trench_den_m, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS7Y2627', @ord_fs7y2627, @prof_staff3, @t_fs7y2627),
(@var_nv_trench_den_l, 'IMPORT', 5, 5, 'Xưởng veston Hoàng Gia', 1295000.00, 'Nhập kho biến thể mới (TRENCH-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_trench_be_s, 'IMPORT', 7, 7, 'Xưởng veston Hoàng Gia', 1295000.00, 'Nhập kho biến thể mới (TRENCH-BE-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_trench_be_m, 'IMPORT', 10, 10, 'Xưởng veston Hoàng Gia', 1295000.00, 'Nhập kho biến thể mới (TRENCH-BE-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_trench_be_l, 'IMPORT', 6, 6, 'Xưởng veston Hoàng Gia', 1295000.00, 'Nhập kho biến thể mới (TRENCH-BE-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_blazer_nam_xam_s, 'IMPORT', 6, 6, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập kho biến thể mới (BLAZER-NAM-XAM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_blazer_nam_xam_xxl, 'IMPORT', 3, 3, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập kho biến thể mới (BLAZER-NAM-XAM-XXL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_blazer_nam_nv_m, 'IMPORT', 8, 8, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập kho biến thể mới (BLAZER-NAM-NV-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_blazer_nam_nv_l, 'IMPORT', 10, 10, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập kho biến thể mới (BLAZER-NAM-NV-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_blazer_nam_nv_xl, 'IMPORT', 5, 5, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập kho biến thể mới (BLAZER-NAM-NV-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_blazer_nam_den_m, 'IMPORT', 9, 9, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập kho biến thể mới (BLAZER-NAM-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_blazer_nam_den_l, 'IMPORT', 11, 11, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập kho biến thể mới (BLAZER-NAM-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_blazer_nam_den_xl, 'IMPORT', 6, 6, 'Xưởng veston Hoàng Gia', 1222000.00, 'Nhập kho biến thể mới (BLAZER-NAM-DEN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_xeply_den_s, 'IMPORT', 12, 12, 'Xưởng thiết kế Lam Boutique', 411000.00, 'Nhập kho biến thể mới (CV-XEPLY-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_xeply_den_m, 'IMPORT', 17, 17, 'Xưởng thiết kế Lam Boutique', 411000.00, 'Nhập kho biến thể mới (CV-XEPLY-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_xeply_den_m, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS7Y2424', @ord_fs7y2424, @prof_staff3, @t_fs7y2424),
(@var_nv_cv_xeply_den_l, 'IMPORT', 10, 10, 'Xưởng thiết kế Lam Boutique', 411000.00, 'Nhập kho biến thể mới (CV-XEPLY-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_xeply_nau_s, 'IMPORT', 10, 10, 'Xưởng thiết kế Lam Boutique', 411000.00, 'Nhập kho biến thể mới (CV-XEPLY-NAU-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_xeply_nau_m, 'IMPORT', 14, 14, 'Xưởng thiết kế Lam Boutique', 411000.00, 'Nhập kho biến thể mới (CV-XEPLY-NAU-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_xeply_nau_l, 'IMPORT', 8, 8, 'Xưởng thiết kế Lam Boutique', 411000.00, 'Nhập kho biến thể mới (CV-XEPLY-NAU-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_chua_xn_s, 'IMPORT', 10, 10, 'Xưởng may Bình Minh', 307000.00, 'Nhập kho biến thể mới (CV-CHUA-XN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_chua_xn_m, 'IMPORT', 14, 14, 'Xưởng may Bình Minh', 307000.00, 'Nhập kho biến thể mới (CV-CHUA-XN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_chua_xn_l, 'IMPORT', 9, 9, 'Xưởng may Bình Minh', 307000.00, 'Nhập kho biến thể mới (CV-CHUA-XN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_chua_den_s, 'IMPORT', 9, 9, 'Xưởng may Bình Minh', 307000.00, 'Nhập kho biến thể mới (CV-CHUA-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_chua_den_m, 'IMPORT', 13, 13, 'Xưởng may Bình Minh', 307000.00, 'Nhập kho biến thể mới (CV-CHUA-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cv_chua_den_m, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS7Y2610', @ord_fs7y2610, @prof_staff3, @t_fs7y2610),
(@var_nv_cv_chua_den_l, 'IMPORT', 7, 7, 'Xưởng may Bình Minh', 307000.00, 'Nhập kho biến thể mới (CV-CHUA-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_d_s, 'IMPORT', 22, 22, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-D-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_d_l, 'IMPORT', 29, 29, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-D-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_d_l, 'SALE', -1, 28, NULL, NULL, 'Xuất kho theo đơn FS7Y2401', @ord_fs7y2401, @prof_staff3, @t_fs7y2401),
(@var_nv_at_basic_d_xl, 'IMPORT', 16, 16, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-D-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_xt_s, 'IMPORT', 18, 18, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-XT-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_xt_m, 'IMPORT', 24, 24, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-XT-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_xt_l, 'IMPORT', 20, 20, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-XT-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_xt_xl, 'IMPORT', 12, 12, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-XT-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_nv_m, 'IMPORT', 20, 20, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-NV-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_nv_l, 'IMPORT', 18, 18, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-NV-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_basic_nv_xl, 'IMPORT', 10, 10, 'Xưởng dệt may Phong Phú', 151000.00, 'Nhập kho biến thể mới (AT-BASIC-NV-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_over_tr_s, 'IMPORT', 14, 14, 'Xưởng dệt may Phong Phú', 171000.00, 'Nhập kho biến thể mới (AT-OVER-TR-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_over_tr_m, 'IMPORT', 21, 21, 'Xưởng dệt may Phong Phú', 171000.00, 'Nhập kho biến thể mới (AT-OVER-TR-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_over_tr_m, 'SALE', -1, 20, NULL, NULL, 'Xuất kho theo đơn FS7Y2615', @ord_fs7y2615, @prof_staff3, @t_fs7y2615),
(@var_nv_at_over_tr_l, 'IMPORT', 22, 22, 'Xưởng dệt may Phong Phú', 171000.00, 'Nhập kho biến thể mới (AT-OVER-TR-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_over_tr_xl, 'IMPORT', 12, 12, 'Xưởng dệt may Phong Phú', 171000.00, 'Nhập kho biến thể mới (AT-OVER-TR-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_over_nau_m, 'IMPORT', 16, 16, 'Xưởng dệt may Phong Phú', 171000.00, 'Nhập kho biến thể mới (AT-OVER-NAU-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_over_nau_l, 'IMPORT', 18, 18, 'Xưởng dệt may Phong Phú', 171000.00, 'Nhập kho biến thể mới (AT-OVER-NAU-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_over_nau_xl, 'IMPORT', 9, 9, 'Xưởng dệt may Phong Phú', 171000.00, 'Nhập kho biến thể mới (AT-OVER-NAU-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_colo_kem_s, 'IMPORT', 10, 10, 'Xưởng len Đà Lạt Knit', 494000.00, 'Nhập kho biến thể mới (AL-COLO-KEM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_colo_kem_m, 'IMPORT', 14, 14, 'Xưởng len Đà Lạt Knit', 494000.00, 'Nhập kho biến thể mới (AL-COLO-KEM-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_colo_kem_l, 'IMPORT', 9, 9, 'Xưởng len Đà Lạt Knit', 494000.00, 'Nhập kho biến thể mới (AL-COLO-KEM-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_colo_den_s, 'IMPORT', 11, 11, 'Xưởng len Đà Lạt Knit', 494000.00, 'Nhập kho biến thể mới (AL-COLO-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_colo_den_m, 'IMPORT', 15, 15, 'Xưởng len Đà Lạt Knit', 494000.00, 'Nhập kho biến thể mới (AL-COLO-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_colo_den_l, 'IMPORT', 10, 10, 'Xưởng len Đà Lạt Knit', 494000.00, 'Nhập kho biến thể mới (AL-COLO-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qj_ongrong_xl, 'IMPORT', 8, 8, 'Xưởng may Bình Minh', 442000.00, 'Nhập kho biến thể mới (QJ-ONGRONG-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qj_ongrong_xn_s, 'IMPORT', 11, 11, 'Xưởng may Bình Minh', 442000.00, 'Nhập kho biến thể mới (QJ-ONGRONG-XN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qj_ongrong_xn_m, 'IMPORT', 15, 15, 'Xưởng may Bình Minh', 442000.00, 'Nhập kho biến thể mới (QJ-ONGRONG-XN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qj_ongrong_xn_l, 'IMPORT', 10, 10, 'Xưởng may Bình Minh', 442000.00, 'Nhập kho biến thể mới (QJ-ONGRONG-XN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qj_ongrong_den_s, 'IMPORT', 9, 9, 'Xưởng may Bình Minh', 442000.00, 'Nhập kho biến thể mới (QJ-ONGRONG-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qj_ongrong_den_m, 'IMPORT', 15, 15, 'Xưởng may Bình Minh', 442000.00, 'Nhập kho biến thể mới (QJ-ONGRONG-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qj_ongrong_den_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS7Y2517', @ord_fs7y2517, @prof_staff3, @t_fs7y2517),
(@var_nv_qj_ongrong_den_l, 'IMPORT', 9, 9, 'Xưởng may Bình Minh', 442000.00, 'Nhập kho biến thể mới (QJ-ONGRONG-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qs_kaki_reu_s, 'IMPORT', 10, 10, 'Xưởng may Việt Tiến', 255000.00, 'Nhập kho biến thể mới (QS-KAKI-REU-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qs_kaki_be_m, 'IMPORT', 16, 16, 'Xưởng may Việt Tiến', 255000.00, 'Nhập kho biến thể mới (QS-KAKI-BE-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qs_kaki_be_l, 'IMPORT', 18, 18, 'Xưởng may Việt Tiến', 255000.00, 'Nhập kho biến thể mới (QS-KAKI-BE-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qs_kaki_be_xl, 'IMPORT', 10, 10, 'Xưởng may Việt Tiến', 255000.00, 'Nhập kho biến thể mới (QS-KAKI-BE-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qs_kaki_den_m, 'IMPORT', 14, 14, 'Xưởng may Việt Tiến', 255000.00, 'Nhập kho biến thể mới (QS-KAKI-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qs_kaki_den_l, 'IMPORT', 15, 15, 'Xưởng may Việt Tiến', 255000.00, 'Nhập kho biến thể mới (QS-KAKI-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qs_kaki_den_xl, 'IMPORT', 8, 8, 'Xưởng may Việt Tiến', 255000.00, 'Nhập kho biến thể mới (QS-KAKI-DEN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_hoanhi_vk_s, 'IMPORT', 9, 9, 'Xưởng thiết kế Lam Boutique', 515000.00, 'Nhập kho biến thể mới (DAM-HOANHI-VK-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_hoanhi_vk_m, 'IMPORT', 12, 12, 'Xưởng thiết kế Lam Boutique', 515000.00, 'Nhập kho biến thể mới (DAM-HOANHI-VK-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_hoanhi_vk_l, 'IMPORT', 7, 7, 'Xưởng thiết kế Lam Boutique', 515000.00, 'Nhập kho biến thể mới (DAM-HOANHI-VK-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_hoanhi_xb_s, 'IMPORT', 8, 8, 'Xưởng thiết kế Lam Boutique', 515000.00, 'Nhập kho biến thể mới (DAM-HOANHI-XB-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_hoanhi_xb_m, 'IMPORT', 11, 11, 'Xưởng thiết kế Lam Boutique', 515000.00, 'Nhập kho biến thể mới (DAM-HOANHI-XB-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_denim_s, 'IMPORT', 8, 8, 'Xưởng may Bình Minh', 723000.00, 'Nhập kho biến thể mới (AK-DENIM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_denim_den_s, 'IMPORT', 7, 7, 'Xưởng may Bình Minh', 723000.00, 'Nhập kho biến thể mới (AK-DENIM-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_denim_den_m, 'IMPORT', 11, 11, 'Xưởng may Bình Minh', 723000.00, 'Nhập kho biến thể mới (AK-DENIM-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_denim_den_l, 'IMPORT', 9, 9, 'Xưởng may Bình Minh', 723000.00, 'Nhập kho biến thể mới (AK-DENIM-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_denim_tk_m, 'IMPORT', 8, 8, 'Xưởng may Bình Minh', 723000.00, 'Nhập kho biến thể mới (AK-DENIM-TK-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_denim_tk_l, 'IMPORT', 6, 6, 'Xưởng may Bình Minh', 723000.00, 'Nhập kho biến thể mới (AK-DENIM-TK-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_cardi_xam_s, 'IMPORT', 6, 6, 'Xưởng len Đà Lạt Knit', 463000.00, 'Nhập kho biến thể mới (AL-CARDI-XAM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_cardi_xam_xl, 'IMPORT', 4, 4, 'Xưởng len Đà Lạt Knit', 463000.00, 'Nhập kho biến thể mới (AL-CARDI-XAM-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_nam_ks_s, 'IMPORT', 10, 10, 'Xưởng may Nhà Bè', 390000.00, 'Nhập kho biến thể mới (SM-NAM-KS-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_nam_ks_xxl, 'IMPORT', 5, 5, 'Xưởng may Nhà Bè', 390000.00, 'Nhập kho biến thể mới (SM-NAM-KS-XXL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_nam_tsx_m, 'IMPORT', 14, 14, 'Xưởng may Nhà Bè', 390000.00, 'Nhập kho biến thể mới (SM-NAM-TSX-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_nam_tsx_l, 'IMPORT', 16, 16, 'Xưởng may Nhà Bè', 390000.00, 'Nhập kho biến thể mới (SM-NAM-TSX-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_nam_tsx_xl, 'IMPORT', 9, 9, 'Xưởng may Nhà Bè', 390000.00, 'Nhập kho biến thể mới (SM-NAM-TSX-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_reu_s, 'IMPORT', 12, 12, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập kho biến thể mới (PLO-REU-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_tr_m, 'IMPORT', 22, 22, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập kho biến thể mới (PLO-TR-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_tr_m, 'SALE', -2, 20, NULL, NULL, 'Xuất kho theo đơn FS7Y2516', @ord_fs7y2516, @prof_staff3, @t_fs7y2516),
(@var_nv_plo_tr_l, 'IMPORT', 18, 18, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập kho biến thể mới (PLO-TR-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_tr_xl, 'IMPORT', 10, 10, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập kho biến thể mới (PLO-TR-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_den_m, 'IMPORT', 22, 22, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập kho biến thể mới (PLO-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_den_l, 'IMPORT', 18, 18, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập kho biến thể mới (PLO-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_den_l, 'SALE', -2, 16, NULL, NULL, 'Xuất kho theo đơn FS7Y2414', @ord_fs7y2414, @prof_staff3, @t_fs7y2414),
(@var_nv_plo_den_xl, 'IMPORT', 9, 9, 'Xưởng dệt kim Hòa Thọ', 218000.00, 'Nhập kho biến thể mới (PLO-DEN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_kem_l, 'IMPORT', 14, 14, 'Xưởng may Việt Tiến', 234000.00, 'Nhập kho biến thể mới (PLO-KEM-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_kem_xl, 'IMPORT', 6, 6, 'Xưởng may Việt Tiến', 234000.00, 'Nhập kho biến thể mới (PLO-KEM-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_xpa_s, 'IMPORT', 15, 15, 'Xưởng may Việt Tiến', 234000.00, 'Nhập kho biến thể mới (PLO-XPA-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_xpa_m, 'IMPORT', 19, 19, 'Xưởng may Việt Tiến', 234000.00, 'Nhập kho biến thể mới (PLO-XPA-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_xpa_m, 'SALE', -1, 18, NULL, NULL, 'Xuất kho theo đơn FS7Y2411', @ord_fs7y2411, @prof_staff3, @t_fs7y2411),
(@var_nv_plo_xpa_l, 'IMPORT', 10, 10, 'Xưởng may Việt Tiến', 234000.00, 'Nhập kho biến thể mới (PLO-XPA-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_dpt_s, 'IMPORT', 14, 14, 'Xưởng may Việt Tiến', 234000.00, 'Nhập kho biến thể mới (PLO-DPT-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_dpt_s, 'SALE', -2, 12, NULL, NULL, 'Xuất kho theo đơn FS7Y2511', @ord_fs7y2511, @prof_staff3, @t_fs7y2511),
(@var_nv_plo_dpt_m, 'IMPORT', 16, 16, 'Xưởng may Việt Tiến', 234000.00, 'Nhập kho biến thể mới (PLO-DPT-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_plo_dpt_l, 'IMPORT', 9, 9, 'Xưởng may Việt Tiến', 234000.00, 'Nhập kho biến thể mới (PLO-DPT-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_mint_s, 'IMPORT', 11, 11, 'Xưởng thiết kế Lam Boutique', 567000.00, 'Nhập kho biến thể mới (DAM-MINT-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_mint_s, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS7Y2403', @ord_fs7y2403, @prof_staff3, @t_fs7y2403),
(@var_nv_dam_mint_m, 'IMPORT', 14, 14, 'Xưởng thiết kế Lam Boutique', 567000.00, 'Nhập kho biến thể mới (DAM-MINT-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_mint_l, 'IMPORT', 8, 8, 'Xưởng thiết kế Lam Boutique', 567000.00, 'Nhập kho biến thể mới (DAM-MINT-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_kems_s, 'IMPORT', 11, 11, 'Xưởng thiết kế Lam Boutique', 567000.00, 'Nhập kho biến thể mới (DAM-KEMS-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_kems_m, 'IMPORT', 16, 16, 'Xưởng thiết kế Lam Boutique', 567000.00, 'Nhập kho biến thể mới (DAM-KEMS-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_kems_m, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS7Y2505', @ord_fs7y2505, @prof_staff3, @t_fs7y2505),
(@var_nv_dam_kems_l, 'IMPORT', 9, 9, 'Xưởng thiết kế Lam Boutique', 567000.00, 'Nhập kho biến thể mới (DAM-KEMS-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_do_l, 'IMPORT', 6, 6, 'Xưởng thiết kế Lam Boutique', 983000.00, 'Nhập kho biến thể mới (DAM-DO-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_dt_s, 'IMPORT', 8, 8, 'Xưởng thiết kế Lam Boutique', 983000.00, 'Nhập kho biến thể mới (DAM-DT-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_dt_m, 'IMPORT', 12, 12, 'Xưởng thiết kế Lam Boutique', 983000.00, 'Nhập kho biến thể mới (DAM-DT-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_dt_m, 'SALE', -1, 11, NULL, NULL, 'Xuất kho theo đơn FS7Y2413', @ord_fs7y2413, @prof_staff3, @t_fs7y2413),
(@var_nv_dam_dt_l, 'IMPORT', 5, 5, 'Xưởng thiết kế Lam Boutique', 983000.00, 'Nhập kho biến thể mới (DAM-DT-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_xnl_s, 'IMPORT', 6, 6, 'Xưởng thiết kế Lam Boutique', 983000.00, 'Nhập kho biến thể mới (DAM-XNL-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_xnl_m, 'IMPORT', 9, 9, 'Xưởng thiết kế Lam Boutique', 983000.00, 'Nhập kho biến thể mới (DAM-XNL-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_dam_xnl_m, 'SALE', -1, 8, NULL, NULL, 'Xuất kho theo đơn FS7Y2530', @ord_fs7y2530, @prof_staff3, @t_fs7y2530),
(@var_nv_sm_oxf_s, 'IMPORT', 12, 12, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_oxf_xxl, 'IMPORT', 5, 5, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-XXL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_oxf_tr_s, 'IMPORT', 14, 14, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-TR-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_oxf_tr_m, 'IMPORT', 23, 23, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-TR-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_oxf_tr_m, 'SALE', -1, 22, NULL, NULL, 'Xuất kho theo đơn FS7Y2402', @ord_fs7y2402, @prof_staff3, @t_fs7y2402),
(@var_nv_sm_oxf_tr_l, 'IMPORT', 18, 18, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-TR-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_oxf_tr_xl, 'IMPORT', 10, 10, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-TR-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_oxf_xn_m, 'IMPORT', 16, 16, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-XN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_oxf_xn_l, 'IMPORT', 16, 16, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-XN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_sm_oxf_xn_l, 'SALE', -2, 14, NULL, NULL, 'Xuất kho theo đơn FS7Y2608', @ord_fs7y2608, @prof_staff3, @t_fs7y2608),
(@var_nv_sm_oxf_xn_xl, 'IMPORT', 8, 8, 'Xưởng may Nhà Bè', 281000.00, 'Nhập kho biến thể mới (SM-OXF-XN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_l, 'IMPORT', 12, 12, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_xl, 'IMPORT', 6, 6, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_den_s, 'IMPORT', 15, 15, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_den_s, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS7Y2406', @ord_fs7y2406, @prof_staff3, @t_fs7y2406),
(@var_nv_qn_cul_den_m, 'IMPORT', 18, 18, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_den_l, 'IMPORT', 13, 13, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_den_xl, 'IMPORT', 7, 7, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-DEN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_be_s, 'IMPORT', 10, 10, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-BE-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_be_m, 'IMPORT', 15, 15, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-BE-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_cul_be_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS7Y2526', @ord_fs7y2526, @prof_staff3, @t_fs7y2526),
(@var_nv_qn_cul_be_l, 'IMPORT', 9, 9, 'Xưởng may Bình Minh', 374000.00, 'Nhập kho biến thể mới (QN-CUL-BE-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_s, 'IMPORT', 12, 12, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập kho biến thể mới (QN-JOG-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_xl, 'IMPORT', 9, 9, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập kho biến thể mới (QN-JOG-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_den_s, 'IMPORT', 14, 14, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập kho biến thể mới (QN-JOG-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_den_m, 'IMPORT', 23, 23, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập kho biến thể mới (QN-JOG-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_den_m, 'SALE', -1, 22, NULL, NULL, 'Xuất kho theo đơn FS7Y2423', @ord_fs7y2423, @prof_staff3, @t_fs7y2423),
(@var_nv_qn_jog_den_l, 'IMPORT', 18, 18, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập kho biến thể mới (QN-JOG-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_den_xl, 'IMPORT', 11, 11, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập kho biến thể mới (QN-JOG-DEN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_reu_m, 'IMPORT', 13, 13, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập kho biến thể mới (QN-JOG-REU-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_reu_l, 'IMPORT', 11, 11, 'Xưởng dệt may Phong Phú', 255000.00, 'Nhập kho biến thể mới (QN-JOG-REU-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_qn_jog_reu_l, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS7Y2621', @ord_fs7y2621, @prof_staff3, @t_fs7y2621),
(@var_nv_ak_blz_l, 'IMPORT', 9, 9, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập kho biến thể mới (AK-BLZ-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_blz_xl, 'IMPORT', 4, 4, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập kho biến thể mới (AK-BLZ-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_blz_kb_s, 'IMPORT', 11, 11, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập kho biến thể mới (AK-BLZ-KB-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_blz_kb_s, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS7Y2405', @ord_fs7y2405, @prof_staff3, @t_fs7y2405),
(@var_nv_ak_blz_kb_m, 'IMPORT', 14, 14, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập kho biến thể mới (AK-BLZ-KB-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_blz_kb_m, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS7Y2633', @ord_fs7y2633, @prof_staff3, @t_fs7y2633),
(@var_nv_ak_blz_kb_l, 'IMPORT', 8, 8, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập kho biến thể mới (AK-BLZ-KB-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_blz_nau_s, 'IMPORT', 9, 9, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập kho biến thể mới (AK-BLZ-NAU-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_blz_nau_s, 'SALE', -1, 8, NULL, NULL, 'Xuất kho theo đơn FS7Y2521', @ord_fs7y2521, @prof_staff3, @t_fs7y2521),
(@var_nv_ak_blz_nau_m, 'IMPORT', 11, 11, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập kho biến thể mới (AK-BLZ-NAU-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_ak_blz_nau_l, 'IMPORT', 7, 7, 'Xưởng veston Hoàng Gia', 650000.00, 'Nhập kho biến thể mới (AK-BLZ-NAU-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_gym_s, 'IMPORT', 18, 18, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập kho biến thể mới (AT-GYM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_gym_xxl, 'IMPORT', 8, 8, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập kho biến thể mới (AT-GYM-XXL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_gym_xt_m, 'IMPORT', 26, 26, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập kho biến thể mới (AT-GYM-XT-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_gym_xt_m, 'SALE', -2, 24, NULL, NULL, 'Xuất kho theo đơn FS7Y2410', @ord_fs7y2410, @prof_staff3, @t_fs7y2410),
(@var_nv_at_gym_xt_l, 'IMPORT', 20, 20, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập kho biến thể mới (AT-GYM-XT-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_gym_xt_xl, 'IMPORT', 11, 11, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập kho biến thể mới (AT-GYM-XT-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_gym_xk_m, 'IMPORT', 22, 22, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập kho biến thể mới (AT-GYM-XK-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_gym_xk_l, 'IMPORT', 19, 19, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập kho biến thể mới (AT-GYM-XK-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_at_gym_xk_l, 'SALE', -1, 18, NULL, NULL, 'Xuất kho theo đơn FS7Y2513', @ord_fs7y2513, @prof_staff3, @t_fs7y2513),
(@var_nv_at_gym_xk_xl, 'IMPORT', 9, 9, 'Xưởng đồ thể thao ActiveVN', 161000.00, 'Nhập kho biến thể mới (AT-GYM-XK-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_gil_l, 'IMPORT', 11, 11, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập kho biến thể mới (AL-GIL-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_gil_nhd_s, 'IMPORT', 13, 13, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập kho biến thể mới (AL-GIL-NHD-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_gil_nhd_s, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS7Y2409', @ord_fs7y2409, @prof_staff3, @t_fs7y2409),
(@var_nv_al_gil_nhd_m, 'IMPORT', 15, 15, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập kho biến thể mới (AL-GIL-NHD-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_gil_nhd_l, 'IMPORT', 9, 9, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập kho biến thể mới (AL-GIL-NHD-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_gil_nv_s, 'IMPORT', 10, 10, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập kho biến thể mới (AL-GIL-NV-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_gil_nv_m, 'IMPORT', 15, 15, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập kho biến thể mới (AL-GIL-NV-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_al_gil_nv_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS7Y2534', @ord_fs7y2534, @prof_staff3, @t_fs7y2534),
(@var_nv_al_gil_nv_l, 'IMPORT', 8, 8, 'Xưởng len Đà Lạt Knit', 307000.00, 'Nhập kho biến thể mới (AL-GIL-NV-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_vs_den_s, 'IMPORT', 8, 8, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập kho biến thể mới (VS-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_vs_den_l, 'IMPORT', 13, 13, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập kho biến thể mới (VS-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_vs_den_l, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS7Y2617', @ord_fs7y2617, @prof_staff3, @t_fs7y2617),
(@var_nv_vs_den_xl, 'IMPORT', 6, 6, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập kho biến thể mới (VS-DEN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_vs_xam_m, 'IMPORT', 10, 10, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập kho biến thể mới (VS-XAM-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_vs_xam_xl, 'IMPORT', 5, 5, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập kho biến thể mới (VS-XAM-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_vs_nv_m, 'IMPORT', 11, 11, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập kho biến thể mới (VS-NV-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_vs_nv_l, 'IMPORT', 10, 10, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập kho biến thể mới (VS-NV-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_vs_nv_l, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS7Y2412', @ord_fs7y2412, @prof_staff3, @t_fs7y2412),
(@var_nv_vs_nv_xl, 'IMPORT', 4, 4, 'Xưởng veston Hoàng Gia', 442000.00, 'Nhập kho biến thể mới (VS-NV-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cd_kem_s, 'IMPORT', 14, 14, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập kho biến thể mới (CD-KEM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cd_kem_l, 'IMPORT', 16, 16, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập kho biến thể mới (CD-KEM-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cd_kem_l, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS7Y2533', @ord_fs7y2533, @prof_staff3, @t_fs7y2533),
(@var_nv_cd_kem_xl, 'IMPORT', 8, 8, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập kho biến thể mới (CD-KEM-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cd_den_s, 'IMPORT', 12, 12, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập kho biến thể mới (CD-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cd_den_m, 'IMPORT', 18, 18, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập kho biến thể mới (CD-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cd_den_xl, 'IMPORT', 9, 9, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập kho biến thể mới (CD-DEN-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cd_reu_m, 'IMPORT', 15, 15, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập kho biến thể mới (CD-REU-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_cd_reu_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS7Y2420', @ord_fs7y2420, @prof_staff3, @t_fs7y2420),
(@var_nv_cd_reu_l, 'IMPORT', 11, 11, 'Xưởng len Đà Lạt Knit', 218000.00, 'Nhập kho biến thể mới (CD-REU-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_tt_gym_l, 'IMPORT', 10, 10, 'Xưởng đồ thể thao ActiveVN', 307000.00, 'Nhập kho biến thể mới (TT-GYM-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_tt_gym_den_s, 'IMPORT', 17, 17, 'Xưởng đồ thể thao ActiveVN', 307000.00, 'Nhập kho biến thể mới (TT-GYM-DEN-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_tt_gym_den_s, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS7Y2408', @ord_fs7y2408, @prof_staff3, @t_fs7y2408),
(@var_nv_tt_gym_den_m, 'IMPORT', 18, 18, 'Xưởng đồ thể thao ActiveVN', 307000.00, 'Nhập kho biến thể mới (TT-GYM-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_tt_gym_den_l, 'IMPORT', 12, 12, 'Xưởng đồ thể thao ActiveVN', 307000.00, 'Nhập kho biến thể mới (TT-GYM-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_tt_gym_hd_s, 'IMPORT', 14, 14, 'Xưởng đồ thể thao ActiveVN', 307000.00, 'Nhập kho biến thể mới (TT-GYM-HD-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_tt_gym_hd_m, 'IMPORT', 16, 16, 'Xưởng đồ thể thao ActiveVN', 307000.00, 'Nhập kho biến thể mới (TT-GYM-HD-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_tt_gym_hd_m, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS7Y2535', @ord_fs7y2535, @prof_staff3, @t_fs7y2535),
(@var_nv_tt_gym_hd_l, 'IMPORT', 9, 9, 'Xưởng đồ thể thao ActiveVN', 307000.00, 'Nhập kho biến thể mới (TT-GYM-HD-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_hd_xam_s, 'IMPORT', 4, 4, 'Xưởng dệt may Phong Phú', 338000.00, 'Nhập kho biến thể mới (HD-XAM-S)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_hd_xam_m, 'IMPORT', 6, 6, 'Xưởng dệt may Phong Phú', 338000.00, 'Nhập kho biến thể mới (HD-XAM-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_hd_xam_xl, 'IMPORT', 3, 3, 'Xưởng dệt may Phong Phú', 338000.00, 'Nhập kho biến thể mới (HD-XAM-XL)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_hd_den_m, 'IMPORT', 5, 5, 'Xưởng dệt may Phong Phú', 338000.00, 'Nhập kho biến thể mới (HD-DEN-M)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s')),
(@var_nv_hd_den_l, 'IMPORT', 4, 4, 'Xưởng dệt may Phong Phú', 338000.00, 'Nhập kho biến thể mới (HD-DEN-L)', NULL, @prof_staff3, STR_TO_DATE(CONCAT(@y2_num, '-01-02 08:00:00'), '%Y-%m-%d %H:%i:%s'));

-- ============================================================================
-- MỤC 6: TRUY VẤN KIỂM CHỨNG TOÀN VẸN & THỐNG KÊ THEO NĂM / NGÀY
-- ============================================================================
SELECT
    (SELECT COUNT(*) FROM orders o
     WHERE o.subtotal <> (SELECT SUM(i.unit_price * i.quantity) FROM order_item i WHERE i.order_id = o.id)
        OR o.total_amount <> o.subtotal - o.discount_amount + o.shipping_fee) AS so_don_sai_tong_tien,
    (SELECT COUNT(*) FROM product_variant v
     JOIN stock_history h ON h.id = (SELECT MAX(id) FROM stock_history WHERE variant_id = v.id)
     WHERE h.stock_after <> v.stock_quantity) AS so_bien_the_lech_kho,
    (SELECT COUNT(*) FROM coupon c
     WHERE c.code IN ('SALE2024', 'SALE2025', 'SALE2026')
       AND c.used_count <> (SELECT COUNT(*) FROM orders o WHERE o.coupon_id = c.id AND o.status <> 'CANCELLED')) AS so_coupon_lech_luot_dung,
    (SELECT COUNT(*) FROM product) AS tong_san_pham,
    (SELECT COUNT(*) FROM product_variant) AS tong_bien_the;

SELECT YEAR(created_at) AS nam, COUNT(*) AS so_don_thanh_cong, SUM(total_amount) AS tong_doanh_thu
FROM orders
WHERE status IN ('COMPLETED', 'SHIPPING', 'CONFIRMED')
GROUP BY YEAR(created_at)
ORDER BY nam;

SELECT DATE(created_at) AS ngay, COUNT(*) AS so_don_trong_ngay, SUM(total_amount) AS doanh_thu_ngay
FROM orders
WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 9 DAY) AND status IN ('COMPLETED', 'SHIPPING', 'CONFIRMED')
GROUP BY DATE(created_at)
ORDER BY ngay;
