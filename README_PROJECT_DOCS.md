# Tài liệu cấu trúc và hướng dẫn FashionShop

## 1. Tổng quan

FashionShop là website thương mại điện tử thời trang theo mô hình Spring Boot MVC. Phiên bản hiện tại gồm:

- Storefront công khai: trang chủ, shop, chi tiết sản phẩm, sale.
- Tài khoản khách hàng: đăng ký, đăng nhập, tài khoản, giỏ hàng, checkout, yêu thích và lịch sử đơn hàng.
- Khu vực quản trị: dashboard, danh mục, sản phẩm, tồn kho, đơn hàng, coupon, người dùng và thiết lập.
- Xác thực kép: tài khoản dev hardcoded để kiểm thử nhanh và tài khoản thật từ MariaDB/MySQL.

## 2. Công nghệ và cấu hình

| Thành phần | Phiên bản/cấu hình |
|---|---|
| Ngôn ngữ | Java 21 |
| Backend | Spring Boot 4.1.1, Spring MVC, Spring Data JPA |
| Bảo mật | Spring Security, BCrypt, role `ADMIN`/`CUSTOMER` |
| View | Thymeleaf |
| UI | Bootstrap 5.3.3, Bootstrap Icons 1.11.3, CSS tùy biến |
| Database | MariaDB/MySQL Vector, database `fashionshop`, `utf8mb4` |
| Build | Gradle Wrapper |

`application.properties` import tùy chọn `application-local.properties`, bật JPA `ddl-auto=update` và SQL logging. File local chứa thông tin kết nối máy phát triển; không đưa mật khẩu thật vào tài liệu hoặc source.

## 3. Tài khoản kiểm thử

### Tài khoản dev

| Username | Password | Role | Redirect |

### Tài khoản trong `database/fashionshop.sql`

| Email | Password gốc | Role |
|---|---|---|
| `admin1@fashionshop.vn` | `Admin@123` | `ROLE_ADMIN` |
| `admin2@fashionshop.vn` | `Admin@123` | `ROLE_ADMIN` |
| `khach1@gmail.com` | `Khach@123` | `ROLE_CUSTOMER` |
| `khach2@gmail.com` | `Khach@123` | `ROLE_CUSTOMER` |

Mật khẩu trong SQL được lưu dưới dạng BCrypt. Đăng ký mới tại `/register` tạo `Account` và `UserProfile` trong cùng transaction.

## 4. Cấu trúc project

```text
FashionShop/
├── build.gradle
├── database/fashionshop.sql
├── README.md
├── README_PROJECT_DOCS.md
├── TAI_LIEU_DU_AN_FASHION_SHOP.docx
├── src/main/java/com/iuh/fashionshop/
│   ├── FashionShopApplication.java
│   ├── config/
│   │   ├── GlobalModelAttributes.java
│   │   └── SecurityConfig.java
│   ├── controller/
│   ├── dto/RegisterForm.java
│   ├── form/RegisterForm.java
│   ├── model/
│   ├── repository/
│   └── service/
└── src/main/resources/
    ├── application.properties
    ├── application-local.properties
    ├── database/fashionshop.sql
    ├── static/css/{theme.css,admin.css,auth.css}
    ├── static/images/
    └── templates/
        ├── layouts/{user-base.html,admin-base.html}
        ├── fragments/{user-header.html,user-footer.html,admin-sidebar.html}
        ├── auth/
        ├── user/
        ├── admin/
        └── error/{403.html,404.html,500.html}
```

## 5. Backend modules

### Controller

| Controller | Base route | View/logic |
|---|---|---|
| `UserController` | `/` | `user/home.html` |
| `ShopController` | `/shop`, `/shop/{id}` | Danh sách và chi tiết sản phẩm; nhận `keyword` |
| `SaleController` | `/sale` | Sản phẩm khuyến mãi |
| `CartController` | `/cart` | Giỏ hàng |
| `CheckoutController` | `/checkout` | Thanh toán |
| `OrderController` | `/orders` | Đơn hàng thật theo email đang đăng nhập |
| `WishlistController` | `/wishlist` | Sản phẩm yêu thích |
| `AccountController` | `/account` | Thông tin tài khoản |
| `AuthController` | `/login`, `/register`, `/logout` | Xác thực và đăng ký |
| `AdminController` | `/admin`, `/admin/dashboard` | Dashboard |
| `AdminCategoryController` | `/admin/categories` | Danh mục |
| `AdminProductController` | `/admin/products` | Sản phẩm |
| `AdminInventoryController` | `/admin/inventory` | Tồn kho |
| `AdminOrderController` | `/admin/orders` | Đơn hàng |
| `AdminCouponController` | `/admin/coupons` | Coupon |
| `AdminUserController` | `/admin/users` | Người dùng |
| `AdminSettingsController` | `/admin/settings` | Thiết lập |

`OrderController` lấy profile theo tài khoản hiện tại, nhóm đơn theo các tab `processing`, `shipping`, `completed`, `cancelled` và truy vấn chi tiết item. Các route hiện tại chủ yếu cung cấp màn hình/view; nghiệp vụ CRUD quản trị được bố trí để phát triển tiếp trong từng controller.

### Service và repository

- `AccountService`: kiểm tra email, mã hóa BCrypt, tạo tài khoản và profile.
- `AccountUserDetailsService`: nạp user từ `AccountRepository`, ánh xạ role và trạng thái bị khóa.
- `AccountRepository`: `findByEmail`, `existsByEmail`.
- `UserProfileRepository`: truy vấn profile theo account id/email.
- `GlobalModelAttributes`: cung cấp dữ liệu dùng chung cho view.

## 6. Bảo mật

`SecurityConfig`:

- Cho phép tài nguyên tĩnh và `/login`, `/register`, `/logout`.
- Bảo vệ toàn bộ `/admin/**` bằng `ROLE_ADMIN`; các route storefront hiện cho phép truy cập công khai.
- Dùng `BCryptPasswordEncoder`.
- Chuyển admin về `/admin/dashboard`, customer về `/` sau đăng nhập.
- Phân loại lỗi đăng nhập thành `email`, `password`, `locked`, `unknown`.
- Logout hủy session, xóa cookie `JSESSIONID` và chuyển về `/login?logout=true`.

## 7. Mô hình dữ liệu

| Entity | Bảng | Vai trò |
|---|---|---|
| `Account` | `account` | Email, mật khẩu, role, trạng thái xác thực |
| `UserProfile` | `user_profile` | Hồ sơ người dùng, liên kết 1-1 với account |
| `ShippingAddress` | `shipping_address` | Địa chỉ giao hàng |
| `Category` | `category` | Danh mục |
| `Product` | `product` | Sản phẩm, giá, giới tính, trạng thái |
| `ProductVariant` | `product_variant` | Size, màu, SKU, tồn kho, `@Version` |
| `Coupon` | `coupon` | Mã giảm giá và giới hạn sử dụng |
| `Order` | `orders` | Đơn hàng, tổng tiền, trạng thái |
| `OrderItem` | `order_item` | Snapshot sản phẩm trong đơn |
| `StockHistory` | `stock_history` | Lịch sử nhập/xuất/điều chỉnh kho |
| `CartItem` | `cart_item` | Sản phẩm trong giỏ |
| `WishlistItem` | `wishlist_item` | Sản phẩm yêu thích |

`ShippingInfo` và `PaymentInfo` là `@Embeddable` nằm trong bảng `orders`. Các enum chính gồm `Role`, `AccountStatus`, `CategoryStatus`, `ProductStatus`, `VariantStatus`, `Gender`, `DiscountType`, `CouponStatus`, `OrderStatus`, `PaymentMethod`, `PaymentStatus` và `StockMovementType`.

SQL tạo 13 bảng, gồm `product_embedding` để lưu vector sản phẩm, cùng các khóa ngoại giữa account/profile/product/order và dữ liệu mẫu cho 2 admin cùng 2 customer. Có hai bản SQL: `database/fashionshop.sql` dùng để khởi tạo thủ công và bản sao trong `src/main/resources/database/fashionshop.sql`.

## 8. Giao diện và giải thích các trang template

- `user-base.html`: layout storefront, dùng `user-header.html` và `user-footer.html`.
- `admin-base.html`: layout quản trị hai cột, dùng `admin-sidebar.html`; sidebar có điều hướng dashboard, danh mục, sản phẩm, kho, đơn hàng, coupon, user và settings.
- `auth/*.html`: đăng nhập, đăng ký và fragment riêng cho xác thực.
- `error/403.html`, `404.html`, `500.html`: trang lỗi.
- `theme.css`: biến màu và design system; `admin.css`: giao diện admin; `auth.css`: giao diện đăng nhập/đăng ký.

### 8.1. Layout và fragment dùng chung

| Template | Giải thích |
|---|---|
| `layouts/user-base.html` | Khung bao ngoài cho các trang khách hàng, nạp tiêu đề và CSS storefront. |
| `fragments/user-header.html` | Thanh điều hướng chính, tìm kiếm, yêu thích, giỏ hàng và trạng thái đăng nhập. |
| `fragments/user-footer.html` | Footer và các liên kết nhanh đến nhóm sản phẩm, Sale và cổng Admin. |
| `layouts/admin-base.html` | Khung bao ngoài cho trang quản trị, chia vùng sidebar và nội dung. |
| `fragments/admin-sidebar.html` | Menu điều hướng toàn bộ module quản trị và thao tác đăng xuất. |
| `auth/auth-header.html`, `auth/auth-footer.html` | Header/footer dùng chung cho các trang xác thực. |

### 8.2. Trang storefront và xác thực

| Template | Chức năng |
|---|---|
| `user/home.html` | Trang chủ, hiển thị sản phẩm mới, trạng thái hết hàng/khuyến mãi và liên kết đến chi tiết. |
| `user/shop.html` | Trang danh sách sản phẩm, là điểm vào cho tìm kiếm theo `keyword` và các tham số lọc. Hiện phần nội dung chính là placeholder. |
| `user/detail.html` | Trang chi tiết sản phẩm theo mã trên URL; hiện phần nội dung chi tiết là placeholder. |
| `user/sale.html` | Trang sản phẩm khuyến mãi; hiện phần nội dung chính là placeholder. |
| `user/cart.html` | Trang giỏ hàng; template đã có route nhưng phần giao diện nghiệp vụ chưa hoàn thiện. |
| `user/checkout.html` | Trang thanh toán/giao hàng; template đã có route nhưng phần giao diện nghiệp vụ chưa hoàn thiện. |
| `user/orders.html` | Lịch sử đơn hàng của tài khoản hiện tại, có tab tất cả/đang xử lý/đang vận chuyển/đã giao/đã hủy. |
| `user/wishlist.html` | Danh sách sản phẩm yêu thích; hiện là placeholder. |
| `user/account.html` | Hồ sơ cá nhân, số lượng đơn/yêu thích và địa chỉ giao hàng mặc định. |
| `auth/login.html` | Form đăng nhập và hiển thị trạng thái/lỗi đăng nhập. |
| `auth/register.html` | Form đăng ký tài khoản và xác nhận mật khẩu. |

### 8.3. Trang quản trị

Tất cả template dưới đây được bọc bởi `admin-base.html` và điều hướng từ `admin-sidebar.html`.

| Template | Chức năng và trạng thái |
|---|---|
| `admin/dashboard.html` | Bảng điều khiển tổng quan. |
| `admin/categories.html` | Màn hình quản lý danh mục; hiện placeholder. |
| `admin/products.html` | Màn hình quản lý sản phẩm/biến thể; hiện placeholder. |
| `admin/inventory.html` | Màn hình quản lý tồn kho; hiện placeholder. |
| `admin/orders.html` | Màn hình quản lý đơn hàng; hiện placeholder. |
| `admin/coupons.html` | Màn hình quản lý mã giảm giá; hiện placeholder. |
| `admin/users.html` | Màn hình quản lý người dùng; hiện placeholder. |
| `admin/settings.html` | Màn hình trợ giúp và thiết lập; hiện placeholder. |

### 8.4. Trang lỗi

- `error/403.html`: hiển thị khi người dùng không đủ quyền.
- `error/404.html`: hiển thị khi không tìm thấy tài nguyên/trang.
- `error/500.html`: hiển thị khi máy chủ gặp lỗi nội bộ.

> Lưu ý: “placeholder” nghĩa là route và template đã tồn tại để định hình giao diện, nhưng nội dung nghiệp vụ trong template hiện chưa được xây dựng đầy đủ. Không nên xem các màn hình này là CRUD đã hoàn thiện.

## 9. Tìm kiếm ngữ nghĩa bằng vector trên giao diện user

Ô tìm kiếm trên header được khai báo trong `fragments/user-header.html`. Người dùng nhập từ khóa tại ô “Tìm kiếm bộ sưu tập...”; template gọi `GET /api/products/search?q=...` để lấy gợi ý nhanh và hiển thị ảnh, tên, danh mục và giá. Mỗi gợi ý liên kết đến trang `/shop/{id}`.

API dùng chiến lược 3 tầng:

1. Tìm theo tên sản phẩm thông thường.
2. Tìm theo tên/danh mục sau khi bỏ dấu tiếng Việt.
3. Chỉ khi hai tầng đầu không có kết quả, mới dùng tìm kiếm ngữ nghĩa bằng vector; tầng này lấy tối đa 3 kết quả và lọc theo khoảng cách cosine.

Vector search không dùng một hệ quản trị vector riêng. Vector được lưu ngay trong MariaDB thông qua bảng `product_embedding`:

| Thành phần | Mô tả |
|---|---|
| Bảng lưu vector | `product_embedding`, liên kết với `product` bằng `product_id` |
| Kiểu dữ liệu | `VECTOR(1024)` |
| Model embedding | Ollama `bge-m3` |
| Ollama URL mặc định | `http://localhost:11434` |
| So sánh vector | MariaDB `VEC_DISTANCE_COSINE` |
| Ngưỡng cấu hình | `vector.search.max-distance=1.0` |

Khi ứng dụng khởi động, `EmbeddingStartupIndexer` tạo vector cho các sản phẩm chưa có vector nếu Ollama khả dụng. Admin có thể gọi `GET /admin/embeddings/rebuild` để tạo lại vector cho toàn bộ sản phẩm. Cấu hình nằm trong `application-local.properties`:

```properties
ollama.base-url=http://localhost:11434
ollama.embedding.model=bge-m3
ollama.embedding.dimensions=1024
vector.search.max-distance=1.0
```

Để dùng được chức năng này, MariaDB phải hỗ trợ kiểu `VECTOR` (script SQL yêu cầu MariaDB từ 11.7 trở lên) và Ollama cần được bật cùng model `bge-m3` (`ollama pull bge-m3`). Khi Ollama không khả dụng, tìm kiếm tên thông thường và tìm kiếm không dấu vẫn hoạt động; chỉ tầng tìm kiếm ngữ nghĩa bị bỏ qua.

## 10. Cài đặt và chạy

1. Cài Java 21 và MariaDB/MySQL.
2. Chạy `database/fashionshop.sql`.
3. Sửa `src/main/resources/application-local.properties`:

   ```properties
   spring.datasource.url=jdbc:mariadb://localhost:3306/fashionshop
   spring.datasource.username=root
   spring.datasource.password=<mat-khau-cua-ban>
   ```

4. Chạy:

   ```bash
   gradlew.bat bootRun
   ```

5. Truy cập `http://localhost:8080/` hoặc `http://localhost:8080/login`.

## 11. Kiểm tra build

```bash
gradlew.bat test
gradlew.bat build
```

Test hiện có nằm tại `src/test/java/com/iuh/fashionshop/FashionShopApplicationTests.java`.
