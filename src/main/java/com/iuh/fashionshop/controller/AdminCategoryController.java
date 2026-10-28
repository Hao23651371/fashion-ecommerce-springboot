package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/admin/categories")
public class AdminCategoryController {

    private final CategoryRepository categoryRepository;
    public AdminCategoryController(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    @GetMapping
    public String list(@org.springframework.web.bind.annotation.RequestParam(defaultValue = "0") int page,
                       @org.springframework.web.bind.annotation.RequestParam(defaultValue = "10") int size,
                       Model model) {
        Page<Category> categories = categoryRepository.findAll(PageRequest.of(Math.max(0, page), Math.min(size, 50)));
        model.addAttribute("pageTitle", "Danh mục");
        model.addAttribute("categories", categories);
        model.addAttribute("categoryCount", categoryRepository.count());
        model.addAttribute("visibleCategoryCount", categoryRepository.findAll().stream()
                .filter(category -> category.getStatus() == CategoryStatus.VISIBLE).count());
        return "admin/categories";
    }
}
