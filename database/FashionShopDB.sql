-- ============================================================================
-- FASHION SHOP - FILE CSDL GỘP DUY NHẤT (FashionShopDB.sql)
-- Gộp tự động theo thứ tự: fashion1.sql -> fashion7.sql + 2 mã mẫu từ migration_coupon_update.sql
-- Cách chạy: Mở trong HeidiSQL -> File -> Run SQL file... (hoặc Ctrl+A -> F9)
-- ============================================================================

-- >>> BẮT ĐẦU: database\fashion1.sql
-- =====================================================
-- FashionShop - FILE 1/2: TAO DATABASE + BANG + TAI KHOAN
-- MariaDB >= 11.7 (can kieu VECTOR). Ban dang dung 12.2.2 nen on.
--
-- File nay XOA database fashionshop cu va tao lai (14 bang), roi nap 4 tai khoan mau.
-- CHI CHAY FILE NAY KHI CAN TAO LAI TOAN BO. Chay xong thi chay tiep fashion2.sql.
--
-- Cach dung: mo trong HeidiSQL, Ctrl+A roi F9. DUNG chay trong IntelliJ (loi GSS-API).
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

CREATE TABLE product_image (
                               id            BIGINT       NOT NULL AUTO_INCREMENT,
                               product_id    BIGINT       NOT NULL,
                               image_url     VARCHAR(255) NOT NULL,
                               is_thumbnail  BIT(1)       NOT NULL DEFAULT 0,
                               display_order INT          NOT NULL DEFAULT 0,
                               PRIMARY KEY (id),
                               CONSTRAINT fk_product_image_product FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
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
                        id                      BIGINT        NOT NULL AUTO_INCREMENT,
                        code                    VARCHAR(50)   NOT NULL,
                        name                    VARCHAR(150)  NOT NULL,
                        description             TEXT          NULL,
                        discount_type           VARCHAR(20)   NOT NULL,
                        discount_value          DECIMAL(15,2) NOT NULL,
                        max_discount            DECIMAL(15,2) NULL,
                        min_order_value         DECIMAL(15,2) NULL,
                        quantity                INT           NOT NULL,
                        used_count              INT           NOT NULL DEFAULT 0,
                        per_user_limit          INT           NOT NULL DEFAULT 1,
                        target_customer_type    VARCHAR(20)   NOT NULL DEFAULT 'ALL',
                        applicable_category_id  BIGINT        NULL,
                        start_date              DATETIME(6)   NOT NULL,
                        end_date                DATETIME(6)   NOT NULL,
                        status                  VARCHAR(20)   NOT NULL,
                        PRIMARY KEY (id),
                        UNIQUE KEY uk_coupon_code (code),
                        CONSTRAINT fk_coupon_category FOREIGN KEY (applicable_category_id) REFERENCES category (id) ON DELETE SET NULL
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
                               receipt_code       VARCHAR(50)   NULL,
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
-- ADMIN / STAFF mat khau: Admin@123   |   CUSTOMER mat khau: Khach@123
-- ================= KHÁCH BỔ SUNG (TRƯỜNG HỢP BIÊN) =================
-- khach3: khách mới, KHÔNG có địa chỉ / đơn / giỏ / yêu thích -> test các màn hình trống
-- khach4: đã xác thực nhưng bị khóa (BANNED)                    -> test chặn đăng nhập, nút mở khóa ở /admin/users
INSERT INTO account (email, password, role, status, email_verified, created_at) VALUES
                                                                                    ('admin1@fashionshop.vn', '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK', 'ADMIN',    'ACTIVE', 1, NOW(6)),
                                                                                    ('admin2@fashionshop.vn', '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK', 'ADMIN',    'ACTIVE', 1, NOW(6)),
                                                                                    ('staff1@fashionshop.vn', '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK', 'STAFF',    'ACTIVE', 1, NOW(6)),
                                                                                    ('staff2@fashionshop.vn', '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK', 'STAFF',    'ACTIVE', 1, NOW(6)),
                                                                                    ('khach1@gmail.com',      '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'ACTIVE', 1, NOW(6)),
                                                                                    ('khach2@gmail.com',      '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'ACTIVE', 1, NOW(6)),
                                                                                    ('khach3@gmail.com', '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'ACTIVE', 1, NOW(6)),
                                                                                    ('khach4@gmail.com', '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'BANNED', 1, NOW(6));

INSERT INTO user_profile (full_name, phone_number, birth_date, account_id) VALUES
                                                                               ('Nguyễn Quản Trị', '0901000001', '1995-03-15', (SELECT id FROM account WHERE email = 'admin1@fashionshop.vn')),
                                                                               ('Phạm Thu Hà',     '0901000002', '1998-07-22', (SELECT id FROM account WHERE email = 'admin2@fashionshop.vn')),
                                                                               ('Hoàng Thị Nhân Viên', '0902000001', '1999-05-20', (SELECT id FROM account WHERE email = 'staff1@fashionshop.vn')),
                                                                               ('Lê Văn Nhân Viên',    '0902000002', '2000-08-12', (SELECT id FROM account WHERE email = 'staff2@fashionshop.vn')),
                                                                               ('Trần Thị Mai',    '0912000001', '2001-11-05', (SELECT id FROM account WHERE email = 'khach1@gmail.com')),
                                                                               ('Lê Văn Hùng',     '0912000002', '1999-01-30', (SELECT id FROM account WHERE email = 'khach2@gmail.com')),
                                                                               ('Võ Minh Anh',    '0912000003', '2003-06-18', (SELECT id FROM account WHERE email = 'khach3@gmail.com')),
                                                                               ('Đặng Quốc Bảo',  '0912000004', '1997-09-09', (SELECT id FROM account WHERE email = 'khach4@gmail.com'));





INSERT INTO shipping_address (user_profile_id, address, default_address) VALUES
                                                                             ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
                                                                              '12 Nguyễn Văn Bảo, Phường 4, Quận Gò Vấp, TP. Hồ Chí Minh', 1),
                                                                             ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach1@gmail.com'),
                                                                              '45 Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh', 0),
                                                                             ((SELECT u.id FROM user_profile u JOIN account a ON a.id = u.account_id WHERE a.email = 'khach2@gmail.com'),
                                                                              '88 Trần Hưng Đạo, Phường 2, Quận 5, TP. Hồ Chí Minh', 1);


-- ================= KIEM TRA SAU KHI CHAY (dung: 8) =================
SELECT COUNT(*) AS so_tai_khoan FROM account;

-- >>> BẮT ĐẦU: database\fashion2.sql
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

-- >>> BẮT ĐẦU: database\fashion3.sql
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
    ('GIAM10', 'Giảm 10% đơn từ 300.000 ₫ (tối đa 100.000 ₫)', 'PERCENT', 10.00, 100000.00, 300000.00, 100, 1,
     DATE_SUB(NOW(6), INTERVAL 30 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE'),

    -- Dùng được. Giảm cố định 50.000đ, đơn từ 500.000đ. used_count = 1 vì đơn FS20261021001 (fashion4) đang dùng.
    ('GIAM50K', 'Giảm 50.000 ₫ đơn từ 500.000 ₫', 'FIXED_AMOUNT', 50000.00, NULL, 500000.00, 50, 1,
     DATE_SUB(NOW(6), INTERVAL 30 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE'),

    -- Admin đã tạm ngừng (status INACTIVE) -> không được áp dụng dù còn hạn.
    ('TAMNGUNG', 'Mã đang tạm ngừng', 'PERCENT', 15.00, 150000.00, NULL, 100, 0,
     DATE_SUB(NOW(6), INTERVAL 30 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'INACTIVE'),

    -- Đã quá hạn (end_date là 10 ngày trước) -> báo mã hết hạn.
    ('HETHAN', 'Mã đã hết hạn', 'PERCENT', 20.00, 200000.00, NULL, 100, 0,
     DATE_SUB(NOW(6), INTERVAL 60 DAY), DATE_SUB(NOW(6), INTERVAL 10 DAY), 'ACTIVE'),

    -- Chưa tới ngày bắt đầu (start_date là 10 ngày sau) -> báo mã chưa có hiệu lực.
    ('CHUABATDAU', 'Giảm 100.000 ₫ đơn từ 1.000.000 ₫', 'FIXED_AMOUNT', 100000.00, NULL, 1000000.00, 100, 0,
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

-- >>> BẮT ĐẦU: database\fashion4.sql

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

-- >>> BẮT ĐẦU: database\fashion5.sql

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

-- >>> BẮT ĐẦU: database\fashion6.sql
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
SET @cur_m_start := STR_TO_DATE(DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00'), '%Y-%m-%d %H:%i:%s');
SET @cur_span := GREATEST(TIMESTAMPDIFF(SECOND, @cur_m_start, NOW(6)), 60);

SELECT up.id
INTO @prof_staff1
FROM user_profile up
         JOIN account a ON up.account_id = a.id
WHERE a.email = 'staff1@fashionshop.vn'
LIMIT 1;
SELECT up.id
INTO @prof_khach1
FROM user_profile up
         JOIN account a ON up.account_id = a.id
WHERE a.email = 'khach1@gmail.com'
LIMIT 1;
SELECT up.id
INTO @prof_khach2
FROM user_profile up
         JOIN account a ON up.account_id = a.id
WHERE a.email = 'khach2@gmail.com'
LIMIT 1;

SELECT id
INTO @cat_dam
FROM category
WHERE name = 'Đầm'
LIMIT 1;
SELECT id
INTO @cat_somi
FROM category
WHERE name = 'Áo sơ mi'
LIMIT 1;
SELECT id
INTO @cat_quan
FROM category
WHERE name = 'Quần'
LIMIT 1;
SELECT id
INTO @cat_khoac
FROM category
WHERE name = 'Áo khoác'
LIMIT 1;
SELECT id
INTO @cat_thun
FROM category
WHERE name = 'Áo thun'
LIMIT 1;
SELECT id
INTO @cat_hoodie
FROM category
WHERE name = 'Áo hoodie'
LIMIT 1;
SELECT id
INTO @cat_len
FROM category
WHERE name = 'Áo len'
LIMIT 1;

SELECT id
INTO @var_dam_lua_be_s
FROM product_variant
WHERE sku = 'DAM-LUA-BE-S'
LIMIT 1;
SELECT id
INTO @var_sm_linen_tr_m
FROM product_variant
WHERE sku = 'SM-LINEN-TR-M'
LIMIT 1;
SELECT id
INTO @var_at_basic_tr_l
FROM product_variant
WHERE sku = 'AT-BASIC-TR-L'
LIMIT 1;
SELECT id
INTO @var_cv_xeply_m
FROM product_variant
WHERE sku = 'CV-XEPLY-KEM-M'
LIMIT 1;

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

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('admin3@fashionshop.vn', @pw_admin, 'ADMIN', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 55 DAY),
        DATE_SUB(NOW(6), INTERVAL 12 HOUR));
SET @acc_admin3 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_admin3, 'Lê Minh Quản Trị', '0903000003', '1993-05-12');
SET @prof_admin3 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('admin4@fashionshop.vn', @pw_admin, 'ADMIN', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 52 DAY),
        DATE_SUB(NOW(6), INTERVAL 5 HOUR));
SET @acc_admin4 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_admin4, 'Nguyễn Thị Điều Hành', '0903000004', '1991-09-20');
SET @prof_admin4 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('admin5@fashionshop.vn', @pw_admin, 'ADMIN', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 48 DAY),
        DATE_SUB(NOW(6), INTERVAL 24 HOUR));
SET @acc_admin5 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_admin5, 'Trần Quốc Bảo', '0903000005', '1994-03-08');
SET @prof_admin5 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('staff3@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 45 DAY),
        DATE_SUB(NOW(6), INTERVAL 2 HOUR));
SET @acc_staff3 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_staff3, 'Phạm Thị Kho Vận', '0903000006', '1997-08-21');
SET @prof_staff3 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('staff4@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 42 DAY),
        DATE_SUB(NOW(6), INTERVAL 4 HOUR));
SET @acc_staff4 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_staff4, 'Trần Hoàng Chăm Sóc', '0903000007', '1998-11-04');
SET @prof_staff4 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('staff5@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 38 DAY),
        DATE_SUB(NOW(6), INTERVAL 8 HOUR));
SET @acc_staff5 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_staff5, 'Võ Minh Đóng Gói', '0903000008', '1999-01-17');
SET @prof_staff5 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('staff6@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 34 DAY),
        DATE_SUB(NOW(6), INTERVAL 16 HOUR));
SET @acc_staff6 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_staff6, 'Đặng Thị Kiểm Kê', '0903000009', '1996-06-29');
SET @prof_staff6 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('staff7@fashionshop.vn', @pw_admin, 'STAFF', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 30 DAY),
        DATE_SUB(NOW(6), INTERVAL 6 HOUR));
SET @acc_staff7 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_staff7, 'Huỳnh Tấn Kế Toán', '0903000010', '1995-12-15');
SET @prof_staff7 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('staff8@fashionshop.vn', @pw_admin, 'STAFF', 'BANNED', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 60 DAY),
        DATE_SUB(NOW(6), INTERVAL 480 HOUR));
SET @acc_staff8 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_staff8, 'Ngô Văn Nghỉ Việc', '0903000011', '1997-04-02');
SET @prof_staff8 := LAST_INSERT_ID();

INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach5@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 58 DAY),
        DATE_SUB(NOW(6), INTERVAL 3 HOUR));
SET @acc_khach5 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach5, 'Nguyễn Ngọc Lan', '0915000005', '1996-02-14');
SET @prof_khach5 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach6@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 55 DAY),
        DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach6 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach6, 'Trần Minh Tuấn', '0915000006', '1994-09-30');
SET @prof_khach6 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach7@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 52 DAY),
        DATE_SUB(NOW(6), INTERVAL 6 HOUR));
SET @acc_khach7 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach7, 'Lê Thị Thu Hà', '0915000007', '1999-07-19');
SET @prof_khach7 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach8@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 50 DAY),
        DATE_SUB(NOW(6), INTERVAL 12 HOUR));
SET @acc_khach8 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach8, 'Phạm Quốc Bảo', '0915000008', '1995-12-03');
SET @prof_khach8 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach9@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 49 DAY),
        DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach9 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach9, 'Võ Thị Mỹ Linh', '0915000009', '2000-04-25');
SET @prof_khach9 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach10@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 47 DAY),
        DATE_SUB(NOW(6), INTERVAL 4 HOUR));
SET @acc_khach10 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach10, 'Đặng Hoàng Nam', '0915000010', '1997-01-11');
SET @prof_khach10 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach11@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 46 DAY),
        DATE_SUB(NOW(6), INTERVAL 8 HOUR));
SET @acc_khach11 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach11, 'Bùi Thanh Thảo', '0915000011', '2001-06-18');
SET @prof_khach11 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach12@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 44 DAY),
        DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach12 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach12, 'Phan Văn Khánh', '0915000012', '1993-08-22');
SET @prof_khach12 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach13@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 43 DAY),
        DATE_SUB(NOW(6), INTERVAL 5 HOUR));
SET @acc_khach13 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach13, 'Đỗ Thị Kim Chi', '0915000013', '1998-03-10');
SET @prof_khach13 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach14@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 41 DAY),
        DATE_SUB(NOW(6), INTERVAL 9 HOUR));
SET @acc_khach14 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach14, 'Trương Công Minh', '0915000014', '1995-11-28');
SET @prof_khach14 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach15@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 40 DAY),
        DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach15 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach15, 'Hoàng Bảo Ngọc', '0915000015', '2000-09-05');
SET @prof_khach15 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach16@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 39 DAY),
        DATE_SUB(NOW(6), INTERVAL 14 HOUR));
SET @acc_khach16 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach16, 'Nguyễn Thanh Tùng', '0915000016', '1992-07-14');
SET @prof_khach16 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach17@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 38 DAY),
        DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach17 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach17, 'Lương Thị Thanh Mai', '0915000017', '1999-05-16');
SET @prof_khach17 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach18@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 36 DAY),
        DATE_SUB(NOW(6), INTERVAL 3 DAY));
SET @acc_khach18 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach18, 'Mai Xuân Trường', '0915000018', '1996-10-01');
SET @prof_khach18 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach19@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 35 DAY),
        DATE_SUB(NOW(6), INTERVAL 7 HOUR));
SET @acc_khach19 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach19, 'Tạ Thị Hồng Nhung', '0915000019', '2001-01-23');
SET @prof_khach19 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach20@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 33 DAY),
        DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach20 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach20, 'Vương Gia Huy', '0915000020', '1998-06-07');
SET @prof_khach20 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach21@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 31 DAY),
        DATE_SUB(NOW(6), INTERVAL 10 HOUR));
SET @acc_khach21 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach21, 'Châu Ngọc Bích', '0915000021', '2002-02-19');
SET @prof_khach21 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach22@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 29 DAY),
        DATE_SUB(NOW(6), INTERVAL 4 HOUR));
SET @acc_khach22 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach22, 'Lâm Đức Anh', '0915000022', '1994-12-27');
SET @prof_khach22 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach23@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 27 DAY),
        DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach23 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach23, 'Đoàn Thị Phương Thảo', '0915000023', '1997-04-12');
SET @prof_khach23 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach24@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 25 DAY),
        DATE_SUB(NOW(6), INTERVAL 3 DAY));
SET @acc_khach24 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach24, 'Kiều Minh Khoa', '0915000024', '1995-08-30');
SET @prof_khach24 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach25@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 24 DAY),
        DATE_SUB(NOW(6), INTERVAL 2 HOUR));
SET @acc_khach25 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach25, 'Hà Tuyết Nhi', '0915000025', '2000-11-11');
SET @prof_khach25 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach26@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 22 DAY),
        DATE_SUB(NOW(6), INTERVAL 5 DAY));
SET @acc_khach26 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach26, 'Cao Tấn Lộc', '0915000026', '1993-03-04');
SET @prof_khach26 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach27@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 37 DAY),
        DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach27 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach27, 'Phùng Thị Ánh Tuyết', '0915000027', '1998-07-08');
SET @prof_khach27 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach28@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 34 DAY),
        DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach28 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach28, 'Diệp Hoàng Long', '0915000028', '1996-09-14');
SET @prof_khach28 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach29@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 32 DAY),
        DATE_SUB(NOW(6), INTERVAL 4 DAY));
SET @acc_khach29 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach29, 'Từ Thị Thanh Hương', '0915000029', '1999-12-20');
SET @prof_khach29 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach30@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 20 DAY),
        DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach30 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach30, 'Tô Văn Hậu', '0915000030', '1997-02-02');
SET @prof_khach30 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach31@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 18 DAY),
        DATE_SUB(NOW(6), INTERVAL 12 HOUR));
SET @acc_khach31 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach31, 'Quách Mỹ Duyên', '0915000031', '2001-10-15');
SET @prof_khach31 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach32@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 16 DAY),
        DATE_SUB(NOW(6), INTERVAL 3 DAY));
SET @acc_khach32 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach32, 'Hồ Văn Hùng', '0915000032', '1992-10-08');
SET @prof_khach32 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach33@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 14 DAY),
        DATE_SUB(NOW(6), INTERVAL 1 DAY));
SET @acc_khach33 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach33, 'Dương Ngọc Ánh', '0915000033', '2002-03-27');
SET @prof_khach33 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach34@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 12 DAY),
        DATE_SUB(NOW(6), INTERVAL 6 HOUR));
SET @acc_khach34 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach34, 'Nghiêm Bảo Trân', '0915000034', '2001-08-19');
SET @prof_khach34 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach35@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 10 DAY),
        DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach35 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach35, 'La Minh Triết', '0915000035', '1999-04-06');
SET @prof_khach35 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach36@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 6 DAY), NULL);
SET @acc_khach36 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach36, 'Ngô Tấn Phát', '0915000036', '1998-05-02');
SET @prof_khach36 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach37@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 5 DAY), NULL);
SET @acc_khach37 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach37, 'Lưu Thị Cẩm Tú', '0915000037', '2003-01-13');
SET @prof_khach37 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach38@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 4 DAY),
        DATE_SUB(NOW(6), INTERVAL 2 DAY));
SET @acc_khach38 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach38, 'Bành Quốc Vinh', '0915000038', '2000-07-24');
SET @prof_khach38 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach39@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 3 DAY), NULL);
SET @acc_khach39 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach39, 'Trang Ngọc Hân', '0915000039', '2002-11-30');
SET @prof_khach39 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach40@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 1 DAY), NULL);
SET @acc_khach40 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach40, 'Tống Hải Đăng', '0915000040', '1997-06-15');
SET @prof_khach40 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach41@gmail.com', @pw_khach, 'CUSTOMER', 'BANNED', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 48 DAY),
        DATE_SUB(NOW(6), INTERVAL 15 DAY));
SET @acc_khach41 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach41, 'Lý Văn Khóa', '0915000041', '1991-11-22');
SET @prof_khach41 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach42@gmail.com', @pw_khach, 'CUSTOMER', 'BANNED', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 36 DAY),
        DATE_SUB(NOW(6), INTERVAL 10 DAY));
SET @acc_khach42 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach42, 'Mạc Văn Bom Hàng', '0915000042', '1995-03-19');
SET @prof_khach42 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach43@gmail.com', @pw_khach, 'CUSTOMER', 'BANNED', 1, NULL, NULL, DATE_SUB(NOW(6), INTERVAL 20 DAY), NULL);
SET @acc_khach43 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach43, 'Trịnh Thị Vi Phạm', '0915000043', '1996-08-14');
SET @prof_khach43 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach44@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 0, '849201', DATE_ADD(NOW(6), INTERVAL 24 HOUR),
        DATE_SUB(NOW(6), INTERVAL 1 DAY), NULL);
SET @acc_khach44 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach44, 'Vũ Đức Duy', '0915000044', '2003-09-09');
SET @prof_khach44 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach45@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 0, '371905', DATE_ADD(NOW(6), INTERVAL 5 MINUTE),
        DATE_SUB(NOW(6), INTERVAL 2 MINUTE), NULL);
SET @acc_khach45 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach45, 'Phạm Ngọc Huyền', '0915000045', '2002-05-18');
SET @prof_khach45 := LAST_INSERT_ID();
INSERT INTO account (email, password, role, status, email_verified, verification_code, verification_expiry, created_at,
                     last_login_at)
VALUES ('khach46@gmail.com', @pw_khach, 'CUSTOMER', 'ACTIVE', 0, '604812', DATE_SUB(NOW(6), INTERVAL 1 HOUR),
        DATE_SUB(NOW(6), INTERVAL 2 HOUR), NULL);
SET @acc_khach46 := LAST_INSERT_ID();
INSERT INTO user_profile (account_id, full_name, phone_number, birth_date)
VALUES (@acc_khach46, 'Trần Gia Bảo', '0915000046', '2001-12-11');
SET @prof_khach46 := LAST_INSERT_ID();

-- Địa chỉ giao hàng mẫu (nhóm E tài khoản trống và khach43..khach46 không có địa chỉ)
INSERT INTO shipping_address (user_profile_id, address, default_address)
VALUES (@prof_khach5, '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 1),
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

INSERT INTO category (name, status)
VALUES ('Áo polo', 'VISIBLE');
SET @cat_polo := LAST_INSERT_ID();
INSERT INTO category (name, status)
VALUES ('Áo vest', 'VISIBLE');
SET @cat_vest := LAST_INSERT_ID();
INSERT INTO category (name, status)
VALUES ('Áo cardigan', 'VISIBLE');
SET @cat_cardigan := LAST_INSERT_ID();
INSERT INTO category (name, status)
VALUES ('Đồ thể thao', 'VISIBLE');
SET @cat_thethao := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_polo, 'Áo Polo Nam Dệt Kim Xanh Rêu',
        'Áo polo nam chất liệu cotton dệt kim thoáng khí, form regular lịch sự phù hợp công sở và dạo phố.', 480000.00,
        420000.00, 'MALE', 'ACTIVE', 'https://lados.vn/wp-content/uploads/2024/10/2-xanhreu-ld9187-1400x1400.webp',
        DATE_SUB(NOW(6), INTERVAL 40 DAY));
SET @prod_polo_reu := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_polo_reu, 'https://lados.vn/wp-content/uploads/2024/10/2-xanhreu-ld9187-1400x1400.webp', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_polo_reu, 'M', 'Xanh rêu', 'PLO-REU-M', 25, 'ACTIVE', 0);
SET @var_plo_reu_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_polo_reu, 'L', 'Xanh rêu', 'PLO-REU-L', 18, 'ACTIVE', 0);
SET @var_plo_reu_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_polo_reu, 'XL', 'Xanh rêu', 'PLO-REU-XL', 4, 'ACTIVE', 0);
SET @var_plo_reu_xl := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_polo, 'Áo Polo Nữ Cổ Phối Trắng Kem',
        'Áo polo nữ cổ bẻ phối viền thanh lịch, chất liệu pique co giãn nhẹ thấm hút mồ hôi tốt.', 450000.00, NULL,
        'FEMALE', 'ACTIVE', 'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 39 DAY));
SET @prod_polo_kem := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_polo_kem, 'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=800&auto=format&fit=crop', 1,
        0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_polo_kem, 'S', 'Kem', 'PLO-KEM-S', 15, 'ACTIVE', 0);
SET @var_plo_kem_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_polo_kem, 'M', 'Kem', 'PLO-KEM-M', 20, 'ACTIVE', 0);
SET @var_plo_kem_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_dam, 'Đầm Sơ Mi Lụa Pastel Tay Bồng',
        'Đầm sơ mi dáng chữ A kèm đai eo vải, chất lụa tơ mềm rủ tôn dáng dịu dàng.', 1290000.00, 1090000.00, 'FEMALE',
        'ACTIVE', 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 38 DAY));
SET @prod_dam_pas := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_dam_pas, 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_dam_pas, 'S', 'Hồng pastel', 'DAM-PAS-S', 10, 'ACTIVE', 0);
SET @var_dam_pas_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_dam_pas, 'M', 'Hồng pastel', 'DAM-PAS-M', 12, 'ACTIVE', 0);
SET @var_dam_pas_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_dam_pas, 'L', 'Hồng pastel', 'DAM-PAS-L', 0, 'INACTIVE', 0);
SET @var_dam_pas_l := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_dam, 'Đầm Dự Tiệc Satin Đỏ Đô',
        'Đầm dự tiệc dài qua gối bằng lụa satin cao cấp, xẻ tà tinh tế tạo vẻ sang trọng.', 1890000.00, NULL, 'FEMALE',
        'ACTIVE', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 37 DAY));
SET @prod_dam_do := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_dam_do, 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_dam_do, 'S', 'Đỏ đô', 'DAM-DO-S', 6, 'ACTIVE', 0);
SET @var_dam_do_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_dam_do, 'M', 'Đỏ đô', 'DAM-DO-M', 8, 'ACTIVE', 0);
SET @var_dam_do_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_somi, 'Áo Sơ Mi Oxford Nam Xanh Biển',
        'Áo sơ mi dài tay vải Oxford dệt dày dặn, ít nhăn, đường may chuẩn form công sở.', 620000.00, 540000.00, 'MALE',
        'ACTIVE', 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 36 DAY));
SET @prod_sm_oxf := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_sm_oxf, 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_sm_oxf, 'M', 'Xanh biển', 'SM-OXF-M', 22, 'ACTIVE', 0);
SET @var_sm_oxf_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_sm_oxf, 'L', 'Xanh biển', 'SM-OXF-L', 16, 'ACTIVE', 0);
SET @var_sm_oxf_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_sm_oxf, 'XL', 'Xanh biển', 'SM-OXF-XL', 9, 'ACTIVE', 0);
SET @var_sm_oxf_xl := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_quan, 'Quần Culottes Ống Rộng Trắng Kem',
        'Quần culottes cạp cao khóa kéo bên hông, hack dáng chân dài, vải tuyết mưa đứng phom.', 720000.00, NULL,
        'FEMALE', 'ACTIVE', 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 35 DAY));
SET @prod_qn_cul := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_qn_cul, 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_qn_cul, 'S', 'Trắng kem', 'QN-CUL-S', 14, 'ACTIVE', 0);
SET @var_qn_cul_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_qn_cul, 'M', 'Trắng kem', 'QN-CUL-M', 17, 'ACTIVE', 0);
SET @var_qn_cul_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_quan, 'Quần Jogger Nỉ Unisex Xám Tiêu',
        'Quần jogger bo gấu cạp chun dây rút, chất nỉ da cá 350gsm mềm mịn không xù lông.', 550000.00, 490000.00,
        'UNISEX', 'ACTIVE', 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 34 DAY));
SET @prod_qn_jog := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_qn_jog, 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_qn_jog, 'M', 'Xám tiêu', 'QN-JOG-M', 20, 'ACTIVE', 0);
SET @var_qn_jog_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_qn_jog, 'L', 'Xám tiêu', 'QN-JOG-L', 3, 'ACTIVE', 0);
SET @var_qn_jog_l := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_khoac, 'Áo Khoác Blazer Nữ Đen Cổ Vest',
        'Blazer nữ 2 lớp lót lụa mịn, đệm vai nhẹ chuẩn dáng thanh lịch cho nàng công sở.', 1450000.00, 1250000.00,
        'FEMALE', 'ACTIVE', 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 33 DAY));
SET @prod_ak_blz := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_ak_blz, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_ak_blz, 'S', 'Đen', 'AK-BLZ-S', 9, 'ACTIVE', 0);
SET @var_ak_blz_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_ak_blz, 'M', 'Đen', 'AK-BLZ-M', 11, 'ACTIVE', 0);
SET @var_ak_blz_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_thun, 'Áo Thun Thể Thao Dry-Fit Đen',
        'Áo thun thể thao vải mè thoáng khí siêu nhẹ, khô nhanh khi vận động cường độ cao.', 360000.00, 310000.00,
        'UNISEX', 'ACTIVE', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 32 DAY));
SET @prod_at_gym := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_at_gym, 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_at_gym, 'M', 'Đen', 'AT-GYM-M', 30, 'ACTIVE', 0);
SET @var_at_gym_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_at_gym, 'L', 'Đen', 'AT-GYM-L', 25, 'ACTIVE', 0);
SET @var_at_gym_l := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_at_gym, 'XL', 'Đen', 'AT-GYM-XL', 12, 'ACTIVE', 0);
SET @var_at_gym_xl := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_len, 'Áo Len Gile Cổ Tim Kem Sữa',
        'Áo len gile dệt thừng phong cách Hàn Quốc, dễ phối cùng áo sơ mi hoặc áo thun dài tay.', 590000.00, NULL,
        'FEMALE', 'ACTIVE', 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 31 DAY));
SET @prod_al_gil := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_al_gil, 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_al_gil, 'S', 'Kem sữa', 'AL-GIL-S', 13, 'ACTIVE', 0);
SET @var_al_gil_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_al_gil, 'M', 'Kem sữa', 'AL-GIL-M', 16, 'ACTIVE', 0);
SET @var_al_gil_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_vest, 'Áo Vest Nam Công Sở Slimfit Đen',
        'Áo vest nam 2 khuy form slimfit hiện đại, vải tuýt si đứng dáng ít nhăn phù hợp đi làm và dự tiệc.', 980000.00,
        850000.00, 'MALE', 'ACTIVE',
        'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 30 DAY));
SET @prod_vs_den := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_vs_den, 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_vs_den, 'M', 'Đen', 'VS-DEN-M', 14, 'ACTIVE', 0);
SET @var_vs_den_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_vs_den, 'L', 'Xám than', 'VS-XAM-L', 7, 'ACTIVE', 0);
SET @var_vs_xam_l := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_cardigan, 'Áo Cardigan Len Mỏng Cổ Chữ V',
        'Áo khoác cardigan len dệt mịn nhẹ thoáng, cài khuy trước dễ phối cùng sơ mi hoặc áo thun.', 420000.00, NULL,
        'UNISEX', 'ACTIVE', 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 29 DAY));
SET @prod_cd_len := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_cd_len, 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_cd_len, 'M', 'Nâu kem', 'CD-KEM-M', 20, 'ACTIVE', 0);
SET @var_cd_kem_m := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_cd_len, 'L', 'Đen', 'CD-DEN-L', 18, 'ACTIVE', 0);
SET @var_cd_den_l := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_thethao, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều',
        'Set áo croptop bra kèm quần legging cạp cao nâng dáng, vải poly-spandex co giãn 4 chiều.', 680000.00,
        590000.00, 'FEMALE', 'ACTIVE',
        'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 28 DAY));
SET @prod_tt_gym := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_tt_gym, 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_tt_gym, 'S', 'Xám khói', 'TT-GYM-S', 15, 'ACTIVE', 0);
SET @var_tt_gym_s := LAST_INSERT_ID();
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_tt_gym, 'M', 'Xám khói', 'TT-GYM-M', 0, 'ACTIVE', 0);
SET @var_tt_gym_m := LAST_INSERT_ID();

INSERT INTO product (category_id, name, description, price, sale_price, gender, status, image_url, created_at)
VALUES (@cat_hoodie, 'Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán)',
        'Áo hoodie nỉ bông dày dặn giữ ấm mùa đông, hiện đang tạm ngừng kinh doanh.', 650000.00, NULL, 'UNISEX',
        'INACTIVE', 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800&auto=format&fit=crop',
        DATE_SUB(NOW(6), INTERVAL 50 DAY));
SET @prod_hd_xam := LAST_INSERT_ID();
INSERT INTO product_image (product_id, image_url, is_thumbnail, display_order)
VALUES (@prod_hd_xam, 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800&auto=format&fit=crop', 1, 0);
INSERT INTO product_variant (product_id, size, color, sku, stock_quantity, status, version)
VALUES (@prod_hd_xam, 'L', 'Xám', 'HD-XAM-L', 5, 'ACTIVE', 0);
SET @var_hd_xam_l := LAST_INSERT_ID();

-- ============================================================================
-- MỤC 3: MÃ GIẢM GIÁ MỚI (6 mã - used_count khớp chính xác số đơn không hủy)
-- ============================================================================
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count,
                    start_date, end_date, status)
VALUES ('WELCOME15', 'Giảm 15% cho khách hàng mới (tối đa 150K)', 'PERCENT', 15.00, 150000.00, 400000.00, 200, 6,
        DATE_SUB(NOW(6), INTERVAL 60 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE');
SET @cp_welcome15 := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count,
                    start_date, end_date, status)
VALUES ('FREESHIP30', 'Hỗ trợ phí vận chuyển 30K', 'FIXED_AMOUNT', 30000.00, NULL, 300000.00, 300, 5,
        DATE_SUB(NOW(6), INTERVAL 60 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE');
SET @cp_freeship30 := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count,
                    start_date, end_date, status)
VALUES ('VIP200K', 'Ưu đãi đơn cao cấp giảm 200K', 'FIXED_AMOUNT', 200000.00, NULL, 1500000.00, 150, 6,
        DATE_SUB(NOW(6), INTERVAL 45 DAY), DATE_ADD(NOW(6), INTERVAL 45 DAY), 'ACTIVE');
SET @cp_vip200k := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count,
                    start_date, end_date, status)
VALUES ('SALETET20', 'Siêu sale giảm 20% tối đa 300K', 'PERCENT', 20.00, 300000.00, 800000.00, 150, 5,
        DATE_SUB(NOW(6), INTERVAL 45 DAY), DATE_ADD(NOW(6), INTERVAL 30 DAY), 'ACTIVE');
SET @cp_saletet20 := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count,
                    start_date, end_date, status)
VALUES ('THANGVANG', 'Tháng vàng mua sắm giảm ngay 100K', 'FIXED_AMOUNT', 100000.00, NULL, 700000.00, 150, 6,
        DATE_SUB(NOW(6), INTERVAL 35 DAY), DATE_ADD(NOW(6), INTERVAL 30 DAY), 'ACTIVE');
SET @cp_thangvang := LAST_INSERT_ID();
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count,
                    start_date, end_date, status)
VALUES ('NOEL2025', 'Giảm 25% mùa Giáng Sinh (Đã hết hạn)', 'PERCENT', 25.00, 250000.00, 500000.00, 40, 0,
        '2025-12-20 00:00:00', '2025-12-31 23:59:59', 'INACTIVE');
SET @cp_noel2025 := LAST_INSERT_ID();

-- ============================================================================
-- MỤC 4: ĐƠN HÀNG & CHI TIẾT ĐƠN HÀNG (50 đơn: 20 tháng trước + 30 tháng này)
-- ============================================================================

-- FS2026F701 | COMPLETED | BANK_TRANSFER + PAID | total=2,540,000
SET @t_f701 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 27 DAY), '09:15:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F701', @prof_khach5, @cp_vip200k, 'COMPLETED', 2740000.00, 200000.00, 2540000.00, 'Nguyễn Ngọc Lan',
        '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f701, INTERVAL 3 MINUTE), @t_f701, DATE_ADD(@t_f701, INTERVAL 2 DAY));
SET @ord_f701 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f701, @var_dam_do_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đỏ đô', 1890000.00, 1),
       (@ord_f701, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1);

-- FS2026F702 | COMPLETED | COD + PAID | total=1,008,000
SET @t_f702 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 26 DAY), '14:20:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F702', @prof_khach6, @cp_saletet20, 'COMPLETED', 1260000.00, 252000.00, 1008000.00, 'Trần Minh Tuấn',
        '0915000006', '88 Lê Lợi, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'COD', 'PAID',
        DATE_ADD(@t_f702, INTERVAL 2 DAY), @t_f702, DATE_ADD(@t_f702, INTERVAL 2 DAY));
SET @ord_f702 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f702, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 2),
       (@ord_f702, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS2026F703 | COMPLETED | E_WALLET + PAID | total=990,000
SET @t_f703 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 25 DAY), '19:45:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F703', @prof_khach7, @cp_thangvang, 'COMPLETED', 1090000.00, 100000.00, 990000.00, 'Lê Thị Thu Hà',
        '0915000007', '215 Cầu Giấy, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f703, INTERVAL 3 MINUTE), @t_f703, DATE_ADD(@t_f703, INTERVAL 2 DAY));
SET @ord_f703 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f703, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1);

-- FS2026F704 | COMPLETED | COD + PAID | total=752,500
SET @t_f704 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 24 DAY), '10:30:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F704', @prof_khach8, @cp_welcome15, 'COMPLETED', 850000.00, 127500.00, 752500.00, 'Phạm Quốc Bảo',
        '0915000008', '14 Phan Văn Trị, Phường 7, Quận Gò Vấp, TP.HCM', 30000.00, NULL, 'COD', 'PAID',
        DATE_ADD(@t_f704, INTERVAL 2 DAY), @t_f704, DATE_ADD(@t_f704, INTERVAL 2 DAY));
SET @ord_f704 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f704, @var_sm_oxf_l, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'L', 'Xanh biển', 540000.00, 1),
       (@ord_f704, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 1);

-- FS2026F705 | COMPLETED | BANK_TRANSFER + PAID | total=1,770,000
SET @t_f705 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 22 DAY), '16:10:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F705', @prof_khach9, @cp_vip200k, 'COMPLETED', 1970000.00, 200000.00, 1770000.00, 'Võ Thị Mỹ Linh',
        '0915000009', '302 Cách Mạng Tháng 8, Phường 10, Quận 3, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f705, INTERVAL 3 MINUTE), @t_f705, DATE_ADD(@t_f705, INTERVAL 2 DAY));
SET @ord_f705 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f705, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1),
       (@ord_f705, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1);

-- FS2026F706 | COMPLETED | E_WALLET + PAID | total=1,080,000
SET @t_f706 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 21 DAY), '11:05:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F706', @prof_khach10, NULL, 'COMPLETED', 1080000.00, 0.00, 1080000.00, 'Đặng Hoàng Nam', '0915000010',
        '56 Nguyễn Văn Linh, Phường Tân Thuận Tây, Quận 7, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f706, INTERVAL 3 MINUTE), @t_f706, DATE_ADD(@t_f706, INTERVAL 2 DAY));
SET @ord_f706 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f706, @var_tt_gym_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Xám khói', 590000.00, 1),
       (@ord_f706, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS2026F707 | COMPLETED | COD + PAID | total=940,000
SET @t_f707 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 20 DAY), '20:15:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F707', @prof_khach11, @cp_thangvang, 'COMPLETED', 1040000.00, 100000.00, 940000.00, 'Bùi Thanh Thảo',
        '0915000011', '79 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'COD', 'PAID',
        DATE_ADD(@t_f707, INTERVAL 2 DAY), @t_f707, DATE_ADD(@t_f707, INTERVAL 2 DAY));
SET @ord_f707 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f707, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1),
       (@ord_f707, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 1);

-- FS2026F708 | COMPLETED | COD + PAID | total=1,590,000
SET @t_f708 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 18 DAY), '13:40:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F708', @prof_khach41, NULL, 'COMPLETED', 1590000.00, 0.00, 1590000.00, 'Lý Văn Khóa', '0915000041',
        '99 Tô Hiến Thành, Phường 13, Quận 10, TP.HCM', 0.00, NULL, 'COD', 'PAID', DATE_ADD(@t_f708, INTERVAL 2 DAY),
        @t_f708, DATE_ADD(@t_f708, INTERVAL 2 DAY));
SET @ord_f708 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f708, @var_dam_lua_be_s, 'Đầm lụa dáng dài màu be', 'S', 'Be', 1590000.00, 1);

-- FS2026F709 | COMPLETED | BANK_TRANSFER + PAID | total=850,000
SET @t_f709 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 17 DAY), '15:25:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F709', @prof_khach12, @cp_freeship30, 'COMPLETED', 850000.00, 30000.00, 850000.00, 'Phan Văn Khánh',
        '0915000012', '240 Điện Biên Phủ, Phường 17, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f709, INTERVAL 3 MINUTE), @t_f709, DATE_ADD(@t_f709, INTERVAL 2 DAY));
SET @ord_f709 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f709, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1);

-- FS2026F710 | CANCELLED | COD + UNPAID | total=570,000
SET @t_f710 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 16 DAY), '17:50:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F710', @prof_khach6, NULL, 'CANCELLED', 540000.00, 0.00, 570000.00, 'Trần Minh Tuấn', '0915000006',
        '88 Lê Lợi, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f710,
        'Khách muốn đổi sang size lớn hơn', DATE_ADD(@t_f710, INTERVAL 3 HOUR));
SET @ord_f710 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f710, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1);

-- FS2026F711 | COMPLETED | E_WALLET + PAID | total=872,000
SET @t_f711 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 14 DAY), '10:00:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F711', @prof_khach13, @cp_saletet20, 'COMPLETED', 1090000.00, 218000.00, 872000.00, 'Đỗ Thị Kim Chi',
        '0915000013', '64 Nguyễn Trãi, Phường Thượng Đình, Quận Thanh Xuân, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f711, INTERVAL 3 MINUTE), @t_f711, DATE_ADD(@t_f711, INTERVAL 2 DAY));
SET @ord_f711 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f711, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1);

-- FS2026F712 | COMPLETED | BANK_TRANSFER + PAID | total=752,500
SET @t_f712 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 12 DAY), '14:15:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F712', @prof_khach14, @cp_welcome15, 'COMPLETED', 850000.00, 127500.00, 752500.00, 'Trương Công Minh',
        '0915000014', '112 Trần Phú, Phường Lộc Thọ, TP. Nha Trang, Khánh Hòa', 30000.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f712, INTERVAL 3 MINUTE), @t_f712, DATE_ADD(@t_f712, INTERVAL 2 DAY));
SET @ord_f712 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f712, @var_sm_oxf_xl, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'XL', 'Xanh biển', 540000.00, 1),
       (@ord_f712, @var_at_gym_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Đen', 310000.00, 1);

-- FS2026F713 | COMPLETED | COD + PAID | total=900,000
SET @t_f713 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 11 DAY), '09:40:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F713', @prof_khach15, @cp_freeship30, 'COMPLETED', 900000.00, 30000.00, 900000.00, 'Hoàng Bảo Ngọc',
        '0915000015', '50 Lý Tự Trọng, Phường An Cư, Quận Ninh Kiều, Cần Thơ', 30000.00, NULL, 'COD', 'PAID',
        DATE_ADD(@t_f713, INTERVAL 2 DAY), @t_f713, DATE_ADD(@t_f713, INTERVAL 2 DAY));
SET @ord_f713 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f713, @var_plo_kem_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Kem', 450000.00, 2);

-- FS2026F714 | COMPLETED | E_WALLET + PAID | total=1,690,000
SET @t_f714 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 9 DAY), '18:30:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F714', @prof_khach16, @cp_vip200k, 'COMPLETED', 1890000.00, 200000.00, 1690000.00, 'Nguyễn Thanh Tùng',
        '0915000016', '18 Nguyễn Thị Minh Khai, Phường Đa Kao, Quận 1, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f714, INTERVAL 3 MINUTE), @t_f714, DATE_ADD(@t_f714, INTERVAL 2 DAY));
SET @ord_f714 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f714, @var_dam_do_s, 'Đầm Dự Tiệc Satin Đỏ Đô', 'S', 'Đỏ đô', 1890000.00, 1);

-- FS2026F715 | COMPLETED | BANK_TRANSFER + PAID | total=1,210,000
SET @t_f715 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 8 DAY), '15:05:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F715', @prof_khach17, @cp_thangvang, 'COMPLETED', 1310000.00, 100000.00, 1210000.00,
        'Lương Thị Thanh Mai', '0915000017', '75 Hoàng Diệu, Phường Nam Dương, Quận Hải Châu, Đà Nẵng', 0.00, NULL,
        'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f715, INTERVAL 3 MINUTE), @t_f715, DATE_ADD(@t_f715, INTERVAL 2 DAY));
SET @ord_f715 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f715, @var_qn_cul_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Trắng kem', 720000.00, 1),
       (@ord_f715, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1);

-- FS2026F716 | COMPLETED | COD + PAID | total=760,000
SET @t_f716 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 7 DAY), '12:20:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F716', @prof_khach18, NULL, 'COMPLETED', 730000.00, 0.00, 760000.00, 'Mai Xuân Trường', '0915000018',
        '27 Lê Văn Sỹ, Phường 13, Quận Phú Nhuận, TP.HCM', 30000.00, NULL, 'COD', 'PAID',
        DATE_ADD(@t_f716, INTERVAL 2 DAY), @t_f716, DATE_ADD(@t_f716, INTERVAL 2 DAY));
SET @ord_f716 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f716, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1),
       (@ord_f716, @var_at_gym_xl, 'Áo Thun Thể Thao Dry-Fit Đen', 'XL', 'Đen', 310000.00, 1);

-- FS2026F717 | COMPLETED | BANK_TRANSFER + PAID | total=1,250,000
SET @t_f717 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 5 DAY), '16:45:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F717', @prof_khach27, NULL, 'COMPLETED', 1250000.00, 0.00, 1250000.00, 'Phùng Thị Ánh Tuyết',
        '0915000027', '142 Lạc Long Quân, Phường 3, Quận 11, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f717, INTERVAL 3 MINUTE), @t_f717, DATE_ADD(@t_f717, INTERVAL 2 DAY));
SET @ord_f717 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f717, @var_ak_blz_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Đen', 1250000.00, 1);

-- FS2026F718 | CANCELLED | COD + UNPAID | total=450,000
SET @t_f718 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 4 DAY), '11:10:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F718', @prof_khach29, NULL, 'CANCELLED', 420000.00, 0.00, 450000.00, 'Từ Thị Thanh Hương', '0915000029',
        '81 Kim Mã, Phường Kim Mã, Quận Ba Đình, Hà Nội', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f718,
        'Khách đặt nhầm màu sắc', DATE_ADD(@t_f718, INTERVAL 3 HOUR));
SET @ord_f718 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f718, @var_plo_reu_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Xanh rêu', 420000.00, 1);

-- FS2026F719 | CANCELLED | COD + UNPAID | total=520,000
SET @t_f719 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 2 DAY), '19:00:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F719', @prof_khach42, NULL, 'CANCELLED', 490000.00, 0.00, 520000.00, 'Mạc Văn Bom Hàng', '0915000042',
        '205 Âu Cơ, Phường 5, Quận 11, TP.HCM', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f719,
        'Không liên hệ được người nhận khi giao', DATE_ADD(@t_f719, INTERVAL 3 HOUR));
SET @ord_f719 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f719, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS2026F720 | CANCELLED | BANK_TRANSFER + FAILED | total=620,000
SET @t_f720 := TIMESTAMP(DATE_SUB(@prev_m_last_day, INTERVAL 1 DAY), '21:15:00');
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F720', @prof_khach28, NULL, 'CANCELLED', 590000.00, 0.00, 620000.00, 'Diệp Hoàng Long', '0915000028',
        '58 Xô Viết Nghệ Tĩnh, Phường 19, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'BANK_TRANSFER', 'FAILED', NULL,
        @t_f720, 'Thanh toán chuyển khoản quá hạn', DATE_ADD(@t_f720, INTERVAL 3 HOUR));
SET @ord_f720 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f720, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1);

-- FS2026F721 | COMPLETED | BANK_TRANSFER + PAID | total=2,840,000
SET @t_f721 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.03) SECOND);
SET @c_f721 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.06) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F721', @prof_khach5, @cp_saletet20, 'COMPLETED', 3140000.00, 300000.00, 2840000.00, 'Nguyễn Ngọc Lan',
        '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f721, INTERVAL 2 MINUTE), @t_f721, @c_f721);
SET @ord_f721 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f721, @var_dam_do_s, 'Đầm Dự Tiệc Satin Đỏ Đô', 'S', 'Đỏ đô', 1890000.00, 1),
       (@ord_f721, @var_ak_blz_s, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'S', 'Đen', 1250000.00, 1);

-- FS2026F722 | COMPLETED | E_WALLET + PAID | total=1,420,000
SET @t_f722 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.06) SECOND);
SET @c_f722 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.09) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F722', @prof_khach7, @cp_vip200k, 'COMPLETED', 1620000.00, 200000.00, 1420000.00, 'Lê Thị Thu Hà',
        '0915000007', '215 Cầu Giấy, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f722, INTERVAL 2 MINUTE), @t_f722, @c_f722);
SET @ord_f722 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f722, @var_plo_kem_m, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'M', 'Kem', 450000.00, 2),
       (@ord_f722, @var_qn_cul_m, 'Quần Culottes Ống Rộng Trắng Kem', 'M', 'Trắng kem', 720000.00, 1);

-- FS2026F723 | COMPLETED | COD + PAID | total=1,110,000
SET @t_f723 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.09) SECOND);
SET @c_f723 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.12) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F723', @prof_khach8, @cp_welcome15, 'COMPLETED', 1260000.00, 150000.00, 1110000.00, 'Phạm Quốc Bảo',
        '0915000008', '14 Phan Văn Trị, Phường 7, Quận Gò Vấp, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_f723, @t_f723,
        @c_f723);
SET @ord_f723 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f723, @var_plo_reu_l, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'L', 'Xanh rêu', 420000.00, 2),
       (@ord_f723, @var_cd_den_l, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'L', 'Đen', 420000.00, 1);

-- FS2026F724 | COMPLETED | BANK_TRANSFER + PAID | total=1,580,000
SET @t_f724 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.12) SECOND);
SET @c_f724 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.15) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F724', @prof_khach9, @cp_thangvang, 'COMPLETED', 1680000.00, 100000.00, 1580000.00, 'Võ Thị Mỹ Linh',
        '0915000009', '302 Cách Mạng Tháng 8, Phường 10, Quận 3, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f724, INTERVAL 2 MINUTE), @t_f724, @c_f724);
SET @ord_f724 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f724, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1),
       (@ord_f724, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1);

-- FS2026F725 | COMPLETED | E_WALLET + PAID | total=1,110,000
SET @t_f725 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.15) SECOND);
SET @c_f725 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.18) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F725', @prof_khach10, NULL, 'COMPLETED', 1110000.00, 0.00, 1110000.00, 'Đặng Hoàng Nam', '0915000010',
        '56 Nguyễn Văn Linh, Phường Tân Thuận Tây, Quận 7, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f725, INTERVAL 2 MINUTE), @t_f725, @c_f725);
SET @ord_f725 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f725, @var_at_gym_l, 'Áo Thun Thể Thao Dry-Fit Đen', 'L', 'Đen', 310000.00, 2),
       (@ord_f725, @var_qn_jog_l, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'L', 'Xám tiêu', 490000.00, 1);

-- FS2026F726 | COMPLETED | BANK_TRANSFER + PAID | total=984,000
SET @t_f726 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.19) SECOND);
SET @c_f726 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.22) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F726', @prof_khach6, @cp_saletet20, 'COMPLETED', 1230000.00, 246000.00, 984000.00, 'Trần Minh Tuấn',
        '0915000006', '88 Lê Lợi, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f726, INTERVAL 2 MINUTE), @t_f726, @c_f726);
SET @ord_f726 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f726, @var_sm_linen_tr_m, 'Áo sơ mi linen trắng tối giản', 'M', 'Trắng', 690000.00, 1),
       (@ord_f726, @var_sm_oxf_xl, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'XL', 'Xanh biển', 540000.00, 1);

-- FS2026F727 | COMPLETED | COD + PAID | total=1,440,000
SET @t_f727 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.22) SECOND);
SET @c_f727 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.25) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F727', @prof_khach11, @cp_vip200k, 'COMPLETED', 1640000.00, 200000.00, 1440000.00, 'Bùi Thanh Thảo',
        '0915000011', '79 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM', 0.00, NULL, 'COD', 'PAID', @c_f727, @t_f727,
        @c_f727);
SET @ord_f727 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f727, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1),
       (@ord_f727, @var_cv_xeply_m, 'Chân váy midi xếp ly màu kem', 'M', 'Kem', 790000.00, 1);

-- FS2026F728 | COMPLETED | E_WALLET + PAID | total=1,180,000
SET @t_f728 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.25) SECOND);
SET @c_f728 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.28) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F728', @prof_khach1, NULL, 'COMPLETED', 1180000.00, 0.00, 1180000.00, 'Lê Văn Khách', '0902000001',
        '12 Nguyễn Văn Bảo, Gò Vấp, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID', DATE_ADD(@t_f728, INTERVAL 2 MINUTE),
        @t_f728, @c_f728);
SET @ord_f728 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f728, @var_at_basic_tr_l, 'Áo thun cotton basic cổ tròn màu trắng', 'L', 'Trắng', 290000.00, 3),
       (@ord_f728, @var_at_gym_xl, 'Áo Thun Thể Thao Dry-Fit Đen', 'XL', 'Đen', 310000.00, 1);

-- FS2026F729 | COMPLETED | BANK_TRANSFER + PAID | total=2,440,000
SET @t_f729 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.29) SECOND);
SET @c_f729 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.32) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F729', @prof_khach2, NULL, 'COMPLETED', 2440000.00, 0.00, 2440000.00, 'Phạm Thị Mai', '0902000002',
        '85 Lê Lợi, Quận 1, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID', DATE_ADD(@t_f729, INTERVAL 2 MINUTE), @t_f729,
        @c_f729);
SET @ord_f729 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f729, @var_dam_lua_be_s, 'Đầm lụa dáng dài màu be', 'S', 'Be', 1590000.00, 1),
       (@ord_f729, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1);

-- FS2026F730 | COMPLETED | E_WALLET + PAID | total=590,000
SET @t_f730 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.32) SECOND);
SET @c_f730 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.35) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F730', @prof_khach5, @cp_freeship30, 'COMPLETED', 590000.00, 30000.00, 590000.00, 'Nguyễn Ngọc Lan',
        '0915000005', '120 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM', 30000.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f730, INTERVAL 2 MINUTE), @t_f730, @c_f730);
SET @ord_f730 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f730, @var_tt_gym_m, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'M', 'Xám khói', 590000.00, 1);

-- FS2026F731 | COMPLETED | COD + PAID | total=744,000
SET @t_f731 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.36) SECOND);
SET @c_f731 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.39) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F731', @prof_khach12, @cp_welcome15, 'COMPLETED', 840000.00, 126000.00, 744000.00, 'Phan Văn Khánh',
        '0915000012', '240 Điện Biên Phủ, Phường 17, Quận Bình Thạnh, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_f731,
        @t_f731, @c_f731);
SET @ord_f731 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f731, @var_plo_reu_m, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'M', 'Xanh rêu', 420000.00, 2);

-- FS2026F732 | COMPLETED | BANK_TRANSFER + PAID | total=1,070,000
SET @t_f732 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.39) SECOND);
SET @c_f732 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.42) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F732', @prof_khach13, @cp_thangvang, 'COMPLETED', 1170000.00, 100000.00, 1070000.00, 'Đỗ Thị Kim Chi',
        '0915000013', '64 Nguyễn Trãi, Phường Thượng Đình, Quận Thanh Xuân, Hà Nội', 0.00, NULL, 'BANK_TRANSFER',
        'PAID', DATE_ADD(@t_f732, INTERVAL 2 MINUTE), @t_f732, @c_f732);
SET @ord_f732 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f732, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1),
       (@ord_f732, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 1);

-- FS2026F733 | COMPLETED | E_WALLET + PAID | total=1,080,000
SET @t_f733 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.43) SECOND);
SET @c_f733 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.46) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F733', @prof_khach14, NULL, 'COMPLETED', 1080000.00, 0.00, 1080000.00, 'Trương Công Minh', '0915000014',
        '112 Trần Phú, Phường Lộc Thọ, TP. Nha Trang, Khánh Hòa', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f733, INTERVAL 2 MINUTE), @t_f733, @c_f733);
SET @ord_f733 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f733, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 2);

-- FS2026F734 | COMPLETED | BANK_TRANSFER + PAID | total=1,690,000
SET @t_f734 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.46) SECOND);
SET @c_f734 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.49) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F734', @prof_khach15, @cp_vip200k, 'COMPLETED', 1890000.00, 200000.00, 1690000.00, 'Hoàng Bảo Ngọc',
        '0915000015', '50 Lý Tự Trọng, Phường An Cư, Quận Ninh Kiều, Cần Thơ', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f734, INTERVAL 2 MINUTE), @t_f734, @c_f734);
SET @ord_f734 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f734, @var_dam_do_m, 'Đầm Dự Tiệc Satin Đỏ Đô', 'M', 'Đỏ đô', 1890000.00, 1);

-- FS2026F735 | COMPLETED | COD + PAID | total=840,000
SET @t_f735 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.5) SECOND);
SET @c_f735 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.53) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F735', @prof_khach16, @cp_freeship30, 'COMPLETED', 840000.00, 30000.00, 840000.00, 'Nguyễn Thanh Tùng',
        '0915000016', '18 Nguyễn Thị Minh Khai, Phường Đa Kao, Quận 1, TP.HCM', 30000.00, NULL, 'COD', 'PAID', @c_f735,
        @t_f735, @c_f735);
SET @ord_f735 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f735, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 2);

-- FS2026F736 | COMPLETED | E_WALLET + PAID | total=872,000
SET @t_f736 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.54) SECOND);
SET @c_f736 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.57) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F736', @prof_khach19, @cp_saletet20, 'COMPLETED', 1090000.00, 218000.00, 872000.00, 'Tạ Thị Hồng Nhung',
        '0915000019', '190 Quang Trung, Phường 10, Quận Gò Vấp, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f736, INTERVAL 2 MINUTE), @t_f736, @c_f736);
SET @ord_f736 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f736, @var_dam_pas_s, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'S', 'Hồng pastel', 1090000.00, 1);

-- FS2026F737 | COMPLETED | COD + PAID | total=880,000
SET @t_f737 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.58) SECOND);
SET @c_f737 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.61) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F737', @prof_khach20, @cp_welcome15, 'COMPLETED', 1030000.00, 150000.00, 880000.00, 'Vương Gia Huy',
        '0915000020', '41 Bà Triệu, Phường Hàng Bài, Quận Hoàn Kiếm, Hà Nội', 0.00, NULL, 'COD', 'PAID', @c_f737,
        @t_f737, @c_f737);
SET @ord_f737 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f737, @var_sm_oxf_l, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'L', 'Xanh biển', 540000.00, 1),
       (@ord_f737, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS2026F738 | COMPLETED | BANK_TRANSFER + PAID | total=1,150,000
SET @t_f738 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.62) SECOND);
SET @c_f738 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.65) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F738', @prof_khach21, @cp_thangvang, 'COMPLETED', 1250000.00, 100000.00, 1150000.00, 'Châu Ngọc Bích',
        '0915000021', '155 Sư Vạn Hạnh, Phường 12, Quận 10, TP.HCM', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f738, INTERVAL 2 MINUTE), @t_f738, @c_f738);
SET @ord_f738 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f738, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1);

-- FS2026F739 | COMPLETED | E_WALLET + PAID | total=1,180,000
SET @t_f739 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.66) SECOND);
SET @c_f739 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.69) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F739', @prof_khach23, NULL, 'COMPLETED', 1180000.00, 0.00, 1180000.00, 'Đoàn Thị Phương Thảo',
        '0915000023', '220 Cộng Hòa, Phường 12, Quận Tân Bình, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f739, INTERVAL 2 MINUTE), @t_f739, @c_f739);
SET @ord_f739 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f739, @var_tt_gym_s, 'Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều', 'S', 'Xám khói', 590000.00, 1),
       (@ord_f739, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1);

-- FS2026F740 | COMPLETED | COD + PAID | total=620,000
SET @t_f740 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.7) SECOND);
SET @c_f740 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.73) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F740', @prof_khach24, @cp_freeship30, 'COMPLETED', 620000.00, 30000.00, 620000.00, 'Kiều Minh Khoa',
        '0915000024', '11 Nguyễn Ái Quốc, Phường Tân Phong, TP. Biên Hòa, Đồng Nai', 30000.00, NULL, 'COD', 'PAID',
        @c_f740, @t_f740, @c_f740);
SET @ord_f740 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f740, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 2);

-- FS2026F741 | COMPLETED | BANK_TRANSFER + PAID | total=1,390,000
SET @t_f741 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.74) SECOND);
SET @c_f741 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.77) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, completed_at)
VALUES ('FS2026F741', @prof_khach26, NULL, 'COMPLETED', 1390000.00, 0.00, 1390000.00, 'Cao Tấn Lộc', '0915000026',
        '34 Đại lộ Bình Dương, TP. Thủ Dầu Một, Bình Dương', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f741, INTERVAL 2 MINUTE), @t_f741, @c_f741);
SET @ord_f741 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f741, @var_vs_den_m, 'Áo Vest Nam Công Sở Slimfit Đen', 'M', 'Đen', 850000.00, 1),
       (@ord_f741, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1);

-- FS2026F742 | SHIPPING | BANK_TRANSFER + PAID | total=1,250,000
SET @t_f742 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.78) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at)
VALUES ('FS2026F742', @prof_khach7, NULL, 'SHIPPING', 1250000.00, 0.00, 1250000.00, 'Lê Thị Thu Hà', '0915000007',
        '215 Cầu Giấy, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 0.00, NULL, 'BANK_TRANSFER', 'PAID',
        DATE_ADD(@t_f742, INTERVAL 2 MINUTE), @t_f742);
SET @ord_f742 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f742, @var_ak_blz_m, 'Áo Khoác Blazer Nữ Đen Cổ Vest', 'M', 'Đen', 1250000.00, 1);

-- FS2026F743 | SHIPPING | E_WALLET + PAID | total=1,090,000
SET @t_f743 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.81) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at)
VALUES ('FS2026F743', @prof_khach19, NULL, 'SHIPPING', 1090000.00, 0.00, 1090000.00, 'Tạ Thị Hồng Nhung', '0915000019',
        '190 Quang Trung, Phường 10, Quận Gò Vấp, TP.HCM', 0.00, NULL, 'E_WALLET', 'PAID',
        DATE_ADD(@t_f743, INTERVAL 2 MINUTE), @t_f743);
SET @ord_f743 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f743, @var_dam_pas_m, 'Đầm Sơ Mi Lụa Pastel Tay Bồng', 'M', 'Hồng pastel', 1090000.00, 1);

-- FS2026F744 | CONFIRMED | COD + UNPAID | total=744,000
SET @t_f744 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.84) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at)
VALUES ('FS2026F744', @prof_khach8, @cp_welcome15, 'CONFIRMED', 840000.00, 126000.00, 744000.00, 'Phạm Quốc Bảo',
        '0915000008', '14 Phan Văn Trị, Phường 7, Quận Gò Vấp, TP.HCM', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f744);
SET @ord_f744 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f744, @var_plo_reu_xl, 'Áo Polo Nam Dệt Kim Xanh Rêu', 'XL', 'Xanh rêu', 420000.00, 1),
       (@ord_f744, @var_cd_kem_m, 'Áo Cardigan Len Mỏng Cổ Chữ V', 'M', 'Nâu kem', 420000.00, 1);

-- FS2026F745 | CONFIRMED | COD + UNPAID | total=880,000
SET @t_f745 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.87) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at)
VALUES ('FS2026F745', @prof_khach22, NULL, 'CONFIRMED', 850000.00, 0.00, 880000.00, 'Lâm Đức Anh', '0915000022',
        '90 Hùng Vương, Phường Phú Nhuận, TP. Huế', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f745);
SET @ord_f745 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f745, @var_vs_xam_l, 'Áo Vest Nam Công Sở Slimfit Đen', 'L', 'Xám than', 850000.00, 1);

-- FS2026F746 | PENDING | E_WALLET + UNPAID | total=1,030,000
SET @t_f746 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.9) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at)
VALUES ('FS2026F746', @prof_khach10, NULL, 'PENDING', 1030000.00, 0.00, 1030000.00, 'Đặng Hoàng Nam', '0915000010',
        '56 Nguyễn Văn Linh, Phường Tân Thuận Tây, Quận 7, TP.HCM', 0.00, NULL, 'E_WALLET', 'UNPAID', NULL, @t_f746);
SET @ord_f746 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f746, @var_sm_oxf_m, 'Áo Sơ Mi Oxford Nam Xanh Biển', 'M', 'Xanh biển', 540000.00, 1),
       (@ord_f746, @var_qn_jog_m, 'Quần Jogger Nỉ Unisex Xám Tiêu', 'M', 'Xám tiêu', 490000.00, 1);

-- FS2026F747 | PENDING | COD + UNPAID | total=1,040,000
SET @t_f747 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.92) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at)
VALUES ('FS2026F747', @prof_khach25, NULL, 'PENDING', 1040000.00, 0.00, 1040000.00, 'Hà Tuyết Nhi', '0915000025',
        '68 Trường Chinh, Phường Tây Thạnh, Quận Tân Phú, TP.HCM', 0.00, NULL, 'COD', 'UNPAID', NULL, @t_f747);
SET @ord_f747 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f747, @var_al_gil_s, 'Áo Len Gile Cổ Tim Kem Sữa', 'S', 'Kem sữa', 590000.00, 1),
       (@ord_f747, @var_plo_kem_s, 'Áo Polo Nữ Cổ Phối Trắng Kem', 'S', 'Kem', 450000.00, 1);

-- FS2026F748 | CANCELLED | BANK_TRANSFER + FAILED | total=620,000
SET @t_f748 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.94) SECOND);
SET @x_f748 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.97) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F748', @prof_khach11, NULL, 'CANCELLED', 590000.00, 0.00, 620000.00, 'Bùi Thanh Thảo', '0915000011',
        '79 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM', 30000.00, NULL, 'BANK_TRANSFER', 'FAILED', NULL, @t_f748,
        'Lỗi giao dịch ngân hàng khi thanh toán', @x_f748);
SET @ord_f748 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f748, @var_al_gil_m, 'Áo Len Gile Cổ Tim Kem Sữa', 'M', 'Kem sữa', 590000.00, 1);

-- FS2026F749 | CANCELLED | COD + UNPAID | total=340,000
SET @t_f749 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.96) SECOND);
SET @x_f749 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.99) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F749', @prof_khach30, NULL, 'CANCELLED', 310000.00, 0.00, 340000.00, 'Tô Văn Hậu', '0915000030',
        '19 Hậu Giang, Phường 2, Quận 6, TP.HCM', 30000.00, NULL, 'COD', 'UNPAID', NULL, @t_f749,
        'Khách đổi ý không nhận hàng', @x_f749);
SET @ord_f749 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f749, @var_at_gym_m, 'Áo Thun Thể Thao Dry-Fit Đen', 'M', 'Đen', 310000.00, 1);

-- FS2026F750 | CANCELLED | E_WALLET + FAILED | total=750,000
SET @t_f750 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.98) SECOND);
SET @x_f750 := DATE_ADD(@cur_m_start, INTERVAL FLOOR(@cur_span * 0.99) SECOND);
INSERT INTO orders (order_code, user_profile_id, coupon_id, status, subtotal, discount_amount, total_amount,
                    recipient_name, recipient_phone, shipping_address, shipping_fee, note, payment_method,
                    payment_status, paid_at, created_at, cancel_reason, cancelled_at)
VALUES ('FS2026F750', @prof_khach31, NULL, 'CANCELLED', 720000.00, 0.00, 750000.00, 'Quách Mỹ Duyên', '0915000031',
        '44 Nguyễn Oanh, Phường 7, Quận Gò Vấp, TP.HCM', 30000.00, NULL, 'E_WALLET', 'FAILED', NULL, @t_f750,
        'Khách hủy đơn để áp thêm mã giảm giá', @x_f750);
SET @ord_f750 := LAST_INSERT_ID();
INSERT INTO order_item (order_id, variant_id, product_name, size, color, unit_price, quantity)
VALUES (@ord_f750, @var_qn_cul_s, 'Quần Culottes Ống Rộng Trắng Kem', 'S', 'Trắng kem', 720000.00, 1);

-- ============================================================================
-- MỤC 5: LỊCH SỬ KHO ĐỒNG BỘ 100% CHO CẢ 35 BIẾN THỂ
-- ============================================================================
INSERT INTO stock_history (variant_id, type, quantity_change, stock_after, supplier, import_price, reason, order_id,
                           performed_by_id, created_at)
VALUES (@var_ak_blz_m, 'IMPORT', 14, 14, 'Xưởng may thời trang FashionShop', 650000.00,
        'Nhập kho Áo Khoác Blazer Nữ Đen Cổ Vest (M - Đen)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_ak_blz_m, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F705', @ord_f705, @prof_staff3, @t_f705),
       (@var_ak_blz_m, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS2026F738', @ord_f738, @prof_staff3, @t_f738),
       (@var_ak_blz_m, 'SALE', -1, 11, NULL, NULL, 'Xuất kho theo đơn FS2026F742', @ord_f742, @prof_staff3, @t_f742),
       (@var_ak_blz_s, 'IMPORT', 11, 11, 'Xưởng may thời trang FashionShop', 650000.00,
        'Nhập kho Áo Khoác Blazer Nữ Đen Cổ Vest (S - Đen)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_ak_blz_s, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS2026F717', @ord_f717, @prof_staff3, @t_f717),
       (@var_ak_blz_s, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS2026F721', @ord_f721, @prof_staff3, @t_f721),
       (@var_al_gil_m, 'IMPORT', 18, 18, 'Xưởng may thời trang FashionShop', 307000.00,
        'Nhập kho Áo Len Gile Cổ Tim Kem Sữa (M - Kem sữa)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_al_gil_m, 'SALE', -1, 17, NULL, NULL, 'Xuất kho theo đơn FS2026F707', @ord_f707, @prof_staff3, @t_f707),
       (@var_al_gil_m, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F720', @ord_f720, @prof_staff3, @t_f720),
       (@var_al_gil_m, 'CANCELLED_ORDER', 1, 17, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F720', @ord_f720, @prof_khach28,
        DATE_ADD(@t_f720, INTERVAL 3 HOUR)),
       (@var_al_gil_m, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F739', @ord_f739, @prof_staff3, @t_f739),
       (@var_al_gil_m, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F748', @ord_f748, @prof_staff3, @t_f748),
       (@var_al_gil_m, 'CANCELLED_ORDER', 1, 16, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F748', @ord_f748, @prof_khach11,
        @x_f748),
       (@var_al_gil_s, 'IMPORT', 16, 16, 'Xưởng may thời trang FashionShop', 307000.00,
        'Nhập kho Áo Len Gile Cổ Tim Kem Sữa (S - Kem sữa)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_al_gil_s, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F715', @ord_f715, @prof_staff3, @t_f715),
       (@var_al_gil_s, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS2026F724', @ord_f724, @prof_staff3, @t_f724),
       (@var_al_gil_s, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F747', @ord_f747, @prof_staff3, @t_f747),
       (@var_at_basic_tr_l, 'IMPORT', 38, 38, 'Xưởng dệt may Phong Phú', 140000.00,
        'Nhập kho Áo thun cotton basic cổ tròn màu trắng (L - Trắng)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_at_basic_tr_l, 'SALE', -3, 35, NULL, NULL, 'Xuất kho theo đơn FS2026F728', @ord_f728, @prof_staff3,
        @t_f728),
       (@var_at_gym_l, 'IMPORT', 28, 28, 'Xưởng may thời trang FashionShop', 161000.00,
        'Nhập kho Áo Thun Thể Thao Dry-Fit Đen (L - Đen)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_at_gym_l, 'SALE', -1, 27, NULL, NULL, 'Xuất kho theo đơn FS2026F712', @ord_f712, @prof_staff3, @t_f712),
       (@var_at_gym_l, 'SALE', -2, 25, NULL, NULL, 'Xuất kho theo đơn FS2026F725', @ord_f725, @prof_staff3, @t_f725),
       (@var_at_gym_m, 'IMPORT', 33, 33, 'Xưởng may thời trang FashionShop', 161000.00,
        'Nhập kho Áo Thun Thể Thao Dry-Fit Đen (M - Đen)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_at_gym_m, 'SALE', -1, 32, NULL, NULL, 'Xuất kho theo đơn FS2026F704', @ord_f704, @prof_staff3, @t_f704),
       (@var_at_gym_m, 'SALE', -2, 30, NULL, NULL, 'Xuất kho theo đơn FS2026F740', @ord_f740, @prof_staff3, @t_f740),
       (@var_at_gym_m, 'SALE', -1, 29, NULL, NULL, 'Xuất kho theo đơn FS2026F749', @ord_f749, @prof_staff3, @t_f749),
       (@var_at_gym_m, 'CANCELLED_ORDER', 1, 30, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F749', @ord_f749, @prof_khach30,
        @x_f749),
       (@var_at_gym_xl, 'IMPORT', 14, 14, 'Xưởng may thời trang FashionShop', 161000.00,
        'Nhập kho Áo Thun Thể Thao Dry-Fit Đen (XL - Đen)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_at_gym_xl, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F716', @ord_f716, @prof_staff3, @t_f716),
       (@var_at_gym_xl, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS2026F728', @ord_f728, @prof_staff3, @t_f728),
       (@var_cd_den_l, 'IMPORT', 20, 20, 'Xưởng may thời trang FashionShop', 218000.00,
        'Nhập kho Áo Cardigan Len Mỏng Cổ Chữ V (L - Đen)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_cd_den_l, 'SALE', -1, 19, NULL, NULL, 'Xuất kho theo đơn FS2026F716', @ord_f716, @prof_staff3, @t_f716),
       (@var_cd_den_l, 'SALE', -1, 18, NULL, NULL, 'Xuất kho theo đơn FS2026F723', @ord_f723, @prof_staff3, @t_f723),
       (@var_cd_kem_m, 'IMPORT', 24, 24, 'Xưởng may thời trang FashionShop', 218000.00,
        'Nhập kho Áo Cardigan Len Mỏng Cổ Chữ V (M - Nâu kem)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_cd_kem_m, 'SALE', -1, 23, NULL, NULL, 'Xuất kho theo đơn FS2026F702', @ord_f702, @prof_staff3, @t_f702),
       (@var_cd_kem_m, 'SALE', -2, 21, NULL, NULL, 'Xuất kho theo đơn FS2026F735', @ord_f735, @prof_staff3, @t_f735),
       (@var_cd_kem_m, 'SALE', -1, 20, NULL, NULL, 'Xuất kho theo đơn FS2026F744', @ord_f744, @prof_staff3, @t_f744),
       (@var_cv_xeply_m, 'IMPORT', 19, 19, 'Xưởng thiết kế Lam Boutique', 390000.00,
        'Nhập kho Chân váy midi xếp ly màu kem (M - Kem)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_cv_xeply_m, 'SALE', -1, 18, NULL, NULL, 'Xuất kho theo đơn FS2026F727', @ord_f727, @prof_staff3, @t_f727),
       (@var_dam_do_m, 'IMPORT', 10, 10, 'Xưởng may thời trang FashionShop', 983000.00,
        'Nhập kho Đầm Dự Tiệc Satin Đỏ Đô (M - Đỏ đô)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_dam_do_m, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS2026F701', @ord_f701, @prof_staff3, @t_f701),
       (@var_dam_do_m, 'SALE', -1, 8, NULL, NULL, 'Xuất kho theo đơn FS2026F734', @ord_f734, @prof_staff3, @t_f734),
       (@var_dam_do_s, 'IMPORT', 8, 8, 'Xưởng may thời trang FashionShop', 983000.00,
        'Nhập kho Đầm Dự Tiệc Satin Đỏ Đô (S - Đỏ đô)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_dam_do_s, 'SALE', -1, 7, NULL, NULL, 'Xuất kho theo đơn FS2026F714', @ord_f714, @prof_staff3, @t_f714),
       (@var_dam_do_s, 'SALE', -1, 6, NULL, NULL, 'Xuất kho theo đơn FS2026F721', @ord_f721, @prof_staff3, @t_f721),
       (@var_dam_lua_be_s, 'IMPORT', 14, 14, 'Xưởng thiết kế Lam Boutique', 820000.00,
        'Nhập kho Đầm lụa dáng dài màu be (S - Be)', NULL, @prof_staff3, DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_dam_lua_be_s, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F708', @ord_f708, @prof_staff3,
        @t_f708),
       (@var_dam_lua_be_s, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS2026F729', @ord_f729, @prof_staff3,
        @t_f729),
       (@var_dam_pas_l, 'IMPORT', 4, 4, 'Xưởng may thời trang FashionShop', 567000.00,
        'Nhập kho Đầm Sơ Mi Lụa Pastel Tay Bồng (L - Hồng pastel)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_dam_pas_l, 'ADJUSTMENT', -4, 0, NULL, NULL, 'Thu hồi 4 sản phẩm size L trả xưởng do lỗi đường chỉ', NULL,
        @prof_staff6, DATE_SUB(@prev_m_last_day, INTERVAL 20 DAY)),
       (@var_dam_pas_m, 'IMPORT', 15, 15, 'Xưởng may thời trang FashionShop', 567000.00,
        'Nhập kho Đầm Sơ Mi Lụa Pastel Tay Bồng (M - Hồng pastel)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_dam_pas_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS2026F711', @ord_f711, @prof_staff3, @t_f711),
       (@var_dam_pas_m, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F724', @ord_f724, @prof_staff3, @t_f724),
       (@var_dam_pas_m, 'SALE', -1, 12, NULL, NULL, 'Xuất kho theo đơn FS2026F743', @ord_f743, @prof_staff3, @t_f743),
       (@var_dam_pas_s, 'IMPORT', 12, 12, 'Xưởng may thời trang FashionShop', 567000.00,
        'Nhập kho Đầm Sơ Mi Lụa Pastel Tay Bồng (S - Hồng pastel)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_dam_pas_s, 'SALE', -1, 11, NULL, NULL, 'Xuất kho theo đơn FS2026F703', @ord_f703, @prof_staff3, @t_f703),
       (@var_dam_pas_s, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS2026F736', @ord_f736, @prof_staff3, @t_f736),
       (@var_hd_xam_l, 'IMPORT', 5, 5, 'Xưởng may thời trang FashionShop', 338000.00,
        'Nhập kho Áo Hoodie Nỉ Bông Xám (Mẫu Ngừng Bán) (L - Xám)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_plo_kem_m, 'IMPORT', 24, 24, 'Xưởng may thời trang FashionShop', 234000.00,
        'Nhập kho Áo Polo Nữ Cổ Phối Trắng Kem (M - Kem)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_plo_kem_m, 'SALE', -2, 22, NULL, NULL, 'Xuất kho theo đơn FS2026F713', @ord_f713, @prof_staff3, @t_f713),
       (@var_plo_kem_m, 'SALE', -2, 20, NULL, NULL, 'Xuất kho theo đơn FS2026F722', @ord_f722, @prof_staff3, @t_f722),
       (@var_plo_kem_s, 'IMPORT', 18, 18, 'Xưởng may thời trang FashionShop', 234000.00,
        'Nhập kho Áo Polo Nữ Cổ Phối Trắng Kem (S - Kem)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_plo_kem_s, 'SALE', -1, 17, NULL, NULL, 'Xuất kho theo đơn FS2026F707', @ord_f707, @prof_staff3, @t_f707),
       (@var_plo_kem_s, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F732', @ord_f732, @prof_staff3, @t_f732),
       (@var_plo_kem_s, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F747', @ord_f747, @prof_staff3, @t_f747),
       (@var_plo_reu_l, 'IMPORT', 20, 20, 'Xưởng may thời trang FashionShop', 218000.00,
        'Nhập kho Áo Polo Nam Dệt Kim Xanh Rêu (L - Xanh rêu)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_plo_reu_l, 'SALE', -1, 19, NULL, NULL, 'Xuất kho theo đơn FS2026F718', @ord_f718, @prof_staff3, @t_f718),
       (@var_plo_reu_l, 'CANCELLED_ORDER', 1, 20, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F718', @ord_f718,
        @prof_khach29, DATE_ADD(@t_f718, INTERVAL 3 HOUR)),
       (@var_plo_reu_l, 'SALE', -2, 18, NULL, NULL, 'Xuất kho theo đơn FS2026F723', @ord_f723, @prof_staff3, @t_f723),
       (@var_plo_reu_m, 'IMPORT', 29, 29, 'Xưởng may thời trang FashionShop', 218000.00,
        'Nhập kho Áo Polo Nam Dệt Kim Xanh Rêu (M - Xanh rêu)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_plo_reu_m, 'SALE', -2, 27, NULL, NULL, 'Xuất kho theo đơn FS2026F702', @ord_f702, @prof_staff3, @t_f702),
       (@var_plo_reu_m, 'SALE', -2, 25, NULL, NULL, 'Xuất kho theo đơn FS2026F731', @ord_f731, @prof_staff3, @t_f731),
       (@var_plo_reu_xl, 'IMPORT', 5, 5, 'Xưởng may thời trang FashionShop', 218000.00,
        'Nhập kho Áo Polo Nam Dệt Kim Xanh Rêu (XL - Xanh rêu)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_plo_reu_xl, 'SALE', -1, 4, NULL, NULL, 'Xuất kho theo đơn FS2026F744', @ord_f744, @prof_staff3, @t_f744),
       (@var_qn_cul_m, 'IMPORT', 19, 19, 'Xưởng may thời trang FashionShop', 374000.00,
        'Nhập kho Quần Culottes Ống Rộng Trắng Kem (M - Trắng kem)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_qn_cul_m, 'SALE', -1, 18, NULL, NULL, 'Xuất kho theo đơn FS2026F715', @ord_f715, @prof_staff3, @t_f715),
       (@var_qn_cul_m, 'SALE', -1, 17, NULL, NULL, 'Xuất kho theo đơn FS2026F722', @ord_f722, @prof_staff3, @t_f722),
       (@var_qn_cul_s, 'IMPORT', 16, 16, 'Xưởng may thời trang FashionShop', 374000.00,
        'Nhập kho Quần Culottes Ống Rộng Trắng Kem (S - Trắng kem)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_qn_cul_s, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F705', @ord_f705, @prof_staff3, @t_f705),
       (@var_qn_cul_s, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS2026F732', @ord_f732, @prof_staff3, @t_f732),
       (@var_qn_cul_s, 'SALE', -1, 13, NULL, NULL, 'Xuất kho theo đơn FS2026F750', @ord_f750, @prof_staff3, @t_f750),
       (@var_qn_cul_s, 'CANCELLED_ORDER', 1, 14, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F750', @ord_f750, @prof_khach31,
        @x_f750),
       (@var_qn_jog_l, 'IMPORT', 5, 5, 'Xưởng may thời trang FashionShop', 255000.00,
        'Nhập kho Quần Jogger Nỉ Unisex Xám Tiêu (L - Xám tiêu)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_qn_jog_l, 'ADJUSTMENT', -1, 4, NULL, NULL, 'Kiểm kê định kỳ phát hiện thiếu 1 chiếc size L', NULL,
        @prof_staff6, DATE_SUB(@prev_m_last_day, INTERVAL 20 DAY)),
       (@var_qn_jog_l, 'SALE', -1, 3, NULL, NULL, 'Xuất kho theo đơn FS2026F725', @ord_f725, @prof_staff3, @t_f725),
       (@var_qn_jog_m, 'IMPORT', 23, 23, 'Xưởng may thời trang FashionShop', 255000.00,
        'Nhập kho Quần Jogger Nỉ Unisex Xám Tiêu (M - Xám tiêu)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_qn_jog_m, 'SALE', -1, 22, NULL, NULL, 'Xuất kho theo đơn FS2026F706', @ord_f706, @prof_staff3, @t_f706),
       (@var_qn_jog_m, 'SALE', -1, 21, NULL, NULL, 'Xuất kho theo đơn FS2026F719', @ord_f719, @prof_staff3, @t_f719),
       (@var_qn_jog_m, 'CANCELLED_ORDER', 1, 22, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F719', @ord_f719, @prof_khach42,
        DATE_ADD(@t_f719, INTERVAL 3 HOUR)),
       (@var_qn_jog_m, 'SALE', -1, 21, NULL, NULL, 'Xuất kho theo đơn FS2026F737', @ord_f737, @prof_staff3, @t_f737),
       (@var_qn_jog_m, 'SALE', -1, 20, NULL, NULL, 'Xuất kho theo đơn FS2026F746', @ord_f746, @prof_staff3, @t_f746),
       (@var_sm_linen_tr_m, 'IMPORT', 26, 26, 'Xưởng may Nhà Bè', 340000.00,
        'Nhập kho Áo sơ mi linen trắng tối giản (M - Trắng)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_sm_linen_tr_m, 'SALE', -1, 25, NULL, NULL, 'Xuất kho theo đơn FS2026F726', @ord_f726, @prof_staff3,
        @t_f726),
       (@var_sm_oxf_l, 'IMPORT', 18, 18, 'Xưởng may thời trang FashionShop', 281000.00,
        'Nhập kho Áo Sơ Mi Oxford Nam Xanh Biển (L - Xanh biển)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_sm_oxf_l, 'SALE', -1, 17, NULL, NULL, 'Xuất kho theo đơn FS2026F704', @ord_f704, @prof_staff3, @t_f704),
       (@var_sm_oxf_l, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F737', @ord_f737, @prof_staff3, @t_f737),
       (@var_sm_oxf_m, 'IMPORT', 26, 26, 'Xưởng may thời trang FashionShop', 281000.00,
        'Nhập kho Áo Sơ Mi Oxford Nam Xanh Biển (M - Xanh biển)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_sm_oxf_m, 'SALE', -1, 25, NULL, NULL, 'Xuất kho theo đơn FS2026F710', @ord_f710, @prof_staff3, @t_f710),
       (@var_sm_oxf_m, 'CANCELLED_ORDER', 1, 26, NULL, NULL, 'Hoàn kho do hủy đơn FS2026F710', @ord_f710, @prof_khach6,
        DATE_ADD(@t_f710, INTERVAL 3 HOUR)),
       (@var_sm_oxf_m, 'SALE', -2, 24, NULL, NULL, 'Xuất kho theo đơn FS2026F733', @ord_f733, @prof_staff3, @t_f733),
       (@var_sm_oxf_m, 'SALE', -1, 23, NULL, NULL, 'Xuất kho theo đơn FS2026F741', @ord_f741, @prof_staff3, @t_f741),
       (@var_sm_oxf_m, 'SALE', -1, 22, NULL, NULL, 'Xuất kho theo đơn FS2026F746', @ord_f746, @prof_staff3, @t_f746),
       (@var_sm_oxf_xl, 'IMPORT', 11, 11, 'Xưởng may thời trang FashionShop', 281000.00,
        'Nhập kho Áo Sơ Mi Oxford Nam Xanh Biển (XL - Xanh biển)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_sm_oxf_xl, 'SALE', -1, 10, NULL, NULL, 'Xuất kho theo đơn FS2026F712', @ord_f712, @prof_staff3, @t_f712),
       (@var_sm_oxf_xl, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS2026F726', @ord_f726, @prof_staff3, @t_f726),
       (@var_tt_gym_m, 'IMPORT', 1, 1, 'Xưởng may thời trang FashionShop', 307000.00,
        'Nhập kho Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều (M - Xám khói)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_tt_gym_m, 'SALE', -1, 0, NULL, NULL, 'Xuất kho theo đơn FS2026F730', @ord_f730, @prof_staff3, @t_f730),
       (@var_tt_gym_s, 'IMPORT', 17, 17, 'Xưởng may thời trang FashionShop', 307000.00,
        'Nhập kho Bộ Đồ Tập Gym Nữ Co Giãn 4 Chiều (S - Xám khói)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_tt_gym_s, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F706', @ord_f706, @prof_staff3, @t_f706),
       (@var_tt_gym_s, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F739', @ord_f739, @prof_staff3, @t_f739),
       (@var_vs_den_m, 'IMPORT', 17, 17, 'Xưởng may thời trang FashionShop', 442000.00,
        'Nhập kho Áo Vest Nam Công Sở Slimfit Đen (M - Đen)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_vs_den_m, 'SALE', -1, 16, NULL, NULL, 'Xuất kho theo đơn FS2026F701', @ord_f701, @prof_staff3, @t_f701),
       (@var_vs_den_m, 'SALE', -1, 15, NULL, NULL, 'Xuất kho theo đơn FS2026F727', @ord_f727, @prof_staff3, @t_f727),
       (@var_vs_den_m, 'SALE', -1, 14, NULL, NULL, 'Xuất kho theo đơn FS2026F741', @ord_f741, @prof_staff3, @t_f741),
       (@var_vs_xam_l, 'IMPORT', 10, 10, 'Xưởng may thời trang FashionShop', 442000.00,
        'Nhập kho Áo Vest Nam Công Sở Slimfit Đen (L - Xám than)', NULL, @prof_staff3,
        DATE_SUB(@prev_m_last_day, INTERVAL 28 DAY)),
       (@var_vs_xam_l, 'SALE', -1, 9, NULL, NULL, 'Xuất kho theo đơn FS2026F709', @ord_f709, @prof_staff3, @t_f709),
       (@var_vs_xam_l, 'SALE', -1, 8, NULL, NULL, 'Xuất kho theo đơn FS2026F729', @ord_f729, @prof_staff3, @t_f729),
       (@var_vs_xam_l, 'SALE', -1, 7, NULL, NULL, 'Xuất kho theo đơn FS2026F745', @ord_f745, @prof_staff3, @t_f745);

-- ============================================================================
-- MỤC 6: GIỎ HÀNG (10 dòng) & YÊU THÍCH (14 dòng) - gồm nhóm D chưa từng đặt đơn
-- ============================================================================
INSERT INTO cart_item (user_profile_id, variant_id, quantity, added_at)
VALUES (@prof_khach5, @var_dam_pas_s, 1, DATE_SUB(NOW(6), INTERVAL 2 DAY)),
       (@prof_khach5, @var_vs_xam_l, 1, DATE_SUB(NOW(6), INTERVAL 1 DAY)),
       (@prof_khach6, @var_plo_reu_l, 2, DATE_SUB(NOW(6), INTERVAL 3 DAY)),
       (@prof_khach8, @var_cd_den_l, 1, DATE_SUB(NOW(6), INTERVAL 12 HOUR)),
       (@prof_khach10, @var_at_gym_m, 2, DATE_SUB(NOW(6), INTERVAL 6 HOUR)),
       (@prof_khach32, @var_al_gil_s, 1, DATE_SUB(NOW(6), INTERVAL 5 DAY)),
       (@prof_khach32, @var_qn_cul_m, 1, DATE_SUB(NOW(6), INTERVAL 4 DAY)),
       (@prof_khach33, @var_plo_kem_m, 1, DATE_SUB(NOW(6), INTERVAL 2 DAY)),
       (@prof_khach33, @var_sm_oxf_m, 1, DATE_SUB(NOW(6), INTERVAL 1 DAY)),
       (@prof_khach35, @var_cd_kem_m, 1, DATE_SUB(NOW(6), INTERVAL 10 HOUR));

INSERT INTO wishlist_item (user_profile_id, product_id, added_at)
VALUES (@prof_khach5, @prod_dam_do, DATE_SUB(NOW(6), INTERVAL 15 DAY)),
       (@prof_khach5, @prod_ak_blz, DATE_SUB(NOW(6), INTERVAL 10 DAY)),
       (@prof_khach7, @prod_dam_pas, DATE_SUB(NOW(6), INTERVAL 12 DAY)),
       (@prof_khach7, @prod_vs_den, DATE_SUB(NOW(6), INTERVAL 6 DAY)),
       (@prof_khach9, @prod_qn_cul, DATE_SUB(NOW(6), INTERVAL 8 DAY)),
       (@prof_khach9, @prod_al_gil, DATE_SUB(NOW(6), INTERVAL 4 DAY)),
       (@prof_khach11, @prod_tt_gym, DATE_SUB(NOW(6), INTERVAL 5 DAY)),
       (@prof_khach11, @prod_polo_kem, DATE_SUB(NOW(6), INTERVAL 3 DAY)),
       (@prof_khach34, @prod_polo_reu, DATE_SUB(NOW(6), INTERVAL 14 DAY)),
       (@prof_khach34, @prod_sm_oxf, DATE_SUB(NOW(6), INTERVAL 14 DAY)),
       (@prof_khach34, @prod_cd_len, DATE_SUB(NOW(6), INTERVAL 9 DAY)),
       (@prof_khach34, @prod_qn_jog, DATE_SUB(NOW(6), INTERVAL 7 DAY)),
       (@prof_khach35, @prod_vs_den, DATE_SUB(NOW(6), INTERVAL 5 DAY)),
       (@prof_khach32, @prod_dam_do, DATE_SUB(NOW(6), INTERVAL 3 DAY));

-- ============================================================================
-- MỤC 7: TRUY VẤN KIỂM CHỨNG TOÀN VẸN & TỔNG QUAN DỮ LIỆU
-- ============================================================================
SELECT (SELECT COUNT(*)
        FROM orders o
        WHERE o.subtotal <> (SELECT SUM(i.unit_price * i.quantity) FROM order_item i WHERE i.order_id = o.id)
           OR o.total_amount <> o.subtotal - o.discount_amount + o.shipping_fee)                                    AS so_don_sai_tong_tien,
       (SELECT COUNT(*)
        FROM product_variant v
                 JOIN stock_history h ON h.id = (SELECT MAX(id) FROM stock_history WHERE variant_id = v.id)
        WHERE h.stock_after <> v.stock_quantity)                                                                    AS so_bien_the_lech_kho,
       (SELECT COUNT(*)
        FROM coupon c
        WHERE c.code IN ('WELCOME15', 'FREESHIP30', 'VIP200K', 'SALETET20', 'THANGVANG', 'NOEL2025')
          AND c.used_count <> (SELECT COUNT(*)
                               FROM orders o
                               WHERE o.coupon_id = c.id
                                 AND o.status <> 'CANCELLED'))                                                      AS so_coupon_lech_luot_dung;

SELECT role, status, COUNT(*) AS so_luong
FROM account
GROUP BY role, status
ORDER BY role, status;

SELECT (SELECT COUNT(*) FROM account)         AS tong_tai_khoan,
       (SELECT COUNT(*) FROM category)        AS tong_danh_muc,
       (SELECT COUNT(*) FROM product)         AS tong_san_pham,
       (SELECT COUNT(*) FROM product_variant) AS tong_bien_the,
       (SELECT COUNT(*) FROM coupon)          AS tong_ma_giam_gia,
       (SELECT COUNT(*) FROM orders)          AS tong_don_hang,
       (SELECT COUNT(*) FROM order_item)      AS tong_chi_tiet_don,
       (SELECT COUNT(*) FROM stock_history)   AS tong_lich_su_kho,
       (SELECT COUNT(*) FROM cart_item)       AS tong_gio_hang,
       (SELECT COUNT(*) FROM wishlist_item)   AS tong_yeu_thich;

-- >>> BẮT ĐẦU: database\fashion7.sql
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

-- >>> BỔ SUNG DỮ LIỆU MẪU TỪ: database\migration_coupon_update.sql
-- (Các cột mới của bảng coupon và stock_history đã có sẵn trong fashion1.sql)
USE fashionshop;
INSERT INTO coupon (code, name, discount_type, discount_value, max_discount, min_order_value, quantity, used_count, per_user_limit, target_customer_type, applicable_category_id, start_date, end_date, status)
VALUES
    ('FREESHIP', 'Miễn phí vận chuyển toàn quốc đơn từ 200K', 'FREESHIP', 0.00, NULL, 200000.00, 100, 0, 1, 'ALL', NULL, DATE_SUB(NOW(6), INTERVAL 5 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE'),
    ('KHACHMOI', 'Ưu đãi khách hàng mới giảm 20% (đơn đầu tiên)', 'PERCENT', 20.00, 100000.00, 150000.00, 100, 0, 1, 'NEW_CUSTOMER', NULL, DATE_SUB(NOW(6), INTERVAL 5 DAY), DATE_ADD(NOW(6), INTERVAL 60 DAY), 'ACTIVE')
ON DUPLICATE KEY UPDATE name = VALUES(name);
