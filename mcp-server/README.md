# FashionShop Admin AI Copilot - MCP Server

Dự án Model Context Protocol (MCP) Server độc lập dành cho **Admin / Chủ shop FashionShop**. Cung cấp các công cụ (Tools) chuẩn hóa để kết nối với các ứng dụng AI Agent như **Claude Desktop**, **Antigravity**, **Cursor** để quản lý doanh thu, cảnh báo tồn kho và tạo mã giảm giá bằng câu lệnh ngôn ngữ tự nhiên.

---

## 1. Thiết lập Database (Nguyên tắc đặc quyền tối thiểu)

Để đảm bảo AI không thể xóa hay sửa nhầm các dữ liệu quan trọng, hãy tạo một user MySQL/MariaDB riêng biệt chỉ có quyền đọc (`SELECT`) và quyền thêm mã (`INSERT` trên bảng `coupon`):

1. Mở **HeidiSQL** hoặc **DBeaver**, đăng nhập bằng tài khoản `root`.
2. Mở file `init-mcp-user.sql` và bấm **F9** để thực thi:
   ```sql
   CREATE USER IF NOT EXISTS 'fashionshop_mcp'@'localhost' IDENTIFIED BY 'mcp_secret_pass_2026';
   GRANT SELECT ON fashionshop.* TO 'fashionshop_mcp'@'localhost';
   GRANT INSERT ON fashionshop.coupon TO 'fashionshop_mcp'@'localhost';
   FLUSH PRIVILEGES;
   ```

---

## 2. Cài đặt và cấu hình

1. Cài đặt các gói phụ thuộc (nếu chưa cài):
   ```bash
   cd mcp-server
   npm install
   ```

2. Tạo file `.env` từ `.env.example`:
   ```bash
   cp .env.example .env
   ```
   Kiểm tra thông tin kết nối trong `.env`:
   ```env
   DB_HOST=localhost
   DB_PORT=3306
   DB_NAME=fashionshop
   DB_USER=fashionshop_mcp
   DB_PASSWORD=mcp_secret_pass_2026
   ```

---

## 3. Danh sách Tools cung cấp

| Tên Tool | Tham số chính | Mô tả chức năng |
| :--- | :--- | :--- |
| `check_low_stock` | `threshold` (mặc định 5) | Quét danh sách các biến thể sản phẩm (size, màu) có tồn kho $\le$ ngưỡng. |
| `get_revenue_summary` | `days` (mặc định 7) | Thống kê doanh thu thực tế (chỉ đơn hàng `COMPLETED`) và phân bổ trạng thái đơn trong $N$ ngày. |
| `create_promotional_coupon` | `code`, `name`, `discountType`, `discountValue`, `maxDiscount`, `minOrderValue`, `quantity`, `durationDays` | Tạo mã giảm giá mới với các quy tắc kiểm tra nghiêm ngặt (chống trùng, % từ 1-50%, giới hạn số tiền). |
| `search_products` | `keyword`, `limit` | Tìm kiếm sản phẩm theo tên hoặc danh mục kèm giá, sale và tổng tồn kho. |

---

## 4. Kiểm thử trước với MCP Inspector

Trước khi cấu hình vào Claude Desktop, bạn có thể kiểm thử trực quan tất cả các tool bằng công cụ chính thức **MCP Inspector**:

```bash
cd mcp-server
npx @modelcontextprotocol/inspector node index.js
```

1. Mở trình duyệt tại đường dẫn hiển thị (thường là `http://localhost:5173`).
2. Chọn tab **Tools** -> bấm **List Tools**.
3. Chọn từng tool, điền tham số và bấm **Run Tool** để xem dữ liệu trả về trực tiếp từ CSDL.

---

## 5. Tích hợp vào Claude Desktop

1. Mở file cấu hình Claude Desktop:
   - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
     (Đường dẫn thật: `C:\Users\<Tên-bạn>\AppData\Roaming\Claude\claude_desktop_config.json`)

2. Thêm cấu hình MCP Server:
   ```json
   {
     "mcpServers": {
       "fashionshop": {
         "command": "node",
         "args": [
           "C:\\Users\\MSI GF63\\Documents\\WWW.JAVA\\Đề tài\\Xay dung project\\Chotproject\\FashionShop\\mcp-server\\index.js"
         ]
       }
     }
   }
   ```
   *(Nhớ thay đổi đường dẫn tuyệt đối trỏ tới file `index.js` trên máy bạn nếu thư mục thay đổi).*

3. Khởi động lại ứng dụng **Claude Desktop**. Bạn sẽ thấy biểu tượng hình búa 🔨 (Tools) xuất hiện ở góc khung chat.
4. Thử ra lệnh cho Claude:
   - *"Kiểm tra kho giúp tôi xem có biến thể nào còn dưới 5 sản phẩm không?"*
   - *"Báo cáo doanh thu trong 30 ngày qua của FashionShop."*
   - *"Tạo giúp tôi mã giảm giá SALE10 giảm 10% cho đơn từ 200k thời hạn 15 ngày."*
