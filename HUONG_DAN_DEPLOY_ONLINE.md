# HƯỚNG DẪN DEPLOY ONLINE & SỬ DỤNG MCP (FASHIONSHOP)

> ⚠️ **LƯU Ý QUAN TRỌNG VỀ NHÁNH GIT:**
> Nhánh `feature/hao-deploy-online` được tạo riêng để phục vụ thử nghiệm triển khai lên Cloud.
> **TUYỆT ĐỐI KHÔNG GỘP (MERGE) NHÁNH NÀY VÀO `develop` HOẶC `main`**.
> Nhánh `develop` phải được giữ nguyên vẹn để các thành viên trong nhóm `git pull` về máy chạy Local cho buổi thuyết trình.

---

## PHẦN 1: CÁC THAY ĐỔI ĐÃ CHUẨN BỊ TRÊN NHÁNH NÀY

1. **`src/main/resources/application.properties`**:
   - Thêm `server.port=${PORT:8080}`: Tự động nhận diện cổng do Cloud cấp, không lo bị lỗi timeout.
   - Thêm cấu hình fallback `spring.datasource.url=${SPRING_DATASOURCE_URL:...}`: Giúp Cloud đọc trực tiếp chuỗi kết nối từ biến môi trường.
2. **`Dockerfile` & `.dockerignore`**:
   - Sử dụng multi-stage build siêu nhẹ với **Eclipse Temurin JDK 21 Alpine**.
   - Tương thích 100% với Railway, Render, Fly.io, Koyeb, Docker VPS.
3. **`mcp-server/`**:
   - `index.js`: Chế độ `stdio` (dành cho Claude Desktop / Antigravity chạy Local).
   - `server.js`: Chế độ `SSE / HTTP` (sẵn sàng deploy thành Web Service online qua cổng HTTP).
   - `mcp-app.js`: Tích hợp trọn bộ 5 công cụ AI Copilot quản trị kho, doanh thu và khuyến mãi.

---

## PHẦN 2: HƯỚNG DẪN DEPLOY WEBSITE LÊN RAILWAY (MIỄN PHÍ & DỄ NHẤT)

### Bước 1: Tạo Database MariaDB / MySQL trên Railway
1. Truy cập [Railway.app](https://railway.app/) và đăng nhập bằng tài khoản GitHub.
2. Bấm nút **+ New Project** -> Chọn **Provision MariaDB** (hoặc **Provision MySQL**).
3. Nhấp vào service Database vừa tạo -> Chọn tab **Variables** hoặc **Connect**:
   - Sao chép các thông tin: `MYSQLHOST` (hoặc `MARIADB_HOST`), `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, `MYSQLDATABASE`, hoặc URL kết nối đầy đủ.
4. Mở **HeidiSQL** (hoặc DBeaver) trên máy tính:
   - Tạo kết nối mới trỏ tới Host, Port, User, Password của Railway vừa cấp.
   - Mở lần lượt các file SQL trong thư mục `database/` (`fashion1.sql` $\rightarrow$ `fashion5.sql`) và nhấn **F9** để nạp cấu trúc bảng và dữ liệu mẫu vào CSDL Cloud.

---

### Bước 2: Deploy Web App Spring Boot
1. Trên dashboard Railway của cùng Project đó, bấm nút **+ Create** (hoặc **+ New**) -> Chọn **GitHub Repo**.
2. Chọn repo `fashion-ecommerce-springboot`.
3. Bấm vào Service vừa tạo -> Chọn tab **Settings**:
   - Tại mục **Source Branch**: Chọn nhánh `feature/hao-deploy-online` (KHÔNG chọn develop).
   - Tại mục **Build**: Railway sẽ tự động phát hiện `Dockerfile` và build bằng Java 21.
4. Chuyển sang tab **Variables**, thêm các biến môi trường sau:
   - `SPRING_DATASOURCE_URL`: `jdbc:mariadb://${{MariaDB.MARIADB_HOST}}:${{MariaDB.MARIADB_PORT}}/${{MariaDB.MARIADB_DATABASE}}` *(hoặc điền URL kết nối lấy ở Bước 1)*
   - `SPRING_DATASOURCE_USERNAME`: Điền User của database
   - `SPRING_DATASOURCE_PASSWORD`: Điền Password của database
   - `GEMINI_API_KEY`: Điền API key Google Gemini của bạn (lấy tại Google AI Studio)
   - `MAIL_USERNAME`: Tài khoản Gmail gửi OTP (nếu có)
   - `MAIL_PASSWORD`: Mật khẩu ứng dụng 16 ký tự của Gmail (nếu có)
5. Chuyển sang tab **Settings** -> Tại mục **Networking**, bấm **Generate Domain** để nhận đường link truy cập công khai (ví dụ: `https://fashionshop-production.up.railway.app`).

---

## PHẦN 3: HƯỚNG DẪN SỬ DỤNG MCP SERVER

### Cách A: Dùng Local trên máy (Dành cho buổi thuyết trình)
1. Chạy SQL tạo user bảo mật (chỉ cần làm 1 lần):
   - Mở HeidiSQL kết nối vào localhost `root`.
   - Chạy file `mcp-server/init-mcp-user.sql` để tạo user `fashionshop_mcp`.
2. Mở Terminal tại thư mục `mcp-server/`:
   ```bash
   cd mcp-server
   npm run inspect
   ```
3. Mở trình duyệt tại `http://localhost:5173` để tương tác trực quan với 5 công cụ AI Copilot.

---

### Cách B: Deploy MCP Server Online (Chế độ SSE)
1. Trên Railway hoặc Render, tạo một Service mới từ GitHub repo, trỏ vào thư mục `mcp-server`.
2. Thiết lập lệnh khởi chạy:
   - **Root Directory**: `mcp-server`
   - **Start Command**: `node server.js`
3. Cung cấp các biến môi trường:
   - `DB_HOST`: Host của CSDL Cloud
   - `DB_PORT`: Port CSDL Cloud
   - `DB_NAME`: Tên database Cloud
   - `DB_USER`: User database
   - `DB_PASSWORD`: Mật khẩu database
4. Khi deploy thành công, đường link MCP SSE của bạn sẽ có dạng:
   `https://<ten-mien-cloud>/sse`
   (Có thể dán link này vào Claude Desktop để điều khiển CSDL online từ bất kỳ đâu).

---

## PHẦN 4: CÁC LỆNH GIT QUẢN LÝ NHANH

- **Chuyển về nhánh develop (khi cần cùng nhóm test Local cho thuyết trình):**
  ```bash
  git checkout develop
  git pull origin develop
  ```

- **Quay lại nhánh deploy để tiếp tục thử nghiệm Cloud:**
  ```bash
  git checkout feature/hao-deploy-online
  ```
