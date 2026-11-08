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

@Service
public class AccountService {

    public static final String DEMO_BYPASS_OTP = "111111"; // Mã dự phòng cố định dùng demo nhanh

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
     * - Tạo hoặc cập nhật tài khoản tạm thời với email_verified = false
     * - Sinh mã xác thực 6 số ngẫu nhiên
     * - Đặt thời gian hết hạn đúng 5 phút
     * - Gửi email chứa mã OTP và in log console
     */
    @Transactional
    public String initiateRegistration(RegisterForm form) {
        String normalizedEmail = form.getEmail().trim().toLowerCase();
        String otp = String.format("%06d", random.nextInt(1000000));
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(5);

        Optional<Account> existingOpt = accountRepository.findByEmail(normalizedEmail);
        Account account;
        UserProfile profile;

        if (existingOpt.isPresent()) {
            account = existingOpt.get();
            if (account.isEmailVerified()) {
                throw new IllegalStateException("Email này đã được đăng ký và xác thực tài khoản.");
            }
            // Trường hợp đăng ký trước đó nhưng chưa xác thực: cập nhật lại thông tin mới
            account.setPassword(passwordEncoder.encode(form.getPassword()));
            account.setVerificationCode(otp);
            account.setVerificationExpiry(expiry);
            accountRepository.save(account);

            profile = userProfileRepository.findByAccount(account).orElseGet(() -> {
                UserProfile p = new UserProfile();
                p.setAccount(account);
                return p;
            });
            profile.setFullName(form.getFullName().trim());
            String phone = form.getPhoneNumber();
            profile.setPhoneNumber(phone == null || phone.isBlank() ? null : phone.replaceAll("[\\s.-]", ""));
            userProfileRepository.save(profile);
        } else {
            account = new Account();
            account.setEmail(normalizedEmail);
            account.setPassword(passwordEncoder.encode(form.getPassword()));
            account.setRole(Role.CUSTOMER);
            account.setStatus(AccountStatus.ACTIVE);
            account.setEmailVerified(false);
            account.setVerificationCode(otp);
            account.setVerificationExpiry(expiry);
            accountRepository.save(account);

            profile = new UserProfile();
            profile.setFullName(form.getFullName().trim());
            String phone = form.getPhoneNumber();
            profile.setPhoneNumber(phone == null || phone.isBlank() ? null : phone.replaceAll("[\\s.-]", ""));
            profile.setAccount(account);
            userProfileRepository.save(profile);
        }

        // Gửi email OTP tới người dùng
        emailService.sendOtpVerificationEmail(normalizedEmail, otp, profile.getFullName());
        return otp;
    }

    /**
     * Xác thực mã OTP để kích hoạt tài khoản:
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

        Optional<Account> accountOpt = accountRepository.findByEmail(normalizedEmail);
        if (accountOpt.isEmpty()) {
            response.put("success", false);
            response.put("message", "Không tìm thấy thông tin tài khoản đăng ký.");
            return response;
        }

        Account account = accountOpt.get();

        if (account.isEmailVerified()) {
            response.put("success", true);
            response.put("message", "Tài khoản của bạn đã được kích hoạt trước đó.");
            return response;
        }

        // 1. Kiểm tra mã dự phòng demo cố định 111111
        boolean isBypass = DEMO_BYPASS_OTP.equals(inputOtp);

        // 2. Kiểm tra mã thực gửi trong email
        boolean isOtpCorrect = inputOtp.equals(account.getVerificationCode());
        boolean isOtpStillValid = account.isVerificationCodeValid();

        if (isBypass || (isOtpCorrect && isOtpStillValid)) {
            // Kích hoạt thành công
            account.setEmailVerified(true);
            account.setVerificationCode(null);
            account.setVerificationExpiry(null);
            accountRepository.save(account);

            response.put("success", true);
            response.put("message", "Xác thực tài khoản thành công! Bạn có thể đăng nhập ngay.");
            return response;
        }

        if (isOtpCorrect && !isOtpStillValid) {
            // Nhập đúng mã nhưng đã quá 5 phút
            response.put("success", false);
            response.put("expired", true);
            response.put("message", "Mã xác thực đã hết hạn (quá 5 phút). Vui lòng nhấn 'Gửi lại mã'!");
            return response;
        }

        // Nhập sai mã
        response.put("success", false);
        response.put("expired", false);
        response.put("message", "Mã xác thực không chính xác. Vui lòng kiểm tra lại!");
        return response;
    }

    /**
     * Gửi lại mã xác thực OTP mới cho tài khoản (gia hạn thêm 5 phút).
     */
    @Transactional
    public Map<String, Object> resendRegistrationOtp(String email) {
        Map<String, Object> response = new HashMap<>();

        if (email == null || email.isBlank()) {
            response.put("success", false);
            response.put("message", "Email không hợp lệ.");
            return response;
        }

        String normalizedEmail = email.trim().toLowerCase();
        Optional<Account> accountOpt = accountRepository.findByEmail(normalizedEmail);

        if (accountOpt.isEmpty()) {
            response.put("success", false);
            response.put("message", "Không tìm thấy thông tin tài khoản.");
            return response;
        }

        Account account = accountOpt.get();
        if (account.isEmailVerified()) {
            response.put("success", false);
            response.put("message", "Tài khoản đã được kích hoạt thành công, không cần gửi lại mã.");
            return response;
        }

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
}
