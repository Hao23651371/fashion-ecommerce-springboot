package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.dto.AccountForm;
import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.enums.AccountStatus;
import com.iuh.fashionshop.model.enums.Role;
import com.iuh.fashionshop.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/**
 * Controller quản lý tài khoản (Account) trong giao diện Admin.
 * Hiển thị chính xác các thuộc tính của bảng account và cung cấp đầy đủ chức năng CRUD, tìm kiếm, lọc.
 */
@Controller
@RequestMapping({"/admin/users", "/admin/accounts"})
public class AdminUserController {

    private final AccountService accountService;

    public AdminUserController(AccountService accountService) {
        this.accountService = accountService;
    }

    /**
     * Danh sách tài khoản kèm tìm kiếm, lọc theo thuộc tính bảng Account và phân trang.
     */
    @GetMapping
    public String list(@RequestParam(required = false) String keyword,
                       @RequestParam(required = false) Role role,
                       @RequestParam(required = false) AccountStatus status,
                       @RequestParam(required = false) Boolean emailVerified,
                       @RequestParam(defaultValue = "asc") String sortDir,
                       @RequestParam(defaultValue = "0") int page,
                       @RequestParam(defaultValue = "15") int size,
                       Authentication auth,
                       Model model) {

        String safeSortDir = "desc".equalsIgnoreCase(sortDir) ? "desc" : "asc";
        Page<Account> accountPage = accountService.getAccounts(keyword, role, status, emailVerified, page, size, safeSortDir);

        model.addAttribute("pageTitle", "Quản lý Tài khoản");
        model.addAttribute("accounts", accountPage);
        model.addAttribute("keyword", keyword != null ? keyword.trim() : "");
        model.addAttribute("selectedRole", role);
        model.addAttribute("selectedStatus", status);
        model.addAttribute("selectedVerified", emailVerified);
        model.addAttribute("sortDir", safeSortDir);
        model.addAttribute("currentPage", page);
        model.addAttribute("pageSize", size);

        // Enum lists cho bộ lọc và modal
        model.addAttribute("allRoles", Role.values());
        model.addAttribute("allStatuses", AccountStatus.values());

        // Thống kê dựa trên dữ liệu bảng Account
        model.addAttribute("totalAccounts", accountService.countTotalAccounts());
        model.addAttribute("activeAccounts", accountService.countActiveAccounts());
        model.addAttribute("bannedAccounts", accountService.countBannedAccounts());
        model.addAttribute("adminAccounts", accountService.countAdminAccounts());
        model.addAttribute("customerAccounts", accountService.countCustomerAccounts());

        if (auth != null) {
            model.addAttribute("currentAdminEmail", auth.getName());
        }

        if (!model.containsAttribute("accountForm")) {
            model.addAttribute("accountForm", new AccountForm());
        }

        return "admin/users";
    }

    /**
     * Thêm mới tài khoản vào bảng Account.
     */
    @PostMapping("/create")
    public String create(@Valid @ModelAttribute("accountForm") AccountForm form,
                         BindingResult bindingResult,
                         RedirectAttributes redirectAttributes) {

        if (bindingResult.hasErrors()) {
            String errorMsg = bindingResult.getAllErrors().get(0).getDefaultMessage();
            redirectAttributes.addFlashAttribute("errorMessage", errorMsg);
            redirectAttributes.addFlashAttribute("accountForm", form);
            return "redirect:/admin/users";
        }

        try {
            accountService.createAccount(form);
            redirectAttributes.addFlashAttribute("successMessage", "Thêm tài khoản '" + form.getEmail() + "' thành công!");
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            redirectAttributes.addFlashAttribute("accountForm", form);
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Đã xảy ra lỗi khi tạo tài khoản: " + e.getMessage());
            redirectAttributes.addFlashAttribute("accountForm", form);
        }

        return "redirect:/admin/users";
    }

    /**
     * Cập nhật thông tin tài khoản trong bảng Account.
     */
    @PostMapping("/edit/{id}")
    public String edit(@PathVariable Long id,
                       @Valid @ModelAttribute("accountForm") AccountForm form,
                       BindingResult bindingResult,
                       RedirectAttributes redirectAttributes) {

        if (bindingResult.hasErrors()) {
            String errorMsg = bindingResult.getAllErrors().get(0).getDefaultMessage();
            redirectAttributes.addFlashAttribute("errorMessage", errorMsg);
            return "redirect:/admin/users";
        }

        try {
            accountService.updateAccount(id, form);
            redirectAttributes.addFlashAttribute("successMessage", "Cập nhật tài khoản ID #" + id + " (" + form.getEmail() + ") thành công!");
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Đã xảy ra lỗi khi cập nhật: " + e.getMessage());
        }

        return "redirect:/admin/users";
    }

    /**
     * Đổi nhanh trạng thái tài khoản: ACTIVE <-> BANNED.
     */
    @PostMapping("/{id}/toggle-status")
    public String toggleStatus(@PathVariable Long id,
                               Authentication auth,
                               RedirectAttributes redirectAttributes) {
        try {
            String currentEmail = (auth != null) ? auth.getName() : null;
            Account acc = accountService.toggleAccountStatus(id, currentEmail);
            String statusLabel = (acc.getStatus() == AccountStatus.ACTIVE) ? "Kích hoạt (ACTIVE)" : "Khóa (BANNED)";
            redirectAttributes.addFlashAttribute("successMessage", "Đã chuyển trạng thái tài khoản #" + id + " sang: " + statusLabel);
        } catch (IllegalStateException | IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Lỗi đổi trạng thái: " + e.getMessage());
        }

        return "redirect:/admin/users";
    }

    /**
     * Xóa tài khoản khỏi bảng Account.
     */
    @PostMapping("/{id}/delete")
    public String delete(@PathVariable Long id,
                         Authentication auth,
                         RedirectAttributes redirectAttributes) {
        try {
            String currentEmail = (auth != null) ? auth.getName() : null;
            accountService.deleteAccount(id, currentEmail);
            redirectAttributes.addFlashAttribute("successMessage", "Đã xóa tài khoản ID #" + id + " thành công!");
        } catch (IllegalStateException | IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        } catch (DataIntegrityViolationException e) {
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Không thể xóa tài khoản ID #" + id + " do có ràng buộc dữ liệu (đơn hàng, lịch sử...). Bạn có thể chuyển trạng thái tài khoản sang BANNED (Bị khóa) thay thế.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Lỗi khi xóa tài khoản: " + e.getMessage());
        }

        return "redirect:/admin/users";
    }
}
