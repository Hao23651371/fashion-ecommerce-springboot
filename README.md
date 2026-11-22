# FashionShop - Studio & Atelier

Website thương mại điện tử thời trang xây dựng trên nền tảng **Spring Boot MVC (Java 21)**. Ứng dụng cung cấp trọn vẹn storefront cao cấp dành cho khách hàng, phân hệ quản trị chuyên nghiệp cho Ban quản lý (Admin & Staff), hệ thống xác thực bảo mật đa phương thức (Email / Số điện thoại) kèm OTP qua Email thật, quản lý sản phẩm và biến thể chi tiết (SKU, màu sắc, kích cỡ, tồn kho, thư viện ảnh), giỏ hàng, danh sách yêu thích, đơn hàng, mã giảm giá, quản lý kho hàng và lịch sử biến động kho, xuất báo cáo Excel, tìm kiếm thông minh đa tầng (kết hợp MariaDB Vector) và Trợ lý AI Chatbot tư vấn phong cách thời trang (RAG + Ollama / Google Gemini).

---

## 1. Công nghệ sử dụng

- **Ngôn ngữ**: Java 21 LTS
- **Framework backend**: Spring Boot 3.4.x, Spring MVC, Spring Data JPA, Spring Security, Spring Validation, Spring Mail (JavaMailSender)
- **Template engine & Giao diện**: Thymeleaf, Bootstrap 5.3.3, Bootstrap Icons 1.11.3, Vanilla CSS phong cách Atelier hiện đại
- **Cơ sở dữ liệu**: MariaDB $\ge$ 11.7 (khuyên dùng để hỗ trợ kiểu dữ liệu `VECTOR(1024)` và hàm `VEC_DISTANCE_COSINE`) hoặc MySQL 8.0+
- **AI & Vector Search**: MariaDB Vector, Ollama cục bộ (`bge-m3` cho embedding và `qwen2.5:3b` cho LLM chatbot) hoặc Google Gemini API (Cloud LLM)
- **Công cụ build**: Gradle Wrapper (`gradlew`)
- **Tích hợp mở rộng**: MCP Server (Model Context Protocol qua Node.js) hỗ trợ kết nối AI Agent điều hành shop

---

## 2. Hướng dẫn Cài đặt và Khởi chạy Hệ thống

### Bước 1: Clone mã nguồn từ GitHub
```bash
# Clone dự án từ GitHub
git clone https://github.com/Hao23651371/fashion-ecommerce-springboot.git

# Chuyển vào thư mục dự án và chuyển sang nhánh develop
cd fashion-ecommerce-springboot
git checkout develop
```

### Bước 2: Khởi tạo Cơ sở dữ liệu (MariaDB >= 11.7)
Hệ thống cung cấp sẵn bộ 5 script SQL theo thứ tự trong thư mục `database/`:
1. `database/fashion1.sql`: **BẮT BUỘC CHẠY ĐẦU TIÊN**. Tạo mới database `fashionshop`, 14 bảng thực thể (bao gồm bảng `product_embedding` và `product_image`) và các tài khoản mẫu đã băm mật khẩu chuẩn BCrypt.
2. `database/fashion2.sql`: Dữ liệu danh mục, sản phẩm, biến thể chi tiết (SKU, màu sắc, size, giá bán, tồn kho) và thư viện ảnh sản phẩm (`product_image`).
3. `database/fashion3.sql`: Dữ liệu mã giảm giá mẫu (coupon).
4. `database/fashion4.sql`: Dữ liệu đơn hàng mẫu đa dạng trạng thái (COMPLETED, SHIPPING, PENDING, COD, chuyển khoản...).
5. `database/fashion5.sql`: Dữ liệu lịch sử xuất/nhập/điều chỉnh kho (`stock_history`).

> **Khuyến nghị**: Mở các file SQL trên bằng công cụ quản lý CSDL (HeidiSQL, DBeaver, hoặc MySQL Workbench), chọn database `fashionshop` và thực thi lần lượt từ `fashion1.sql` đến `fashion5.sql`.

### Bước 3: Cấu hình môi trường cục bộ (`application-local.properties`)
1. Sao chép file mẫu:
   ```bash
   # Trên Windows PowerShell
   copy src\main\resources\application-local.properties.example src\main\resources\application-local.properties

   # Trên Linux / macOS
   cp src/main/resources/application-local.properties.example src/main/resources/application-local.properties
   ```
2. Mở file `src/main/resources/application-local.properties` và cấu hình các thông số máy của bạn:
   - **`spring.datasource.password`**: Điền mật khẩu tài khoản root MariaDB/MySQL của bạn (để trống nếu không đặt mật khẩu).
   - **`spring.mail.username` & `spring.mail.password`**: (Tùy chọn) Điền tài khoản Gmail và Mật khẩu ứng dụng (Google App Password 16 số) để kiểm thử tính năng gửi mã OTP đăng ký và quên mật khẩu qua email thật.
   - **Cấu hình Chatbot AI**: Lựa chọn 1 trong 2 chế độ (Ollama hoặc Gemini) bên dưới.

### Bước 4: Cấu hình Trợ lý Chatbot AI (Tùy chọn)

Hệ thống hỗ trợ 2 chế độ nhà cung cấp AI linh hoạt:

#### 👉 LỰA CHỌN A: Dùng Ollama cục bộ (Mặc định - Hoàn toàn miễn phí, chạy Offline)
1. Cài đặt Ollama từ [ollama.com](https://ollama.com/).
2. Mở terminal tải mô hình embedding và mô hình chat:
   ```bash
   ollama pull bge-m3
   ollama pull qwen2.5:3b
   ```
3. Trong `application-local.properties`:
   ```properties
   chatbot.provider=ollama
   ollama.base-url=http://localhost:11434
   ollama.embedding.model=bge-m3
   ollama.chat.model=qwen2.5:3b
   ```

#### 👉 LỰA CHỌN B: Dùng Google Gemini (Cloud LLM thông minh)
1. Tạo API Key tại [Google AI Studio](https://aistudio.google.com/).
2. Trong `application-local.properties`:
   ```properties
   chatbot.provider=gemini
   gemini.api-key=<dien-api-key-gemini-cua-ban>
   gemini.model=gemini-2.5-flash
   chatbot.fallback-to-ollama=false
   ```
   *(Hệ thống đã tích hợp sẵn cơ chế cache bộ nhớ 600 giây và tự động cooldown an toàn khi gặp lỗi hạn mức).*

### Bước 5: Khởi chạy Ứng dụng
```bash
# Trên Windows
.\gradlew.bat bootRun

# Trên Linux / macOS
./gradlew bootRun
```

Mở trình duyệt truy cập: `http://localhost:8080/`. Hệ thống sẽ tự động chuyển hướng hoặc hiển thị trang đăng nhập `/login` khi cần thiết.

---

## 3. Danh sách Tài khoản Kiểm thử (Demo Accounts)

| Vai trò (Role) | Tên đăng nhập (Email hoặc SĐT) | Mật khẩu | Quyền hạn và Điều hướng |
|---|---|---|---|
| **Quản trị viên (Admin)** | `admin1@fashionshop.vn` | `Admin@123` | Toàn quyền hệ thống, quản lý tài khoản ➔ `/admin/dashboard` |
| **Quản trị viên (Admin)** | `admin2@fashionshop.vn` | `Admin@123` | Toàn quyền hệ thống ➔ `/admin/dashboard` |
| **Khách hàng (Customer)** | `khach1@gmail.com` *(hoặc `0912000001`)* | `Khach@123` | Đặt hàng, giỏ hàng, yêu thích, lịch sử đơn ➔ `/` (Trang chủ) |
| **Khách hàng (Customer)** | `khach2@gmail.com` *(hoặc `0912000002`)* | `Khach@123` | Mua sắm, đánh giá, theo dõi trạng thái đơn ➔ `/` (Trang chủ) |

> 🌟 **Điểm nổi bật khi xác thực:**
> - Cho phép đăng nhập linh hoạt bằng cả **Email** hoặc **Số điện thoại**.
> - Tích hợp **hiệu ứng thông báo đăng nhập thành công 3 giây** hiển thị góc màn hình cho mọi tài khoản và tự động dọn URL.
> - Đăng ký tài khoản mới kèm cơ chế xác thực OTP 6 số gửi qua Email thật (hạn 5 phút).
> - Tính năng quên mật khẩu / đặt lại mật khẩu với mã OTP qua Email hoặc Số điện thoại.
> - Tự động phát hiện và cảnh báo mất kết nối CSDL ngay trên form đăng nhập kèm hướng dẫn sửa lỗi trực quan.

---

## 4. Tổng hợp Chức năng và Phân hệ Hệ thống

### 4.1. Phân hệ Khách hàng (Storefront)
- **Trang chủ (`/`):** Lookbook bộ sưu tập, danh mục nổi bật, sản phẩm mới nhất.
- **Cửa hàng & Sản phẩm (`/shop`):** Bộ lọc đa tầng (danh mục, giới tính, khoảng giá, sale), sắp xếp theo giá và mức chiết khấu, phân trang mượt mà.
- **Chi tiết sản phẩm (`/shop/{id}`):** Chọn biến thể màu sắc, kích cỡ, xem tồn kho thực tế, bộ sưu tập hình ảnh chi tiết, gợi ý sản phẩm liên quan.
- **Tìm kiếm thông minh (`/api/products/search`):** Tìm kiếm tức thì (live search) 3 tầng: từ khóa chính xác, tiếng Việt không dấu và ngữ nghĩa vector.
- **Trợ lý AI Chatbot (`/api/chatbot`):** Tư vấn chọn đồ, phối đồ theo sự kiện, kiểm tra size, giá và voucher tự động.
- **Giỏ hàng (`/cart`):** Thêm, sửa số lượng, xóa sản phẩm, tính toán tạm tính tự động.
- **Thanh toán & Đặt hàng (`/checkout`):** Hỗ trợ "Mua ngay" hoặc đặt từ giỏ hàng, áp dụng mã giảm giá (voucher), chọn hình thức thanh toán COD hoặc Quét mã VietQR tự động điền tiền và nội dung.
- **Danh sách yêu thích (`/wishlist`):** Thả tim lưu sản phẩm, xem danh sách và xóa toàn bộ.
- **Theo dõi đơn hàng (`/orders`):** Lịch sử đơn hàng, lọc theo trạng thái, xem chi tiết đơn hàng, tự hủy đơn hàng khi đang chờ xử lý.
- **Quản lý tài khoản (`/account`):** Cập nhật hồ sơ cá nhân, quản lý sổ địa chỉ nhận hàng, đổi mật khẩu bảo mật (`/account/security`).

### 4.2. Phân hệ Quản trị (Admin & Staff)
- **Bảng điều khiển tổng quan (`/admin/dashboard`):** Thống kê nhanh doanh thu, số đơn hàng, khách hàng mới, cảnh báo tồn kho thấp.
- **Quản lý danh mục (`/admin/categories`):** Thêm, sửa, xóa, ẩn/hiện danh mục kèm cascade tự động ẩn sản phẩm bên trong.
- **Quản lý sản phẩm & biến thể (`/admin/products`):** Quản lý chi tiết biến thể theo SKU, Size, Màu, Giá, Tồn kho, quản lý thư viện nhiều hình ảnh, bật/tắt kinh doanh.
- **Quản lý kho hàng (`/admin/inventory`):** Tra cứu tồn kho chi tiết, nhập kho (lưu nhà cung cấp, giá nhập, lý do), kiểm kê điều chỉnh kho thực tế, tra cứu nhật ký lịch sử biến động kho (`Stock History`).
- **Quản lý đơn hàng (`/admin/orders`):** Cập nhật trạng thái đơn (Xác nhận, Giao hàng, Hoàn thành, Hủy), xác nhận đã nhận chuyển khoản ngân hàng hoặc đã thu tiền COD.
- **Quản lý mã giảm giá (`/admin/coupons`):** Tạo voucher giảm %, số tiền cố định hoặc Freeship, phân loại đối tượng áp dụng (Mọi khách, Khách mới, Khách VIP), **xuất file Excel danh sách mã giảm giá**.
- **Quản lý tài khoản người dùng (`/admin/users`):** Danh sách người dùng, cấp tài khoản nội bộ (Admin/Staff), phân quyền vai trò, khóa/mở khóa tài khoản, khôi phục mật khẩu mặc định.
- **Báo cáo thống kê (`/admin/statistics`):** Biểu đồ và bảng thống kê doanh thu, số đơn, top sản phẩm bán chạy theo khoảng ngày tùy chọn, **xuất báo cáo thống kê ra file Excel (.xlsx)**.
- **Đồng bộ Vector AI (`/admin/embeddings/rebuild`):** Nạp và tính toán lại vector embedding cho toàn bộ sản phẩm trong kho.
- **Hồ sơ cá nhân Admin (`/admin/account`):** Xem thông tin cá nhân và đổi mật khẩu quản trị.

---

## 5. Cấu trúc Thư mục Dự án

```text
FashionShop/
├── database/                                # Bộ 5 script SQL khởi tạo CSDL
│   ├── fashion1.sql                         # Khởi tạo DB, 14 bảng thực thể & tài khoản mẫu
│   ├── fashion2.sql                         # Dữ liệu danh mục, sản phẩm, biến thể, hình ảnh
│   ├── fashion3.sql                         # Dữ liệu mã giảm giá (coupon)
│   ├── fashion4.sql                         # Dữ liệu đơn hàng mẫu
│   └── fashion5.sql                         # Dữ liệu lịch sử biến động kho
├── mcp-server/                              # Module MCP Server độc lập (Node.js) cho Admin AI
├── src/main/java/com/iuh/fashionshop/
│   ├── config/                              # Cấu hình Spring Security, Global Attributes, Model Advice
│   ├── controller/                          # Controllers Storefront, Auth và Admin
│   ├── dto/                                 # Đối tượng truyền dữ liệu (DTO)
│   ├── model/                               # Các JPA Entities (Account, Product, Order, Inventory...)
│   ├── repository/                          # JPA Repositories và Native Vector Queries
│   └── service/                             # Xử lý nghiệp vụ, Email OTP, Excel Export, AI Chatbot
└── src/main/resources/
    ├── application.properties               # Cấu hình lõi của ứng dụng
    ├── application-local.properties.example # File cấu hình môi trường mẫu
    ├── static/                              # Tài nguyên tĩnh CSS, JS, Images (phân tách Admin & User)
    └── templates/                           # Giao diện Thymeleaf (Layouts, Fragments, Admin, User, Auth)
```

---

## 6. Lệnh Kiểm thử và Đóng gói

```bash
# Biên dịch mã nguồn Java
.\gradlew.bat compileJava

# Chạy kiểm thử tự động
.\gradlew.bat test

# Đóng gói file JAR thực thi độc lập
.\gradlew.bat build -x test
```
File JAR sau khi build thành công sẽ nằm tại: `build/libs/fashionshop-0.0.1-SNAPSHOT.jar`.
Chạy ứng dụng từ file JAR:
```bash
java -jar build/libs/fashionshop-0.0.1-SNAPSHOT.jar
```
