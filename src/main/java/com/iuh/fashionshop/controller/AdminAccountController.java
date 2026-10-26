package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.Optional;

/** Trang tài khoản đăng nhập của admin. */
@Controller
@RequestMapping("/admin/account")
public class AdminAccountController {

    private final AccountRepository accountRepository;
    private final UserProfileRepository userProfileRepository;

    public AdminAccountController(AccountRepository accountRepository, UserProfileRepository userProfileRepository) {
        this.accountRepository = accountRepository;
        this.userProfileRepository = userProfileRepository;
    }

    @GetMapping
    public String account(Authentication auth, Model model) {
        model.addAttribute("pageTitle", "Tài khoản đăng nhập");
        if (auth != null) {
            String email = auth.getName();
            Optional<Account> accountOpt = accountRepository.findByEmail(email);
            Optional<UserProfile> profileOpt = userProfileRepository.findByAccountEmail(email);

            accountOpt.ifPresent(account -> model.addAttribute("adminAccount", account));
            profileOpt.ifPresent(profile -> model.addAttribute("adminProfile", profile));
        }
        return "admin/account";
    }
}
