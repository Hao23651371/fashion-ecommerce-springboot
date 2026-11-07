package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.model.enums.ProductStatus;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.repository.ProductRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequestMapping("/admin/categories")
public class AdminCategoryController {

    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;

    public AdminCategoryController(CategoryRepository categoryRepository, ProductRepository productRepository) {
        this.categoryRepository = categoryRepository;
        this.productRepository = productRepository;
    }

    @GetMapping
    public String list(@RequestParam(defaultValue = "0") int page,
                       @RequestParam(defaultValue = "10") int size,
                       @RequestParam(required = false) String keyword,
                       @RequestParam(required = false) CategoryStatus status,
                       Model model) {

        int validPage = Math.max(0, page);
        int validSize = Math.min(Math.max(1, size), 50);
        Pageable pageable = PageRequest.of(validPage, validSize, Sort.by(Sort.Direction.DESC, "id"));

        Page<Category> categories;
        boolean hasKeyword = keyword != null && !keyword.trim().isBlank();
        String trimmedKw = hasKeyword ? keyword.trim() : null;

        if (hasKeyword && status != null) {
            categories = categoryRepository.findByNameContainingIgnoreCaseAndStatus(trimmedKw, status, pageable);
        } else if (hasKeyword) {
            categories = categoryRepository.findByNameContainingIgnoreCase(trimmedKw, pageable);
        } else if (status != null) {
            categories = categoryRepository.findByStatus(status, pageable);
        } else {
            categories = categoryRepository.findAll(pageable);
        }

        List<Category> allCategories = categoryRepository.findAll();
        long totalCategories = allCategories.size();
        long visibleCount = allCategories.stream()
                .filter(c -> c.getStatus() == CategoryStatus.VISIBLE)
                .count();
        long hiddenCount = totalCategories - visibleCount;
        long totalCategorizedProducts = allCategories.stream()
                .mapToLong(c -> c.getProducts() != null ? c.getProducts().size() : 0)
                .sum();

        model.addAttribute("pageTitle", "Quản lý danh mục");
        model.addAttribute("categories", categories);
        model.addAttribute("keyword", trimmedKw != null ? trimmedKw : "");
        model.addAttribute("selectedStatus", status);
        model.addAttribute("categoryCount", totalCategories);
        model.addAttribute("visibleCategoryCount", visibleCount);
        model.addAttribute("hiddenCategoryCount", hiddenCount);
        model.addAttribute("totalCategorizedProducts", totalCategorizedProducts);
        model.addAttribute("allStatuses", CategoryStatus.values());

        return "admin/categories";
    }

    @PostMapping("/create")
    public String create(@RequestParam String name,
                         @RequestParam(defaultValue = "VISIBLE") CategoryStatus status,
                         RedirectAttributes redirect) {
        if (name == null || name.trim().isBlank()) {
            redirect.addFlashAttribute("errorMessage", "Tên danh mục không được để trống.");
            return "redirect:/admin/categories";
        }

        String cleanName = name.trim();
        if (categoryRepository.existsByNameIgnoreCase(cleanName)) {
            redirect.addFlashAttribute("errorMessage", "Danh mục '" + cleanName + "' đã tồn tại.");
            return "redirect:/admin/categories";
        }

        Category category = new Category();
        category.setName(cleanName);
        category.setStatus(status != null ? status : CategoryStatus.VISIBLE);
        categoryRepository.save(category);

        redirect.addFlashAttribute("successMessage", "Thêm danh mục '" + cleanName + "' thành công!");
        return "redirect:/admin/categories";
    }

    @PostMapping("/edit/{id}")
    @Transactional
    public String edit(@PathVariable Long id,
                       @RequestParam String name,
                       @RequestParam CategoryStatus status,
                       RedirectAttributes redirect) {
        Category category = categoryRepository.findById(id).orElse(null);
        if (category == null) {
            redirect.addFlashAttribute("errorMessage", "Không tìm thấy danh mục để cập nhật.");
            return "redirect:/admin/categories";
        }

        if (name == null || name.trim().isBlank()) {
            redirect.addFlashAttribute("errorMessage", "Tên danh mục không được để trống.");
            return "redirect:/admin/categories";
        }

        String cleanName = name.trim();
        if (categoryRepository.existsByNameIgnoreCaseAndIdNot(cleanName, id)) {
            redirect.addFlashAttribute("errorMessage", "Danh mục '" + cleanName + "' đã tồn tại.");
            return "redirect:/admin/categories";
        }

        CategoryStatus oldStatus = category.getStatus();
        category.setName(cleanName);
        category.setStatus(status != null ? status : CategoryStatus.VISIBLE);
        categoryRepository.save(category);

        int hiddenProductCount = 0;
        if (oldStatus == CategoryStatus.VISIBLE && category.getStatus() == CategoryStatus.HIDDEN) {
            List<Product> products = productRepository.findByCategoryId(id);
            if (products != null && !products.isEmpty()) {
                for (Product p : products) {
                    p.setStatus(ProductStatus.INACTIVE);
                    hiddenProductCount++;
                }
                productRepository.saveAll(products);
            }
        }

        if (hiddenProductCount > 0) {
            redirect.addFlashAttribute("successMessage",
                    "Cập nhật danh mục #" + id + " thành công và đã tự động ẩn " + hiddenProductCount + " sản phẩm đi kèm!");
        } else {
            redirect.addFlashAttribute("successMessage", "Cập nhật danh mục #" + id + " thành công!");
        }
        return "redirect:/admin/categories";
    }

    @PostMapping("/hide/{id}")
    @Transactional
    public String hide(@PathVariable Long id, RedirectAttributes redirect) {
        Category category = categoryRepository.findById(id).orElse(null);
        if (category == null) {
            redirect.addFlashAttribute("errorMessage", "Không tìm thấy danh mục để ẩn.");
            return "redirect:/admin/categories";
        }

        category.setStatus(CategoryStatus.HIDDEN);
        categoryRepository.save(category);

        List<Product> products = productRepository.findByCategoryId(id);
        int hiddenProductCount = 0;
        if (products != null && !products.isEmpty()) {
            for (Product p : products) {
                p.setStatus(ProductStatus.INACTIVE);
                hiddenProductCount++;
            }
            productRepository.saveAll(products);
        }

        redirect.addFlashAttribute("successMessage",
                "Đã ẩn danh mục '" + category.getName() + "' và tự động ẩn " + hiddenProductCount + " sản phẩm đi kèm thành công!");
        return "redirect:/admin/categories";
    }

    @PostMapping("/show/{id}")
    @Transactional
    public String show(@PathVariable Long id, RedirectAttributes redirect) {
        Category category = categoryRepository.findById(id).orElse(null);
        if (category == null) {
            redirect.addFlashAttribute("errorMessage", "Không tìm thấy danh mục để hiển thị.");
            return "redirect:/admin/categories";
        }

        category.setStatus(CategoryStatus.VISIBLE);
        categoryRepository.save(category);

        redirect.addFlashAttribute("successMessage",
                "Đã hiển thị lại danh mục '" + category.getName() + "' thành công!");
        return "redirect:/admin/categories";
    }

    @PostMapping("/delete/{id}")
    @Transactional
    public String delete(@PathVariable Long id, RedirectAttributes redirect) {
        Category category = categoryRepository.findById(id).orElse(null);
        if (category == null) {
            redirect.addFlashAttribute("errorMessage", "Không tìm thấy danh mục cần xóa.");
            return "redirect:/admin/categories";
        }

        if (category.getProducts() != null && !category.getProducts().isEmpty()) {
            redirect.addFlashAttribute("errorMessage",
                    "Không thể xóa danh mục '" + category.getName() + "' vì đang có "
                            + category.getProducts().size() + " sản phẩm liên kết. Vui lòng chuyển hoặc xóa sản phẩm trước.");
            return "redirect:/admin/categories";
        }

        String name = category.getName();
        categoryRepository.delete(category);
        redirect.addFlashAttribute("successMessage", "Đã xóa danh mục '" + name + "' thành công!");
        return "redirect:/admin/categories";
    }
}
