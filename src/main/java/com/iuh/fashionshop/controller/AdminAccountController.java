package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import com.iuh.fashionshop.service.AccountService;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

/** Trang tài khoản đăng nhập của admin. */
@Controller
@RequestMapping("/admin/account")
public class AdminAccountController {

    private final AccountRepository accountRepository;
    private final UserProfileRepository userProfileRepository;
    private final AccountService accountService;
    private final PasswordEncoder passwordEncoder;

    public AdminAccountController(AccountRepository accountRepository,
                                  UserProfileRepository userProfileRepository,
                                  AccountService accountService,
                                  PasswordEncoder passwordEncoder) {
        this.accountRepository = accountRepository;
        this.userProfileRepository = userProfileRepository;
        this.accountService = accountService;
        this.passwordEncoder = passwordEncoder;
    }

    @GetMapping
    public String account(Authentication auth, Model model) {
        model.addAttribute("pageTitle", "Tài khoản đăng nhập");
        if (auth != null && auth.isAuthenticated()) {
            String email = auth.getName().trim().toLowerCase();
            Optional<Account> accountOpt = accountRepository.findByEmail(email);
            Optional<UserProfile> profileOpt = userProfileRepository.findByAccountEmail(email);

            accountOpt.ifPresent(account -> model.addAttribute("adminAccount", account));
            profileOpt.ifPresent(profile -> model.addAttribute("adminProfile", profile));
            model.addAttribute("currentEmail", email);
        }
        return "admin/account";
    }

    /**
     * Cập nhật thông tin chi tiết tài khoản Admin (Họ tên, Số điện thoại, Ngày sinh).
     */
    @PostMapping("/update-profile")
    @Transactional
    public String updateProfile(@RequestParam String fullName,
                                @RequestParam(required = false) String phoneNumber,
                                @RequestParam(required = false) String birthDate,
                                Authentication auth,
                                RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        String email = auth.getName().trim().toLowerCase();

        // 1. Ràng buộc Họ và tên
        if (fullName == null || fullName.trim().isBlank()) {
            ra.addFlashAttribute("errorMessage", "Họ và tên không được để trống.");
            return "redirect:/admin/account";
        }
        String cleanFullName = fullName.trim();
        if (cleanFullName.length() < 2 || cleanFullName.length() > 100) {
            ra.addFlashAttribute("errorMessage", "Họ và tên phải có độ dài từ 2 đến 100 ký tự.");
            return "redirect:/admin/account";
        }

        // 2. Ràng buộc Số điện thoại
        String cleanPhone = null;
        if (phoneNumber != null && !phoneNumber.trim().isBlank()) {
            cleanPhone = phoneNumber.trim().replaceAll("[\\s.-]", "");
            if (!cleanPhone.matches("^(0[3|5|7|8|9])[0-9]{8}$")) {
                ra.addFlashAttribute("errorMessage", "Số điện thoại không hợp lệ (yêu cầu 10 chữ số, bắt đầu bằng 03, 05, 07, 08, 09).");
                return "redirect:/admin/account";
            }
            if (accountService.isPhoneTakenByAnotherUser(cleanPhone, email)) {
                ra.addFlashAttribute("errorMessage", "Số điện thoại này đã được sử dụng bởi một tài khoản khác trong hệ thống.");
                return "redirect:/admin/account";
            }
        }

        // 3. Ràng buộc Ngày sinh
        LocalDate parsedBirthDate = null;
        if (birthDate != null && !birthDate.trim().isBlank()) {
            try {
                parsedBirthDate = LocalDate.parse(birthDate.trim(), DateTimeFormatter.ISO_LOCAL_DATE);
                if (parsedBirthDate.isAfter(LocalDate.now())) {
                    ra.addFlashAttribute("errorMessage", "Ngày sinh không được là ngày trong tương lai.");
                    return "redirect:/admin/account";
                }
            } catch (Exception e) {
                ra.addFlashAttribute("errorMessage", "Định dạng ngày sinh không hợp lệ (YYYY-MM-DD).");
                return "redirect:/admin/account";
            }
        }

        // 4. Lưu UserProfile
        UserProfile profile = userProfileRepository.findByAccountEmail(email)
                .orElseGet(() -> {
                    Account acc = accountRepository.findByEmail(email)
                            .orElseThrow(() -> new IllegalStateException("Không tìm thấy tài khoản quản trị: " + email));
                    UserProfile newProfile = new UserProfile();
                    newProfile.setAccount(acc);
                    return newProfile;
                });

        profile.setFullName(cleanFullName);
        profile.setPhoneNumber(cleanPhone);
        profile.setBirthDate(parsedBirthDate);
        userProfileRepository.save(profile);

        ra.addFlashAttribute("successMessage", "Cập nhật thông tin chi tiết tài khoản thành công!");
        return "redirect:/admin/account";
    }

    /**
     * Đổi mật khẩu tài khoản quản trị (tách biệt hoàn toàn khỏi chỉnh sửa thông tin).
     */
    @PostMapping("/change-password")
    @Transactional
    public String changePassword(@RequestParam String currentPassword,
                                 @RequestParam String newPassword,
                                 @RequestParam String confirmPassword,
                                 Authentication auth,
                                 RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        String email = auth.getName().trim().toLowerCase();
        Account account = accountRepository.findByEmail(email).orElse(null);
        if (account == null) {
            ra.addFlashAttribute("pwdError", "Không tìm thấy tài khoản quản trị trong hệ thống.");
            return "redirect:/admin/account";
        }

        // 1. Kiểm tra mật khẩu hiện tại
        if (currentPassword == null || currentPassword.isBlank()) {
            ra.addFlashAttribute("pwdError", "Vui lòng nhập mật khẩu cũ (mật khẩu hiện tại).");
            return "redirect:/admin/account";
        }
        if (!passwordEncoder.matches(currentPassword, account.getPassword())) {
            ra.addFlashAttribute("pwdError", "Mật khẩu cũ (mật khẩu hiện tại) không chính xác.");
            return "redirect:/admin/account";
        }

        // 2. Ràng buộc mật khẩu mới
        if (newPassword == null || newPassword.trim().length() < 6) {
            ra.addFlashAttribute("pwdError", "Mật khẩu mới phải có độ dài tối thiểu từ 6 ký tự.");
            return "redirect:/admin/account";
        }

        // 3. Ràng buộc trùng khớp xác nhận
        if (!newPassword.equals(confirmPassword)) {
            ra.addFlashAttribute("pwdError", "Xác nhận lại mật khẩu mới không trùng khớp.");
            return "redirect:/admin/account";
        }

        // 4. Mật khẩu mới không được giống mật khẩu cũ
        if (passwordEncoder.matches(newPassword, account.getPassword())) {
            ra.addFlashAttribute("pwdError", "Mật khẩu mới không được trùng với mật khẩu cũ đang sử dụng.");
            return "redirect:/admin/account";
        }

        // 5. Cập nhật và lưu vào CSDL
        account.setPassword(passwordEncoder.encode(newPassword));
        accountRepository.save(account);

        ra.addFlashAttribute("pwdSuccess", "Đổi mật khẩu thành công! Bạn có thể sử dụng mật khẩu mới này cho những lần đăng nhập tiếp theo.");
        return "redirect:/admin/account";
    }
}
