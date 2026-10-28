package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, Long> {
}
