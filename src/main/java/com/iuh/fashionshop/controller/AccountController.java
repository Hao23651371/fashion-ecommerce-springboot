package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.ShippingAddress;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.ShippingAddressRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import com.iuh.fashionshop.service.AccountService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Trang tài khoản khách hàng: lấy dữ liệu thật từ database theo email đang đăng
 * nhập.
 */
@Controller
@RequestMapping("/account")
public class AccountController {

    private static final String IN_PROGRESS = "'PENDING','CONFIRMED','PROCESSING','SHIPPING'";

    private final JdbcTemplate jdbc;
    private final AccountRepository accountRepository;
    private final UserProfileRepository userProfileRepository;
    private final ShippingAddressRepository shippingAddressRepository;
    private final PasswordEncoder passwordEncoder;
    private final AccountService accountService;

    public AccountController(JdbcTemplate jdbc,
            AccountRepository accountRepository,
            UserProfileRepository userProfileRepository,
            ShippingAddressRepository shippingAddressRepository,
            PasswordEncoder passwordEncoder,
            AccountService accountService) {
        this.jdbc = jdbc;
        this.accountRepository = accountRepository;
        this.userProfileRepository = userProfileRepository;
        this.shippingAddressRepository = shippingAddressRepository;
        this.passwordEncoder = passwordEncoder;
        this.accountService = accountService;
    }

    @GetMapping
    public String account(@RequestParam(required = false, defaultValue = "profile") String tab,
            Authentication auth,
            Model model) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        String email = auth.getName().trim().toLowerCase();

        // 1. Thông tin cá nhân (account + user_profile)
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT up.id AS profileId, up.full_name AS fullName, up.phone_number AS phone,
                       DATE_FORMAT(up.birth_date, '%d/%m/%Y') AS birthDate,
                       DATE_FORMAT(up.birth_date, '%Y-%m-%d') AS birthDateIso,
                       a.email AS email,
                       DATE_FORMAT(a.last_login_at, '%H:%i - %d/%m/%Y') AS lastLoginAt
                FROM account a
                LEFT JOIN user_profile up ON up.account_id = a.id
                WHERE a.email = ?
                """, email);

        Map<String, Object> profile = rows.isEmpty() ? null : rows.get(0);
        model.addAttribute("profile", profile);
        model.addAttribute("email", email);
        model.addAttribute("currentTab", tab);

        Object profileIdObj = profile == null ? null : profile.get("profileId");
        Long profileId = profileIdObj instanceof Number ? ((Number) profileIdObj).longValue() : null;

        long processingCount = 0, orderCount = 0, wishlistCount = 0;
        List<ShippingAddress> addresses = List.of();
        String defaultAddress = null;

        if (profileId != null) {
            orderCount = count("SELECT COUNT(*) FROM orders WHERE user_profile_id = ?", profileId);
            processingCount = count(
                    "SELECT COUNT(*) FROM orders WHERE user_profile_id = ? AND status IN (" + IN_PROGRESS + ")",
                    profileId);
            wishlistCount = count("SELECT COUNT(*) FROM wishlist_item WHERE user_profile_id = ?", profileId);

            addresses = shippingAddressRepository.findByUserProfileIdOrderByDefaultAddressDescIdDesc(profileId);
            defaultAddress = addresses.stream()
                    .filter(ShippingAddress::isDefaultAddress)
                    .map(ShippingAddress::getAddress)
                    .findFirst()
                    .orElse(addresses.isEmpty() ? null : addresses.get(0).getAddress());
        }

        model.addAttribute("addresses", addresses);
        model.addAttribute("defaultAddress", defaultAddress);
        model.addAttribute("processingCount", processingCount);
        model.addAttribute("orderCount", orderCount);
        model.addAttribute("wishlistCount", wishlistCount);

        return "user/account";
    }

    @PostMapping("/update-profile")
    @Transactional
    public String updateProfile(@RequestParam(required = false) String fullName,
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String birthDate,
            Authentication auth,
            RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }

        // 1. Ràng buộc Họ và tên
        if (fullName == null || fullName.trim().isBlank()) {
            ra.addFlashAttribute("errorMessage", "Họ và tên không được để trống.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }
        String cleanFullName = fullName.trim();
        if (cleanFullName.length() < 2 || cleanFullName.length() > 100) {
            ra.addFlashAttribute("errorMessage", "Họ và tên phải có độ dài từ 2 đến 100 ký tự.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }

        // 2. Ràng buộc Số điện thoại
        if (phone == null || phone.trim().isBlank()) {
            ra.addFlashAttribute("errorMessage", "Số điện thoại không được để trống.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }
        String cleanPhone = phone.trim().replaceAll("[\\s.-]", "");
        if (cleanPhone.startsWith("+84")) {
            cleanPhone = "0" + cleanPhone.substring(3);
        }
        // Định dạng SĐT di động Việt Nam: 10 chữ số, bắt đầu bằng 03, 05, 07, 08, 09
        if (!cleanPhone.matches("^0[35789]\\d{8}$")) {
            ra.addFlashAttribute("errorMessage", "Số điện thoại không hợp lệ (phải gồm 10 chữ số và bắt đầu bằng 03, 05, 07, 08 hoặc 09).");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }
        // Kiểm tra số điện thoại có bị tài khoản khác sử dụng chưa
        if (accountService.isPhoneTakenByAnotherUser(cleanPhone, auth.getName())) {
            ra.addFlashAttribute("errorMessage", "Số điện thoại này đã được sử dụng bởi một tài khoản khác.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }

        // 3. Ràng buộc Ngày sinh
        if (birthDate == null || birthDate.trim().isBlank()) {
            ra.addFlashAttribute("errorMessage", "Ngày sinh không được để trống.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }
        LocalDate parsedBirthDate;
        try {
            parsedBirthDate = LocalDate.parse(birthDate.trim(), DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", "Định dạng ngày sinh không hợp lệ.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }

        LocalDate today = LocalDate.now();
        if (parsedBirthDate.isAfter(today)) {
            ra.addFlashAttribute("errorMessage", "Ngày sinh không thể là ngày trong tương lai.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }
        if (parsedBirthDate.isEqual(today)) {
            ra.addFlashAttribute("errorMessage", "Ngày sinh phải trước ngày hiện tại.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }
        if (parsedBirthDate.isAfter(today.minusYears(15))) {
            ra.addFlashAttribute("errorMessage", "Khách hàng phải từ đủ 15 tuổi trở lên.");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }
        if (parsedBirthDate.isBefore(today.minusYears(120))) {
            ra.addFlashAttribute("errorMessage", "Ngày sinh không hợp lệ (vượt quá 120 tuổi).");
            ra.addFlashAttribute("openEditProfileModal", true);
            return "redirect:/account?tab=profile";
        }

        UserProfile userProfile = getOrCreateUserProfile(auth.getName());
        userProfile.setFullName(cleanFullName);
        userProfile.setPhoneNumber(cleanPhone);
        userProfile.setBirthDate(parsedBirthDate);

        userProfileRepository.save(userProfile);
        ra.addFlashAttribute("successMessage", "Cập nhật thông tin cá nhân thành công!");
        return "redirect:/account?tab=profile";
    }

    @PostMapping("/address/add")
    @Transactional
    public String addAddress(
            @RequestParam(required = false) String recipientName,
            @RequestParam(required = false) String recipientPhone,
            @RequestParam String address,
            @RequestParam(defaultValue = "false") boolean defaultAddress,
            Authentication auth,
            RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        if (address == null || address.trim().isBlank()) {
            ra.addFlashAttribute("errorMessage", "Vui lòng nhập địa chỉ giao hàng hợp lệ");
            return "redirect:/account?tab=address";
        }

        UserProfile userProfile = getOrCreateUserProfile(auth.getName());
        List<ShippingAddress> existing = shippingAddressRepository
                .findByUserProfileIdOrderByDefaultAddressDescIdDesc(userProfile.getId());

        boolean makeDefault = defaultAddress || existing.isEmpty();
        if (makeDefault) {
            shippingAddressRepository.resetDefaultAddress(userProfile.getId());
        }

        ShippingAddress newAddr = new ShippingAddress();
        newAddr.setUserProfile(userProfile);
        newAddr.setAddress(address.trim());
        newAddr.setRecipientName(
                recipientName != null && !recipientName.isBlank() ? recipientName.trim() : userProfile.getFullName());
        newAddr.setRecipientPhone(
                recipientPhone != null && !recipientPhone.isBlank() ? recipientPhone.trim() : userProfile.getPhoneNumber());
        newAddr.setDefaultAddress(makeDefault);
        shippingAddressRepository.save(newAddr);

        ra.addFlashAttribute("successMessage", "Đã thêm địa chỉ giao hàng mới thành công!");
        return "redirect:/account?tab=address";
    }

    @PostMapping("/address/default/{id}")
    @Transactional
    public String setDefaultAddress(@PathVariable Long id,
            Authentication auth,
            RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        UserProfile userProfile = getOrCreateUserProfile(auth.getName());
        Optional<ShippingAddress> addrOpt = shippingAddressRepository.findById(id);

        if (addrOpt.isPresent() && addrOpt.get().getUserProfile().getId().equals(userProfile.getId())) {
            shippingAddressRepository.resetDefaultAddress(userProfile.getId());
            ShippingAddress addr = addrOpt.get();
            addr.setDefaultAddress(true);
            shippingAddressRepository.save(addr);
            ra.addFlashAttribute("successMessage", "Đã đặt làm địa chỉ mặc định!");
        } else {
            ra.addFlashAttribute("errorMessage", "Không tìm thấy địa chỉ hợp lệ.");
        }

        return "redirect:/account?tab=address";
    }

    @PostMapping("/address/delete/{id}")
    @Transactional
    public String deleteAddress(@PathVariable Long id,
            Authentication auth,
            RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        UserProfile userProfile = getOrCreateUserProfile(auth.getName());
        Optional<ShippingAddress> addrOpt = shippingAddressRepository.findById(id);

        if (addrOpt.isPresent() && addrOpt.get().getUserProfile().getId().equals(userProfile.getId())) {
            boolean wasDefault = addrOpt.get().isDefaultAddress();
            shippingAddressRepository.delete(addrOpt.get());

            // Nếu vừa xóa địa chỉ mặc định, tự động gán địa chỉ còn lại làm mặc định
            if (wasDefault) {
                List<ShippingAddress> remain = shippingAddressRepository
                        .findByUserProfileIdOrderByDefaultAddressDescIdDesc(userProfile.getId());
                if (!remain.isEmpty()) {
                    ShippingAddress newDef = remain.get(0);
                    newDef.setDefaultAddress(true);
                    shippingAddressRepository.save(newDef);
                }
            }
            ra.addFlashAttribute("successMessage", "Đã xóa địa chỉ thành công!");
        } else {
            ra.addFlashAttribute("errorMessage", "Không tìm thấy địa chỉ để xóa.");
        }

        return "redirect:/account?tab=address";
    }

    @PostMapping("/address/update")
    @Transactional
    public String updateAddress(@RequestParam Long id,
            @RequestParam(required = false) String recipientName,
            @RequestParam(required = false) String recipientPhone,
            @RequestParam String address,
            @RequestParam(defaultValue = "false") boolean defaultAddress,
            Authentication auth,
            RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        if (address == null || address.trim().isBlank()) {
            ra.addFlashAttribute("errorMessage", "Địa chỉ giao hàng không được để trống.");
            return "redirect:/account?tab=address";
        }

        UserProfile userProfile = getOrCreateUserProfile(auth.getName());
        Optional<ShippingAddress> addrOpt = shippingAddressRepository.findById(id);

        if (addrOpt.isPresent() && addrOpt.get().getUserProfile().getId().equals(userProfile.getId())) {
            ShippingAddress addr = addrOpt.get();
            addr.setAddress(address.trim());
            if (recipientName != null && !recipientName.isBlank()) {
                addr.setRecipientName(recipientName.trim());
            }
            if (recipientPhone != null && !recipientPhone.isBlank()) {
                addr.setRecipientPhone(recipientPhone.trim());
            }
            if (defaultAddress && !addr.isDefaultAddress()) {
                shippingAddressRepository.resetDefaultAddress(userProfile.getId());
                addr.setDefaultAddress(true);
            }
            shippingAddressRepository.save(addr);
            ra.addFlashAttribute("successMessage", "Đã cập nhật địa chỉ giao hàng thành công!");
        } else {
            ra.addFlashAttribute("errorMessage", "Không tìm thấy địa chỉ hợp lệ để cập nhật.");
        }

        return "redirect:/account?tab=address";
    }

    @GetMapping({ "/security", "/account/security" })
    public String security(Authentication auth, Model model) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        String email = auth.getName().trim().toLowerCase();

        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT up.id AS profileId, up.full_name AS fullName, up.phone_number AS phone,
                       a.email AS email,
                       DATE_FORMAT(a.last_login_at, '%H:%i - %d/%m/%Y') AS lastLoginAt
                FROM account a
                LEFT JOIN user_profile up ON up.account_id = a.id
                WHERE a.email = ?
                """, email);

        Map<String, Object> profile = rows.isEmpty() ? null : rows.get(0);
        model.addAttribute("profile", profile);
        model.addAttribute("email", email);

        Object profileIdObj = profile == null ? null : profile.get("profileId");
        Long profileId = profileIdObj instanceof Number ? ((Number) profileIdObj).longValue() : null;

        long processingCount = 0, orderCount = 0, wishlistCount = 0;
        if (profileId != null) {
            orderCount = count("SELECT COUNT(*) FROM orders WHERE user_profile_id = ?", profileId);
            wishlistCount = count("""
                        SELECT COUNT(w.id) FROM wishlist_item w
                        JOIN product p ON p.id = w.product_id
                        JOIN category c ON c.id = p.category_id
                        WHERE w.user_profile_id = ? AND p.status = 'ACTIVE' AND c.status = 'VISIBLE'
                    """, profileId);
        }

        model.addAttribute("orderCount", orderCount);
        model.addAttribute("wishlistCount", wishlistCount);
        return "user/security";
    }

    @PostMapping("/change-password")
    @Transactional
    public String changePassword(@RequestParam String currentPassword,
            @RequestParam String newPassword,
            @RequestParam String confirmPassword,
            @RequestParam(required = false, defaultValue = "/account/security") String redirectUrl,
            Authentication auth,
            RedirectAttributes ra) {
        if (auth == null || !auth.isAuthenticated()) {
            return "redirect:/login";
        }
        String target = redirectUrl != null && !redirectUrl.isBlank() ? redirectUrl : "/account/security";
        Account account = accountRepository.findByEmail(auth.getName().trim().toLowerCase()).orElse(null);
        if (account == null) {
            ra.addFlashAttribute("pwdError", "Không tìm thấy tài khoản người dùng.");
            return "redirect:" + target;
        }

        if (!passwordEncoder.matches(currentPassword, account.getPassword())) {
            ra.addFlashAttribute("pwdError", "Mật khẩu hiện tại không chính xác.");
            return "redirect:" + target;
        }

        if (newPassword == null || newPassword.length() < 6) {
            ra.addFlashAttribute("pwdError", "Mật khẩu mới phải có ít nhất 6 ký tự.");
            return "redirect:" + target;
        }

        if (!newPassword.equals(confirmPassword)) {
            ra.addFlashAttribute("pwdError", "Xác nhận mật khẩu mới không trùng khớp.");
            return "redirect:" + target;
        }

        if (passwordEncoder.matches(newPassword, account.getPassword())) {
            ra.addFlashAttribute("pwdError", "Mật khẩu mới không được trùng với mật khẩu hiện tại.");
            return "redirect:" + target;
        }

        account.setPassword(passwordEncoder.encode(newPassword));
        accountRepository.save(account);

        ra.addFlashAttribute("pwdSuccess", "Đổi mật khẩu thành công! Vui lòng ghi nhớ mật khẩu mới của bạn.");
        return "redirect:" + target;
    }

    private UserProfile getOrCreateUserProfile(String email) {
        String cleanEmail = email.trim().toLowerCase();
        return userProfileRepository.findByAccountEmail(cleanEmail)
                .orElseGet(() -> {
                    Account acc = accountRepository.findByEmail(cleanEmail)
                            .orElseThrow(() -> new IllegalStateException("Không tìm thấy tài khoản"));
                    UserProfile profile = new UserProfile();
                    profile.setAccount(acc);
                    profile.setFullName(cleanEmail);
                    return userProfileRepository.save(profile);
                });
    }

    private long count(String sql, Object arg) {
        Long n = jdbc.queryForObject(sql, Long.class, arg);
        return n == null ? 0 : n;
    }
}
