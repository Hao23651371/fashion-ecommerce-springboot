package com.iuh.fashionshop.service;

import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Autowired(required = false)
    private N8nWebhookService n8nWebhookService;

    @Value("${spring.mail.username:fashionshop.iuh2026@gmail.com}")
    private String fromEmail;

    /**
     * Gửi email mã OTP xác thực kích hoạt tài khoản.
     * Ưu tiên gửi tự động qua n8n Webhook, dự phòng bằng JavaMailSender (SMTP).
     */
    public boolean sendOtpVerificationEmail(String toEmail, String otpCode, String recipientName) {
        log.info("Yêu cầu gửi email xác thực tài khoản tới: {} | Mã OTP: {} (Mã dự phòng demo: 111111)", toEmail, otpCode);
        String subject = "Mã xác thực tài khoản Fashion Shop: " + otpCode;
        String actionText = "xác thực tài khoản";
        String plainText = buildPlainTextEmail(recipientName, otpCode, actionText);
        String htmlContent = buildEmailTemplate(recipientName, otpCode);
        return dispatchOtpEmail("REGISTER_OTP", toEmail, otpCode, recipientName, subject, actionText, plainText, htmlContent);
    }

    /**
     * Gửi email đặt lại mật khẩu cho tài khoản.
     * Ưu tiên gửi tự động qua n8n Webhook, dự phòng bằng JavaMailSender (SMTP).
     */
    public boolean sendPasswordResetEmail(String toEmail, String resetCode, String recipientName) {
        log.info("Yêu cầu gửi email đặt lại mật khẩu tới: {} | Mã OTP: {} (Mã dự phòng demo: 111111)", toEmail, resetCode);
        String subject = "Mã đặt lại mật khẩu Fashion Shop: " + resetCode;
        String actionText = "đặt lại mật khẩu";
        String plainText = buildPlainTextEmail(recipientName, resetCode, actionText);
        String htmlContent = buildPasswordResetEmailTemplate(recipientName, resetCode);
        return dispatchOtpEmail("RESET_PASSWORD_OTP", toEmail, resetCode, recipientName, subject, actionText, plainText, htmlContent);
    }

    private boolean dispatchOtpEmail(String eventType,
                                     String toEmail,
                                     String otpCode,
                                     String recipientName,
                                     String subject,
                                     String actionText,
                                     String plainText,
                                     String htmlContent) {
        // 1. Ưu tiên gửi tự động qua n8n Webhook
        if (n8nWebhookService != null
                && n8nWebhookService.sendOtpEmail(eventType, toEmail, otpCode, recipientName, subject, actionText, htmlContent)) {
            log.info("Gửi email {} qua n8n Webhook thành công tới: {}", actionText, toEmail);
            return true;
        }

        // 2. Dự phòng qua JavaMailSender nếu n8n chưa bật
        if (mailSender == null) {
            log.warn("JavaMailSender chưa được cấu hình và n8n OTP không khả dụng. Không thể gửi tới: {}", toEmail);
            return false;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            message.setHeader("Auto-Submitted", "auto-generated");
            message.setHeader("X-Auto-Response-Suppress", "All");
            message.setHeader("X-Mailer", "FashionShop Security Mailer v2.0");

            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());

            helper.setFrom(fromEmail, "Fashion Shop");
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(plainText, htmlContent);

            mailSender.send(message);
            log.info("Gửi email {} qua SMTP thành công tới: {}", actionText, toEmail);
            return true;
        } catch (Exception ex) {
            log.error("Không thể gửi email {} qua SMTP tới {}: {}", actionText, toEmail, ex.getMessage());
            return false;
        }
    }

    /**
     * Mẫu Plain Text hỗ trợ các trình đọc thư thuần và giảm tỷ lệ spam xuống mức thấp nhất
     */
    private String buildPlainTextEmail(String recipientName, String code, String action) {
        String name = (recipientName != null && !recipientName.isBlank()) ? recipientName : "Quý khách";
        return String.format(
            "FASHION SHOP - STUDIO & ATELIER\n\n" +
            "Xin chào %s,\n\n" +
            "Bạn vừa yêu cầu mã bảo mật để %s tại Fashion Shop.\n" +
            "Mã xác thực gồm 6 chữ số của bạn là: %s\n\n" +
            "Mã này có hiệu lực trong vòng 5 phút.\n" +
            "Lưu ý: Tuyệt đối không chia sẻ mã này cho bất kỳ ai để bảo vệ an toàn tài khoản.\n\n" +
            "Trân trọng,\n" +
            "Đội ngũ Fashion Shop Studio & Atelier\n" +
            "Hotline hỗ trợ: 1900 6868 | Website: fashionshop.com",
            name, action, code
        );
    }

    /**
     * Mẫu Email HTML Sạch - Trong - Tinh tế (Minimalist Luxury)
     */
    private String buildEmailTemplate(String recipientName, String otpCode) {
        String name = (recipientName != null && !recipientName.isBlank()) ? recipientName : "Quý khách";
        return """
            <!DOCTYPE html>
            <html lang="vi">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Xác thực tài khoản Fashion Shop</title>
            </head>
            <body style="margin: 0; padding: 0; background-color: #f7f4ef; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; color: #222222; -webkit-font-smoothing: antialiased;">
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 35px 15px; background-color: #f7f4ef;">
                    <tr>
                        <td align="center">
                            <table width="100%" style="max-width: 520px; background-color: #ffffff; border-radius: 12px; overflow: hidden; border: 1px solid #ebdcd0; box-shadow: 0 4px 20px rgba(0,0,0,0.03);" cellpadding="0" cellspacing="0">
                                
                                <!-- Brand Header: Thanh lịch, tinh tế, không dùng mảng đen dày -->
                                <tr>
                                    <td style="padding: 32px 30px 24px; text-align: center; border-bottom: 1px solid #f2ece4;">
                                        <div style="font-family: Georgia, serif; font-size: 21px; font-weight: 700; letter-spacing: 3px; color: #111111; text-transform: uppercase;">
                                            FASHION SHOP
                                        </div>
                                        <div style="font-size: 10px; letter-spacing: 2px; text-transform: uppercase; color: #8a8279; margin-top: 4px;">
                                            STUDIO &amp; ATELIER
                                        </div>
                                    </td>
                                </tr>

                                <!-- Body Content -->
                                <tr>
                                    <td style="padding: 32px 32px 28px;">
                                        <h1 style="margin: 0 0 14px 0; font-size: 18px; font-weight: 700; color: #111111; letter-spacing: -0.2px;">
                                            Xác thực tài khoản của bạn
                                        </h1>
                                        <p style="margin: 0 0 8px 0; font-size: 14px; line-height: 1.6; color: #444444;">
                                            Xin chào <strong>{{CUSTOMER_NAME}}</strong>,
                                        </p>
                                        <p style="margin: 0 0 24px 0; font-size: 14px; line-height: 1.6; color: #555555;">
                                            Cảm ơn bạn đã lựa chọn đăng ký tài khoản tại <strong>Fashion Shop</strong>. Để hoàn tất kích hoạt quyền truy cập, vui lòng sử dụng mã xác thực bảo mật bên dưới:
                                        </p>

                                        <!-- OTP Box: Nền kem trang nhã, số đen sắc nét, dễ đọc -->
                                        <div style="background-color: #faf7f2; border: 1px solid #ebdcd0; border-radius: 10px; padding: 22px 20px; text-align: center; margin: 20px 0 24px;">
                                            <div style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 1.8px; color: #7a736a; margin-bottom: 8px;">
                                                MÃ XÁC THỰC BẢO MẬT
                                            </div>
                                            <div style="font-size: 34px; font-weight: 800; letter-spacing: 10px; color: #111111; font-family: 'SF Pro Display', Consolas, monospace; padding-left: 10px;">
                                                {{OTP_CODE}}
                                            </div>
                                            <div style="font-size: 12px; color: #8a8279; margin-top: 8px;">
                                                ⏱️ Mã có hiệu lực trong <strong>5 phút</strong>
                                            </div>
                                        </div>

                                        <!-- Hộp ghi chú bảo mật -->
                                        <div style="background-color: #fbf9f6; border-left: 3px solid #111111; border-radius: 4px; padding: 12px 14px; margin-bottom: 20px; font-size: 13px; line-height: 1.5; color: #666057;">
                                            <strong>Bảo mật:</strong> Tuyệt đối không chia sẻ mã này cho người khác. Nhân viên Fashion Shop sẽ không bao giờ hỏi mã OTP của bạn.
                                        </div>

                                        <p style="margin: 0; font-size: 12.5px; line-height: 1.5; color: #888279;">
                                            Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua thư này hoặc thông báo cho bộ phận hỗ trợ của chúng tôi.
                                        </p>
                                    </td>
                                </tr>

                                <!-- Footer: Nhẹ nhàng, thông tin rõ ràng -->
                                <tr>
                                    <td style="background-color: #faf8f5; padding: 22px 30px; text-align: center; border-top: 1px solid #f0eae1; font-size: 12px; color: #91897f; line-height: 1.6;">
                                        <strong>Fashion Shop Studio &amp; Atelier</strong><br>
                                        Hỗ trợ trực tuyến 24/7 &bull; Email: fashionshop.iuh2026@gmail.com<br>
                                        &copy; 2026 Fashion Shop. Mọi quyền được bảo lưu.
                                    </td>
                                </tr>

                            </table>
                        </td>
                    </tr>
                </table>
            </body>
            </html>
            """
            .replace("{{CUSTOMER_NAME}}", name)
            .replace("{{OTP_CODE}}", otpCode);
    }

    /**
     * Mẫu Email HTML Đặt Lại Mật Khẩu Sạch - Trong - Tinh tế
     */
    private String buildPasswordResetEmailTemplate(String recipientName, String resetCode) {
        String name = (recipientName != null && !recipientName.isBlank()) ? recipientName : "Quý khách";
        return """
            <!DOCTYPE html>
            <html lang="vi">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Đặt lại mật khẩu Fashion Shop</title>
            </head>
            <body style="margin: 0; padding: 0; background-color: #f7f4ef; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; color: #222222; -webkit-font-smoothing: antialiased;">
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 35px 15px; background-color: #f7f4ef;">
                    <tr>
                        <td align="center">
                            <table width="100%" style="max-width: 520px; background-color: #ffffff; border-radius: 12px; overflow: hidden; border: 1px solid #ebdcd0; box-shadow: 0 4px 20px rgba(0,0,0,0.03);" cellpadding="0" cellspacing="0">
                                
                                <!-- Brand Header -->
                                <tr>
                                    <td style="padding: 32px 30px 24px; text-align: center; border-bottom: 1px solid #f2ece4;">
                                        <div style="font-family: Georgia, serif; font-size: 21px; font-weight: 700; letter-spacing: 3px; color: #111111; text-transform: uppercase;">
                                            FASHION SHOP
                                        </div>
                                        <div style="font-size: 10px; letter-spacing: 2px; text-transform: uppercase; color: #8a8279; margin-top: 4px;">
                                            BẢO MẬT TÀI KHOẢN
                                        </div>
                                    </td>
                                </tr>

                                <!-- Body Content -->
                                <tr>
                                    <td style="padding: 32px 32px 28px;">
                                        <h1 style="margin: 0 0 14px 0; font-size: 18px; font-weight: 700; color: #111111; letter-spacing: -0.2px;">
                                            Yêu cầu thiết lập lại mật khẩu
                                        </h1>
                                        <p style="margin: 0 0 8px 0; font-size: 14px; line-height: 1.6; color: #444444;">
                                            Xin chào <strong>{{CUSTOMER_NAME}}</strong>,
                                        </p>
                                        <p style="margin: 0 0 24px 0; font-size: 14px; line-height: 1.6; color: #555555;">
                                            Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu cho tài khoản Fashion Shop của bạn. Vui lòng nhập mã bảo mật dưới đây để thiết lập mật khẩu mới:
                                        </p>

                                        <!-- OTP Box -->
                                        <div style="background-color: #faf7f2; border: 1px solid #ebdcd0; border-radius: 10px; padding: 22px 20px; text-align: center; margin: 20px 0 24px;">
                                            <div style="font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 1.8px; color: #7a736a; margin-bottom: 8px;">
                                                MÃ ĐẶT LẠI MẬT KHẨU
                                            </div>
                                            <div style="font-size: 34px; font-weight: 800; letter-spacing: 10px; color: #111111; font-family: 'SF Pro Display', Consolas, monospace; padding-left: 10px;">
                                                {{RESET_CODE}}
                                            </div>
                                            <div style="font-size: 12px; color: #8a8279; margin-top: 8px;">
                                                ⏱️ Mã có hiệu lực trong <strong>5 phút</strong>
                                            </div>
                                        </div>

                                        <!-- Lưu ý an toàn -->
                                        <div style="background-color: #fbf9f6; border-left: 3px solid #111111; border-radius: 4px; padding: 12px 14px; margin-bottom: 20px; font-size: 13px; line-height: 1.5; color: #666057;">
                                            <strong>Bảo mật:</strong> Nếu bạn không yêu cầu đặt lại mật khẩu, xin hãy bỏ qua email này hoặc liên hệ ngay với chúng tôi để bảo vệ tài khoản.
                                        </div>

                                        <p style="margin: 0; font-size: 12.5px; line-height: 1.5; color: #888279;">
                                            Email này được gửi tự động bởi hệ thống bảo mật của Fashion Shop.
                                        </p>
                                    </td>
                                </tr>

                                <!-- Footer -->
                                <tr>
                                    <td style="background-color: #faf8f5; padding: 22px 30px; text-align: center; border-top: 1px solid #f0eae1; font-size: 12px; color: #91897f; line-height: 1.6;">
                                        <strong>Fashion Shop Studio &amp; Atelier</strong><br>
                                        Hỗ trợ trực tuyến 24/7 &bull; Email: fashionshop.iuh2026@gmail.com<br>
                                        &copy; 2026 Fashion Shop. Mọi quyền được bảo lưu.
                                    </td>
                                </tr>

                            </table>
                        </td>
                    </tr>
                </table>
            </body>
            </html>
            """
            .replace("{{CUSTOMER_NAME}}", name)
            .replace("{{RESET_CODE}}", resetCode);
    }
}
