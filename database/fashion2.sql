-- =====================================================
-- FashionShop - FILE 2/2: DU LIEU SAN PHAM (danh muc, san pham, bien the)
-- KHONG tao bang, KHONG xoa database. Phai chay fashion1.sql TRUOC.
--
-- Muon them du lieu moi: tao them file fashion3.sql, fashion4.sql... chi gom cac cau INSERT,
-- roi chay lan luot sau fashion2.sql (khong can tao lai bang).
--
-- Cach dung: mo trong HeidiSQL, Ctrl+A roi F9. DUNG chay trong IntelliJ (loi GSS-API).
-- =====================================================

SET NAMES utf8mb4;

USE fashionshop;

-- ================= DANH MỤC, có thêm 1 cái ẩn =================
INSERT INTO category (name, status) VALUES
                                        ('Đầm', 'VISIBLE'),
                                        ('Áo sơ mi', 'VISIBLE'),
                                        ('Quần', 'VISIBLE'),
                                        ('Áo khoác', 'VISIBLE'),
                                        ('Chân váy', 'VISIBLE'),
                                        ('Áo thun', 'VISIBLE'),
                                        ('Áo hoodie', 'HIDDEN'),
                                        ('Áo len', 'VISIBLE');


-- ================= SẢN PHẨM =================
-- image_url trỏ tới Cloudinary theo Public ID "sp-<tên-ngắn>". Upload ảnh với ĐÚNG Public ID đó là ảnh tự hiện.
INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at) VALUES
                                                                                                                   ((SELECT id FROM category WHERE name = 'Đầm'),
                                                                                                                    'Đầm lụa dáng dài màu be',
                                                                                                                    'Đầm lụa dáng dài màu be nhẹ nhàng, chất liệu lụa mềm rũ tự nhiên, thoáng mát và không nhăn. Phom xòe nhẹ tôn dáng, cổ chữ V thanh lịch, phù hợp dự tiệc, đám cưới, sự kiện buổi tối hoặc dạo phố cuối tuần.',
                                                                                                                    1850000, 1590000, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-dam-lua-be', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo sơ mi'),
                                                                                                                    'Áo sơ mi linen trắng tối giản',
                                                                                                                    'Áo sơ mi linen trắng phom rộng nhẹ, vải linen tự nhiên thấm hút mồ hôi tốt, mặc mát vào mùa hè. Thiết kế tối giản, cúc ngọc trai, mặc đi làm, đi học hay đi chơi đều hợp. Nam nữ đều mặc được.',
                                                                                                                    690000, NULL, 'UNISEX', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-so-mi-linen-trang', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Quần'),
                                                                                                                    'Quần tây ống đứng màu đen',
                                                                                                                    'Quần tây ống đứng màu đen lưng cao, chất vải tuyt-si dày dặn, đứng form và ít nhăn. Cạp cao giúp kéo dài đôi chân, phù hợp môi trường công sở và các buổi gặp gỡ cần sự chỉn chu.',
                                                                                                                    890000, NULL, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-quan-tay-ong-dung-den', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo khoác'),
                                                                                                                    'Áo trench coat dáng dài màu camel',
                                                                                                                    'Áo trench coat dáng dài màu camel kinh điển, chất vải gabardine chống gió nhẹ, có đai thắt eo và cầu vai chuẩn phong cách Anh. Phù hợp thời tiết se lạnh, đi làm, đi du lịch hay chụp ảnh thời trang.',
                                                                                                                    2990000, 2490000, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-trench-coat-camel', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo khoác'),
                                                                                                                    'Áo blazer nam màu xám tro',
                                                                                                                    'Áo blazer nam màu xám tro, phom slim fit vừa vặn, chất vải len pha co giãn nhẹ, lót trong mềm mại. Hai cúc, hai túi nắp, phù hợp đi làm, dự tiệc, phỏng vấn hay sự kiện trang trọng.',
                                                                                                                    2350000, NULL, 'MALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-blazer-nam-xam', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Chân váy'),
                                                                                                                    'Chân váy midi xếp ly màu kem',
                                                                                                                    'Chân váy midi xếp ly màu kem nhẹ nhàng, chất vải voan lót mềm bay bổng khi di chuyển. Cạp chun co giãn thoải mái, độ dài qua gối trang nhã. Phù hợp đi làm, đi cafe, dạo phố hay chụp ảnh.',
                                                                                                                    790000, NULL, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-chan-vay-xep-ly-kem', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Chân váy'),
                                                                                                                    'Chân váy chữ A denim xanh',
                                                                                                                    'Chân váy chữ A chất denim xanh cổ điển, dày dặn vừa phải, đứng form và không nhăn. Dáng ngắn trên gối trẻ trung, hai túi hông tiện lợi. Hợp phong cách năng động, đi học, đi chơi.',
                                                                                                                    690000, 590000, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-chan-vay-chu-a-denim', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo thun'),
                                                                                                                    'Áo thun cotton basic cổ tròn màu trắng',
                                                                                                                    'Áo thun cotton 100% màu trắng cổ tròn, vải dày mịn thấm hút mồ hôi tốt, không bai không xù sau nhiều lần giặt. Phom suông thoải mái cho cả nam và nữ. Món đồ nền tảng để phối với mọi trang phục.',
                                                                                                                    290000, NULL, 'UNISEX', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-thun-basic-trang', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo thun'),
                                                                                                                    'Áo thun oversize màu đen in chữ',
                                                                                                                    'Áo thun oversize màu đen in chữ tối giản ở ngực, chất cotton dày dặn đứng form, tay rơi phong cách streetwear. Mặc rộng thoải mái, che khuyết điểm tốt. Hợp đi chơi, đi học.',
                                                                                                                    390000, 329000, 'UNISEX', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-thun-oversize-den', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo len'),
                                                                                                                    'Áo len cổ lọ màu nâu cà phê',
                                                                                                                    'Áo len cổ lọ màu nâu cà phê ấm áp, sợi len mềm không gây ngứa, ôm nhẹ tôn dáng. Giữ ấm tốt trong ngày se lạnh, dễ phối cùng chân váy, quần tây hoặc khoác ngoài trench coat.',
                                                                                                                    950000, NULL, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-len-co-lo-nau', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Quần'),
                                                                                                                    'Quần jean ống rộng màu xanh đậm',
                                                                                                                    'Quần jean ống rộng màu xanh đậm, lưng cao, chất denim dày dặn có độ co giãn nhẹ. Dáng suông rộng che khuyết điểm và kéo dài đôi chân, phong cách retro hiện đại. Nam nữ đều mặc được.',
                                                                                                                    850000, NULL, 'UNISEX', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-quan-jean-ong-rong', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Quần'),
                                                                                                                    'Quần short kaki nam màu xanh rêu',
                                                                                                                    'Quần short kaki nam màu xanh rêu, chất vải kaki mềm thoáng, co giãn nhẹ, độ dài ngang gối. Lưng có dây rút kết hợp cúc, hai túi chéo tiện dụng. Phù hợp đi biển, du lịch, đi chơi cuối tuần.',
                                                                                                                    490000, NULL, 'MALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-quan-short-kaki-nam', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Đầm'),
                                                                                                                    'Đầm midi hoa nhí màu hồng phấn',
                                                                                                                    'Đầm midi họa tiết hoa nhí trên nền hồng phấn dịu dàng, chất vải chiffon hai lớp mát nhẹ. Cổ vuông, tay phồng nhẹ, eo chun ôm gọn rất nữ tính. Phù hợp đi chơi, hẹn hò, dạo biển hay dự tiệc nhẹ ban ngày.',
                                                                                                                    1250000, 990000, 'FEMALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-dam-midi-hoa-nhi', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo khoác'),
                                                                                                                    'Áo khoác denim xanh dáng ngắn',
                                                                                                                    'Áo khoác denim xanh dáng ngắn, chất denim dày dặn bền màu, cổ bẻ, hai túi ngực và cúc kim loại. Phong cách trẻ trung, dễ phối cùng áo thun, đầm hoặc chân váy. Nam nữ đều mặc được, hợp đi chơi và du lịch.',
                                                                                                                    1390000, NULL, 'UNISEX', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-khoac-denim', NOW(6)),


                                                                                                                   -- ================= Sản phẩm bị ẩn -> /shop/{id} phải trả 404 và không hiện ở trang chủ, chỉ admin thấy =================
                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo len'),
                                                                                                                    'Áo len cardigan màu xám (đang ẩn)',
                                                                                                                    'Áo len cardigan màu xám dáng dài, sợi len mềm ấm, cài cúc phía trước. Sản phẩm đang tạm ẩn khỏi cửa hàng để test trường hợp sản phẩm không hiển thị.',
                                                                                                                    890000, NULL, 'FEMALE', 'INACTIVE',   -- TODO: đổi 'INACTIVE' cho đúng ProductStatus
                                                                                                                    'https://res.cloudinary.com/dxk6xlsre/image/upload/v1792676354/sp-ao-len-cardigan-xam.png', NOW(6)),

                                                                                                                   ((SELECT id FROM category WHERE name = 'Áo sơ mi'),
                                                                                                                    'Áo sơ mi nam kẻ sọc xanh navy',
                                                                                                                    'Áo sơ mi nam kẻ sọc xanh navy, chất cotton pha thoáng mát ít nhăn, phom regular vừa vặn. Cổ bẻ lịch sự, tay dài có thể xắn gọn. Phù hợp đi làm công sở, gặp đối tác hay đi chơi.',
                                                                                                                    750000, NULL, 'MALE', 'ACTIVE', 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-so-mi-nam-ke-soc', NOW(6));

-- ================= BIẾN THỂ (SIZE / MÀU / TỒN KHO) =================
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version) VALUES
-- Đầm lụa dáng dài màu be
((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be'), 'S', 'Be', 'DAM-LUA-BE-S', 12, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be'), 'M', 'Be', 'DAM-LUA-BE-M', 15, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be'), 'L', 'Be', 'DAM-LUA-BE-L', 8, 'ACTIVE', 0),
-- Áo sơ mi linen trắng tối giản
((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản'), 'S', 'Trắng', 'SM-LINEN-TR-S', 20, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản'), 'M', 'Trắng', 'SM-LINEN-TR-M', 25, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản'), 'L', 'Trắng', 'SM-LINEN-TR-L', 18, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản'), 'M', 'Xanh nhạt', 'SM-LINEN-XN-M', 10, 'ACTIVE', 0),
-- Quần tây ống đứng màu đen
((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen'), 'S', 'Đen', 'QT-ONGDUNG-D-S', 14, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen'), 'M', 'Đen', 'QT-ONGDUNG-D-M', 16, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Quần tây ống đứng màu đen'), 'L', 'Đen', 'QT-ONGDUNG-D-L', 9, 'ACTIVE', 0),
-- Áo trench coat dáng dài màu camel
((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel'), 'S', 'Camel', 'TRENCH-CAMEL-S', 6, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel'), 'M', 'Camel', 'TRENCH-CAMEL-M', 8, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo trench coat dáng dài màu camel'), 'L', 'Camel', 'TRENCH-CAMEL-L', 5, 'ACTIVE', 0),
-- Áo blazer nam màu xám tro
((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro'), 'M', 'Xám tro', 'BLAZER-NAM-XAM-M', 7, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro'), 'L', 'Xám tro', 'BLAZER-NAM-XAM-L', 9, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo blazer nam màu xám tro'), 'XL', 'Xám tro', 'BLAZER-NAM-XAM-XL', 4, 'ACTIVE', 0),
-- Chân váy midi xếp ly màu kem
((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem'), 'S', 'Kem', 'CV-XEPLY-KEM-S', 14, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem'), 'M', 'Kem', 'CV-XEPLY-KEM-M', 18, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Chân váy midi xếp ly màu kem'), 'L', 'Kem', 'CV-XEPLY-KEM-L', 10, 'ACTIVE', 0),
-- Chân váy chữ A denim xanh
((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh'), 'S', 'Xanh denim', 'CV-CHUA-DENIM-S', 11, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh'), 'M', 'Xanh denim', 'CV-CHUA-DENIM-M', 13, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Chân váy chữ A denim xanh'), 'L', 'Xanh denim', 'CV-CHUA-DENIM-L', 7, 'ACTIVE', 0),
-- Áo thun cotton basic cổ tròn màu trắng
((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng'), 'S', 'Trắng', 'AT-BASIC-TR-S', 30, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng'), 'M', 'Trắng', 'AT-BASIC-TR-M', 40, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng'), 'L', 'Trắng', 'AT-BASIC-TR-L', 35, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng'), 'XL', 'Trắng', 'AT-BASIC-TR-XL', 20, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo thun cotton basic cổ tròn màu trắng'), 'M', 'Đen', 'AT-BASIC-D-M', 25, 'ACTIVE', 0),
-- Áo thun oversize màu đen in chữ
((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ'), 'M', 'Đen', 'AT-OVER-D-M', 22, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ'), 'L', 'Đen', 'AT-OVER-D-L', 26, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ'), 'XL', 'Đen', 'AT-OVER-D-XL', 15, 'ACTIVE', 0),
-- Áo len cổ lọ màu nâu cà phê
((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê'), 'S', 'Nâu', 'AL-COLO-NAU-S', 9, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê'), 'M', 'Nâu', 'AL-COLO-NAU-M', 12, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo len cổ lọ màu nâu cà phê'), 'L', 'Nâu', 'AL-COLO-NAU-L', 8, 'ACTIVE', 0),
-- Quần jean ống rộng màu xanh đậm
((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm'), 'S', 'Xanh denim', 'QJ-ONGRONG-S', 12, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm'), 'M', 'Xanh denim', 'QJ-ONGRONG-M', 17, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Quần jean ống rộng màu xanh đậm'), 'L', 'Xanh denim', 'QJ-ONGRONG-L', 11, 'ACTIVE', 0),
-- Quần short kaki nam màu xanh rêu
((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu'), 'M', 'Xanh rêu', 'QS-KAKI-REU-M', 14, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu'), 'L', 'Xanh rêu', 'QS-KAKI-REU-L', 16, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Quần short kaki nam màu xanh rêu'), 'XL', 'Xanh rêu', 'QS-KAKI-REU-XL', 9, 'ACTIVE', 0),
-- Đầm midi hoa nhí màu hồng phấn
((SELECT id FROM product WHERE name = 'Đầm midi hoa nhí màu hồng phấn'), 'S', 'Hồng phấn', 'DAM-HOANHI-HP-S', 8, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Đầm midi hoa nhí màu hồng phấn'), 'M', 'Hồng phấn', 'DAM-HOANHI-HP-M', 12, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Đầm midi hoa nhí màu hồng phấn'), 'L', 'Hồng phấn', 'DAM-HOANHI-HP-L', 6, 'ACTIVE', 0),
-- Áo khoác denim xanh dáng ngắn
((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn'), 'M', 'Xanh denim', 'AK-DENIM-M', 9, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn'), 'L', 'Xanh denim', 'AK-DENIM-L', 12, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo khoác denim xanh dáng ngắn'), 'XL', 'Xanh denim', 'AK-DENIM-XL', 7, 'ACTIVE', 0),
-- sp-ao-len-cardigan-xam
((SELECT id FROM product WHERE name = 'Áo len cardigan màu xám (đang ẩn)'), 'M', 'Xám', 'AL-CARDI-XAM-M', 10, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo len cardigan màu xám (đang ẩn)'), 'L', 'Xám', 'AL-CARDI-XAM-L', 5,  'ACTIVE', 0),
-- Biến thể HẾT HÀNG (stock_quantity = 0) -> test badge "hết hàng", chặn thêm vào giỏ, chặn đặt hàng
((SELECT id FROM product WHERE name = 'Áo thun oversize màu đen in chữ'), 'S', 'Đen', 'AT-OVER-D-S', 0, 'ACTIVE', 0),
-- Áo sơ mi nam kẻ sọc xanh navy
((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy'), 'M', 'Xanh navy', 'SM-NAM-KS-M', 13, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy'), 'L', 'Xanh navy', 'SM-NAM-KS-L', 15, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy'), 'XL', 'Xanh navy', 'SM-NAM-KS-XL', 8, 'ACTIVE', 0);


-- ================= HÌNH ẢNH SẢN PHẨM (product_image) =================
-- HƯỚNG DẪN:
-- 1 sản phẩm có thể có 1 ảnh chính (is_thumbnail = 1, display_order = 1) và tối đa 3 ảnh phụ (display_order 2, 3, 4)
-- Khi muốn thêm ảnh cho sản phẩm khác, bạn chỉ cần copy khối dưới và đổi Tên sản phẩm + link ảnh tương ứng.

INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order) VALUES
    -- 1. Đầm lụa dáng dài màu be (1 ảnh chính + 3 ảnh phụ = 4 ảnh)
    ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be'), 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-dam-lua-be', 1, 1),
    ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be'), 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-dam-midi-hoa-nhi', 0, 2),
    ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be'), 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-chan-vay-xep-ly-kem', 0, 3),
    ((SELECT id FROM product WHERE name = 'Đầm lụa dáng dài màu be'), 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-chan-vay-chua-a-denim', 0, 4),

    -- 2. Áo sơ mi linen trắng tối giản (1 ảnh chính + 3 ảnh phụ = 4 ảnh)
    ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản'), 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-so-mi-linen-trang', 1, 1),
    ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản'), 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-so-mi-nam-ke-soc', 0, 2),
    ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản'), 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-thun-basic-trang', 0, 3),
    ((SELECT id FROM product WHERE name = 'Áo sơ mi linen trắng tối giản'), 'https://res.cloudinary.com/dxk6xlsre/image/upload/f_auto,q_auto,w_600/sp-ao-thun-oversize-den', 0, 4);


-- ================= KIEM TRA SAU KHI CHAY =================
SELECT COUNT(*) AS so_danh_muc    FROM category;
SELECT COUNT(*) AS so_san_pham    FROM product;
SELECT COUNT(*) AS so_bien_the    FROM product_variant;
SELECT COUNT(*) AS so_anh_san_pham FROM product_image;
SELECT COUNT(*) AS so_vector      FROM product_embedding;
