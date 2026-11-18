package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.AccountForm;
import com.iuh.fashionshop.dto.RegisterForm;
import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.AccountStatus;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.model.enums.Role;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.OrderRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import jakarta.persistence.criteria.Predicate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AccountService {

    public static final String DEMO_BYPASS_OTP = "111111"; // Mã dự phòng cố định dùng demo nhanh
    public static final String DEFAULT_RESET_PASSWORD = "FashionShop@123"; // Mật khẩu mặc định khi Admin reset mật khẩu cho người dùng

    /**
     * Lớp lưu trữ thông tin đăng ký chờ xác thực trong bộ nhớ RAM.
     * RÀNG BUỘC: Tuyệt đối không lưu tài khoản vào Database khi chưa xác thực OTP!
     */
    public static class PendingRegistration {
        private final RegisterForm form;
        private String otp;
        private LocalDateTime expiry;

        public PendingRegistration(RegisterForm form, String otp, LocalDateTime expiry) {
            this.form = form;
            this.otp = otp;
            this.expiry = expiry;
        }

        public RegisterForm getForm() { return form; }
        public String getOtp() { return otp; }
        public void setOtp(String otp) { this.otp = otp; }
        public LocalDateTime getExpiry() { return expiry; }
        public void setExpiry(LocalDateTime expiry) { this.expiry = expiry; }
        public boolean isExpired() {
            return expiry != null && expiry.isBefore(LocalDateTime.now());
        }
    }

    private final Map<String, PendingRegistration> pendingRegistrations = new ConcurrentHashMap<>();

    private final AccountRepository accountRepository;
    private final UserProfileRepository userProfileRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final OrderRepository orderRepository;
    private final SecureRandom random = new SecureRandom();

    @Autowired
    public AccountService(AccountRepository accountRepository,
                          UserProfileRepository userProfileRepository,
                          PasswordEncoder passwordEncoder,
                          EmailService emailService,
                          OrderRepository orderRepository) {
        this.accountRepository = accountRepository;
        this.userProfileRepository = userProfileRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
        this.orderRepository = orderRepository;
    }

    public boolean emailExists(String email) {
        if (email == null) {
            return false;
        }
        return accountRepository.existsByEmail(email.trim().toLowerCase());
    }

    public boolean isEmailAlreadyVerified(String email) {
        if (email == null) return false;
        return accountRepository.findByEmail(email.trim().toLowerCase())
                .map(Account::isEmailVerified)
                .orElse(false);
    }

    public boolean phoneExists(String phone) {
        if (phone == null || phone.isBlank()) {
            return false;
        }
        String cleaned = phone.replaceAll("[\\s.-]", "");
        return userProfileRepository.existsByPhoneNumber(cleaned)
                || userProfileRepository.existsByPhoneNumber(phone.trim());
    }

    /**
     * Kiểm tra số điện thoại có bị tài khoản KHÁC chiếm dụng hay không.
     * Nếu số điện thoại này thuộc về chính email đang đăng ký (chưa kích hoạt) thì cho phép dùng tiếp.
     */
    public boolean isPhoneTakenByAnotherUser(String phone, String currentEmail) {
        if (phone == null || phone.isBlank()) {
            return false;
        }
        String cleaned = phone.replaceAll("[\\s.-]", "");
        Optional<UserProfile> profileOpt = userProfileRepository.findByPhoneNumber(cleaned);
        if (profileOpt.isEmpty()) {
            profileOpt = userProfileRepository.findByPhoneNumber(phone.trim());
        }

        if (profileOpt.isEmpty()) {
            return false;
        }

        UserProfile profile = profileOpt.get();
        Account acc = profile.getAccount();
        if (acc == null) {
            return true;
        }

        // Nếu thuộc về chính email đang đăng ký -> không coi là trùng
        if (currentEmail != null && acc.getEmail().equalsIgnoreCase(currentEmail.trim())) {
            return false;
        }

        // Nếu thuộc về tài khoản khác nhưng tài khoản đó đã được kích hoạt -> trùng
        // hoặc nếu tài khoản đó chưa kích hoạt nhưng khác email -> cũng bảo vệ trùng
        return true;
    }

    /**
     * Khởi tạo quá trình đăng ký tài khoản:
     * - RÀNG BUỘC NGHIÊM NGẶT: Chưa xác thực OTP thì TUYỆT ĐỐI KHÔNG lưu bất kỳ thông tin nào vào Database!
     * - Lưu tạm thời thông tin form + OTP vào bộ nhớ RAM (pendingRegistrations) có thời hạn 5 phút.
     * - Gửi email chứa mã OTP và in log console.
     */
    public String initiateRegistration(RegisterForm form) {
        String normalizedEmail = form.getEmail().trim().toLowerCase();
        String otp = String.format("%06d", random.nextInt(1000000));
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(5);

        Optional<Account> existingOpt = accountRepository.findByEmail(normalizedEmail);
        if (existingOpt.isPresent() && existingOpt.get().isEmailVerified()) {
            throw new IllegalStateException("Email này đã được đăng ký và xác thực tài khoản. Vui lòng đăng nhập.");
        }

        // Lưu vào bộ nhớ RAM, KHÔNG LƯU VÀO DATABASE
        pendingRegistrations.put(normalizedEmail, new PendingRegistration(form, otp, expiry));

        // Gửi email OTP tới người dùng
        emailService.sendOtpVerificationEmail(normalizedEmail, otp, form.getFullName().trim());
        return otp;
    }

    /**
     * Xác thực mã OTP để kích hoạt tài khoản:
     * - RÀNG BUỘC: CHỈ KHI NÀO MÃ OTP ĐƯỢC XÁC THỰC THÀNH CÔNG, HỆ THỐNG MỚI LƯU TÀI KHOẢN VÀO DATABASE!
     * - Nếu mã sai hoặc hết hạn: TUYỆT ĐỐI KHÔNG LƯU BẤT KỲ DỮ LIỆU NÀO VÀO CSDL.
     * - Hỗ trợ mã dự phòng cố định DEMO_BYPASS_OTP ("111111")
     * - Hoặc mã OTP gửi qua email còn trong hạn 5 phút
     */
    @Transactional
    public Map<String, Object> verifyRegistrationOtp(String email, String otp) {
        Map<String, Object> response = new HashMap<>();

        if (email == null || email.isBlank()) {
            response.put("success", false);
            response.put("message", "Email không hợp lệ.");
            return response;
        }

        String inputOtp = (otp != null) ? otp.trim() : "";
        String normalizedEmail = email.trim().toLowerCase();

        PendingRegistration pending = pendingRegistrations.get(normalizedEmail);

        // Trường hợp không có trong bộ nhớ chờ xác thực
        if (pending == null) {
            Optional<Account> accountOpt = accountRepository.findByEmail(normalizedEmail);
            if (accountOpt.isPresent() && accountOpt.get().isEmailVerified()) {
                response.put("success", true);
                response.put("message", "Tài khoản của bạn đã được kích hoạt trước đó.");
                return response;
            }

            // Fallback trường hợp tài khoản unverified cũ tồn dư trong DB (nếu có từ trước)
            if (accountOpt.isPresent() && !accountOpt.get().isEmailVerified()) {
                Account account = accountOpt.get();
                boolean isBypass = DEMO_BYPASS_OTP.equals(inputOtp);
                boolean isOtpCorrect = inputOtp.equals(account.getVerificationCode());
                boolean isOtpStillValid = account.isVerificationCodeValid();

                if (isBypass || (isOtpCorrect && isOtpStillValid)) {
                    account.setEmailVerified(true);
                    account.setVerificationCode(null);
                    account.setVerificationExpiry(null);
                    accountRepository.save(account);

                    response.put("success", true);
                    response.put("message", "Xác thực tài khoản thành công! Bạn có thể đăng nhập ngay.");
                    return response;
                }

                if (isOtpCorrect && !isOtpStillValid) {
                    response.put("success", false);
                    response.put("expired", true);
                    response.put("message", "Mã xác thực đã hết hạn (quá 5 phút). Vui lòng nhấn 'Gửi lại mã'!");
                    return response;
                }

                response.put("success", false);
                response.put("expired", false);
                response.put("message", "Mã xác thực không chính xác. Vui lòng kiểm tra lại!");
                return response;
            }

            response.put("success", false);
            response.put("message", "Không tìm thấy thông tin đăng ký chờ xác thực. Vui lòng đăng ký lại.");
            return response;
        }

        // 1. Kiểm tra mã dự phòng demo cố định 111111
        boolean isBypass = DEMO_BYPASS_OTP.equals(inputOtp);

        // 2. Kiểm tra mã thực gửi trong email
        boolean isOtpCorrect = inputOtp.equals(pending.getOtp());
        boolean isOtpStillValid = !pending.isExpired();

        if (isBypass || (isOtpCorrect && isOtpStillValid)) {
            // ===>>> CHỈ KHI NÀO MÃ ĐÚNG VÀ HỢP LỆ: MỚI TẠO VÀ LƯU VÀO DATABASE <<<===
            RegisterForm form = pending.getForm();

            // Xóa tài khoản chưa kích hoạt cũ nếu có trùng email
            accountRepository.findByEmail(normalizedEmail).ifPresent(old -> {
                if (!old.isEmailVerified()) {
                    userProfileRepository.findByAccount(old).ifPresent(userProfileRepository::delete);
                    accountRepository.delete(old);
                }
            });

            Account account = new Account();
            account.setEmail(normalizedEmail);
            account.setPassword(passwordEncoder.encode(form.getPassword()));
            account.setRole(Role.CUSTOMER);
            account.setStatus(AccountStatus.ACTIVE);
            account.setEmailVerified(true); // Đã xác thực xong
            account.setVerificationCode(null);
            account.setVerificationExpiry(null);
            accountRepository.save(account);

            UserProfile profile = new UserProfile();
            profile.setFullName(form.getFullName().trim());
            String phone = form.getPhoneNumber();
            profile.setPhoneNumber(phone == null || phone.isBlank() ? null : phone.replaceAll("[\\s.-]", ""));
            profile.setAccount(account);
            userProfileRepository.save(profile);

            // Xóa thông tin đăng ký tạm khỏi bộ nhớ RAM
            pendingRegistrations.remove(normalizedEmail);

            response.put("success", true);
            response.put("message", "Xác thực tài khoản thành công! Bạn có thể đăng nhập ngay.");
            return response;
        }

        if (isOtpCorrect && !isOtpStillValid) {
            response.put("success", false);
            response.put("expired", true);
            response.put("message", "Mã xác thực đã hết hạn (quá 5 phút). Vui lòng nhấn 'Gửi lại mã'!");
            return response;
        }

        // Nhập sai mã -> TUYỆT ĐỐI KHÔNG LƯU GÌ VÀO DATABASE
        response.put("success", false);
        response.put("expired", false);
        response.put("message", "Mã xác thực không chính xác. Vui lòng kiểm tra lại!");
        return response;
    }

    /**
     * Gửi lại mã xác thực OTP mới cho tài khoản (gia hạn thêm 5 phút).
     */
    public Map<String, Object> resendRegistrationOtp(String email) {
        Map<String, Object> response = new HashMap<>();

        if (email == null || email.isBlank()) {
            response.put("success", false);
            response.put("message", "Email không hợp lệ.");
            return response;
        }

        String normalizedEmail = email.trim().toLowerCase();
        PendingRegistration pending = pendingRegistrations.get(normalizedEmail);

        if (pending == null) {
            Optional<Account> accountOpt = accountRepository.findByEmail(normalizedEmail);
            if (accountOpt.isPresent() && !accountOpt.get().isEmailVerified()) {
                Account account = accountOpt.get();
                String newOtp = String.format("%06d", random.nextInt(1000000));
                account.setVerificationCode(newOtp);
                account.setVerificationExpiry(LocalDateTime.now().plusMinutes(5));
                accountRepository.save(account);

                String fullName = userProfileRepository.findByAccount(account)
                        .map(UserProfile::getFullName)
                        .orElse("Quý khách");

                emailService.sendOtpVerificationEmail(normalizedEmail, newOtp, fullName);

                response.put("success", true);
                response.put("message", "Mã xác thực mới đã được gửi tới email của bạn (hiệu lực 5 phút).");
                return response;
            }

            response.put("success", false);
            response.put("message", "Không tìm thấy thông tin đăng ký chờ xác thực.");
            return response;
        }

        String newOtp = String.format("%06d", random.nextInt(1000000));
        pending.setOtp(newOtp);
        pending.setExpiry(LocalDateTime.now().plusMinutes(5));

        emailService.sendOtpVerificationEmail(normalizedEmail, newOtp, pending.getForm().getFullName().trim());

        response.put("success", true);
        response.put("message", "Mã xác thực mới đã được gửi tới email của bạn (hiệu lực 5 phút).");
        return response;
    }

    /**
     * Backward compatibility: Tạo Account + UserProfile (trường hợp gọi trực tiếp)
     */
    @Transactional
    public void register(RegisterForm form) {
        initiateRegistration(form);
    }

    /**
     * Cập nhật thời gian đăng nhập gần nhất khi tài khoản đăng nhập thành công.
     */
    @Transactional
    public void updateLastLogin(String email) {
        if (email != null && !email.isBlank()) {
            accountRepository.findByEmail(email.trim().toLowerCase()).ifPresent(acc -> {
                acc.setLastLoginAt(LocalDateTime.now());
                accountRepository.save(acc);
            });
        }
    }

    // =========================================================================
    // QUẢN LÝ TÀI KHOẢN (CRUD, TÌM KIẾM, LỌC CHO ADMIN)
    // =========================================================================

    public Page<Account> getAccounts(String keyword, Role role, AccountStatus status, Boolean emailVerified, int page, int size) {
        return getAccounts(keyword, role, status, emailVerified, page, size, "asc");
    }

    public Page<Account> getAccounts(String keyword, Role role, AccountStatus status, Boolean emailVerified, int page, int size, String sortDir) {
        Sort.Direction direction = "desc".equalsIgnoreCase(sortDir) ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, "id"));

        Specification<Account> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (keyword != null && !keyword.isBlank()) {
                String kw = "%" + keyword.trim().toLowerCase() + "%";
                Predicate emailPred = cb.like(cb.lower(root.get("email")), kw);

                Predicate idPred = null;
                try {
                    Long idVal = Long.parseLong(keyword.trim());
                    idPred = cb.equal(root.get("id"), idVal);
                } catch (NumberFormatException ignored) {}

                if (idPred != null) {
                    predicates.add(cb.or(emailPred, idPred));
                } else {
                    predicates.add(emailPred);
                }
            }

            if (role != null) {
                predicates.add(cb.equal(root.get("role"), role));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (emailVerified != null) {
                predicates.add(cb.equal(root.get("emailVerified"), emailVerified));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return accountRepository.findAll(spec, pageable);
    }

    public Account getAccountById(Long id) {
        return accountRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tài khoản có ID = " + id));
    }

    @Transactional
    public Account createAccount(AccountForm form) {
        String email = form.getEmail().trim().toLowerCase();
        if (accountRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email '" + email + "' đã tồn tại trong hệ thống.");
        }
        if (form.getPassword() == null || form.getPassword().isBlank()) {
            throw new IllegalArgumentException("Mật khẩu không được để trống khi tạo mới tài khoản.");
        }

        Account account = new Account();
        account.setEmail(email);
        account.setPassword(passwordEncoder.encode(form.getPassword()));
        account.setRole(form.getRole() != null ? form.getRole() : Role.CUSTOMER);
        account.setStatus(form.getStatus() != null ? form.getStatus() : AccountStatus.ACTIVE);
        account.setEmailVerified(form.isEmailVerified());
        account.setVerificationCode(form.getVerificationCode() != null && !form.getVerificationCode().isBlank()
                ? form.getVerificationCode().trim() : null);
        account.setVerificationExpiry(form.getVerificationExpiry());
        account.setCreatedAt(LocalDateTime.now());

        return accountRepository.save(account);
    }

    @Transactional
    public Account updateAccount(Long id, AccountForm form) {
        Account account = getAccountById(id);

        String newEmail = form.getEmail().trim().toLowerCase();
        if (!account.getEmail().equalsIgnoreCase(newEmail) && accountRepository.existsByEmail(newEmail)) {
            throw new IllegalArgumentException("Email '" + newEmail + "' đã được sử dụng bởi tài khoản khác.");
        }

        account.setEmail(newEmail);
        if (form.getPassword() != null && !form.getPassword().isBlank()) {
            account.setPassword(passwordEncoder.encode(form.getPassword()));
        }
        if (form.getRole() != null) {
            account.setRole(form.getRole());
        }
        if (form.getStatus() != null) {
            account.setStatus(form.getStatus());
        }
        account.setEmailVerified(form.isEmailVerified());
        account.setVerificationCode(form.getVerificationCode() != null && !form.getVerificationCode().isBlank()
                ? form.getVerificationCode().trim() : null);
        account.setVerificationExpiry(form.getVerificationExpiry());

        return accountRepository.save(account);
    }

    @Transactional
    public Account toggleAccountStatus(Long id, String currentAdminEmail) {
        Account account = getAccountById(id);

        if (currentAdminEmail != null && account.getEmail().equalsIgnoreCase(currentAdminEmail.trim())) {
            throw new IllegalStateException("Bạn không thể tự khóa tài khoản của chính mình!");
        }

        if (account.getStatus() == AccountStatus.ACTIVE) {
            // 1. Chặn không cho khóa nếu là tài khoản ADMIN duy nhất đang hoạt động
            if (account.getRole() == Role.ADMIN && countActiveAdminAccounts() <= 1) {
                throw new IllegalStateException("Hệ thống phải có ít nhất 1 Quản trị viên (ADMIN) đang hoạt động! Bạn không thể khóa tài khoản Admin này.");
            }

            // 2. Chặn khóa nếu khách hàng đang có đơn hàng chưa hoàn tất (PENDING, CONFIRMED, SHIPPING)
            if (orderRepository != null) {
                var profileOpt = userProfileRepository.findByAccountId(account.getId());
                if (profileOpt.isPresent()) {
                    Long profileId = profileOpt.get().getId();
                    boolean hasPendingOrders = orderRepository.existsByUserProfileIdAndStatusIn(
                            profileId,
                            List.of(OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.SHIPPING)
                    );
                    if (hasPendingOrders) {
                        throw new IllegalStateException("Không thể khóa tài khoản khi khách hàng đang có đơn hàng chưa hoàn tất (đang chờ xử lý, đã xác nhận hoặc đang giao hàng)!");
                    }
                }
            }

            account.setStatus(AccountStatus.BANNED);
        } else {
            // Mở khóa tài khoản từ BANNED -> ACTIVE
            account.setStatus(AccountStatus.ACTIVE);
        }
        return accountRepository.save(account);
    }

    /**
     * Phân quyền tài khoản (Cập nhật vai trò / quyền hạn trong CSDL).
     * Đảm bảo tương tác trực tiếp với Database thông qua AccountRepository trong transaction.
     * Chặn không cho tài khoản Admin đang đăng nhập tự hạ quyền chính mình.
     */
    @Transactional
    public Account updateAccountRole(Long id, Role newRole, String currentAdminEmail) {
        if (id == null) {
            throw new IllegalArgumentException("ID tài khoản không hợp lệ.");
        }
        if (newRole == null) {
            throw new IllegalArgumentException("Vui lòng chọn vai trò hợp lệ để phân quyền.");
        }

        Account account = getAccountById(id);

        if (currentAdminEmail != null && account.getEmail().equalsIgnoreCase(currentAdminEmail.trim())) {
            if (newRole != Role.ADMIN) {
                throw new IllegalStateException("Bạn không thể tự hạ quyền tài khoản của chính mình!");
            }
        }

        account.setRole(newRole);
        return accountRepository.save(account);
    }

    /**
     * Khôi phục / Reset mật khẩu tài khoản về mật khẩu cố định mặc định (DEFAULT_RESET_PASSWORD).
     * Dùng khi người dùng hoặc nhân viên quên mật khẩu và nhờ Admin cấp lại.
     */
    @Transactional
    public String resetAccountPassword(Long id, String currentAdminEmail) {
        if (id == null) {
            throw new IllegalArgumentException("ID tài khoản không hợp lệ.");
        }
        Account account = getAccountById(id);

        if (currentAdminEmail != null && account.getEmail().equalsIgnoreCase(currentAdminEmail.trim())) {
            throw new IllegalStateException("Bạn không thể tự reset mật khẩu của chính mình tại đây! Vui lòng vào trang 'Tài khoản đăng nhập' để đổi mật khẩu cá nhân.");
        }

        account.setPassword(passwordEncoder.encode(DEFAULT_RESET_PASSWORD));
        accountRepository.save(account);
        return DEFAULT_RESET_PASSWORD;
    }

    @Transactional
    public void deleteAccount(Long id, String currentAdminEmail) {
        Account account = getAccountById(id);

        // 1. Chặn không cho tự xóa tài khoản của chính mình
        if (currentAdminEmail != null && account.getEmail().equalsIgnoreCase(currentAdminEmail.trim())) {
            throw new IllegalStateException("Bạn không thể tự xóa tài khoản của chính mình đang đăng nhập!");
        }

        // 2. Chặn không cho xóa nếu là Quản trị viên (ADMIN) duy nhất còn lại
        if (account.getRole() == Role.ADMIN && countAdminAccounts() <= 1) {
            throw new IllegalStateException("Hệ thống phải có ít nhất 1 Quản trị viên (ADMIN)! Bạn không thể xóa Admin duy nhất này.");
        }

        // 3. Chặn không cho xóa nếu tài khoản đã phát sinh đơn hàng trong quá khứ
        if (orderRepository != null) {
            var profileOpt = userProfileRepository.findByAccountId(account.getId());
            if (profileOpt.isPresent()) {
                long orderCount = orderRepository.countByUserProfileId(profileOpt.get().getId());
                if (orderCount > 0) {
                    throw new IllegalStateException("Không thể xóa tài khoản ID #" + id + " vì đã phát sinh " + orderCount + " đơn hàng trong lịch sử hệ thống! Để vô hiệu hóa tài khoản, bạn vui lòng chuyển sang chức năng Khóa tài khoản.");
                }
            }
        }

        accountRepository.delete(account);
    }

    public long countTotalAccounts() {
        return accountRepository.count();
    }

    public long countActiveAccounts() {
        return accountRepository.countByStatus(AccountStatus.ACTIVE);
    }

    public long countActiveAdminAccounts() {
        return accountRepository.countByRoleAndStatus(Role.ADMIN, AccountStatus.ACTIVE);
    }

    public long countBannedAccounts() {
        return accountRepository.countByStatus(AccountStatus.BANNED);
    }

    public long countAdminAccounts() {
        return accountRepository.countByRole(Role.ADMIN);
    }

    public long countStaffAccounts() {
        return accountRepository.countByRole(Role.STAFF);
    }

    public long countCustomerAccounts() {
        return accountRepository.countByRole(Role.CUSTOMER);
    }

    /**
     * Khởi tạo yêu cầu quên mật khẩu:
     * - Tìm tài khoản qua email hoặc số điện thoại
     * - Sinh mã OTP 6 số (hiệu lực 5 phút)
     * - Gửi email hướng dẫn/mã xác thực và in console log
     */
    @Transactional
    public Map<String, Object> initiateForgotPassword(String credential) {
        Map<String, Object> result = new HashMap<>();
        if (credential == null || credential.isBlank()) {
            result.put("success", false);
            result.put("message", "Vui lòng nhập địa chỉ email của bạn.");
            return result;
        }
        String clean = credential.trim();
        Account account = null;

        if (clean.contains("@")) {
            account = accountRepository.findByEmail(clean.toLowerCase()).orElse(null);
        } else {
            // Tìm theo số điện thoại nếu người dùng nhập số
            Optional<UserProfile> profileOpt = userProfileRepository.findByPhoneNumber(clean);
            if (profileOpt.isPresent()) {
                account = profileOpt.get().getAccount();
            }
        }

        if (account == null) {
            result.put("success", false);
            result.put("message", "Không tìm thấy tài khoản tương ứng với email này trong hệ thống Fashion Shop.");
            return result;
        }

        String resetCode = String.format("%06d", random.nextInt(1000000));
        account.setVerificationCode(resetCode);
        account.setVerificationExpiry(LocalDateTime.now().plusMinutes(5));
        accountRepository.save(account);

        UserProfile profile = userProfileRepository.findByAccount(account).orElse(null);
        String fullName = profile != null ? profile.getFullName() : "Quý khách";

        emailService.sendPasswordResetEmail(account.getEmail(), resetCode, fullName);

        result.put("success", true);
        result.put("email", account.getEmail());
        result.put("maskedCredential", maskCredential(clean));
        result.put("message", "Mã xác thực gồm 6 chữ số đã được gửi tới thiết bị cá nhân của quý khách.");
        return result;
    }

    /**
     * Xác thực mã OTP đặt lại mật khẩu:
     * - Chấp nhận mã bypass DEMO_BYPASS_OTP ("111111")
     * - Hoặc mã OTP gửi qua email còn hiệu lực
     */
    public Map<String, Object> verifyResetOtp(String email, String otp) {
        Map<String, Object> result = new HashMap<>();
        if (email == null || email.isBlank()) {
            result.put("success", false);
            result.put("message", "Thiếu thông tin email tài khoản.");
            return result;
        }
        Optional<Account> accountOpt = accountRepository.findByEmail(email.trim().toLowerCase());
        if (accountOpt.isEmpty()) {
            result.put("success", false);
            result.put("message", "Tài khoản không tồn tại trên hệ thống.");
            return result;
        }
        Account account = accountOpt.get();
        String inputOtp = (otp != null) ? otp.trim() : "";
        boolean isBypass = DEMO_BYPASS_OTP.equals(inputOtp);
        boolean isOtpCorrect = inputOtp.equals(account.getVerificationCode());
        boolean isOtpStillValid = account.isVerificationCodeValid();

        if (isBypass || (isOtpCorrect && isOtpStillValid)) {
            result.put("success", true);
            result.put("message", "Xác thực mã OTP thành công. Quý khách vui lòng nhập mật khẩu mới.");
            return result;
        }

        if (isOtpCorrect && !isOtpStillValid) {
            result.put("success", false);
            result.put("message", "Mã OTP đã hết hạn (quá 5 phút). Quý khách vui lòng nhấn 'Gửi lại ngay'.");
            return result;
        }

        result.put("success", false);
        result.put("message", "Mã xác thực OTP không chính xác. Vui lòng kiểm tra lại!");
        return result;
    }

    /**
     * Gửi lại mã OTP đặt lại mật khẩu mới (gia hạn thêm 5 phút):
     */
    @Transactional
    public Map<String, Object> resendResetOtp(String email) {
        Map<String, Object> result = new HashMap<>();
        if (email == null || email.isBlank()) {
            result.put("success", false);
            result.put("message", "Thiếu thông tin email.");
            return result;
        }
        Optional<Account> accountOpt = accountRepository.findByEmail(email.trim().toLowerCase());
        if (accountOpt.isEmpty()) {
            result.put("success", false);
            result.put("message", "Không tìm thấy tài khoản tương ứng.");
            return result;
        }
        Account account = accountOpt.get();
        String newOtp = String.format("%06d", random.nextInt(1000000));
        account.setVerificationCode(newOtp);
        account.setVerificationExpiry(LocalDateTime.now().plusMinutes(5));
        accountRepository.save(account);

        UserProfile profile = userProfileRepository.findByAccount(account).orElse(null);
        String fullName = profile != null ? profile.getFullName() : "Quý khách";

        emailService.sendPasswordResetEmail(account.getEmail(), newOtp, fullName);

        result.put("success", true);
        result.put("message", "Đã gửi lại mã xác thực mới (hiệu lực 5 phút).");
        return result;
    }

    /**
     * Đổi mật khẩu mới kèm xác thực OTP:
     */
    @Transactional
    public Map<String, Object> resetPasswordWithOtp(String email, String otp, String newPassword, String confirmPassword) {
        Map<String, Object> result = new HashMap<>();

        if (newPassword == null || newPassword.length() < 8) {
            result.put("success", false);
            result.put("message", "Mật khẩu mới phải có tối thiểu 8 ký tự.");
            return result;
        }

        if (!newPassword.equals(confirmPassword)) {
            result.put("success", false);
            result.put("message", "Xác nhận mật khẩu mới không khớp!");
            return result;
        }

        // Kiểm tra OTP
        Map<String, Object> verifyCheck = verifyResetOtp(email, otp);
        if (!Boolean.TRUE.equals(verifyCheck.get("success"))) {
            return verifyCheck;
        }

        Account account = accountRepository.findByEmail(email.trim().toLowerCase()).orElse(null);
        if (account == null) {
            result.put("success", false);
            result.put("message", "Không tìm thấy tài khoản.");
            return result;
        }

        account.setPassword(passwordEncoder.encode(newPassword));
        account.setVerificationCode(null);
        account.setVerificationExpiry(null);
        accountRepository.save(account);

        // Đảm bảo luôn khởi tạo UserProfile hợp lệ cho tài khoản
        getOrCreateUserProfile(email);

        result.put("success", true);
        result.put("message", "Đổi mật khẩu thành công!");
        return result;
    }

    /**
     * Lấy hoặc tự động tạo UserProfile an toàn cho tài khoản trong một Transaction hợp lệ.
     */
    @Transactional
    public UserProfile getOrCreateUserProfile(String email) {
        if (email == null || email.isBlank()) {
            return null;
        }
        String cleanEmail = email.trim().toLowerCase();
        Optional<UserProfile> profileOpt = userProfileRepository.findByAccountEmail(cleanEmail);
        if (profileOpt.isPresent()) {
            return profileOpt.get();
        }

        Optional<Account> accountOpt = accountRepository.findByEmail(cleanEmail);
        if (accountOpt.isPresent()) {
            Account acc = accountOpt.get();
            UserProfile newProfile = new UserProfile();
            newProfile.setAccount(acc);
            String defaultName = cleanEmail.contains("@") ? cleanEmail.substring(0, cleanEmail.indexOf('@')) : cleanEmail;
            newProfile.setFullName(defaultName);
            UserProfile saved = userProfileRepository.save(newProfile);
            acc.setUserProfile(saved);
            accountRepository.save(acc);
            return saved;
        }
        return null;
    }

    private String maskCredential(String input) {
        if (input == null || input.length() < 4) return "****";
        if (input.contains("@")) {
            String[] parts = input.split("@");
            String name = parts[0];
            String domain = parts.length > 1 ? parts[1] : "";
            if (name.length() <= 2) {
                return name.charAt(0) + "***@" + domain;
            }
            return name.substring(0, 2) + "***" + name.charAt(name.length() - 1) + "@" + domain;
        } else {
            if (input.length() <= 4) return "****";
            return input.substring(0, 3) + "***" + input.substring(input.length() - 3);
        }
    }
}
