package com.iuh.fashionshop.service;

import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:fashionshop.system@gmail.com}")
    private String fromEmail;

    /**
     * Gửi email mã OTP xác thực kích hoạt tài khoản.
     * Phương thức chạy an toàn: nếu gửi mail thật bị lỗi mạng hoặc chưa cấu hình password thật,
     * mã OTP vẫn sẽ được in to rõ ràng ra Console để test và không làm gián đoạn đăng ký.
     */
    public boolean sendOtpVerificationEmail(String toEmail, String otpCode, String recipientName) {
        log.info("================================================================================");
        log.info(">> [FASHION SHOP - EMAIL VERIFICATION]");
        log.info(">> Gửi mã OTP tới email: {}", toEmail);
        log.info(">> Tên khách hàng: {}", recipientName != null ? recipientName : "Quý khách");
        log.info(">> MÃ XÁC THỰC OTP (Hiệu lực 5 phút): >>> {} <<<", otpCode);
        log.info(">> MÃ BYPASS DEMO NHANH: >>> 111111 <<<");
        log.info("================================================================================");

        if (mailSender == null) {
            log.warn("JavaMailSender chưa được cấu hình. Mã OTP đã được in ra console để kiểm thử.");
            return false;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());

            helper.setFrom(fromEmail, "FASHION SHOP ATELIER");
            helper.setTo(toEmail);
            helper.setSubject("Mã xác thực đăng ký tài khoản Fashion Shop: " + otpCode);

            String htmlContent = buildEmailTemplate(recipientName, otpCode);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            log.info(">> Gửi email xác thực thành công tới: {}", toEmail);
            return true;
        } catch (Exception ex) {
            log.error(">> Không thể gửi email qua SMTP: {}", ex.getMessage(), ex);
            log.info(">> Vui lòng dùng mã OTP in ở console phía trên hoặc mã demo nhanh '111111' để tiếp tục.");
            return false;
        }
    }

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
            <body style="margin: 0; padding: 0; background-color: #f7f7f9; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #222222;">
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 40px 15px;">
                    <tr>
                        <td align="center">
                            <table width="100%" max-width="560px" style="max-width: 560px; background-color: #ffffff; border-radius: 14px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.06); border: 1px solid #e5e7eb;" cellpadding="0" cellspacing="0">
                                <!-- Header -->
                                <tr>
                                    <td style="background-color: #111111; padding: 32px 30px; text-align: center;">
                                        <div style="font-size: 22px; font-weight: 800; letter-spacing: 4px; color: #ffffff; text-transform: uppercase;">
                                            FASHION SHOP
                                        </div>
                                        <div style="font-size: 11px; letter-spacing: 2px; color: #d4af37; text-transform: uppercase; margin-top: 6px;">
                                            Haute Couture & Bespoke Tailoring
                                        </div>
                                    </td>
                                </tr>
                                <!-- Body -->
                                <tr>
                                    <td style="padding: 40px 35px 30px 35px;">
                                        <h2 style="margin: 0 0 14px 0; font-size: 20px; font-weight: 700; color: #111827;">
                                            Xác thực tài khoản của bạn
                                        </h2>
                                        <p style="margin: 0 0 20px 0; font-size: 14px; line-height: 1.6; color: #4b5563;">
                                            Xin chào <strong>{{CUSTOMER_NAME}}</strong>,<br>
                                            Cảm ơn bạn đã lựa chọn trở thành thành viên tại <strong>Fashion Shop</strong>. Để hoàn tất kích hoạt tài khoản, vui lòng sử dụng mã xác thực bên dưới:
                                        </p>
                                        
                                        <!-- OTP Box -->
                                        <div style="background: #111827; border-radius: 12px; padding: 24px; text-align: center; margin: 25px 0; border: 1px solid #374151;">
                                            <div style="font-size: 12px; text-transform: uppercase; letter-spacing: 2px; color: #9ca3af; margin-bottom: 8px;">
                                                MÃ XÁC THỰC CỦA BẠN
                                            </div>
                                            <div style="font-size: 36px; font-weight: 800; letter-spacing: 12px; color: #38bdf8; font-family: 'Courier New', monospace; padding-left: 12px;">
                                                {{OTP_CODE}}
                                            </div>
                                            <div style="font-size: 12px; color: #cbd5e1; margin-top: 10px;">
                                                ⏱️ Mã có hiệu lực trong <strong>5 phút</strong>
                                            </div>
                                        </div>

                                        <p style="margin: 0 0 10px 0; font-size: 13px; line-height: 1.6; color: #6b7280;">
                                            * Tuyệt đối không chia sẻ mã xác thực này cho người khác để bảo vệ an toàn cho tài khoản.
                                        </p>
                                        <p style="margin: 0; font-size: 13px; line-height: 1.6; color: #6b7280;">
                                            Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.
                                        </p>
                                    </td>
                                </tr>
                                <!-- Footer -->
                                <tr>
                                    <td style="background-color: #f8fafc; padding: 22px 30px; text-align: center; border-top: 1px solid #f1f5f9; font-size: 12px; color: #94a3b8;">
                                        Fashion Shop Atelier © 2026. Mọi quyền được bảo lưu.<br>
                                        Email tự động, vui lòng không trả lời thư này.
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
}
