package com.iuh.fashionshop.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Cấu hình mục tiêu kinh doanh và thông số hiển thị bảng điều khiển (Dashboard).
 * Được lưu trữ và thao tác trực tiếp trên Database.
 */
@Entity
@Table(name = "dashboard_setting")
@Getter
@Setter
@NoArgsConstructor
public class DashboardSetting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "monthly_target", nullable = false, precision = 15, scale = 2)
    private BigDecimal monthlyTarget = new BigDecimal("1800000000"); // Mặc định 1.8 tỷ VNĐ

    @Column(name = "highlight_note", length = 255)
    private String highlightNote = "Đạt đỉnh doanh thu vào T10 dịp Fashion Week Thu Đông";

    @Column(name = "target_month", nullable = false)
    private Integer targetMonth = 10;

    @Column(name = "target_year", nullable = false)
    private Integer targetYear = 2024;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PrePersist
    @PreUpdate
    void onSave() {
        this.updatedAt = LocalDateTime.now();
    }
}
