-- =============================================================================
-- Migration: Bổ sung cột receipt_code cho bảng stock_history (Phiếu nhập & kiểm kê)
-- Sử dụng khi nâng cấp cơ sở dữ liệu đã có dữ liệu mà không cần tạo lại bảng
-- =============================================================================

USE fashionshop;

-- 1. Thêm cột receipt_code nếu chưa tồn tại
SET @dbname = DATABASE();
SET @tablename = 'stock_history';
SET @columnname = 'receipt_code';
SET @preparedStatement = (SELECT IF(
    (
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE
            TABLE_SCHEMA = @dbname
            AND TABLE_NAME = @tablename
            AND COLUMN_NAME = @columnname
    ) > 0,
    'SELECT 1',
    'ALTER TABLE stock_history ADD COLUMN receipt_code VARCHAR(50) NULL AFTER reason;'
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;
