package com.iuh.fashionshop.service;

import com.iuh.fashionshop.model.Category;
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
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class InventoryService {

    private static final Map<String, String> COLOR_HEX = Map.ofEntries(
            Map.entry("be", "#d8c3a5"),
            Map.entry("trắng", "#ffffff"),
            Map.entry("xanh nhạt", "#bcd4e6"),
            Map.entry("đen", "#111111"),
            Map.entry("camel", "#c19a6b"),
            Map.entry("xám tro", "#8d9096"),
            Map.entry("kem", "#f3ead3"),
            Map.entry("xanh denim", "#4a6fa5"),
            Map.entry("nâu", "#6f4e37"),
            Map.entry("xanh rêu", "#6b7a3d"),
            Map.entry("hồng phấn", "#f4c2c2"),
            Map.entry("xanh navy", "#1f2a44")
    );
    private static final String DEFAULT_HEX = "#cfcfcf";
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final ProductVariantRepository variantRepository;
    private final StockHistoryRepository stockHistoryRepository;
    private final UserProfileRepository userProfileRepository;
    private final CategoryRepository categoryRepository;

    public InventoryService(ProductVariantRepository variantRepository,
                            StockHistoryRepository stockHistoryRepository,
                            UserProfileRepository userProfileRepository,
                            CategoryRepository categoryRepository) {
        this.variantRepository = variantRepository;
        this.stockHistoryRepository = stockHistoryRepository;
        this.userProfileRepository = userProfileRepository;
        this.categoryRepository = categoryRepository;
    }

    public static String getHexColor(String colorName) {
        if (colorName == null || colorName.isBlank()) return DEFAULT_HEX;
        return COLOR_HEX.getOrDefault(colorName.trim().toLowerCase(Locale.ROOT), DEFAULT_HEX);
    }

    public static String formatCurrency(BigDecimal amount) {
        if (amount == null) return "0 đ";
        return NumberFormat.getNumberInstance(new Locale("vi", "VN")).format(amount) + " đ";
    }

    @Transactional(readOnly = true)
    public Page<InventoryItemView> searchInventory(String keyword, Long categoryId, String stockStatus, Pageable pageable) {
        List<ProductVariant> all = variantRepository.findAllWithProductAndCategory();

        List<InventoryItemView> filtered = all.stream()
                .filter(v -> {
                    if (keyword == null || keyword.isBlank()) return true;
                    String kw = keyword.trim().toLowerCase(Locale.ROOT);
                    String prodName = v.getProduct() != null ? v.getProduct().getName().toLowerCase(Locale.ROOT) : "";
                    String sku = v.getSku() != null ? v.getSku().toLowerCase(Locale.ROOT) : "";
                    String catName = (v.getProduct() != null && v.getProduct().getCategory() != null)
                            ? v.getProduct().getCategory().getName().toLowerCase(Locale.ROOT) : "";
                    return prodName.contains(kw) || sku.contains(kw) || catName.contains(kw);
                })
                .filter(v -> {
                    if (categoryId == null) return true;
                    return v.getProduct() != null
                            && v.getProduct().getCategory() != null
                            && categoryId.equals(v.getProduct().getCategory().getId());
                })
                .filter(v -> {
                    if (stockStatus == null || stockStatus.isBlank() || "ALL".equalsIgnoreCase(stockStatus)) return true;
                    int stock = v.getStockQuantity();
                    return switch (stockStatus.toUpperCase(Locale.ROOT)) {
                        case "OUT" -> stock == 0;
                        case "LOW" -> stock > 0 && stock < 5;
                        case "AVAILABLE" -> stock >= 5;
                        default -> true;
                    };
                })
                .map(this::toItemView)
                .toList();

        int start = (int) pageable.getOffset();
        int end = Math.min(start + pageable.getPageSize(), filtered.size());
        List<InventoryItemView> pageContent = (start <= end && start < filtered.size())
                ? filtered.subList(start, end)
                : Collections.emptyList();

        return new PageImpl<>(pageContent, pageable, filtered.size());
    }

    @Transactional(readOnly = true)
    public InventorySummary getInventorySummary() {
        List<ProductVariant> all = variantRepository.findAllWithProductAndCategory();

        long totalSkus = all.size();
        long totalStock = all.stream().mapToLong(ProductVariant::getStockQuantity).sum();
        long lowStockCount = all.stream().filter(v -> v.getStockQuantity() > 0 && v.getStockQuantity() < 5).count();
        long outOfStockCount = all.stream().filter(v -> v.getStockQuantity() == 0).count();
        long totalValue = all.stream()
                .mapToLong(v -> {
                    BigDecimal price = v.getProduct() != null ? v.getProduct().getCurrentPrice() : BigDecimal.ZERO;
                    return price.multiply(BigDecimal.valueOf(v.getStockQuantity())).longValue();
                })
                .sum();

        return new InventorySummary(
                totalSkus,
                totalStock,
                lowStockCount,
                outOfStockCount,
                formatCurrency(BigDecimal.valueOf(totalValue))
        );
    }

    @Transactional(readOnly = true)
    public List<ProductVariant> getAllVariantsForSelection() {
        return variantRepository.findAllWithProductAndCategory();
    }

    @Transactional
    public void importStock(Long variantId, int quantity, String supplier, BigDecimal importPrice, String reason, String performedByEmail) {
        if (quantity <= 0) {
            throw new IllegalArgumentException("Số lượng nhập kho phải lớn hơn 0");
        }
        ProductVariant variant = variantRepository.findById(variantId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy biến thể sản phẩm có ID: " + variantId));

        variant.increaseStock(quantity);
        variantRepository.save(variant);

        UserProfile performedBy = null;
        if (performedByEmail != null && !performedByEmail.isBlank()) {
            performedBy = userProfileRepository.findByAccountEmail(performedByEmail).orElse(null);
        }

        StockHistory history = new StockHistory();
        history.setVariant(variant);
        history.setType(StockMovementType.IMPORT);
        history.setQuantityChange(quantity);
        history.setStockAfter(variant.getStockQuantity());
        history.setSupplier(supplier != null && !supplier.isBlank() ? supplier.trim() : null);
        history.setImportPrice(importPrice);
        history.setReason(reason != null && !reason.isBlank() ? reason.trim() : "Nhập hàng vào kho");
        history.setPerformedBy(performedBy);
        history.setCreatedAt(LocalDateTime.now());

        stockHistoryRepository.save(history);
    }

    @Transactional
    public void auditStock(Long variantId, int actualStock, String reason, String performedByEmail) {
        if (actualStock < 0) {
            throw new IllegalArgumentException("Số lượng tồn thực tế không được âm");
        }
        ProductVariant variant = variantRepository.findById(variantId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy biến thể sản phẩm có ID: " + variantId));

        int currentStock = variant.getStockQuantity();
        int diff = actualStock - currentStock;

        variant.setStockQuantity(actualStock);
        variantRepository.save(variant);

        UserProfile performedBy = null;
        if (performedByEmail != null && !performedByEmail.isBlank()) {
            performedBy = userProfileRepository.findByAccountEmail(performedByEmail).orElse(null);
        }

        StockHistory history = new StockHistory();
        history.setVariant(variant);
        history.setType(StockMovementType.ADJUSTMENT);
        history.setQuantityChange(diff);
        history.setStockAfter(actualStock);
        history.setReason(reason != null && !reason.isBlank() ? reason.trim() : "Kiểm kê định kỳ");
        history.setPerformedBy(performedBy);
        history.setCreatedAt(LocalDateTime.now());

        stockHistoryRepository.save(history);
    }

    @Transactional(readOnly = true)
    public List<StockHistoryItemView> getVariantHistory(Long variantId) {
        return stockHistoryRepository.findByVariantIdOrderByCreatedAtDesc(variantId).stream()
                .map(this::toHistoryView)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<StockHistoryItemView> searchHistory(String keyword,
                                                   LocalDate startDate,
                                                   LocalDate endDate,
                                                   String movementType,
                                                   String performer,
                                                   Pageable pageable) {
        List<StockHistory> all = stockHistoryRepository.findAllWithDetails();

        List<StockHistoryItemView> filtered = all.stream()
                .filter(h -> {
                    if (keyword == null || keyword.isBlank()) return true;
                    String kw = keyword.trim().toLowerCase(Locale.ROOT);
                    String prodName = (h.getVariant() != null && h.getVariant().getProduct() != null)
                            ? h.getVariant().getProduct().getName().toLowerCase(Locale.ROOT) : "";
                    String sku = (h.getVariant() != null && h.getVariant().getSku() != null)
                            ? h.getVariant().getSku().toLowerCase(Locale.ROOT) : "";
                    String size = (h.getVariant() != null && h.getVariant().getSize() != null)
                            ? h.getVariant().getSize().toLowerCase(Locale.ROOT) : "";
                    String color = (h.getVariant() != null && h.getVariant().getColor() != null)
                            ? h.getVariant().getColor().toLowerCase(Locale.ROOT) : "";
                    String reason = h.getReason() != null ? h.getReason().toLowerCase(Locale.ROOT) : "";
                    String supplier = h.getSupplier() != null ? h.getSupplier().toLowerCase(Locale.ROOT) : "";

                    return prodName.contains(kw)
                            || sku.contains(kw)
                            || size.contains(kw)
                            || color.contains(kw)
                            || reason.contains(kw)
                            || supplier.contains(kw);
                })
                .filter(h -> {
                    if (startDate == null) return true;
                    if (h.getCreatedAt() == null) return false;
                    return !h.getCreatedAt().isBefore(startDate.atStartOfDay());
                })
                .filter(h -> {
                    if (endDate == null) return true;
                    if (h.getCreatedAt() == null) return false;
                    return !h.getCreatedAt().isAfter(endDate.atTime(23, 59, 59, 999999999));
                })
                .filter(h -> {
                    if (movementType == null || movementType.isBlank() || "ALL".equalsIgnoreCase(movementType)) return true;
                    return h.getType() != null && h.getType().name().equalsIgnoreCase(movementType.trim());
                })
                .filter(h -> {
                    if (performer == null || performer.isBlank() || "ALL".equalsIgnoreCase(performer)) return true;
                    if ("SYSTEM".equalsIgnoreCase(performer.trim())) {
                        return h.getPerformedBy() == null;
                    }
                    if (h.getPerformedBy() == null) return false;
                    try {
                        Long pid = Long.parseLong(performer.trim());
                        return pid.equals(h.getPerformedBy().getId());
                    } catch (NumberFormatException e) {
                        String pkw = performer.trim().toLowerCase(Locale.ROOT);
                        String name = h.getPerformedBy().getFullName() != null
                                ? h.getPerformedBy().getFullName().toLowerCase(Locale.ROOT) : "";
                        String email = (h.getPerformedBy().getAccount() != null && h.getPerformedBy().getAccount().getEmail() != null)
                                ? h.getPerformedBy().getAccount().getEmail().toLowerCase(Locale.ROOT) : "";
                        return name.contains(pkw) || email.contains(pkw);
                    }
                })
                .map(this::toHistoryView)
                .toList();

        int start = (int) pageable.getOffset();
        int end = Math.min(start + pageable.getPageSize(), filtered.size());
        List<StockHistoryItemView> pageContent = (start <= end && start < filtered.size())
                ? filtered.subList(start, end)
                : Collections.emptyList();

        return new PageImpl<>(pageContent, pageable, filtered.size());
    }

    @Transactional(readOnly = true)
    public List<UserProfile> getDistinctPerformers() {
        return stockHistoryRepository.findDistinctPerformers();
    }

    @Transactional(readOnly = true)
    public long getTotalHistoryCount() {
        return stockHistoryRepository.count();
    }

    private InventoryItemView toItemView(ProductVariant v) {
        Product p = v.getProduct();
        String img = "";
        if (p != null) {
            if (p.getImageUrl() != null && !p.getImageUrl().isBlank()) {
                img = p.getImageUrl();
            } else if (p.getImages() != null && !p.getImages().isEmpty()) {
                img = p.getImages().get(0).getImageUrl();
            }
        }

        int stock = v.getStockQuantity();
        String statusText;
        String statusClass;
        if (stock == 0) {
            statusText = "Hết hàng";
            statusClass = "stock-out";
        } else if (stock < 5) {
            statusText = "Sắp hết (" + stock + ")";
            statusClass = "stock-low";
        } else {
            statusText = "Còn hàng";
            statusClass = "stock-ok";
        }

        return new InventoryItemView(
                v.getId(),
                v.getSku() != null ? v.getSku() : String.format("#VAR-%04d", v.getId()),
                p != null ? p.getId() : null,
                p != null ? p.getName() : "Không tên",
                (p != null && p.getCategory() != null) ? p.getCategory().getName() : "Chưa phân loại",
                img,
                v.getSize(),
                v.getColor(),
                getHexColor(v.getColor()),
                p != null ? formatCurrency(p.getCurrentPrice()) : "0 đ",
                stock,
                statusText,
                statusClass,
                v.getStatus() == VariantStatus.ACTIVE ? "Đang bán" : "Tạm dừng"
        );
    }

    private StockHistoryItemView toHistoryView(StockHistory h) {
        String typeLabel = switch (h.getType()) {
            case IMPORT -> "Nhập kho";
            case ADJUSTMENT -> "Kiểm kê / Điều chỉnh";
            case SALE -> "Bán hàng";
            case CANCELLED_ORDER -> "Hủy đơn hoàn kho";
        };
        String typeClass = switch (h.getType()) {
            case IMPORT -> "badge-import";
            case ADJUSTMENT -> "badge-adjust";
            case SALE -> "badge-sale";
            case CANCELLED_ORDER -> "badge-cancel";
        };

        String performer = "Hệ thống tự động";
        if (h.getPerformedBy() != null) {
            if (h.getPerformedBy().getFullName() != null && !h.getPerformedBy().getFullName().isBlank()) {
                performer = h.getPerformedBy().getFullName();
            } else if (h.getPerformedBy().getAccount() != null && h.getPerformedBy().getAccount().getEmail() != null) {
                performer = h.getPerformedBy().getAccount().getEmail();
            }
        }

        String formattedChange = (h.getQuantityChange() > 0 ? "+" : "") + h.getQuantityChange();

        return new StockHistoryItemView(
                h.getId(),
                h.getVariant() != null ? h.getVariant().getId() : null,
                h.getVariant() != null ? h.getVariant().getSku() : "",
                (h.getVariant() != null && h.getVariant().getProduct() != null) ? h.getVariant().getProduct().getName() : "",
                (h.getVariant() != null) ? (h.getVariant().getSize() + " / " + h.getVariant().getColor()) : "",
                typeLabel,
                typeClass,
                formattedChange,
                h.getQuantityChange(),
                h.getStockAfter(),
                h.getSupplier() != null ? h.getSupplier() : "-",
                h.getImportPrice() != null ? formatCurrency(h.getImportPrice()) : "-",
                h.getReason() != null ? h.getReason() : "",
                performer,
                h.getCreatedAt() != null ? h.getCreatedAt().format(DATE_TIME_FORMATTER) : ""
        );
    }

    public record InventorySummary(
            long totalSkus,
            long totalStock,
            long lowStockCount,
            long outOfStockCount,
            String totalInventoryValue
    ) {}

    public record InventoryItemView(
            Long id,
            String sku,
            Long productId,
            String productName,
            String categoryName,
            String imageUrl,
            String size,
            String color,
            String colorHex,
            String price,
            int stockQuantity,
            String stockStatusText,
            String stockStatusClass,
            String status
    ) {}

    public record StockHistoryItemView(
            Long id,
            Long variantId,
            String sku,
            String productName,
            String variantDetails,
            String typeLabel,
            String typeClass,
            String formattedChange,
            int quantityChange,
            int stockAfter,
            String supplier,
            String importPrice,
            String reason,
            String performer,
            String createdAt
    ) {}
}
