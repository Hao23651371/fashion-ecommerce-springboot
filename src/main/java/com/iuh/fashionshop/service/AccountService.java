package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.RegisterForm;
import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.AccountStatus;
import com.iuh.fashionshop.model.enums.Role;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountService {

    private final AccountRepository accountRepository;
    private final UserProfileRepository userProfileRepository;
    private final PasswordEncoder passwordEncoder;

    public AccountService(AccountRepository accountRepository,
                          UserProfileRepository userProfileRepository,
                          PasswordEncoder passwordEncoder) {
        this.accountRepository = accountRepository;
        this.userProfileRepository = userProfileRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public boolean emailExists(String email) {
        if (email == null) {
            return false;
        }
        return accountRepository.existsByEmail(email.trim().toLowerCase());
    }

    /**
     * Creates Account + UserProfile in a single transaction.
     */
    @Transactional
    public void register(RegisterForm form) {
        Account account = new Account();
        account.setEmail(form.getEmail().trim().toLowerCase());
        account.setPassword(passwordEncoder.encode(form.getPassword()));
        account.setRole(Role.CUSTOMER);
        account.setStatus(AccountStatus.ACTIVE);
        account.setEmailVerified(true); // Default active, update when email verification flow is enabled
        accountRepository.save(account);

        UserProfile profile = new UserProfile();
        profile.setFullName(form.getFullName().trim());
        String phone = form.getPhoneNumber();
        profile.setPhoneNumber(phone == null || phone.isBlank() ? null : phone.trim());
        profile.setAccount(account);
        userProfileRepository.save(profile);
    }
}
