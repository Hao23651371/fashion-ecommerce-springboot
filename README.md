# FashionShop - Studio & Atelier

Website thương mại điện tử thời trang xây dựng bằng Spring Boot MVC. Ứng dụng có storefront cho khách hàng, khu vực quản trị, xác thực tài khoản, quản lý sản phẩm/biến thể, giỏ hàng, yêu thích, đơn hàng, mã giảm giá và tồn kho. Một số màn hình storefront/admin hiện vẫn là khung template để tiếp tục phát triển.

## Công nghệ

- Java 21
- Spring Boot 4.1.1, Spring MVC, Spring Data JPA, Spring Security, Spring Validation
- Thymeleaf, Bootstrap 5.3.3, Bootstrap Icons 1.11.3
- MariaDB/MySQL với database `fashionshop`, mã hóa `utf8mb4`
- Gradle Wrapper

## Chạy nhanh

1. Tạo database bằng `database/fashionshop.sql` trong MariaDB/MySQL. Script tạo lại database `fashionshop`, 13 bảng (gồm bảng vector sản phẩm) và dữ liệu mẫu.
2. Cấu hình `src/main/resources/application-local.properties`:

   ```properties
   spring.datasource.url=jdbc:mariadb://localhost:3306/fashionshop
   spring.datasource.username=root
   spring.datasource.password=<mat-khau-cua-ban>
   ```

3. Chạy ứng dụng:

   ```bash
   # Windows
   gradlew.bat bootRun

   # Linux/macOS
   ./gradlew bootRun
   ```

4. Mở `http://localhost:8080/`. Cấu hình JPA hiện dùng `ddl-auto=update`; không commit mật khẩu database thật vào source.

## Tài khoản kiểm thử

| Tài khoản | Mật khẩu | Quyền | Sau khi đăng nhập |
|--|--|---|---|
| `admin1@fashionshop.vn` | `Admin@123` | Admin | `/admin/dashboard` |
| `admin2@fashionshop.vn` | `Admin@123` | Admin | `/admin/dashboard` |
| `khach1@gmail.com` | `Khach@123` | Customer | `/` |
| `khach2@gmail.com` | `Khach@123` | Customer | `/` |

Các tài khoản email được nạp từ SQL với mật khẩu BCrypt. Người dùng mới có thể đăng ký tại `/register`.

## Các route chính

### Khách hàng và xác thực

| Method | Route | Chức năng |
|---|---|---|
| GET | `/` | Trang chủ |
| GET | `/shop` | Danh sách sản phẩm, hỗ trợ tham số tìm kiếm `keyword` |
| GET | `/shop/{id}` | Trang chi tiết sản phẩm; chỉ hiển thị sản phẩm đang hoạt động thuộc danh mục đang hiển thị, không tìm thấy thì trả về trang 404 |
| GET | `/sale` | Màn hình sản phẩm khuyến mãi |
| GET | `/cart` | Màn hình giỏ hàng; hiện là khung template |
| GET | `/checkout` | Màn hình thanh toán; hiện là khung template |
| GET | `/orders` | Đơn hàng của tài khoản hiện tại; lọc `status` |
| GET | `/wishlist` | Màn hình sản phẩm yêu thích; hiện là khung template |
| GET | `/account` | Thông tin cá nhân, địa chỉ mặc định và liên kết nhanh |
| GET/POST | `/register` | Đăng ký tài khoản |
| GET | `/login` | Đăng nhập |
| GET | `/logout` | Đăng xuất |

### Quản trị

Tất cả route `/admin/**` yêu cầu `ROLE_ADMIN`.

| Route | Chức năng |
|---|---|
| `/admin` hoặc `/admin/dashboard` | Bảng điều khiển |
| `/admin/categories` | Danh mục |
| `/admin/products` | Sản phẩm và biến thể |
| `/admin/inventory` | Quản lý kho |
| `/admin/orders` | Đơn hàng |
| `/admin/coupons` | Mã giảm giá |
| `/admin/users` | Người dùng |
| `/admin/statistics` | Khung giao diện thống kê |
| `/admin/settings` | Trợ giúp và thiết lập |

### Chatbot tư vấn sản phẩm

Chatbot được hiển thị trong `fragments/chatbox.html` và được nạp trong layout storefront
`layouts/user-base.html`. Chatbot xử lý câu hỏi tiếng Việt về sản phẩm, giá, khuyến mãi,
mã giảm giá, màu, size, tồn kho và chính sách đổi trả dựa trên dữ liệu hiện có trong
database.

| Method | Route | Chức năng |
|---|---|---|
| POST | `/api/chatbot` | Nhận JSON `{ "message": "..." }`, trả JSON `{ "reply": "..." }`. |
| POST | `/api/chatbot/stream` | Nhận cùng định dạng, trả nội dung phản hồi dạng `text/plain` theo từng đoạn để giao diện hiển thị dần. |

Tin nhắn được chuẩn hóa và giới hạn tối đa 500 ký tự ở controller. Chatbot có thể trả
danh sách sản phẩm phù hợp kèm liên kết chi tiết; nếu không có dữ liệu phù hợp sẽ
trả lời theo chính sách hoặc hướng dẫn người dùng. Chức năng streaming không yêu cầu
dịch vụ AI bên ngoài; logic hiện tại sử dụng dữ liệu sản phẩm và coupon từ ứng dụng.

## Tìm kiếm sản phẩm bằng vector trên header

Ô tìm kiếm nằm trong `fragments/user-header.html`, vì vậy xuất hiện trên header của các trang giao diện khách hàng. Khi người dùng nhập từ khóa, JavaScript trong template gọi API `GET /api/products/search?q=...` sau khoảng trễ ngắn và hiển thị danh sách gợi ý gồm ảnh, tên, danh mục và giá sản phẩm. Chọn một gợi ý sẽ mở `/shop/{id}`.

API tìm kiếm xử lý theo 3 tầng:

1. Khớp tên sản phẩm thông thường, không phân biệt hoa thường.
2. Khớp không dấu tiếng Việt, ví dụ `quan` vẫn có thể tìm thấy `Quần`.
3. Nếu hai tầng trên không có kết quả, hệ thống mới tìm theo ngữ nghĩa bằng vector và lấy tối đa 3 kết quả phù hợp.

Phần vector sử dụng **MariaDB Vector** ngay trong database `fashionshop`, không phải một database riêng. Bảng `product_embedding` lưu vector `VECTOR(1024)` cho từng sản phẩm. Ollama chạy cục bộ tại `http://localhost:11434`, dùng model embedding `bge-m3` để:

- chuyển thông tin sản phẩm thành vector khi lập chỉ mục;
- chuyển từ khóa tìm kiếm thành vector truy vấn;
- so sánh bằng khoảng cách cosine (`VEC_DISTANCE_COSINE`) để tìm sản phẩm gần nghĩa nhất.

Khi ứng dụng khởi động, hệ thống tự tạo vector cho các sản phẩm chưa có vector nếu Ollama đã được cấu hình và đang chạy. Admin có thể tạo lại toàn bộ vector qua `GET /admin/embeddings/rebuild`. Nếu Ollama chưa chạy hoặc vector search gặp lỗi, các tầng tìm kiếm tên/không dấu vẫn là cơ chế chính; riêng tầng vector sẽ không trả gợi ý.

### Cấu hình vector search

Các thuộc tính nằm trong `src/main/resources/application-local.properties`:

```properties
ollama.base-url=http://localhost:11434
ollama.embedding.model=bge-m3
ollama.embedding.dimensions=1024
vector.search.max-distance=1.0
```

Yêu cầu MariaDB có hỗ trợ kiểu `VECTOR` (script hiện tại ghi chú MariaDB từ 11.7; môi trường phát triển đang dùng 12.2.2) và cần tải model bằng `ollama pull bge-m3` trước khi lập chỉ mục.

## Giải thích các trang trong template

### Layout và thành phần dùng chung

| Template | Mục đích |
|---|---|
| `layouts/user-base.html` | Layout chung cho storefront; nạp tiêu đề, CSS và nội dung từng trang khách hàng. |
| `fragments/user-header.html` | Header storefront: logo, menu Trang chủ/Sản phẩm/Sale, tìm kiếm, yêu thích, giỏ hàng, đăng nhập/đăng ký hoặc tài khoản. |
| `fragments/user-footer.html` | Footer, liên kết nhanh theo nhóm sản phẩm, liên kết Sale và cổng quản trị. |
| `layouts/admin-base.html` | Layout chung cho khu vực quản trị, gồm sidebar và vùng nội dung chính. |
| `fragments/admin-sidebar.html` | Menu điều hướng Dashboard, danh mục, sản phẩm, kho, đơn hàng, mã giảm giá, người dùng, thiết lập và đăng xuất. |
| `auth/auth-header.html` / `auth/auth-footer.html` | Thành phần dùng chung cho giao diện đăng nhập/đăng ký. |

### Trang khách hàng và xác thực

| Template | Mục đích và trạng thái |
|---|---|
| `user/home.html` | Trang chủ storefront; hiển thị khu vực giới thiệu và danh sách sản phẩm mới, có badge hết hàng/giảm giá và liên kết sang chi tiết. |
| `user/shop.html` | Trang danh sách sản phẩm và điểm vào tìm kiếm/lọc sản phẩm. Hiện phần nội dung chính là khung giao diện. |
| `user/detail.html` | Trang chi tiết theo `/shop/{id}`; hiển thị ảnh, giá, khuyến mãi, SKU, mô tả, thông tin danh mục/giới tính, màu sắc, size, tồn kho theo biến thể và sản phẩm cùng danh mục. Có modal hướng dẫn size, toast thông báo và các thao tác chọn biến thể phía trình duyệt. |
| `user/sale.html` | Trang tập hợp sản phẩm đang khuyến mãi. Hiện phần nội dung chính là khung giao diện. |
| `user/cart.html` | Trang xem và chuẩn bị các sản phẩm trong giỏ trước khi thanh toán. Hiện chưa có giao diện nghiệp vụ hoàn chỉnh. |
| `user/checkout.html` | Trang nhập/thực hiện thông tin thanh toán và giao hàng. Hiện chưa có giao diện nghiệp vụ hoàn chỉnh. |
| `user/orders.html` | Trang lịch sử đơn hàng của tài khoản; hỗ trợ các tab Tất cả, Đang xử lý, Đang vận chuyển, Đã giao và Đã hủy. |
| `user/wishlist.html` | Trang xem các sản phẩm đã yêu thích. Hiện là khung giao diện. |
| `user/account.html` | Trang hồ sơ cá nhân, số lượng đơn hàng/yêu thích và địa chỉ giao hàng mặc định. |
| `auth/login.html` | Form đăng nhập, hiển thị lỗi/trạng thái đăng nhập và liên kết sang đăng ký. |
| `auth/register.html` | Form đăng ký tài khoản, xác nhận mật khẩu và liên kết sang đăng nhập. |

### Trang quản trị và trang lỗi

| Template | Mục đích và trạng thái |
|---|---|
| `admin/dashboard.html` | Màn hình tổng quan sau khi admin đăng nhập. |
| `admin/categories.html` | Quản lý danh mục sản phẩm; hiện là khung giao diện. |
| `admin/products.html` | Quản lý sản phẩm và biến thể; hiện là khung giao diện. |
| `admin/inventory.html` | Theo dõi/quản lý tồn kho; hiện là khung giao diện. |
| `admin/orders.html` | Theo dõi và xử lý đơn hàng; hiện là khung giao diện. |
| `admin/coupons.html` | Quản lý mã giảm giá; hiện là khung giao diện. |
| `admin/users.html` | Quản lý người dùng; hiện là khung giao diện. |
| `admin/statistics.html` | Khung giao diện trang thống kê trong khu vực quản trị. |
| `admin/settings.html` | Khu vực trợ giúp và thiết lập; hiện là khung giao diện. |
| `error/403.html` | Thông báo không có quyền truy cập. |
| `error/404.html` | Thông báo không tìm thấy trang/tài nguyên. |
| `error/500.html` | Thông báo lỗi máy chủ nội bộ. |

### Tài nguyên giao diện

- `static/css/theme.css`: biến màu, kiểu chữ và quy tắc giao diện dùng chung.
- `static/css/admin.css`: bố cục và thành phần riêng của khu vực quản trị.
- `static/css/auth.css`: giao diện đăng nhập/đăng ký.
- `static/images/`: hình ảnh/logo được template sử dụng.

## Mô hình dữ liệu

Các entity chính gồm `Account`, `UserProfile`, `ShippingAddress`, `Category`, `Product`, `ProductVariant`, `Coupon`, `Order`, `OrderItem`, `StockHistory`, `CartItem` và `WishlistItem`. `ShippingInfo` và `PaymentInfo` là các lớp `@Embeddable` trong `orders`. Database có các bảng tương ứng: `account`, `user_profile`, `shipping_address`, `category`, `product`, `product_variant`, `coupon`, `orders`, `order_item`, `stock_history`, `cart_item`, `wishlist_item`.

## Cấu trúc backend hiện tại

- `ProductService` chuyển sản phẩm và các biến thể đang hoạt động thành
  `ProductDetailDto`, tính giá hiện tại, phần trăm giảm, tổng tồn kho, màu và size,
  đồng thời lấy tối đa bốn sản phẩm liên quan cùng danh mục.
- `ProductRepository` cung cấp truy vấn chi tiết sản phẩm và sản phẩm liên quan.
- `CouponRepository` cung cấp dữ liệu coupon cho chatbot và các chức năng liên quan.
- `ChatbotController` cung cấp hai endpoint trả lời thường và streaming.
- `ChatbotService` phân tích câu hỏi, lọc sản phẩm theo tiêu chí và định dạng phản hồi.
- `ProductDetailDto` là DTO dùng chung cho trang chi tiết sản phẩm và logic tư vấn.

Nút thêm giỏ hàng, mua ngay và yêu thích trên trang chi tiết hiện mới mô phỏng tương tác
ở phía trình duyệt; chưa tạo nghiệp vụ đặt hàng hoặc lưu `CartItem`/`WishlistItem`
qua API.

## Kiểm thử và build

```bash
# Windows
gradlew.bat test
gradlew.bat compileJava
gradlew.bat build

# Linux/macOS
./gradlew test
```

Các test hiện có gồm test khởi động ứng dụng và test `ChatbotService` cho câu hỏi về
coupon, sản phẩm khuyến mãi, khoảng giá, size và chính sách đổi trả.

## Cấu trúc tài liệu

- [TAI_LIEU_DU_AN_FASHION_SHOP.docx](TAI_LIEU_DU_AN_FASHION_SHOP.docx): báo cáo Word chi tiết về kiến trúc, module, route, entity và các tính năng hiện tại.
- [database/fashionshop.sql](database/fashionshop.sql): schema, bảng `product_embedding` và dữ liệu mẫu.
