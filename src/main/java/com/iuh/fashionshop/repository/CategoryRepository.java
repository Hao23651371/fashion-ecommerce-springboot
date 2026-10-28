package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    Page<Category> findByNameContainingIgnoreCase(String name, Pageable pageable);
    Page<Category> findByStatus(CategoryStatus status, Pageable pageable);
    Page<Category> findByNameContainingIgnoreCaseAndStatus(String name, CategoryStatus status, Pageable pageable);
    boolean existsByNameIgnoreCase(String name);
    boolean existsByNameIgnoreCaseAndIdNot(String name, Long id);
}
