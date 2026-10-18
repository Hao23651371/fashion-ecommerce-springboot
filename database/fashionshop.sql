-- =====================================================
-- FashionShop - DATABASE HOAN CHINH (TEN BANG/COT TIENG ANH)
-- MariaDB >= 11.7 (can kieu VECTOR). Ban dang dung 12.2.2 nen on.
--
-- Cach dung: mo trong HeidiSQL, Ctrl+A roi F9. DUNG chay trong IntelliJ (loi GSS-API).
-- File se XOA database fashionshop cu va tao lai toan bo (13 bang gom product_embedding).
-- Sau khi chay: bat Ollama, chay Spring Boot -> app tu tao vector cho 15 san pham.
-- =====================================================

SET NAMES utf8mb4;

DROP DATABASE IF EXISTS fashionshop;

CREATE DATABASE fashionshop
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE fashionshop;

-- ================= 1. TAI KHOAN =================
CREATE TABLE account (
                         id                   BIGINT       NOT NULL AUTO_INCREMENT,
                         email                VARCHAR(150) NOT NULL,
                         password             VARCHAR(255) NOT NULL,
                         role                 VARCHAR(20)  NOT NULL,
                         status               VARCHAR(20)  NOT NULL,
                         email_verified       BIT(1)       NOT NULL DEFAULT 0,
                         verification_code    VARCHAR(100) NULL,
                         verification_expiry  DATETIME(6)  NULL,
                         created_at           DATETIME(6)  NOT NULL,
                         last_login_at        DATETIME(6)  NULL,
                         PRIMARY KEY (id),
                         UNIQUE KEY uk_account_email (email)
) ENGINE=InnoDB;

CREATE TABLE user_profile (
                              id            BIGINT       NOT NULL AUTO_INCREMENT,
                              full_name     VARCHAR(100) NOT NULL,
                              phone_number  VARCHAR(15)  NULL,
                              birth_date    DATE         NULL,
                              account_id    BIGINT       NOT NULL,
                              PRIMARY KEY (id),
                              UNIQUE KEY uk_user_profile_account (account_id),
                              CONSTRAINT fk_user_profile_account FOREIGN KEY (account_id) REFERENCES account (id)
) ENGINE=InnoDB;

CREATE TABLE shipping_address (
                                  id               BIGINT       NOT NULL AUTO_INCREMENT,
                                  user_profile_id  BIGINT       NOT NULL,
                                  address          VARCHAR(255) NOT NULL,
                                  default_address  BIT(1)       NOT NULL DEFAULT 0,
                                  PRIMARY KEY (id),
                                  CONSTRAINT fk_shipping_address_user FOREIGN KEY (user_profile_id) REFERENCES user_profile (id)
) ENGINE=InnoDB;

-- ================= 2. SAN PHAM =================
CREATE TABLE category (
                          id      BIGINT       NOT NULL AUTO_INCREMENT,
                          name    VARCHAR(100) NOT NULL,
                          status  VARCHAR(20)  NOT NULL,
                          PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE product (
                         id           BIGINT         NOT NULL AUTO_INCREMENT,
                         category_id  BIGINT         NOT NULL,
                         name         VARCHAR(200)   NOT NULL,
                         description  TEXT           NULL,
                         price        DECIMAL(15,2)  NOT NULL,
                         sale_price   DECIMAL(15,2)  NULL,
                         gender       VARCHAR(20)    NOT NULL,
                         status       VARCHAR(20)    NOT NULL,
                         image_url    VARCHAR(255)   NULL,
                         created_at   DATETIME(6)    NOT NULL,
                         PRIMARY KEY (id),
                         CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES category (id)
) ENGINE=InnoDB;

CREATE TABLE product_variant (
                                 id              BIGINT      NOT NULL AUTO_INCREMENT,
                                 product_id      BIGINT      NOT NULL,
                                 size            VARCHAR(20) NOT NULL,
                                 color           VARCHAR(50) NOT NULL,
                                 sku             VARCHAR(50) NULL,
                                 stock_quantity  INT         NOT NULL DEFAULT 0,
                                 status          VARCHAR(20) NOT NULL,
                                 version         INT         NOT NULL DEFAULT 0,
                                 PRIMARY KEY (id),
                                 UNIQUE KEY uk_variant_sku (sku),
                                 UNIQUE KEY uk_variant_product_size_color (product_id, size, color),
                                 CONSTRAINT fk_variant_product FOREIGN KEY (product_id) REFERENCES product (id)
) ENGINE=InnoDB;

-- Bang vector (Ollama bge-m3 = 1024 chieu). De TRONG, app tu tao khi khoi dong.
CREATE TABLE product_embedding (
                                   product_id BIGINT       NOT NULL,
                                   embedding  VECTOR(1024) NOT NULL,
                                   updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                   PRIMARY KEY (product_id),
                                   CONSTRAINT fk_product_embedding_product FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ================= 3. MA GIAM GIA =================
CREATE TABLE coupon (
                        id               BIGINT        NOT NULL AUTO_INCREMENT,
                        code             VARCHAR(50)   NOT NULL,
                        name             VARCHAR(150)  NOT NULL,
                        discount_type    VARCHAR(20)   NOT NULL,
                        discount_value   DECIMAL(15,2) NOT NULL,
                        max_discount     DECIMAL(15,2) NULL,
                        min_order_value  DECIMAL(15,2) NULL,
                        quantity         INT           NOT NULL,
                        used_count       INT           NOT NULL DEFAULT 0,
                        start_date       DATETIME(6)   NOT NULL,
                        end_date         DATETIME(6)   NOT NULL,
                        status           VARCHAR(20)   NOT NULL,
                        PRIMARY KEY (id),
                        UNIQUE KEY uk_coupon_code (code)
) ENGINE=InnoDB;

-- ================= 4. DON HANG =================
CREATE TABLE orders (
                        id                BIGINT        NOT NULL AUTO_INCREMENT,
                        order_code        VARCHAR(30)   NOT NULL,
                        user_profile_id   BIGINT        NOT NULL,
                        coupon_id         BIGINT        NULL,
                        status            VARCHAR(20)   NOT NULL,
                        subtotal          DECIMAL(15,2) NOT NULL DEFAULT 0,
                        discount_amount   DECIMAL(15,2) NOT NULL DEFAULT 0,
                        total_amount      DECIMAL(15,2) NOT NULL DEFAULT 0,
                        cancel_reason     VARCHAR(255)  NULL,
                        created_at        DATETIME(6)   NOT NULL,
                        completed_at      DATETIME(6)   NULL,
                        cancelled_at      DATETIME(6)   NULL,
                        recipient_name    VARCHAR(100)  NOT NULL,
                        recipient_phone   VARCHAR(15)   NOT NULL,
                        shipping_address  VARCHAR(255)  NOT NULL,
                        shipping_fee      DECIMAL(15,2) NOT NULL DEFAULT 0,
                        note              VARCHAR(255)  NULL,
                        payment_method    VARCHAR(20)   NOT NULL,
                        payment_status    VARCHAR(20)   NOT NULL,
                        paid_at           DATETIME(6)   NULL,
                        PRIMARY KEY (id),
                        UNIQUE KEY uk_orders_code (order_code),
                        CONSTRAINT fk_orders_user   FOREIGN KEY (user_profile_id) REFERENCES user_profile (id),
                        CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupon (id)
) ENGINE=InnoDB;

CREATE TABLE order_item (
                            id            BIGINT        NOT NULL AUTO_INCREMENT,
                            order_id      BIGINT        NOT NULL,
                            variant_id    BIGINT        NOT NULL,
                            product_name  VARCHAR(200)  NOT NULL,
                            size          VARCHAR(20)   NOT NULL,
                            color         VARCHAR(50)   NOT NULL,
                            unit_price    DECIMAL(15,2) NOT NULL,
                            quantity      INT           NOT NULL,
                            PRIMARY KEY (id),
                            CONSTRAINT fk_order_item_order   FOREIGN KEY (order_id)   REFERENCES orders (id),
                            CONSTRAINT fk_order_item_variant FOREIGN KEY (variant_id) REFERENCES product_variant (id)
) ENGINE=InnoDB;

-- ================= 5. KHO =================
CREATE TABLE stock_history (
                               id                 BIGINT        NOT NULL AUTO_INCREMENT,
                               variant_id         BIGINT        NOT NULL,
                               type               VARCHAR(20)   NOT NULL,
                               quantity_change    INT           NOT NULL,
                               stock_after        INT           NOT NULL,
                               supplier           VARCHAR(150)  NULL,
                               import_price       DECIMAL(15,2) NULL,
                               reason             VARCHAR(255)  NULL,
                               order_id           BIGINT        NULL,
                               performed_by_id    BIGINT        NULL,
                               created_at         DATETIME(6)   NOT NULL,
                               PRIMARY KEY (id),
                               CONSTRAINT fk_stock_history_variant FOREIGN KEY (variant_id)      REFERENCES product_variant (id),
                               CONSTRAINT fk_stock_history_order   FOREIGN KEY (order_id)        REFERENCES orders (id),
                               CONSTRAINT fk_stock_history_user    FOREIGN KEY (performed_by_id) REFERENCES user_profile (id)
) ENGINE=InnoDB;

-- ================= 6. GIO HANG & YEU THICH =================
CREATE TABLE cart_item (
                           id               BIGINT      NOT NULL AUTO_INCREMENT,
                           user_profile_id  BIGINT      NOT NULL,
                           variant_id       BIGINT      NOT NULL,
                           quantity         INT         NOT NULL DEFAULT 1,
                           added_at         DATETIME(6) NOT NULL,
                           PRIMARY KEY (id),
                           UNIQUE KEY uk_cart_item_user_variant (user_profile_id, variant_id),
                           CONSTRAINT fk_cart_item_user    FOREIGN KEY (user_profile_id) REFERENCES user_profile (id),
                           CONSTRAINT fk_cart_item_variant FOREIGN KEY (variant_id)      REFERENCES product_variant (id)
) ENGINE=InnoDB;

CREATE TABLE wishlist_item (
                               id               BIGINT      NOT NULL AUTO_INCREMENT,
                               user_profile_id  BIGINT      NOT NULL,
                               product_id       BIGINT      NOT NULL,
                               added_at         DATETIME(6) NOT NULL,
                               PRIMARY KEY (id),
                               UNIQUE KEY uk_wishlist_user_product (user_profile_id, product_id),
                               CONSTRAINT fk_wishlist_user    FOREIGN KEY (user_profile_id) REFERENCES user_profile (id),
                               CONSTRAINT fk_wishlist_product FOREIGN KEY (product_id)      REFERENCES product (id)
) ENGINE=InnoDB;

-- =====================================================
-- DU LIEU MAU
-- =====================================================
-- ADMIN mat khau: Admin@123   |   CUSTOMER mat khau: Khach@123
INSERT INTO account (email, password, role, status, email_verified, created_at) VALUES
                                                                                    ('admin1@fashionshop.vn', '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK', 'ADMIN',    'ACTIVE', 1, NOW(6)),
                                                                                    ('admin2@fashionshop.vn', '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK', 'ADMIN',    'ACTIVE', 1, NOW(6)),
                                                                                    ('khach1@gmail.com',      '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'ACTIVE', 1, NOW(6)),
                                                                                    ('khach2@gmail.com',      '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'ACTIVE', 1, NOW(6));

INSERT INTO user_profile (full_name, phone_number, birth_date, account_id) VALUES
                                                                               ('Nguyễn Quản Trị', '0901000001', '1995-03-15', (SELECT id FROM account WHERE email = 'admin1@fashionshop.vn')),
                                                                               ('Phạm Thu Hà',     '0901000002', '1998-07-22', (SELECT id FROM account WHERE email = 'admin2@fashionshop.vn')),
                                                                               ('Trần Thị Mai',    '0912000001', '2001-11-05', (SELECT id FROM account WHERE email = 'khach1@gmail.com')),
                                                                               ('Lê Văn Hùng',     '0912000002', '1999-01-30', (SELECT id FROM account WHERE email = 'khach2@gmail.com'));

INSERT INTO shipping_address (user_profile_id, address, default_address) VALUES
                                                                             ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
                                                                              '12 Nguyễn Văn Bảo, Phường 4, Quận Gò Vấp, TP. Hồ Chí Minh', 1),
                                                                             ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
                                                                              '45 Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh', 0),
                                                                             ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
                                                                              '88 Trần Hưng Đạo, Phường 2, Quận 5, TP. Hồ Chí Minh', 1);

-- ================= DANH MỤC =================
INSERT INTO category (name, status) VALUES
                                        ('Đầm', 'VISIBLE'),
                                        ('Áo sơ mi', 'VISIBLE'),
                                        ('Quần', 'VISIBLE'),
                                        ('Áo khoác', 'VISIBLE'),
                                        ('Chân váy', 'VISIBLE'),
                                        ('Áo thun', 'VISIBLE'),
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
-- Áo sơ mi nam kẻ sọc xanh navy
((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy'), 'M', 'Xanh navy', 'SM-NAM-KS-M', 13, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy'), 'L', 'Xanh navy', 'SM-NAM-KS-L', 15, 'ACTIVE', 0),
((SELECT id FROM product WHERE name = 'Áo sơ mi nam kẻ sọc xanh navy'), 'XL', 'Xanh navy', 'SM-NAM-KS-XL', 8, 'ACTIVE', 0);

-- ================= KIEM TRA SAU KHI CHAY (dung: 4, 7, 15, 48, 0) =================
SELECT COUNT(*) AS so_tai_khoan FROM account;
SELECT COUNT(*) AS so_danh_muc  FROM category;
SELECT COUNT(*) AS so_san_pham  FROM product;
SELECT COUNT(*) AS so_bien_the  FROM product_variant;
SELECT COUNT(*) AS so_vector    FROM product_embedding;