package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.enums.AccountStatus;
import com.iuh.fashionshop.model.enums.Role;
import com.iuh.fashionshop.repository.AccountRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class AdminUserControllerTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private AccountRepository accountRepository;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    @DisplayName("Truy cập trang Quản lý tài khoản: hiển thị danh sách, phân quyền và thống kê")
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testShowUsersPage_Success() throws Exception {
        mockMvc.perform(get("/admin/users"))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/users"))
                .andExpect(model().attributeExists("accounts"))
                .andExpect(model().attributeExists("allRoles"))
                .andExpect(model().attributeExists("totalAccounts"))
                .andExpect(model().attributeExists("adminAccounts"))
                .andExpect(model().attributeExists("staffAccounts"))
                .andExpect(model().attributeExists("customerAccounts"));
    }

    @Test
    @DisplayName("Chức năng phân quyền: Cập nhật vai trò STAFF và tương tác lưu vào Database thành công")
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testAssignRole_Success_InteractsWithDatabase() throws Exception {
        // Tạo tài khoản thử nghiệm ban đầu là CUSTOMER
        Account testAcc = new Account();
        testAcc.setEmail("test_role_user@fashionshop.vn");
        testAcc.setPassword("$2a$10$dummyHashPassword12345678901234567890");
        testAcc.setRole(Role.CUSTOMER);
        testAcc.setStatus(AccountStatus.ACTIVE);
        testAcc.setEmailVerified(true);
        testAcc.setCreatedAt(LocalDateTime.now());
        testAcc = accountRepository.save(testAcc);

        Long accountId = testAcc.getId();

        // Thực hiện phân quyền sang STAFF thông qua endpoint POST /admin/users/{id}/role
        mockMvc.perform(post("/admin/users/" + accountId + "/role")
                        .param("role", "STAFF"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/users"))
                .andExpect(flash().attributeExists("successMessage"));

        // Kiểm tra trực tiếp trong Database để chứng minh đã lưu thành công
        Account updatedAcc = accountRepository.findById(accountId).orElseThrow();
        assertEquals(Role.STAFF, updatedAcc.getRole(), "Vai trò trong CSDL phải được cập nhật thành STAFF");

        // Tiếp tục phân quyền nâng lên ADMIN
        mockMvc.perform(post("/admin/users/" + accountId + "/role")
                        .param("role", "ADMIN"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/users"))
                .andExpect(flash().attributeExists("successMessage"));

        Account adminAcc = accountRepository.findById(accountId).orElseThrow();
        assertEquals(Role.ADMIN, adminAcc.getRole(), "Vai trò trong CSDL phải được cập nhật thành ADMIN");
    }

    @Test
    @DisplayName("Bảo vệ an toàn: Admin đang đăng nhập không thể tự hạ quyền ADMIN của chính mình")
    @WithMockUser(username = "admin_self_test@fashionshop.vn", roles = {"ADMIN"})
    void testAssignRole_AdminCannotDemoteSelf() throws Exception {
        Account currentAdmin = new Account();
        currentAdmin.setEmail("admin_self_test@fashionshop.vn");
        currentAdmin.setPassword("$2a$10$dummyHashPassword12345678901234567890");
        currentAdmin.setRole(Role.ADMIN);
        currentAdmin.setStatus(AccountStatus.ACTIVE);
        currentAdmin.setEmailVerified(true);
        currentAdmin.setCreatedAt(LocalDateTime.now());
        currentAdmin = accountRepository.save(currentAdmin);

        Long adminId = currentAdmin.getId();

        // Cố gắng tự hạ quyền xuống CUSTOMER
        mockMvc.perform(post("/admin/users/" + adminId + "/role")
                        .param("role", "CUSTOMER"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/users"))
                .andExpect(flash().attributeExists("errorMessage"));

        // Kiểm tra trong CSDL vai trò vẫn là ADMIN không bị thay đổi
        Account reloaded = accountRepository.findById(adminId).orElseThrow();
        assertEquals(Role.ADMIN, reloaded.getRole(), "Tài khoản admin đang đăng nhập không bị hạ quyền");
    }

    @Test
    @DisplayName("Tài khoản STAFF khi truy cập /admin/users bị từ chối quyền (403 Forbidden)")
    @WithMockUser(username = "staff1@fashionshop.vn", roles = {"STAFF"})
    void testStaffAccessUsersPage_Forbidden() throws Exception {
        mockMvc.perform(get("/admin/users"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Trang lỗi 403 hiển thị thành công với đầy đủ nút điều hướng")
    @WithMockUser(username = "staff1@fashionshop.vn", roles = {"STAFF"})
    void test403Page_Success() throws Exception {
        mockMvc.perform(get("/error/403"))
                .andExpect(status().isOk())
                .andExpect(view().name("error/403"))
                .andExpect(model().attributeExists("pageTitle"));
    }
}
