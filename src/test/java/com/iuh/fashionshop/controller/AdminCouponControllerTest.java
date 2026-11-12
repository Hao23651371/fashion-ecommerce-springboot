package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.enums.CouponStatus;
import com.iuh.fashionshop.model.enums.CustomerTargetType;
import com.iuh.fashionshop.model.enums.DiscountType;
import com.iuh.fashionshop.repository.CouponRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
class AdminCouponControllerTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private CouponRepository couponRepository;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testListCoupons() throws Exception {
        mockMvc.perform(get("/admin/coupons"))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/coupons"))
                .andExpect(model().attributeExists("coupons"))
                .andExpect(model().attributeExists("categories"))
                .andExpect(model().attributeExists("totalCoupons"))
                .andExpect(model().attributeExists("activeCoupons"))
                .andExpect(model().attributeExists("totalDiscountAmount"))
                .andExpect(model().attributeExists("totalRevenueGenerated"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testCreateCoupon_Success() throws Exception {
        String testCode = "TEST" + System.currentTimeMillis() % 100000;
        mockMvc.perform(post("/admin/coupons")
                        .param("code", testCode)
                        .param("name", "Mã kiểm thử giảm 15%")
                        .param("description", "Mô tả kiểm thử")
                        .param("discountType", "PERCENT")
                        .param("discountValue", "15")
                        .param("maxDiscount", "50000")
                        .param("minOrderValue", "200000")
                        .param("quantity", "100")
                        .param("perUserLimit", "2")
                        .param("targetCustomerType", "NEW_CUSTOMER")
                        .param("startDate", "2026-10-01T00:00")
                        .param("endDate", "2026-12-31T23:59"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/coupons"))
                .andExpect(flash().attributeExists("successMessage"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testToggleStatus() throws Exception {
        Coupon c = new Coupon();
        c.setCode("TOGGLE" + System.currentTimeMillis() % 100000);
        c.setName("Mã chuyển đổi trạng thái");
        c.setDiscountType(DiscountType.FIXED_AMOUNT);
        c.setDiscountValue(new BigDecimal("30000"));
        c.setQuantity(50);
        c.setStartDate(LocalDateTime.now().minusDays(1));
        c.setEndDate(LocalDateTime.now().plusDays(30));
        c.setStatus(CouponStatus.ACTIVE);
        c = couponRepository.save(c);

        mockMvc.perform(post("/admin/coupons/" + c.getId() + "/toggle-status"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/coupons"))
                .andExpect(flash().attributeExists("successMessage"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testExportExcel() throws Exception {
        mockMvc.perform(get("/admin/coupons/export"))
                .andExpect(status().isOk())
                .andExpect(result -> {
                    String contentType = result.getResponse().getContentType();
                    org.junit.jupiter.api.Assertions.assertNotNull(contentType);
                    org.junit.jupiter.api.Assertions.assertTrue(contentType.contains("spreadsheetml.sheet"));
                    byte[] content = result.getResponse().getContentAsByteArray();
                    org.junit.jupiter.api.Assertions.assertTrue(content.length > 0);
                });
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testCreateCoupon_Ajax_Success() throws Exception {
        String testCode = "AJAX" + System.currentTimeMillis() % 100000;
        mockMvc.perform(post("/admin/coupons")
                        .header("X-Requested-With", "XMLHttpRequest")
                        .header("Accept", "application/json")
                        .param("code", testCode)
                        .param("name", "Mã kiểm thử AJAX")
                        .param("description", "Mô tả kiểm thử AJAX")
                        .param("discountType", "FREESHIP")
                        .param("discountValue", "25000")
                        .param("quantity", "50")
                        .param("perUserLimit", "1")
                        .param("targetCustomerType", "ALL")
                        .param("startDate", "2026-10-01T00:00")
                        .param("endDate", "2026-12-31T23:59"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.coupon.code").value(testCode))
                .andExpect(jsonPath("$.coupon.discountType").value("FREESHIP"))
                .andExpect(jsonPath("$.stats.totalCoupons").exists());
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testToggleStatus_Ajax_Success() throws Exception {
        Coupon c = new Coupon();
        c.setCode("AJAXTOG" + System.currentTimeMillis() % 100000);
        c.setName("Mã toggle qua AJAX");
        c.setDiscountType(DiscountType.PERCENT);
        c.setDiscountValue(new BigDecimal("10"));
        c.setQuantity(20);
        c.setStartDate(LocalDateTime.now().minusDays(1));
        c.setEndDate(LocalDateTime.now().plusDays(30));
        c.setStatus(CouponStatus.ACTIVE);
        c = couponRepository.save(c);

        mockMvc.perform(post("/admin/coupons/" + c.getId() + "/toggle-status")
                        .header("X-Requested-With", "XMLHttpRequest")
                        .header("Accept", "application/json"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.status").value("PAUSED"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testCreateCoupon_Ajax_PercentageWithMaxDiscount() throws Exception {
        String testCode = "PERC" + System.currentTimeMillis() % 100000;
        mockMvc.perform(post("/admin/coupons")
                        .header("X-Requested-With", "XMLHttpRequest")
                        .header("Accept", "application/json")
                        .param("code", testCode)
                        .param("name", "Giảm 20% tối đa 50k")
                        .param("discountType", "PERCENT")
                        .param("discountValue", "20")
                        .param("maxDiscount", "50000")
                        .param("minOrderValue", "200000")
                        .param("quantity", "100")
                        .param("startDate", "2026-10-01T00:00")
                        .param("endDate", "2026-12-31T23:59"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.coupon.code").value(testCode))
                .andExpect(jsonPath("$.coupon.discountType").value("PERCENT"))
                .andExpect(jsonPath("$.coupon.discountText").value("Giảm 20%"))
                .andExpect(jsonPath("$.coupon.maxDiscount").value(50000));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testCreateCoupon_Ajax_Freeship100Percent() throws Exception {
        String testCode = "FREE" + System.currentTimeMillis() % 100000;
        mockMvc.perform(post("/admin/coupons")
                        .header("X-Requested-With", "XMLHttpRequest")
                        .header("Accept", "application/json")
                        .param("code", testCode)
                        .param("name", "Miễn phí vận chuyển toàn sàn")
                        .param("discountType", "FREESHIP")
                        .param("discountValue", "0")
                        .param("quantity", "200")
                        .param("startDate", "2026-10-01T00:00")
                        .param("endDate", "2026-12-31T23:59"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.coupon.code").value(testCode))
                .andExpect(jsonPath("$.coupon.discountType").value("FREESHIP"))
                .andExpect(jsonPath("$.coupon.discountText").value("Freeship 100%"));
    }

    @Test
    @WithMockUser(username = "khach1@gmail.com", roles = {"CUSTOMER"})
    void testForbiddenForCustomer() throws Exception {
        mockMvc.perform(get("/admin/coupons"))
                .andExpect(status().isForbidden());
    }
}
