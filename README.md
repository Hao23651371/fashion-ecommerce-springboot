# FashionShop - Studio & Atelier

Website thương mại điện tử thời trang xây dựng bằng Spring Boot MVC. Ứng dụng cung cấp đầy đủ storefront cao cấp cho khách hàng, khu vực quản trị chuyên nghiệp, hệ thống xác thực tài khoản bảo mật kèm OTP qua Email, quản lý sản phẩm/biến thể (màu sắc, kích cỡ, tồn kho), giỏ hàng, danh sách yêu thích, đơn hàng, mã giảm giá, lịch sử kho, tìm kiếm thông minh đa tầng (kết hợp MariaDB Vector) và Trợ lý AI Chatbot tư vấn thời trang (RAG + Ollama).

---

## 1. Công nghệ sử dụng

- **Ngôn ngữ**: Java 21 (tương thích Java 21/22)
- **Framework backend**: Spring Boot 3.4.x / 4.x, Spring MVC, Spring Data JPA, Spring Security, Spring Validation, Spring Mail (JavaMailSender)
- **Template engine & Giao diện**: Thymeleaf, Bootstrap 5.3.3, Bootstrap Icons 1.11.3, Vanilla CSS phong cách Atelier hiện đại
- **Cơ sở dữ liệu**: MariaDB / MySQL (khuyên dùng MariaDB >= 11.7 để hỗ trợ kiểu dữ liệu `VECTOR`), database `fashionshop`, mã hóa `utf8mb4`
- **AI & Vector Search**: MariaDB Vector (`VECTOR(1024)`, `VEC_DISTANCE_COSINE`), Ollama cục bộ (`bge-m3` cho embedding và `qwen2.5:3b` cho LLM chatbot)
- **Công cụ build**: Gradle Wrapper

---

## 2. Hướng dẫn Clone và Cài đặt

> 🔒 **Lưu ý quyền truy cập Repo:** Kho chứa này ở chế độ **Private**. Thành viên nhóm cần được chủ sở hữu mời vào dự án (*Settings > Collaborators*) và đăng nhập tài khoản GitHub mới có thể clone được.

```bash
# Clone dự án và chuyển sang nhánh develop
git clone https://github.com/Hao23651371/fashion-ecommerce-springboot.git
cd fashion-ecommerce-springboot
git checkout develop
```

### Bước 1: Khởi tạo Cơ sở dữ liệu (MariaDB >= 11.7)
Yêu cầu sử dụng **MariaDB >= 11.7** để hỗ trợ kiểu dữ liệu `VECTOR(1024)` và hàm tìm kiếm `VEC_DISTANCE_COSINE`.
Hệ thống cung cấp bộ 5 script SQL theo thứ tự trong thư mục `database/`:
1. `database/fashion1.sql`: **BẮT BUỘC CHẠY ĐẦU TIÊN**. Tạo mới database `fashionshop`, 14 bảng thực thể (bao gồm bảng `product_embedding` và `product_image`) và 6 tài khoản mẫu đã băm mật khẩu BCrypt.
2. `database/fashion2.sql`: Dữ liệu danh mục, sản phẩm, biến thể chi tiết (SKU, màu sắc, size, giá bán, tồn kho) và thư viện ảnh sản phẩm (`product_image`).
3. `database/fashion3.sql`: Dữ liệu 6 mã giảm giá mẫu (coupon).
4. `database/fashion4.sql`: Dữ liệu đơn hàng mẫu đa dạng trạng thái (COMPLETED, SHIPPING, PENDING, COD, chuyển khoản...).
5. `database/fashion5.sql`: Dữ liệu lịch sử xuất/nhập/điều chỉnh kho (`stock_history`).

> **Khuyến nghị**: Mở các file SQL trong HeidiSQL hoặc DBeaver, nhấn `Ctrl+A` rồi thực thi lần lượt từ `fashion1.sql` đến `fashion5.sql`.

### Bước 2: Cấu hình môi trường cục bộ (BẮT BUỘC)
Trong `application.properties` đã cấu hình `spring.config.import=optional:classpath:application-local.properties`. Vì vậy, người clone về **BẮT BUỘC** phải tạo file `application-local.properties`:

1. Sao chép file mẫu:
   ```bash
   # Windows PowerShell
   copy src\main\resources\application-local.properties.example src\main\resources\application-local.properties
   ```
2. Mở file `src/main/resources/application-local.properties` và điền các thông tin của máy bạn:
   - **`spring.datasource.password`**: Điền mật khẩu MariaDB/MySQL cục bộ của bạn (để trống nếu không có mật khẩu).
   - **`spring.mail.username` & `spring.mail.password`**: (Tùy chọn) Điền tài khoản Gmail và Mật khẩu ứng dụng (App Password 16 số của Google) nếu cần kiểm thử tính năng gửi mã OTP đăng ký tài khoản.
   - **Cấu hình Chatbot AI**: Chọn 1 trong 2 chế độ ở Bước 3.

### Bước 3: Cài đặt và cấu hình Trợ lý Chatbot AI

Hệ thống hỗ trợ 2 chế độ nhà cung cấp AI:

#### 👉 LỰA CHỌN A: Dùng Ollama cục bộ (Mặc định - Hoàn toàn miễn phí, không cần Key)
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
1. Mỗi thành viên **TỰ TẠO KEY RIÊNG** tại [Google AI Studio](https://aistudio.google.com/) (Tuyệt đối KHÔNG dùng chung key).
2. Kiểm tra các model hỗ trợ gói Free Tier tại trang hạn mức (Flow rate limit) của Google AI Studio.
3. Trong `application-local.properties`:
   ```properties
   chatbot.provider=gemini
   gemini.api-key=<dien-api-key-gemini-cua-ban>
   gemini.model=<ma-model-ho-tro-free-tier>
   # Hoặc nếu chưa chắc chắn mã model: ghi CẦN XÁC NHẬN trong kế hoạch
   chatbot.fallback-to-ollama=false
   ```
   *(Hoặc bạn có thể đặt biến môi trường hệ thống `GEMINI_API_KEY`).*
   > **Lưu ý về Gemini Free Tier:**
   > - Free Tier có giới hạn request/phút (RPM) và request/ngày (RPD).
   > - Hệ thống đã tích hợp sẵn cơ chế cache bộ nhớ 600 giây và tự động cooldown 60 giây khi gặp lỗi hạn mức (429/5xx).
   > - Khi Gemini gặp lỗi hạn mức hoặc timeout, chatbot sẽ **tự động chuyển sang chế độ hiển thị danh sách sản phẩm gợi ý**, tuyệt đối KHÔNG làm sập ứng dụng hay gây lỗi HTTP 500.
   > - **Mỗi lần thay đổi cấu hình, bạn BẮT BUỘC phải khởi động lại (restart) ứng dụng.**

### Bước 4: Chạy ứng dụng

```bash
# Windows
.\gradlew.bat bootRun

# Linux / macOS
./gradlew bootRun
```

Mở trình duyệt truy cập: `http://localhost:8080/`. Khi khởi động, hệ thống sẽ tự động mở trang đăng nhập `/login` nếu môi trường Desktop được hỗ trợ.

---

## 3. Tài khoản kiểm thử

| Tài khoản (Email hoặc SĐT) | Mật khẩu | Quyền hạn (Role) | Trang điều hướng sau đăng nhập |
|---|---|---|---|
| `admin1@fashionshop.vn` | `Admin@123` | Quản trị viên (ROLE_ADMIN) | `/admin/dashboard` |
| `admin2@fashionshop.vn` | `Admin@123` | Quản trị viên (ROLE_ADMIN) | `/admin/dashboard` |
| `khach1@gmail.com` hoặc `0912000001` | `Khach@123` | Khách hàng (ROLE_CUSTOMER) | `/` (Trang chủ) |
| `khach2@gmail.com` hoặc `0912000002` | `Khach@123` | Khách hàng (ROLE_CUSTOMER) | `/` (Trang chủ) |

> **Tính năng nổi bật:**
> - Cho phép đăng nhập linh hoạt bằng cả **Email** hoặc **Số điện thoại**.
> - Đăng ký tài khoản mới tại `/register` với cơ chế xác thực mã OTP 6 chữ số gửi qua Email thật (hạn 5 phút).
> - Phát hiện lỗi đăng nhập chi tiết: sai tài khoản, sai mật khẩu, tài khoản bị khóa (`locked`), tài khoản chưa kích hoạt OTP (`unverified`).
> - **Cảnh báo mất kết nối CSDL:** Trang `/login` tự động kiểm tra kết nối database ngay khi vừa mở; nếu không kết nối được sẽ hiển thị banner màu đỏ kèm mã lỗi Exception chi tiết và hướng dẫn khắc phục.

---

## 4. Danh sách Route & Chức năng chính

### Khách hàng & Xác thực
| Method | Route | Quyền truy cập | Chức năng |
|---|---|---|---|
| GET | `/` | Công khai (`permitAll`) | Trang chủ storefront; giới thiệu lookbook và danh sách sản phẩm mới |
| GET | `/shop` | Công khai (`permitAll`) | Danh sách sản phẩm, hỗ trợ tìm kiếm theo từ khóa `keyword` |
| GET | `/shop/{id}` | Công khai (`permitAll`) | Trang chi tiết sản phẩm: chọn màu, chọn size, kiểm tra tồn kho, gợi ý sản phẩm cùng danh mục |
| GET | `/sale` | Công khai (`permitAll`) | Danh sách sản phẩm đang có chương trình khuyến mãi |
| GET | `/cart` | Đăng nhập (`authenticated`) | Giỏ hàng người dùng |
| GET | `/checkout` | Đăng nhập (`authenticated`) | Đặt hàng và thanh toán |
| GET | `/orders` | Đăng nhập (`authenticated`) | Lịch sử đơn hàng cá nhân (lọc theo tab: Tất cả, Đang xử lý, Đang giao, Đã giao, Đã hủy) |
| GET | `/wishlist` | Đăng nhập (`authenticated`) | Danh sách sản phẩm yêu thích |
| GET | `/account` | Đăng nhập (`authenticated`) | Trang hồ sơ cá nhân: thông tin tài khoản, thống kê đơn hàng, địa chỉ giao hàng mặc định |
| GET | `/login` | Công khai (`permitAll`) | Trang đăng nhập (tích hợp tự động kiểm tra tình trạng CSDL) |
| GET | `/register` | Công khai (`permitAll`) | Trang đăng ký tài khoản mới |
| POST | `/register/send-otp` | Công khai (`permitAll`) | API gửi mã OTP xác thực đăng ký tài khoản qua Email |
| GET | `/logout` | Công khai (`permitAll`) | Đăng xuất an toàn khỏi hệ thống |
| GET | `/terms`, `/policy`, `/support` | Công khai (`permitAll`) | Trang Điều khoản sử dụng, Chính sách bảo mật và Hỗ trợ |

### Khu vực Quản trị (Admin)
*Tất cả route `/admin/**` được phân quyền bảo mật, yêu cầu tài khoản có vai trò `ROLE_ADMIN`.*

| Route | Quyền truy cập | Chức năng |
|---|---|---|
| `/admin` hoặc `/admin/dashboard` | `hasRole("ADMIN")` | Bảng điều khiển tổng quan quản trị |
| `/admin/categories` | `hasRole("ADMIN")` | Quản lý danh mục sản phẩm |
| `/admin/products` | `hasRole("ADMIN")` | Quản lý sản phẩm và các biến thể (SKU, size, màu, tồn kho, giá) |
| `/admin/inventory` | `hasRole("ADMIN")` | Quản lý nhập/xuất kho và điều chỉnh tồn kho |
| `/admin/orders` | `hasRole("ADMIN")` | Quản lý và xử lý đơn hàng |
| `/admin/coupons` | `hasRole("ADMIN")` | Quản lý chương trình khuyến mãi và mã giảm giá |
| `/admin/users` | `hasRole("ADMIN")` | Quản lý tài khoản người dùng và khách hàng |
| `/admin/statistics` | `hasRole("ADMIN")` | Thống kê doanh thu, đơn hàng và hiệu quả kinh doanh |
| `/admin/account` | `hasRole("ADMIN")` | **Trang tài khoản đăng nhập Admin:** hiển thị avatar, họ tên, email, quyền hạn, thời gian đăng nhập gần nhất |
| `/admin/settings` | `hasRole("ADMIN")` | Trợ giúp và thiết lập hệ thống |

---

## 5. Kiến trúc Trợ lý AI Chatbot & Tìm kiếm Vector

### 5.1. Chatbot tư vấn thời trang thông minh (Dual-Layer Architecture)
Chatbot được tích hợp sẵn ở góc màn hình qua fragment `templates/fragments/chatbox.html`, hỗ trợ 2 chế độ LLM (`ollama` và `gemini`):

1. **Tầng 1 - Rule-based & Database Query (Chính xác 100%, không tốn token AI)**:
   - Xử lý các câu hỏi về: Mã giảm giá (Coupon), Lọc theo giá (ví dụ: *"dưới 500k"*, *"từ 300k đến 700k"*), Lọc đồ Sale theo danh mục, Kiểm tra kích cỡ (Size), Màu sắc, Số lượng tồn kho và Chính sách cửa hàng (vận chuyển, đổi trả, địa chỉ, hotline).
   - Truy vấn trực tiếp từ CSDL thực qua `ProductService.getAllActiveDetails()`.

2. **Tầng 2 - RAG (Retrieval-Augmented Generation) & LLM (Gemini / Ollama)**:
   - Áp dụng khi khách hỏi câu hỏi mở hoặc yêu cầu tư vấn phong cách (ví dụ: *"Tư vấn đồ đi tiệc sang trọng"*, *"Gợi ý set đồ mùa thu"*...).
   - **Quy trình RAG**:
     1. Chuyển câu hỏi của khách thành vector qua mô hình `bge-m3`.
     2. Tìm các sản phẩm có độ tương đồng ngữ nghĩa cao nhất trong bảng `product_embedding` (MariaDB Vector).
     3. Đưa thông tin sản phẩm tìm được vào mục `"DỮ LIỆU CỬA HÀNG"` trong prompt gửi cho LLM (Gemini hoặc Ollama Qwen).
     4. LLM đóng vai trò chuyên viên thời trang tư vấn tự nhiên, cam kết không bịa đặt sản phẩm ngoài kho.

- `POST /api/chatbot`: Endpoint trao đổi tin nhắn dạng JSON thông thường.
- `POST /api/chatbot/stream`: Endpoint phản hồi dạng streaming (`text/plain`) gõ chữ mượt mà từng từ.

### 5.2. Cơ chế tạo Vector tự động & Xử lý "Chatbot không thấy sản phẩm mới"
* **Tự động tạo vector khi khởi động:** Lớp `EmbeddingStartupIndexer` tự động quét các sản phẩm chưa có vector trong cơ sở dữ liệu (`reindex(false)`) và nạp vào bảng `product_embedding`.
* **Tạo lại toàn bộ thủ công:** Quản trị viên có thể truy cập URL `GET /admin/embeddings/rebuild` để buộc tính toán lại vector cho 100% sản phẩm.
* **⚠️ Hiện tượng "Chatbot không thấy sản phẩm mới":**
  - **Với câu hỏi Lọc giá / Sale / Size / Tồn kho:** Chatbot **THẤY NGAY LẬP TỨC** vì truy vấn SQL trực tiếp.
  - **Với câu hỏi Tư vấn phong cách AI (Tầng 2 RAG):** Khi sản phẩm mới được thêm vào database nhưng chưa có vector embedding trong bảng `product_embedding`, AI sẽ chưa nhận được dữ liệu của sản phẩm này.
  - **Cách xử lý:** Chỉ cần **khởi động lại ứng dụng** (để `EmbeddingStartupIndexer` tự quét) hoặc gọi endpoint `/admin/embeddings/rebuild`.

### 5.3. Hướng dẫn tự kiểm thử Chatbot từng bước
1. **Bước 1 (Kiểm tra tầng 1 - Không tốn token):** Mở chat, gõ *"Có mã giảm giá nào không?"* hoặc *"Áo dưới 500k"*. Bot trả lời ngay lập tức thông tin mã voucher và danh sách ít nhất 5 sản phẩm.
2. **Bước 2 (Kiểm tra tầng 2 RAG):** Gõ *"Tư vấn cho mình đầm đi tiệc sang trọng"*. Quan sát bot gọi mô hình AI (Gemini hoặc Ollama) và phản hồi tư vấn kèm link `/shop/{id}`.
3. **Bước 3 (Kiểm tra Cache bộ nhớ Gemini):** Gõ lại chính xác câu hỏi ở Bước 2. Bot phản hồi ngay lập tức (dưới 100ms) nhờ cơ chế cache 600 giây.
4. **Bước 4 (Kiểm tra Fallback an toàn khi sai key/lỗi mạng):** Thử đổi `gemini.api-key` thành chuỗi không hợp lệ và restart app. Khi hỏi tư vấn, chatbot sẽ không bị sập hay báo lỗi 500, mà tự động fallback sang danh sách sản phẩm gợi ý kèm lời nhắn thân thiện.

### 5.4. Bảng "Lỗi thường gặp" và cách xử lý nhanh

| Hiện tượng / Mã lỗi | Nguyên nhân | Cách khắc phục |
|---|---|---|
| **Chatbot trả về danh sách sản phẩm thô, không có văn phong AI** | Thiếu `gemini.api-key` / `gemini.model` hoặc API Key bị hết hạn ngạch Free Tier | Kiểm tra lại key trong `application-local.properties`, kiểm tra quota tại Google AI Studio, hoặc chuyển về `chatbot.provider=ollama`. |
| **HTTP 400 Bad Request** | Tên `gemini.model` sai hoặc không hỗ trợ phương thức generateContent | Kiểm tra lại danh sách model khả dụng trên Google AI Studio. |
| **HTTP 403 Forbidden** | API Key Gemini sai, bị thu hồi hoặc chưa bật Generative Language API | Tạo API key mới tại Google AI Studio và cập nhật vào `application-local.properties`. |
| **HTTP 404 Not Found** | URL endpoint Gemini hoặc model không tồn tại | Kiểm tra lại tên model trong cấu hình. |
| **HTTP 429 Too Many Requests** | Quá giới hạn request/phút (RPM) hoặc request/ngày (RPD) của gói Free Tier | Chờ 60 giây (hệ thống tự động cooldown), tận dụng cache hoặc dùng tài khoản Google khác để tạo key mới. |
| **Ollama connection refused / Vector search lỗi** | Chưa bật phần mềm Ollama hoặc chưa pull model `bge-m3` | Mở ứng dụng Ollama và chạy lệnh `ollama pull bge-m3`. |
| **Lỗi SQL: Table 'product_embedding' doesn't exist hoặc không hỗ trợ VECTOR** | Chưa chạy `database/fashion1.sql` hoặc phiên bản MariaDB cũ (< 11.7) | Nâng cấp MariaDB lên phiên bản >= 11.7 và thực thi `fashion1.sql`. |
| **Ứng dụng không nhận cấu hình mới sửa** | Quên khởi động lại (restart) ứng dụng | Tắt ứng dụng (`Ctrl+C`) và chạy lại `.\gradlew.bat bootRun`. |

### 5.5. Quy tắc bảo mật quan trọng khi đẩy code (Push)
- ⛔ **Tuyệt đối KHÔNG commit:** `application-local.properties`, `.env`, API Key Gemini, mật khẩu CSDL hoặc App Password Gmail lên GitHub.
- 🔒 **Chế độ Repository:** Dự án nên được giữ ở chế độ **Private**.
- 🚨 **Xử lý sự cố lộ lọt:** Nếu lỡ commit khóa bí mật lên Git, hãy vào Google AI Studio / Google Account để thu hồi (Revoke/Delete) ngay lập tức và tạo khóa mới.

---

## 6. Cấu trúc Thư mục và File chính

```text
FashionShop/
├── database/                                # Bộ script khởi tạo CSDL theo thứ tự
│   ├── fashion1.sql                         # Khởi tạo DB, 13 bảng & tài khoản mẫu
│   ├── fashion2.sql                         # Dữ liệu danh mục, sản phẩm, biến thể
│   ├── fashion3.sql                         # Dữ liệu mã giảm giá (coupon)
│   ├── fashion4.sql                         # Dữ liệu đơn hàng mẫu
│   └── fashion5.sql                         # Dữ liệu lịch sử xuất/nhập kho
├── src/main/java/com/iuh/fashionshop/
│   ├── config/                              # Cấu hình bảo mật, Global attributes, AI Vector
│   │   ├── SecurityConfig.java              # Cấu hình Spring Security, phân quyền route (Public, Customer, Admin)
│   │   ├── GlobalModelAttributes.java       # Nạp thông tin đăng nhập toàn cục (loggedIn, currentEmail, isAdmin...)
│   │   ├── CartModelAdvice.java             # ControllerAdvice độc lập cung cấp số lượng giỏ hàng (cartCount)
│   │   └── WishlistModelAdvice.java         # ControllerAdvice độc lập cung cấp số lượng yêu thích (wishlistCount)
│   ├── controller/                          # REST & MVC Controllers (Storefront, Auth & Admin)
│   │   ├── AuthController.java              # Đăng nhập, đăng ký, gửi OTP, kiểm tra CSDL
│   │   ├── AdminAccountController.java      # Quản lý trang tài khoản đăng nhập Admin
│   │   ├── AccountController.java           # Trang tài khoản cá nhân khách hàng
│   │   ├── ChatbotController.java           # API Trợ lý Chatbot tư vấn
│   │   └── ProductApiController.java        # API tìm kiếm sản phẩm đa tầng (Vector)
│   ├── dto/                                 # Đối tượng truyền dữ liệu (RegisterForm, ProductCardDto...)
│   ├── model/                               # Các JPA Entities (Account, UserProfile, Product, Order...)
│   ├── repository/                          # JPA Repositories
│   └── service/                             # Nghiệp vụ (AccountService, EmailService, ChatbotService...)
└── src/main/resources/
    ├── application.properties               # Cấu hình chính của ứng dụng
    ├── application-local.properties         # Cấu hình CSDL và Ollama cục bộ
    ├── static/                              # Tài nguyên tĩnh (phân chia theo phạm vi quyền hạn)
    │   ├── css/
    │   │   ├── theme.css                    # Design tokens & CSS chung toàn hệ thống
    │   │   ├── auth.css                     # CSS trang xác thực (login, register)
    │   │   ├── admin/                       # CSS khu vực Quản trị viên (admin.css, users.css)
    │   │   └── customer/                    # CSS khu vực Khách hàng (product-card.css, product-detail.css)
    │   ├── js/
    │   │   ├── admin/                       # JS khu vực Quản trị viên (users.js)
    │   │   └── customer/                    # JS khu vực Khách hàng (search.js - live search header)
    │   └── images/                          # logo.png và hình ảnh tĩnh
    └── templates/                           # Giao diện Thymeleaf
        ├── admin/                           # Các trang quản trị (dashboard, account, products...)
        ├── auth/                            # Giao diện xác thực (login, register, terms, auth-header, auth-footer)
        ├── fragments/                       # Các thành phần giao diện tái sử dụng
        │   ├── header/                      # 5 fragment tách nhỏ của Header:
        │   │   ├── main-menu.html           # Menu điều hướng giữa (Trang chủ, Sản phẩm, Sale HOT)
        │   │   ├── search-box.html          # Ô tìm kiếm + dropdown live search (nạp search.js)
        │   │   ├── wishlist-icon.html       # Icon yêu thích kèm badge wishlistCount
        │   │   ├── cart-icon.html           # Icon giỏ hàng kèm badge cartCount
        │   │   └── user-menu.html           # Nút Đăng nhập/Đăng ký hoặc Nút Tài khoản của tôi
        │   ├── user-header.html             # Khung Header khách hàng (gọi 5 fragment trong header/)
        │   ├── user-footer.html             # Footer chung trang khách hàng
        │   ├── admin-sidebar.html           # Sidebar điều hướng trang quản trị
        │   ├── chatbox.html                 # Trợ lý AI Chatbot tư vấn 24/7
        │   └── product-card.html            # Thẻ sản phẩm dùng chung: th:replace="~{fragments/product-card :: card(${p})}"
        ├── layouts/                         # Layout khung chuẩn (admin-base, user-base)
        └── user/                            # Các trang storefront (home, shop, detail, orders...)
```

---

## 7. Kiểm thử & Đóng gói

```bash
# Chạy kiểm thử tự động
.\gradlew.bat test

# Biên dịch mã nguồn Java
.\gradlew.bat compileJava

# Đóng gói file JAR thực thi
.\gradlew.bat build
```

---

## 8. Tài liệu liên quan

- [TAI_LIEU_DU_AN_FASHION_SHOP.docx](TAI_LIEU_DU_AN_FASHION_SHOP.docx): Báo cáo tài liệu dự án định dạng Word chi tiết về kiến trúc, sơ đồ thực thể, luồng nghiệp vụ, phân quyền và API.
- `database/`: Thư mục lưu trữ toàn bộ các kịch bản SQL khởi tạo và nạp dữ liệu mẫu của hệ thống.
