package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    List<Category> findByStatusOrderByNameAsc(CategoryStatus status);
}
