package com.iuh.fashionshop.controller;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class CustomErrorController {

    @GetMapping({"/error/403", "/403"})
    public String accessDenied(Authentication auth, Model model) {
        model.addAttribute("pageTitle", "403 - Quyền truy cập bị từ chối");
        if (auth != null) {
            model.addAttribute("currentUserEmail", auth.getName());
            boolean isStaff = auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
            model.addAttribute("currentRole", isStaff ? "STAFF" : "OTHER");
        }
        return "error/403";
    }
}
