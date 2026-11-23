package com.iuh.fashionshop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Data Transfer Object (DTO) cho chức năng kiểm kê kho hàng loạt.
 */
@Data
@AllArgsConstructor
@Builder
@NoArgsConstructor
public class AuditForm {
    private String auditCode;
    private String reason;
    private String performedBy;
    private LocalDateTime createdAt;
    private int totalDiff;
    private int changedItemCount;

    @Builder.Default
    private List<Long> variantId = new ArrayList<>();

    @Builder.Default
    private List<Integer> actualStock = new ArrayList<>();

    @Builder.Default
    private List<String> itemReason = new ArrayList<>();

    @Builder.Default
    private List<AuditItem> items = new ArrayList<>();

    public List<Long> getVariantIds() {
        return variantId;
    }

    public void setVariantIds(List<Long> variantIds) {
        this.variantId = variantIds;
    }

    public List<Integer> getActualStocks() {
        return actualStock;
    }

    public void setActualStocks(List<Integer> actualStocks) {
        this.actualStock = actualStocks;
    }

    /**
     * Chuyển đổi dữ liệu từ danh sách items hoặc các tham số song song (variantId, actualStock, itemReason)
     * thành danh sách các dòng kiểm kê.
     */
    public List<AuditItem> toAuditItems() {
        if (items != null && !items.isEmpty()) {
            List<AuditItem> nonEmpty = new ArrayList<>();
            for (AuditItem item : items) {
                if (item != null && (item.getVariantId() != null || item.getActualStock() != null)) {
                    nonEmpty.add(item);
                }
            }
            if (!nonEmpty.isEmpty()) {
                return nonEmpty;
            }
        }
        List<AuditItem> list = new ArrayList<>();
        if (variantId != null) {
            for (int i = 0; i < variantId.size(); i++) {
                Long vId = variantId.get(i);
                if (vId == null) {
                    continue;
                }
                Integer actual = (actualStock != null && actualStock.size() > i)
                        ? actualStock.get(i) : null;
                String rowReason = (itemReason != null && itemReason.size() > i)
                        ? itemReason.get(i) : null;
                list.add(new AuditItem(vId, actual, rowReason));
            }
        }
        return list;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class AuditItem {
        private Long variantId;
        private Integer actualStock;
        private String reason;
    }
}
