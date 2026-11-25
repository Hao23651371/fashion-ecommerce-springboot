package com.iuh.fashionshop.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Service xử lý validate và upload hình ảnh sản phẩm lên Cloudinary.
 */
@Service
public class CloudinaryService {

    private static final Logger log = LoggerFactory.getLogger(CloudinaryService.class);
    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp");
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
            "image/jpeg", "image/jpg", "image/png", "image/webp"
    );
    private static final String PRODUCT_FOLDER = "fashionshop/products";

    private final String cloudName;
    private final String apiKey;
    private final String apiSecret;
    private final Cloudinary cloudinary;

    public CloudinaryService(
            @Value("${cloudinary.cloud-name:}") String cloudName,
            @Value("${cloudinary.api-key:}") String apiKey,
            @Value("${cloudinary.api-secret:}") String apiSecret) {
        this.cloudName = cloudName == null ? "" : cloudName.trim();
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.apiSecret = apiSecret == null ? "" : apiSecret.trim();
        this.cloudinary = new Cloudinary(ObjectUtils.asMap(
                "cloud_name", this.cloudName,
                "api_key", this.apiKey,
                "api_secret", this.apiSecret,
                "secure", true
        ));
    }

    /**
     * Kết quả trả về sau khi upload ảnh lên Cloudinary.
     */
    public record CloudinaryUploadResult(String secureUrl, String publicId) {
    }

    /**
     * Validate file ảnh không rỗng và đúng định dạng (jpg, jpeg, png, webp).
     */
    public void validateImageFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File ảnh không được để trống.");
        }

        String originalFilename = file.getOriginalFilename();
        String extension = extractExtension(originalFilename);
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new IllegalArgumentException(
                    "Định dạng file ảnh không hợp lệ. Chỉ chấp nhận: jpg, jpeg, png, webp.");
        }

        String contentType = file.getContentType();
        if (contentType != null && !contentType.isBlank()
                && !ALLOWED_CONTENT_TYPES.contains(contentType.toLowerCase(Locale.ROOT))) {
            throw new IllegalArgumentException(
                    "Kiểu nội dung (Content-Type) không hợp lệ: " + contentType
                            + ". Chỉ chấp nhận ảnh jpg, jpeg, png, webp.");
        }
    }

    /**
     * Upload file ảnh lên Cloudinary và trả về secure_url cùng public_id.
     */
    public CloudinaryUploadResult uploadImage(MultipartFile file) {
        validateImageFile(file);
        ensureConfigured();

        try {
            Map<?, ?> uploadResult = uploadBytes(file.getBytes());
            Object secureUrlObj = uploadResult.get("secure_url");
            if (secureUrlObj == null) {
                secureUrlObj = uploadResult.get("url");
            }
            if (secureUrlObj == null || secureUrlObj.toString().isBlank()) {
                throw new IllegalStateException("Cloudinary không trả về URL ảnh sau khi upload.");
            }
            String secureUrl = secureUrlObj.toString();
            Object publicIdObj = uploadResult.get("public_id");
            String publicId = publicIdObj != null ? publicIdObj.toString() : null;
            return new CloudinaryUploadResult(secureUrl, publicId);
        } catch (IOException e) {
            throw new IllegalStateException("Lỗi khi upload ảnh lên Cloudinary: " + e.getMessage(), e);
        }
    }

    /**
     * Xóa ảnh trên Cloudinary theo public_id (dùng khi cần dọn ảnh cũ).
     */
    public void deleteImage(String publicId) {
        if (publicId == null || publicId.isBlank() || !isConfigured()) {
            return;
        }
        try {
            cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
        } catch (Exception e) {
            log.warn("Không thể xóa ảnh cũ trên Cloudinary (publicId={}): {}", publicId, e.getMessage());
        }
    }

    protected Map<?, ?> uploadBytes(byte[] bytes) throws IOException {
        return cloudinary.uploader().upload(bytes, ObjectUtils.asMap(
                "folder", PRODUCT_FOLDER,
                "resource_type", "image"
        ));
    }

    private boolean isConfigured() {
        return !cloudName.isBlank() && !apiKey.isBlank() && !apiSecret.isBlank();
    }

    private void ensureConfigured() {
        if (!isConfigured()) {
            throw new IllegalStateException(
                    "Chưa cấu hình đầy đủ Cloudinary (cloudinary.cloud-name, cloudinary.api-key, cloudinary.api-secret).");
        }
    }

    private static String extractExtension(String filename) {
        if (filename == null || filename.isBlank()) {
            return "";
        }
        int dotIndex = filename.lastIndexOf('.');
        if (dotIndex < 0 || dotIndex == filename.length() - 1) {
            return "";
        }
        return filename.substring(dotIndex + 1).trim().toLowerCase(Locale.ROOT);
    }
}
