-- =========================================================================
-- SCRIPT TẠO USER CHO FASHIONSHOP MCP SERVER (NGUYÊN TẮC ĐẶC QUYỀN TỐI THIỂU)
-- =========================================================================
-- Hướng dẫn:
-- 1. Mở HeidiSQL hoặc DBeaver, đăng nhập bằng tài khoản root.
-- 2. Chạy toàn bộ script này (F9 trong HeidiSQL) để tạo user chuyên biệt cho MCP.
-- 3. User này CHỈ có quyền:
--    - ĐỌC (SELECT) trên toàn bộ database fashionshop
--    - THÊM MỚI (INSERT) chỉ riêng trên bảng coupon
--    - TUYỆT ĐỐI KHÔNG có quyền UPDATE, DELETE hay DROP bất kỳ bảng nào!
-- =========================================================================

CREATE USER IF NOT EXISTS 'fashionshop_mcp'@'localhost' IDENTIFIED BY 'CHANGE_ME';

-- Cấp quyền Đọc dữ liệu toàn shop
GRANT SELECT ON fashionshop.* TO 'fashionshop_mcp'@'localhost';

-- Cấp quyền Thêm mã giảm giá mới
GRANT INSERT ON fashionshop.coupon TO 'fashionshop_mcp'@'localhost';

-- Áp dụng thay đổi quyền
FLUSH PRIVILEGES;

-- Kiểm tra quyền vừa cấp:
SHOW GRANTS FOR 'fashionshop_mcp'@'localhost';
