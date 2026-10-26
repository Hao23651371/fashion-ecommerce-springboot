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
-- ================= KHÁCH BỔ SUNG (TRƯỜNG HỢP BIÊN) =================
-- khach3: khách mới, KHÔNG có địa chỉ / đơn / giỏ / yêu thích -> test các màn hình trống
-- khach4: đã xác thực nhưng bị khóa (BANNED)                    -> test chặn đăng nhập, nút mở khóa ở /admin/users
INSERT INTO account (email, password, role, status, email_verified, created_at) VALUES
                                                                                    ('admin1@fashionshop.vn', '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK', 'ADMIN',    'ACTIVE', 1, NOW(6)),
                                                                                    ('admin2@fashionshop.vn', '$2a$10$LNbJ3jILuVETgjv8QE7eOecgt9.vKsQszcihb3R12JpnbSJwsbCtK', 'ADMIN',    'ACTIVE', 1, NOW(6)),
                                                                                    ('khach1@gmail.com',      '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'ACTIVE', 1, NOW(6)),
                                                                                    ('khach2@gmail.com',      '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'ACTIVE', 1, NOW(6)),
                                                                                    ('khach3@gmail.com', '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'ACTIVE', 1, NOW(6)),
                                                                                    ('khach4@gmail.com', '$2a$10$274cWtcQ3KIeg.WjXjRJSuzd1TpyCgEkT1CA7KtmmtZNs0Wj4KTye', 'CUSTOMER', 'BANNED', 1, NOW(6));

INSERT INTO user_profile (full_name, phone_number, birth_date, account_id) VALUES
                                                                               ('Nguyễn Quản Trị', '0901000001', '1995-03-15', (SELECT id FROM account WHERE email = 'admin1@fashionshop.vn')),
                                                                               ('Phạm Thu Hà',     '0901000002', '1998-07-22', (SELECT id FROM account WHERE email = 'admin2@fashionshop.vn')),
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


-- ================= KIEM TRA SAU KHI CHAY (dung: 6) =================
SELECT COUNT(*) AS so_tai_khoan FROM account;
