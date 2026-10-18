package com.iuh.fashionshop.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

/** Trang admin: Mã giảm giá. Người phụ trách viết tiếp chức năng trong class này. */
@Controller
@RequestMapping("/admin/coupons")
public class AdminCouponController {

    @GetMapping
    public String list(Model model) {
        model.addAttribute("pageTitle", "Mã giảm giá");
        return "admin/coupons";
    }
}
