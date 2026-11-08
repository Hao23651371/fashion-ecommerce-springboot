package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.service.InventoryService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Controller
@RequestMapping("/admin/inventory")
public class AdminInventoryController {

    private final InventoryService inventoryService;
    private final CategoryRepository categoryRepository;

    public AdminInventoryController(InventoryService inventoryService,
                                    CategoryRepository categoryRepository) {
        this.inventoryService = inventoryService;
        this.categoryRepository = categoryRepository;
    }

    @GetMapping
    public String list(@RequestParam(defaultValue = "0") int page,
                       @RequestParam(defaultValue = "10") int size,
                       @RequestParam(required = false) String keyword,
                       @RequestParam(required = false) Long categoryId,
                       @RequestParam(required = false, defaultValue = "ALL") String stockStatus,
                       @RequestParam(required = false, defaultValue = "stock") String tab,
                       @RequestParam(required = false) String historyKeyword,
                       @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
                       @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
                       @RequestParam(required = false, defaultValue = "ALL") String movementType,
                       @RequestParam(required = false, defaultValue = "ALL") String performer,
                       Model model) {

        int validPage = Math.max(0, page);
        int validSize = Math.min(Math.max(1, size), 50);
        Pageable pageable = PageRequest.of(validPage, validSize);

        Page<InventoryService.InventoryItemView> items =
                inventoryService.searchInventory(keyword, categoryId, stockStatus, pageable);

        InventoryService.InventorySummary summary = inventoryService.getInventorySummary();

        // Lấy lịch sử biến động kho theo bộ lọc nếu xem tab lịch sử
        Page<InventoryService.StockHistoryItemView> historyPage = null;
        if ("history".equalsIgnoreCase(tab)) {
            historyPage = inventoryService.searchHistory(historyKeyword, startDate, endDate, movementType, performer, pageable);
        }

        model.addAttribute("pageTitle", "Quản lý Kho Hàng");
        model.addAttribute("items", items);
        model.addAttribute("historyPage", historyPage);
        model.addAttribute("summary", summary);
        model.addAttribute("categories", categoryRepository.findAll());
        model.addAttribute("allVariants", inventoryService.getAllVariantsForSelection());
        model.addAttribute("performers", inventoryService.getDistinctPerformers());
        model.addAttribute("totalHistoryCount", inventoryService.getTotalHistoryCount());

        // Params cho tab Tồn kho
        model.addAttribute("keyword", keyword != null ? keyword : "");
        model.addAttribute("selectedCategory", categoryId);
        model.addAttribute("selectedStock", stockStatus);
        model.addAttribute("currentTab", tab);

        // Params cho tab Lịch sử
        model.addAttribute("historyKeyword", historyKeyword != null ? historyKeyword : "");
        model.addAttribute("startDate", startDate != null ? startDate.toString() : "");
        model.addAttribute("endDate", endDate != null ? endDate.toString() : "");
        model.addAttribute("movementType", movementType != null ? movementType : "ALL");
        model.addAttribute("selectedPerformer", performer != null ? performer : "ALL");

        return "admin/inventory";
    }

    @PostMapping("/import")
    public String importStock(@RequestParam Long variantId,
                              @RequestParam int quantity,
                              @RequestParam(required = false) String supplier,
                              @RequestParam(required = false) BigDecimal importPrice,
                              @RequestParam(required = false) String reason,
                              RedirectAttributes redirectAttributes) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userEmail = (auth != null) ? auth.getName() : null;

            inventoryService.importStock(variantId, quantity, supplier, importPrice, reason, userEmail);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Đã nhập kho thành công +" + quantity + " sản phẩm.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Lỗi khi nhập kho: " + e.getMessage());
        }
        return "redirect:/admin/inventory";
    }

    @PostMapping("/audit")
    public String auditStock(@RequestParam Long variantId,
                             @RequestParam int actualStock,
                             @RequestParam(required = false) String reason,
                             RedirectAttributes redirectAttributes) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userEmail = (auth != null) ? auth.getName() : null;

            inventoryService.auditStock(variantId, actualStock, reason, userEmail);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Cập nhật kết quả kiểm kê thành công. Tồn kho mới: " + actualStock + " chiếc.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Lỗi khi kiểm kê kho: " + e.getMessage());
        }
        return "redirect:/admin/inventory";
    }

    @GetMapping("/api/history/{variantId}")
    @ResponseBody
    public ResponseEntity<List<InventoryService.StockHistoryItemView>> getVariantHistory(@PathVariable Long variantId) {
        List<InventoryService.StockHistoryItemView> history = inventoryService.getVariantHistory(variantId);
        return ResponseEntity.ok(history);
    }
}
