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

    @Autowired
    private com.iuh.fashionshop.repository.UserProfileRepository userProfileRepository;

    @Autowired
    private com.iuh.fashionshop.repository.OrderRepository orderRepository;

    @Autowired
    private org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

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
    @DisplayName("Ràng buộc xóa: Không thể xóa tài khoản nếu đã phát sinh đơn hàng")
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testDeleteAccount_Blocked_WhenHasOrders() throws Exception {
        Account testAcc = new Account();
        testAcc.setEmail("user_with_order@fashionshop.vn");
        testAcc.setPassword("$2a$10$dummyHashPassword12345678901234567890");
        testAcc.setRole(Role.CUSTOMER);
        testAcc.setStatus(AccountStatus.ACTIVE);
        testAcc.setEmailVerified(true);
        testAcc.setCreatedAt(LocalDateTime.now());
        testAcc = accountRepository.save(testAcc);

        com.iuh.fashionshop.model.UserProfile profile = new com.iuh.fashionshop.model.UserProfile();
        profile.setFullName("User Có Đơn");
        profile.setAccount(testAcc);
        profile = userProfileRepository.save(profile);

        com.iuh.fashionshop.model.Order order = new com.iuh.fashionshop.model.Order();
        order.setOrderCode("TEST-ORD-" + System.currentTimeMillis());
        order.setUserProfile(profile);
        order.setStatus(com.iuh.fashionshop.model.enums.OrderStatus.COMPLETED);
        order.setSubtotal(java.math.BigDecimal.valueOf(100000));
        order.setTotalAmount(java.math.BigDecimal.valueOf(100000));
        order.setDiscountAmount(java.math.BigDecimal.ZERO);
        order.setCreatedAt(LocalDateTime.now());
        orderRepository.save(order);

        mockMvc.perform(post("/admin/users/" + testAcc.getId() + "/delete"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/users"))
                .andExpect(flash().attributeExists("errorMessage"));

        // Xác nhận tài khoản vẫn còn trong CSDL, không bị xóa
        assertEquals(true, accountRepository.existsById(testAcc.getId()));
    }

    @Test
    @DisplayName("Ràng buộc khóa (Cách 2): Không thể khóa tài khoản nếu có đơn hàng đang xử lý/giao hàng")
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testLockAccount_Blocked_WhenHasActiveOrders() throws Exception {
        Account testAcc = new Account();
        testAcc.setEmail("user_active_order@fashionshop.vn");
        testAcc.setPassword("$2a$10$dummyHashPassword12345678901234567890");
        testAcc.setRole(Role.CUSTOMER);
        testAcc.setStatus(AccountStatus.ACTIVE);
        testAcc.setEmailVerified(true);
        testAcc.setCreatedAt(LocalDateTime.now());
        testAcc = accountRepository.save(testAcc);

        com.iuh.fashionshop.model.UserProfile profile = new com.iuh.fashionshop.model.UserProfile();
        profile.setFullName("User Đang Chờ Giao");
        profile.setAccount(testAcc);
        profile = userProfileRepository.save(profile);

        com.iuh.fashionshop.model.Order order = new com.iuh.fashionshop.model.Order();
        order.setOrderCode("TEST-ORD-SHIP-" + System.currentTimeMillis());
        order.setUserProfile(profile);
        order.setStatus(com.iuh.fashionshop.model.enums.OrderStatus.SHIPPING);
        order.setSubtotal(java.math.BigDecimal.valueOf(250000));
        order.setTotalAmount(java.math.BigDecimal.valueOf(250000));
        order.setDiscountAmount(java.math.BigDecimal.ZERO);
        order.setCreatedAt(LocalDateTime.now());
        orderRepository.save(order);

        mockMvc.perform(post("/admin/users/" + testAcc.getId() + "/toggle-status"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/users"))
                .andExpect(flash().attributeExists("errorMessage"));

        // Xác nhận tài khoản vẫn là ACTIVE, không bị chuyển sang BANNED
        Account reloaded = accountRepository.findById(testAcc.getId()).orElseThrow();
        assertEquals(AccountStatus.ACTIVE, reloaded.getStatus());
    }

    @Test
    @DisplayName("Khôi phục / Reset mật khẩu: Reset mật khẩu thành công về FashionShop@123")
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testResetPassword_Success() throws Exception {
        Account testAcc = new Account();
        testAcc.setEmail("user_reset_pwd@fashionshop.vn");
        testAcc.setPassword(passwordEncoder.encode("OldPassword@123"));
        testAcc.setRole(Role.CUSTOMER);
        testAcc.setStatus(AccountStatus.ACTIVE);
        testAcc.setEmailVerified(true);
        testAcc.setCreatedAt(LocalDateTime.now());
        testAcc = accountRepository.save(testAcc);

        mockMvc.perform(post("/admin/users/" + testAcc.getId() + "/reset-password"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/users"))
                .andExpect(flash().attributeExists("successMessage"));

        Account updatedAcc = accountRepository.findById(testAcc.getId()).orElseThrow();
        org.junit.jupiter.api.Assertions.assertTrue(passwordEncoder.matches("FashionShop@123", updatedAcc.getPassword()),
                "Mật khẩu sau khi reset phải khớp với mật khẩu mặc định FashionShop@123");
    }

    @Test
    @DisplayName("Khôi phục / Reset mật khẩu: Admin không thể tự reset mật khẩu của chính mình tại trang quản lý danh sách")
    @WithMockUser(username = "admin_self_reset@fashionshop.vn", roles = {"ADMIN"})
    void testResetPassword_AdminCannotResetSelf() throws Exception {
        Account selfAdmin = new Account();
        selfAdmin.setEmail("admin_self_reset@fashionshop.vn");
        selfAdmin.setPassword(passwordEncoder.encode("AdminPassword@999"));
        selfAdmin.setRole(Role.ADMIN);
        selfAdmin.setStatus(AccountStatus.ACTIVE);
        selfAdmin.setEmailVerified(true);
        selfAdmin.setCreatedAt(LocalDateTime.now());
        selfAdmin = accountRepository.save(selfAdmin);

        mockMvc.perform(post("/admin/users/" + selfAdmin.getId() + "/reset-password"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/users"))
                .andExpect(flash().attributeExists("errorMessage"));

        Account reloaded = accountRepository.findById(selfAdmin.getId()).orElseThrow();
        org.junit.jupiter.api.Assertions.assertTrue(passwordEncoder.matches("AdminPassword@999", reloaded.getPassword()),
                "Mật khẩu của tài khoản Admin đang đăng nhập không bị reset");
    }
}
