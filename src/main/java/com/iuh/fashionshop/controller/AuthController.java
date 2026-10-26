package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.RegisterForm;
import com.iuh.fashionshop.service.AccountService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

@Controller
public class AuthController {

    private final AccountService accountService;
    private final DataSource dataSource;

    public AuthController(AccountService accountService, DataSource dataSource) {
        this.accountService = accountService;
        this.dataSource = dataSource;
    }

    @GetMapping("/login")
    public String showLoginPage(Model model) {
        checkDatabaseConnection(model);
        return "auth/login";
    }

    private void checkDatabaseConnection(Model model) {
        try (Connection conn = dataSource.getConnection()) {
            if (conn == null || !conn.isValid(2)) {
                throw new SQLException("Không thể kết nối hoặc xác thực trạng thái kết nối đến CSDL.");
            }
            try (Statement stmt = conn.createStatement()) {
                stmt.setQueryTimeout(2);
                stmt.execute("SELECT 1");
            }
            model.addAttribute("dbConnected", true);
        } catch (Exception e) {
            model.addAttribute("dbConnected", false);
            String errorMsg = e.getMessage();
            if (errorMsg == null || errorMsg.isBlank()) {
                errorMsg = e.toString();
            }
            model.addAttribute("dbErrorMessage", errorMsg);

            String dbUrl = "jdbc:mariadb://localhost:3306/fashionshop";
            String dbUser = "root";
            try {
                if (dataSource instanceof com.zaxxer.hikari.HikariDataSource hikari) {
                    if (hikari.getJdbcUrl() != null) dbUrl = hikari.getJdbcUrl();
                    if (hikari.getUsername() != null) dbUser = hikari.getUsername();
                }
            } catch (Throwable ignored) {}
            model.addAttribute("dbUrl", dbUrl);
            model.addAttribute("dbUser", dbUser);
        }
    }

    @GetMapping({"/terms", "/policy", "/support", "/auth/terms"})
    public String showTermsPage() {
        return "auth/terms";
    }

    @GetMapping("/register")
    public String showRegisterPage(@ModelAttribute("registerForm") RegisterForm registerForm) {
        return "auth/register";
    }

    /**
     * API gửi mã OTP xác thực khi đăng ký:
     * - Kiểm tra tính hợp lệ toàn bộ form đăng ký
     * - Nếu hợp lệ -> sinh mã OTP 6 số (hạn 5 phút), gửi email và in console
     * - Trả về kết quả JSON để frontend mở Modal nhập mã OTP
     */
    @PostMapping("/register/send-otp")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> sendRegisterOtp(
            @Valid @ModelAttribute("registerForm") RegisterForm registerForm,
            BindingResult result) {

        Map<String, Object> response = new HashMap<>();

        // 1. Kiểm tra mật khẩu xác nhận
        if (!result.hasFieldErrors("password") && !result.hasFieldErrors("confirmPassword")) {
            if (registerForm.getPassword() != null && !registerForm.getPassword().equals(registerForm.getConfirmPassword())) {
                result.rejectValue("confirmPassword", "mismatch", "Mật khẩu xác nhận không khớp với mật khẩu đã nhập");
            }
        }

        // 2. Kiểm tra email đã được kích hoạt trước đó chưa
        if (!result.hasFieldErrors("email") && registerForm.getEmail() != null && !registerForm.getEmail().isBlank()) {
            if (accountService.isEmailAlreadyVerified(registerForm.getEmail())) {
                result.rejectValue("email", "duplicate", "Email này đã được đăng ký và kích hoạt tài khoản. Vui lòng đăng nhập.");
            }
        }

        // 3. Kiểm tra số điện thoại (nếu có nhập)
        if (!result.hasFieldErrors("phoneNumber") && registerForm.getPhoneNumber() != null && !registerForm.getPhoneNumber().isBlank()) {
            if (accountService.isPhoneTakenByAnotherUser(registerForm.getPhoneNumber(), registerForm.getEmail())) {
                result.rejectValue("phoneNumber", "duplicate", "Số điện thoại này đã được đăng ký cho tài khoản khác.");
            }
        }

        // 4. Nếu có lỗi validation
        if (result.hasErrors()) {
            Map<String, String> fieldErrors = new HashMap<>();
            for (FieldError err : result.getFieldErrors()) {
                fieldErrors.put(err.getField(), err.getDefaultMessage());
            }
            response.put("success", false);
            response.put("errors", fieldErrors);
            response.put("message", "Thông tin đăng ký chưa hợp lệ. Vui lòng kiểm tra lại.");
            return ResponseEntity.badRequest().body(response);
        }

        try {
            accountService.initiateRegistration(registerForm);
            response.put("success", true);
            response.put("email", registerForm.getEmail().trim().toLowerCase());
            response.put("message", "Mã xác thực 6 số đã được gửi tới email của bạn (hiệu lực trong 5 phút).");
            return ResponseEntity.ok(response);
        } catch (Exception ex) {
            response.put("success", false);
            response.put("message", "Có lỗi xảy ra: " + ex.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * API xác thực mã OTP nhập vào từ hộp thoại:
     * - Chấp nhận mã dự phòng 111111 (demo nhanh)
     * - Hoặc mã OTP gửi qua email còn trong hạn 5 phút
     */
    @PostMapping("/register/verify-otp")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> verifyRegisterOtp(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");
        String otp = payload.get("otp");

        Map<String, Object> result = accountService.verifyRegistrationOtp(email, otp);
        if (Boolean.TRUE.equals(result.get("success"))) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.badRequest().body(result);
        }
    }

    /**
     * API gửi lại mã OTP mới (gia hạn thêm 5 phút):
     */
    @PostMapping("/register/resend-otp")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> resendRegisterOtp(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");
        Map<String, Object> result = accountService.resendRegistrationOtp(email);
        if (Boolean.TRUE.equals(result.get("success"))) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.badRequest().body(result);
        }
    }

    /**
     * Fallback POST /register truyền thống (hỗ trợ trường hợp tắt JavaScript)
     */
    @PostMapping("/register")
    public String processRegister(@Valid @ModelAttribute("registerForm") RegisterForm registerForm,
                                  BindingResult result,
                                  RedirectAttributes redirect) {

        if (!result.hasFieldErrors("password") && !result.hasFieldErrors("confirmPassword")) {
            if (registerForm.getPassword() != null && !registerForm.getPassword().equals(registerForm.getConfirmPassword())) {
                result.rejectValue("confirmPassword", "mismatch", "Mật khẩu xác nhận không khớp với mật khẩu đã nhập");
            }
        }

        if (!result.hasFieldErrors("email") && registerForm.getEmail() != null && !registerForm.getEmail().isBlank()) {
            if (accountService.isEmailAlreadyVerified(registerForm.getEmail())) {
                result.rejectValue("email", "duplicate", "Email này đã được đăng ký và kích hoạt tài khoản. Vui lòng đăng nhập.");
            }
        }

        if (!result.hasFieldErrors("phoneNumber") && registerForm.getPhoneNumber() != null && !registerForm.getPhoneNumber().isBlank()) {
            if (accountService.isPhoneTakenByAnotherUser(registerForm.getPhoneNumber(), registerForm.getEmail())) {
                result.rejectValue("phoneNumber", "duplicate", "Số điện thoại này đã được đăng ký cho tài khoản khác.");
            }
        }

        if (result.hasErrors()) {
            registerForm.setPassword("");
            registerForm.setConfirmPassword("");
            return "auth/register";
        }

        accountService.register(registerForm);
        redirect.addFlashAttribute("registered", true);
        return "redirect:/login?registered=true";
    }

    @GetMapping("/logout")
    public String logout(HttpServletRequest request, HttpServletResponse response) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null) {
            new SecurityContextLogoutHandler().logout(request, response, auth);
        }
        return "redirect:/login?logout=true";
    }
}