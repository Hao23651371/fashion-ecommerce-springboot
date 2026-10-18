package com.iuh.fashionshop.service;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.enums.AccountStatus;
import com.iuh.fashionshop.repository.AccountRepository;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class AccountUserDetailsService implements UserDetailsService {

    private final AccountRepository accountRepository;

    public AccountUserDetailsService(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        Account account = accountRepository.findByEmail(email.trim().toLowerCase())
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy tài khoản: " + email));

        return User.builder()
                .username(account.getEmail())
                .password(account.getPassword())
                .roles(account.getRole().name()) // ADMIN -> ROLE_ADMIN, CUSTOMER -> ROLE_CUSTOMER
                .accountLocked(account.getStatus() == AccountStatus.BANNED)
                .build();
    }
}
