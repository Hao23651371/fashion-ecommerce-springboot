package com.iuh.fashionshop.model;

import com.iuh.fashionshop.model.enums.VariantStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "product_variant",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_variant_sku", columnNames = {"sku"}),
                @UniqueConstraint(name = "uk_variant_product_size_color", columnNames = {"product_id", "size", "color"})
        })
@Getter
@Setter
@NoArgsConstructor
public class ProductVariant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(nullable = false, length = 20)
    private String size;

    @Column(nullable = false, length = 50)
    private String color;

    @Column(unique = true, length = 50)
    private String sku;

    @Column(name = "stock_quantity", nullable = false)
    private int stockQuantity = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VariantStatus status = VariantStatus.ACTIVE;

    @Version
    @Column(nullable = false)
    private int version;

    public boolean isInStock(int quantity) {
        return status == VariantStatus.ACTIVE && stockQuantity >= quantity;
    }

    public void decreaseStock(int quantity) {
        if (quantity <= 0) {
            throw new IllegalArgumentException("Số lượng phải > 0");
        }
        if (stockQuantity < quantity) {
            throw new IllegalStateException("Không đủ hàng trong kho");
        }
        stockQuantity -= quantity;
    }

    public void increaseStock(int quantity) {
        if (quantity <= 0) {
            throw new IllegalArgumentException("Số lượng phải > 0");
        }
        stockQuantity += quantity;
    }
}
