package com.iuh.fashionshop.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "product_image")
@Getter
@Setter
@NoArgsConstructor
public class ProductImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(name = "image_url", nullable = false, length = 255)
    private String imageUrl;

    @Column(name = "is_thumbnail", nullable = false)
    private boolean thumbnail = false;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    public ProductImage(Product product, String imageUrl, boolean thumbnail, int displayOrder) {
        this.product = product;
        this.imageUrl = imageUrl;
        this.thumbnail = thumbnail;
        this.displayOrder = displayOrder;
    }
}
