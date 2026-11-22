package com.iuh.fashionshop.service;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.AccountStatus;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AccountUserDetailsService implements UserDetailsService {

    private final AccountRepository accountRepository;
    private final UserProfileRepository userProfileRepository;

    public AccountUserDetailsService(AccountRepository accountRepository,
                                     UserProfileRepository userProfileRepository) {
        this.accountRepository = accountRepository;
        this.userProfileRepository = userProfileRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String input) throws UsernameNotFoundException {
        if (input == null || input.isBlank()) {
            throw new UsernameNotFoundException("Tên đăng nhập không được để trống");
        }
        String clean = input.trim();
        Account account = null;

        // 1. Nếu có ký tự '@', ưu tiên tìm theo Email
        if (clean.contains("@")) {
            account = accountRepository.findByEmail(clean.toLowerCase()).orElse(null);
        } else {
            // Không chứa '@', ưu tiên tìm theo Số điện thoại trong thông tin người dùng
            String phoneClean = clean.replaceAll("[\\s.-]", "");
            account = userProfileRepository.findByPhoneNumber(phoneClean)
                    .map(UserProfile::getAccount)
                    .orElse(null);
            if (account == null && !phoneClean.equals(clean)) {
                account = userProfileRepository.findByPhoneNumber(clean)
                        .map(UserProfile::getAccount)
                        .orElse(null);
            }
        }

        // 2. Dự phòng: Nếu vẫn chưa tìm thấy, thử tìm theo cách còn lại
        if (account == null) {
            account = accountRepository.findByEmail(clean.toLowerCase()).orElse(null);
        }
        if (account == null) {
            String phoneClean = clean.replaceAll("[\\s.-]", "");
            account = userProfileRepository.findByPhoneNumber(phoneClean)
                    .map(UserProfile::getAccount)
                    .orElse(null);
        }

        if (account == null) {
            throw new UsernameNotFoundException("Không tìm thấy tài khoản với thông tin: " + input);
        }

        return User.builder()
                .username(account.getEmail()) // Giữ email làm định danh SecurityContext để các controller khác hoạt động chuẩn xác
                .password(account.getPassword())
                .roles(account.getRole().name()) // ADMIN -> ROLE_ADMIN, CUSTOMER -> ROLE_CUSTOMER, STAFF -> ROLE_STAFF
                .accountLocked(account.getStatus() == AccountStatus.BANNED)
                .disabled(!account.isEmailVerified()) // Bắt buộc phải xác thực email mới được đăng nhập
                .build();
    }
}
