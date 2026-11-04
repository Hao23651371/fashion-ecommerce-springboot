package com.iuh.fashionshop.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

@SpringBootTest
class AdminStatisticsControllerTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testShowStatisticsPage_Default() throws Exception {
        mockMvc.perform(get("/admin/statistics"))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/statistics"))
                .andExpect(model().attributeExists("stats"))
                .andExpect(model().attributeExists("pageTitle"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testShowStatisticsPage_WithCustomDateRange() throws Exception {
        mockMvc.perform(get("/admin/statistics")
                        .param("startDate", "2026-10-01")
                        .param("endDate", "2026-10-27"))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/statistics"))
                .andExpect(model().attributeExists("stats"))
                .andExpect(model().attributeExists("pageTitle"));
    }

    @Test
    @WithMockUser(username = "khach1@gmail.com", roles = {"CUSTOMER"})
    void testShowStatisticsPage_ForbiddenForCustomer() throws Exception {
        mockMvc.perform(get("/admin/statistics"))
                .andExpect(status().isForbidden());
    }
}
