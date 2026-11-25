package com.iuh.fashionshop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Data Transfer Object (DTO) cho chức năng nhập kho hàng loạt.
 */

@Data
@AllArgsConstructor
@Builder
@NoArgsConstructor
public class ReceiptForm {
    private String receiptCode;
    private String supplier;
    private String reason;
    private String performedBy;
    private LocalDateTime createdAt;

    @Builder.Default
    private List<Long> variantId = new ArrayList<>();

    @Builder.Default
    private List<Integer> quantity = new ArrayList<>();

    @Builder.Default
    private List<BigDecimal> importPrice = new ArrayList<>();

    @Builder.Default
    private List<ReceiptItem> items = new ArrayList<>();

    public List<Long> getVariantIds() {
        return variantId;
    }

    public void setVariantIds(List<Long> variantIds) {
        this.variantId = variantIds;
    }

    public List<Integer> getQuantities() {
        return quantity;
    }

    public void setQuantities(List<Integer> quantities) {
        this.quantity = quantities;
    }

    public List<BigDecimal> getImportPrices() {
        return importPrice;
    }

    public void setImportPrices(List<BigDecimal> importPrices) {
        this.importPrice = importPrices;
    }

    /**
     * Chuyển đổi dữ liệu từ danh sách params (variantId, quantity, importPrice) hoặc items
     * thành danh sách các dòng nhập kho hợp lệ.
     */
    public List<ReceiptItem> toReceiptItems() {
        if (items != null && !items.isEmpty()) {
            return items;
        }
        List<ReceiptItem> list = new ArrayList<>();
        if (variantId != null) {
            for (int i = 0; i < variantId.size(); i++) {
                Long vId = variantId.get(i);
                if (vId == null) {
                    continue;
                }
                Integer qty = (quantity != null && quantity.size() > i && quantity.get(i) != null)
                        ? quantity.get(i) : 0;
                BigDecimal price = (importPrice != null && importPrice.size() > i)
                        ? importPrice.get(i) : null;
                list.add(new ReceiptItem(vId, qty, price));
            }
        }
        return list;
    }

    /**
     * Tổng số lượng sản phẩm nhập kho.
     */
    public int getTotalQuantity() {
        return toReceiptItems().stream()
                .mapToInt(i -> i.getQuantity() != null ? i.getQuantity() : 0)
                .sum();
    }

    /**
     * Tổng giá trị nhập kho (VNĐ).
     */
    public BigDecimal getTotalAmount() {
        BigDecimal total = BigDecimal.ZERO;
        for (ReceiptItem item : toReceiptItems()) {
            if (item.getImportPrice() != null && item.getQuantity() != null && item.getQuantity() > 0) {
                total = total.add(item.getImportPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
            }
        }
        return total;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ReceiptItem {
        private Long variantId;
        private Integer quantity;
        private BigDecimal importPrice;
    }
}
