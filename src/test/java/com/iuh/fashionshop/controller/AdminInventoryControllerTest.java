package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.StockHistory;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.model.enums.Gender;
import com.iuh.fashionshop.model.enums.ProductStatus;
import com.iuh.fashionshop.model.enums.StockMovementType;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.repository.ProductRepository;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import com.iuh.fashionshop.repository.StockHistoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class AdminInventoryControllerTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private ProductVariantRepository productVariantRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private StockHistoryRepository stockHistoryRepository;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    private ProductVariant createTestVariant(String name, String sku, String size, String color, int stock) {
        Category category = new Category();
        category.setName("Danh mục " + sku);
        category.setStatus(CategoryStatus.VISIBLE);
        category = categoryRepository.save(category);

        Product product = new Product();
        product.setName(name);
        product.setCategory(category);
        product.setGender(Gender.UNISEX);
        product.setPrice(BigDecimal.valueOf(200000));
        product.setStatus(ProductStatus.ACTIVE);
        product = productRepository.save(product);

        ProductVariant variant = new ProductVariant();
        variant.setProduct(product);
        variant.setSku(sku);
        variant.setSize(size);
        variant.setColor(color);
        variant.setStockQuantity(stock);
        variant.setStatus(VariantStatus.ACTIVE);
        return productVariantRepository.save(variant);
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testShowInventoryPage() throws Exception {
        mockMvc.perform(get("/admin/inventory"))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/inventory"))
                .andExpect(model().attributeExists("items"))
                .andExpect(model().attributeExists("summary"))
                .andExpect(model().attributeExists("allVariants"))
                .andExpect(model().attributeExists("categories"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testMultiRowImport_CreatesReceiptAndUpdatesStockAndRecordsHistory() throws Exception {
        ProductVariant var1 = createTestVariant("Áo Sơ Mi Oxford", "TEST-OXF-001", "M", "Trắng", 5);
        ProductVariant var2 = createTestVariant("Quần Tây Slimfit", "TEST-SLIM-002", "L", "Đen", 10);

        mockMvc.perform(post("/admin/inventory/import")
                        .with(csrf())
                        .param("variantId", var1.getId().toString(), var2.getId().toString())
                        .param("quantity", "15", "20")
                        .param("importPrice", "100000", "150000")
                        .param("supplier", "Xưởng may Tân Bình")
                        .param("reason", "Nhập bổ sung đợt 1"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("successMessage"));

        // 1. Kiểm tra tồn kho đã cập nhật chính xác
        ProductVariant updatedVar1 = productVariantRepository.findById(var1.getId()).orElseThrow();
        ProductVariant updatedVar2 = productVariantRepository.findById(var2.getId()).orElseThrow();
        assertEquals(20, updatedVar1.getStockQuantity(), "5 + 15 phải bằng 20");
        assertEquals(30, updatedVar2.getStockQuantity(), "10 + 20 phải bằng 30");

        // 2. Kiểm tra lịch sử biến động kho (StockHistory) được tạo với chung receiptCode
        List<StockHistory> histories1 = stockHistoryRepository.findByVariantIdOrderByCreatedAtDesc(var1.getId());
        assertFalse(histories1.isEmpty());
        StockHistory h1 = histories1.get(0);
        assertEquals(StockMovementType.IMPORT, h1.getType());
        assertEquals(15, h1.getQuantityChange());
        assertEquals(20, h1.getStockAfter());
        assertNotNull(h1.getReceiptCode());
        assertTrue(h1.getReceiptCode().startsWith("PN-"));
        assertEquals("Xưởng may Tân Bình", h1.getSupplier());
        assertEquals("Nhập bổ sung đợt 1", h1.getReason());

        List<StockHistory> histories2 = stockHistoryRepository.findByVariantIdOrderByCreatedAtDesc(var2.getId());
        assertFalse(histories2.isEmpty());
        StockHistory h2 = histories2.get(0);
        assertEquals(StockMovementType.IMPORT, h2.getType());
        assertEquals(20, h2.getQuantityChange());
        assertEquals(30, h2.getStockAfter());
        assertEquals(h1.getReceiptCode(), h2.getReceiptCode());
        assertEquals("Xưởng may Tân Bình", h2.getSupplier());
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testSingleRowImport_WorksSuccessfully() throws Exception {
        ProductVariant var = createTestVariant("Váy Dạ Hội", "TEST-DRESS-001", "S", "Đỏ", 3);

        mockMvc.perform(post("/admin/inventory/import")
                        .with(csrf())
                        .param("variantId", var.getId().toString())
                        .param("quantity", "8")
                        .param("importPrice", "250000")
                        .param("supplier", "Xưởng may Kim Liên")
                        .param("reason", "Nhập hàng đơn lẻ"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("successMessage"));

        ProductVariant updated = productVariantRepository.findById(var.getId()).orElseThrow();
        assertEquals(11, updated.getStockQuantity(), "3 + 8 = 11");

        List<StockHistory> histories = stockHistoryRepository.findByVariantIdOrderByCreatedAtDesc(var.getId());
        assertFalse(histories.isEmpty());
        assertEquals(8, histories.get(0).getQuantityChange());
        assertEquals(11, histories.get(0).getStockAfter());
        assertNotNull(histories.get(0).getReceiptCode());
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testImportStock_ValidationErrors() throws Exception {
        ProductVariant var = createTestVariant("Áo Polo Basic", "TEST-POLO-001", "XL", "Xanh", 10);

        // Trường hợp 1: Không có variantId nào
        mockMvc.perform(post("/admin/inventory/import")
                        .with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("errorMessage"));

        // Trường hợp 2: Số lượng <= 0
        mockMvc.perform(post("/admin/inventory/import")
                        .with(csrf())
                        .param("variantId", var.getId().toString())
                        .param("quantity", "0"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("errorMessage"));

        // Trường hợp 3: Đơn giá nhập âm
        mockMvc.perform(post("/admin/inventory/import")
                        .with(csrf())
                        .param("variantId", var.getId().toString())
                        .param("quantity", "5")
                        .param("importPrice", "-1000"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("errorMessage"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testMultiRowAudit_UpdatesStockAndRecordsHistoryWithCommonAuditCode() throws Exception {
        ProductVariant var1 = createTestVariant("Áo Khoác Denim", "TEST-AUD-001", "M", "Xanh denim", 10);
        ProductVariant var2 = createTestVariant("Quần Jeans Baggy", "TEST-AUD-002", "L", "Đen", 15);
        ProductVariant var3 = createTestVariant("Áo Thun Cotton", "TEST-AUD-003", "S", "Trắng", 8);

        mockMvc.perform(post("/admin/inventory/audit")
                        .with(csrf())
                        .param("reason", "Kiểm kê kho cuối tháng")
                        .param("items[0].variantId", var1.getId().toString())
                        .param("items[0].actualStock", "12")
                        .param("items[0].reason", "Thừa 2 chiếc, phát hiện ở kệ trưng bày")
                        .param("items[1].variantId", var2.getId().toString())
                        .param("items[1].actualStock", "11")
                        .param("items[1].reason", "")
                        .param("items[2].variantId", var3.getId().toString())
                        .param("items[2].actualStock", "8")
                        .param("items[2].reason", ""))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("successMessage"));

        assertEquals(12, productVariantRepository.findById(var1.getId()).orElseThrow().getStockQuantity());
        assertEquals(11, productVariantRepository.findById(var2.getId()).orElseThrow().getStockQuantity());
        assertEquals(8, productVariantRepository.findById(var3.getId()).orElseThrow().getStockQuantity());

        StockHistory h1 = stockHistoryRepository.findByVariantIdOrderByCreatedAtDesc(var1.getId()).get(0);
        StockHistory h2 = stockHistoryRepository.findByVariantIdOrderByCreatedAtDesc(var2.getId()).get(0);
        StockHistory h3 = stockHistoryRepository.findByVariantIdOrderByCreatedAtDesc(var3.getId()).get(0);

        assertEquals(StockMovementType.ADJUSTMENT, h1.getType());
        assertEquals(2, h1.getQuantityChange());
        assertEquals(12, h1.getStockAfter());
        assertEquals("Thừa 2 chiếc, phát hiện ở kệ trưng bày", h1.getReason());
        assertNotNull(h1.getReceiptCode());
        assertTrue(h1.getReceiptCode().startsWith("PKK-"));

        assertEquals(StockMovementType.ADJUSTMENT, h2.getType());
        assertEquals(-4, h2.getQuantityChange());
        assertEquals(11, h2.getStockAfter());
        assertEquals("Kiểm kê kho cuối tháng", h2.getReason());
        assertEquals(h1.getReceiptCode(), h2.getReceiptCode());

        assertEquals(StockMovementType.ADJUSTMENT, h3.getType());
        assertEquals(0, h3.getQuantityChange());
        assertEquals(8, h3.getStockAfter());
        assertEquals("Kiểm kê kho cuối tháng", h3.getReason());
        assertEquals(h1.getReceiptCode(), h3.getReceiptCode());
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testSingleRowAudit_BackwardCompatibleParamsWork() throws Exception {
        ProductVariant var = createTestVariant("Áo Len Cổ Lọ", "TEST-AUD-SINGLE", "M", "Be", 10);

        mockMvc.perform(post("/admin/inventory/audit")
                        .with(csrf())
                        .param("variantId", var.getId().toString())
                        .param("actualStock", "7")
                        .param("reason", "Hàng lỗi / rách"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("successMessage"));

        assertEquals(7, productVariantRepository.findById(var.getId()).orElseThrow().getStockQuantity());
        StockHistory h = stockHistoryRepository.findByVariantIdOrderByCreatedAtDesc(var.getId()).get(0);
        assertEquals(StockMovementType.ADJUSTMENT, h.getType());
        assertEquals(-3, h.getQuantityChange());
        assertEquals(7, h.getStockAfter());
        assertEquals("Hàng lỗi / rách", h.getReason());
        assertNotNull(h.getReceiptCode());
        assertTrue(h.getReceiptCode().startsWith("PKK-"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testAuditStock_ValidationErrors() throws Exception {
        ProductVariant var = createTestVariant("Áo Blazer", "TEST-AUD-VAL", "L", "Đen", 10);

        // Trường hợp 1: Không có dòng SKU nào
        mockMvc.perform(post("/admin/inventory/audit")
                        .with(csrf())
                        .param("reason", "Kiểm kê định kỳ"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("errorMessage"));

        // Trường hợp 2: Tồn thực tế âm
        mockMvc.perform(post("/admin/inventory/audit")
                        .with(csrf())
                        .param("items[0].variantId", var.getId().toString())
                        .param("items[0].actualStock", "-1")
                        .param("reason", "Kiểm kê định kỳ"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("errorMessage"));

        // Trường hợp 3: Trùng biến thể trong cùng phiếu kiểm kê
        mockMvc.perform(post("/admin/inventory/audit")
                        .with(csrf())
                        .param("items[0].variantId", var.getId().toString())
                        .param("items[0].actualStock", "9")
                        .param("items[1].variantId", var.getId().toString())
                        .param("items[1].actualStock", "8")
                        .param("reason", "Kiểm kê định kỳ"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("errorMessage"));

        assertEquals(10, productVariantRepository.findById(var.getId()).orElseThrow().getStockQuantity());
    }
}
