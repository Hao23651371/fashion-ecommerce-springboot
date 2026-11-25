package com.iuh.fashionshop.service;

import com.iuh.fashionshop.controller.AdminInventoryController;
import com.iuh.fashionshop.dto.AuditForm;
import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.StockHistory;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.StockMovementType;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import com.iuh.fashionshop.repository.StockHistoryRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class InventoryServiceAuditTest {

    @Mock
    private ProductVariantRepository variantRepository;

    @Mock
    private StockHistoryRepository stockHistoryRepository;

    @Mock
    private UserProfileRepository userProfileRepository;

    @Mock
    private CategoryRepository categoryRepository;

    private InventoryService inventoryService;

    @BeforeEach
    void setUp() {
        inventoryService = new InventoryService(
                variantRepository,
                stockHistoryRepository,
                userProfileRepository,
                categoryRepository
        );
    }

    private ProductVariant variant(Long id, String sku, String size, String color, int stock) {
        Product p = new Product();
        p.setId(id * 10);
        p.setName("Sản phẩm " + sku);
        p.setPrice(BigDecimal.valueOf(250000));

        ProductVariant v = new ProductVariant();
        v.setId(id);
        v.setProduct(p);
        v.setSku(sku);
        v.setSize(size);
        v.setColor(color);
        v.setStockQuantity(stock);
        v.setStatus(VariantStatus.ACTIVE);
        return v;
    }

    @Test
    void auditStockReceipt_multiRow_updatesStocksAndSharesAuditCode() {
        ProductVariant v1 = variant(1L, "SKU-001", "M", "Đen", 10);
        ProductVariant v2 = variant(2L, "SKU-002", "L", "Trắng", 15);
        ProductVariant v3 = variant(3L, "SKU-003", "S", "Be", 8);

        UserProfile admin = new UserProfile();
        admin.setFullName("Quản lý Kho");

        when(userProfileRepository.findByAccountEmail("admin@shop.vn")).thenReturn(Optional.of(admin));
        when(stockHistoryRepository.count()).thenReturn(41L);
        when(variantRepository.findById(1L)).thenReturn(Optional.of(v1));
        when(variantRepository.findById(2L)).thenReturn(Optional.of(v2));
        when(variantRepository.findById(3L)).thenReturn(Optional.of(v3));

        AuditForm form = new AuditForm();
        form.setReason("Kiểm kê cuối tháng");
        form.setItems(List.of(
                new AuditForm.AuditItem(1L, 12, "Thừa 2 chiếc, tìm thấy ở kho phụ"),
                new AuditForm.AuditItem(2L, 11, ""),
                new AuditForm.AuditItem(3L, 8, null)
        ));

        AuditForm result = inventoryService.auditStockReceipt(form, "admin@shop.vn");

        assertNotNull(result.getAuditCode());
        assertTrue(result.getAuditCode().startsWith("PKK-"));
        assertTrue(result.getAuditCode().endsWith("-0042"));
        assertEquals(-2, result.getTotalDiff()); // +2 - 4 + 0 = -2
        assertEquals(2, result.getChangedItemCount());
        assertEquals("Quản lý Kho", result.getPerformedBy());

        assertEquals(12, v1.getStockQuantity());
        assertEquals(11, v2.getStockQuantity());
        assertEquals(8, v3.getStockQuantity());

        ArgumentCaptor<StockHistory> captor = ArgumentCaptor.forClass(StockHistory.class);
        verify(stockHistoryRepository, times(3)).save(captor.capture());

        List<StockHistory> saved = captor.getAllValues();
        assertEquals(StockMovementType.ADJUSTMENT, saved.get(0).getType());
        assertEquals(2, saved.get(0).getQuantityChange());
        assertEquals(12, saved.get(0).getStockAfter());
        assertEquals("Thừa 2 chiếc, tìm thấy ở kho phụ", saved.get(0).getReason());
        assertEquals(result.getAuditCode(), saved.get(0).getReceiptCode());

        assertEquals(-4, saved.get(1).getQuantityChange());
        assertEquals(11, saved.get(1).getStockAfter());
        assertEquals("Kiểm kê cuối tháng", saved.get(1).getReason());
        assertEquals(result.getAuditCode(), saved.get(1).getReceiptCode());

        assertEquals(0, saved.get(2).getQuantityChange());
        assertEquals(8, saved.get(2).getStockAfter());
        assertEquals("Kiểm kê cuối tháng", saved.get(2).getReason());
        assertEquals(result.getAuditCode(), saved.get(2).getReceiptCode());
    }

    @Test
    void auditStockReceipt_rejectsEmptyNegativeOrDuplicateVariants() {
        AuditForm empty = new AuditForm();
        assertThrows(IllegalArgumentException.class,
                () -> inventoryService.auditStockReceipt(empty, null));

        AuditForm negative = new AuditForm();
        negative.setItems(List.of(new AuditForm.AuditItem(1L, -1, null)));
        assertThrows(IllegalArgumentException.class,
                () -> inventoryService.auditStockReceipt(negative, null));

        AuditForm duplicate = new AuditForm();
        duplicate.setItems(List.of(
                new AuditForm.AuditItem(1L, 5, null),
                new AuditForm.AuditItem(1L, 6, null)
        ));
        assertThrows(IllegalArgumentException.class,
                () -> inventoryService.auditStockReceipt(duplicate, null));

        verify(variantRepository, never()).save(any());
        verify(stockHistoryRepository, never()).save(any());
    }

    @Test
    void getAllVariantViewsForSelection_includesSizeColorAndColorHex() {
        ProductVariant v = variant(10L, "SKU-010", "XL", "Đen", 20);
        when(variantRepository.findAllWithProductAndCategory()).thenReturn(List.of(v));

        List<InventoryService.InventoryItemView> views = inventoryService.getAllVariantViewsForSelection();
        assertEquals(1, views.size());
        assertEquals("XL", views.get(0).size());
        assertEquals("Đen", views.get(0).color());
        assertEquals("#111111", views.get(0).colorHex());
        assertEquals(20, views.get(0).stockQuantity());
    }

    @Test
    void controllerAuditEndpoint_bindsIndexedItemsWithCommasAndBackwardCompatParams() throws Exception {
        ProductVariant v1 = variant(1L, "SKU-001", "M", "Đen", 10);
        ProductVariant v2 = variant(2L, "SKU-002", "L", "Trắng", 5);
        when(variantRepository.findById(1L)).thenReturn(Optional.of(v1));
        when(variantRepository.findById(2L)).thenReturn(Optional.of(v2));
        when(stockHistoryRepository.count()).thenReturn(0L);

        AdminInventoryController controller = new AdminInventoryController(inventoryService, categoryRepository);
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller).build();

        // 1. Multi-row indexed binding (including comma inside item reason)
        mockMvc.perform(post("/admin/inventory/audit")
                        .param("reason", "Kiểm kê định kỳ")
                        .param("items[0].variantId", "1")
                        .param("items[0].actualStock", "12")
                        .param("items[0].reason", "Hàng lỗi, rách nhẹ")
                        .param("items[1].variantId", "2")
                        .param("items[1].actualStock", "3")
                        .param("items[1].reason", ""))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("successMessage"));

        assertEquals(12, v1.getStockQuantity());
        assertEquals(3, v2.getStockQuantity());

        // 2. Single-row backward-compatible binding
        mockMvc.perform(post("/admin/inventory/audit")
                        .param("variantId", "1")
                        .param("actualStock", "9")
                        .param("reason", "Điều chỉnh nhanh"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/inventory"))
                .andExpect(flash().attributeExists("successMessage"));

        assertEquals(9, v1.getStockQuantity());
    }
}
