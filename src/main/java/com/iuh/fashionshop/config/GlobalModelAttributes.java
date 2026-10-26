package com.iuh.fashionshop.config;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

import java.util.Optional;

/** Đưa thông tin đăng nhập vào tất cả các trang để header và sidebar hiển thị đúng. */
@ControllerAdvice
public class GlobalModelAttributes {

    private final AccountRepository accountRepository;
    private final UserProfileRepository userProfileRepository;

    public GlobalModelAttributes(AccountRepository accountRepository, UserProfileRepository userProfileRepository) {
        this.accountRepository = accountRepository;
        this.userProfileRepository = userProfileRepository;
    }

    @ModelAttribute
    public void addLoginInfo(Model model) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        boolean loggedIn = auth != null
                && auth.isAuthenticated()
                && !(auth instanceof AnonymousAuthenticationToken);

        model.addAttribute("loggedIn", loggedIn);

        if (loggedIn) {
            String email = auth.getName();
            model.addAttribute("currentEmail", email);
            model.addAttribute("isAdmin", auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN")));

            Optional<UserProfile> profileOpt = userProfileRepository.findByAccountEmail(email);
            if (profileOpt.isPresent() && profileOpt.get().getFullName() != null && !profileOpt.get().getFullName().isBlank()) {
                model.addAttribute("currentUserName", profileOpt.get().getFullName());
            } else {
                model.addAttribute("currentUserName", email.contains("@") ? email.substring(0, email.indexOf('@')) : email);
            }
        }
    }
}