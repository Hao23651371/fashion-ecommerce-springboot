package com.iuh.fashionshop.config;

import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

/** Đưa thông tin đăng nhập vào tất cả các trang để header hiển thị đúng. */
@ControllerAdvice
public class GlobalModelAttributes {

    @ModelAttribute
    public void addLoginInfo(Model model) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        boolean loggedIn = auth != null
                && auth.isAuthenticated()
                && !(auth instanceof AnonymousAuthenticationToken);

        model.addAttribute("loggedIn", loggedIn);

        if (loggedIn) {
            model.addAttribute("currentEmail", auth.getName());
            model.addAttribute("isAdmin", auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN")));
        }
    }
}