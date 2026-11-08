package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Category;
import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.enums.CategoryStatus;
import com.iuh.fashionshop.model.enums.Gender;
import com.iuh.fashionshop.model.enums.ProductStatus;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.CategoryRepository;
import com.iuh.fashionshop.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@Transactional
class AdminProductControllerTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testShowCreateProductForm() throws Exception {
        mockMvc.perform(get("/admin/products/new"))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/product-form"))
                .andExpect(model().attributeExists("categories"))
                .andExpect(model().attributeExists("sizes"))
                .andExpect(model().attributeExists("colors"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testCreateProductWithoutSalePrice_DefaultsToOriginalPrice() throws Exception {
        Category category = new Category();
        category.setName("Áo sơ mi test");
        category.setStatus(CategoryStatus.VISIBLE);
        category = categoryRepository.save(category);

        mockMvc.perform(post("/admin/products/new")
                        .with(csrf())
                        .param("name", "Áo sơ mi lụa tơ tằm Test")
                        .param("categoryId", category.getId().toString())
                        .param("gender", "FEMALE")
                        .param("price", "350000")
                        .param("description", "Mô tả chất liệu cao cấp")
                        .param("imageUrl", "https://example.com/test.jpg")
                        .param("sizes", "S", "M")
                        .param("colors", "Đen", "Trắng"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/products"));

        List<Product> products = productRepository.findAll();
        Product created = products.stream()
                .filter(p -> "Áo sơ mi lụa tơ tằm Test".equals(p.getName()))
                .findFirst()
                .orElse(null);

        assertNotNull(created);
        assertEquals(0, new BigDecimal("350000").compareTo(created.getPrice()));
        // Sale price defaults to price when empty
        assertNotNull(created.getSalePrice());
        assertEquals(0, created.getPrice().compareTo(created.getSalePrice()));
        assertEquals(4, created.getVariants().size()); // 2 sizes * 2 colors = 4 variants
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testToggleProductStatus() throws Exception {
        Category category = new Category();
        category.setName("Danh mục toggle test");
        category.setStatus(CategoryStatus.VISIBLE);
        category = categoryRepository.save(category);

        Product product = new Product();
        product.setName("Sản phẩm toggle test");
        product.setCategory(category);
        product.setPrice(BigDecimal.valueOf(200000));
        product.setStatus(ProductStatus.ACTIVE);
        product = productRepository.save(product);

        // Toggle to INACTIVE
        mockMvc.perform(post("/admin/products/" + product.getId() + "/toggle-status").with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/products"));

        Product updated = productRepository.findById(product.getId()).orElseThrow();
        assertEquals(ProductStatus.INACTIVE, updated.getStatus());

        // Toggle back to ACTIVE
        mockMvc.perform(post("/admin/products/" + product.getId() + "/toggle-status").with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/products"));

        updated = productRepository.findById(product.getId()).orElseThrow();
        assertEquals(ProductStatus.ACTIVE, updated.getStatus());
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testShowEditProductForm() throws Exception {
        Category category = new Category();
        category.setName("Danh mục edit form test");
        category.setStatus(CategoryStatus.VISIBLE);
        category = categoryRepository.save(category);

        Product product = new Product();
        product.setName("Sản phẩm edit form");
        product.setCategory(category);
        product.setPrice(BigDecimal.valueOf(150000));
        product.setDescription("Mô tả cũ");
        product.setImageUrl("https://example.com/old.jpg");
        product.setStatus(ProductStatus.ACTIVE);

        ProductVariant variant = new ProductVariant();
        variant.setProduct(product);
        variant.setSize("M");
        variant.setColor("Đen");
        variant.setSku("PRD-99999-001");
        variant.setStatus(VariantStatus.ACTIVE);
        product.getVariants().add(variant);

        product = productRepository.save(product);

        mockMvc.perform(get("/admin/products/edit/" + product.getId()))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/product-form"))
                .andExpect(model().attribute("isEdit", true))
                .andExpect(model().attributeExists("product"))
                .andExpect(model().attributeExists("sizes"))
                .andExpect(model().attributeExists("colors"))
                .andExpect(model().attributeExists("selectedSizes"))
                .andExpect(model().attributeExists("selectedColors"));
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testUpdateProduct() throws Exception {
        Category category = new Category();
        category.setName("Danh mục update test");
        category.setStatus(CategoryStatus.VISIBLE);
        category = categoryRepository.save(category);

        Product product = new Product();
        product.setName("Sản phẩm trước update");
        product.setCategory(category);
        product.setPrice(BigDecimal.valueOf(150000));
        product.setDescription("Mô tả trước");
        product.setImageUrl("https://example.com/before.jpg");
        product.setStatus(ProductStatus.ACTIVE);

        ProductVariant variant = new ProductVariant();
        variant.setProduct(product);
        variant.setSize("S");
        variant.setColor("Đen");
        variant.setSku("PRD-88888-001");
        variant.setStatus(VariantStatus.ACTIVE);
        product.getVariants().add(variant);

        product = productRepository.save(product);

        mockMvc.perform(post("/admin/products/edit/" + product.getId())
                        .with(csrf())
                        .param("name", "Sản phẩm sau update")
                        .param("categoryId", category.getId().toString())
                        .param("gender", "MALE")
                        .param("price", "250000")
                        .param("salePrice", "200000")
                        .param("description", "Mô tả mới đã cập nhật")
                        .param("imageUrl", "https://example.com/after.jpg")
                        .param("sizes", "M", "L")
                        .param("colors", "Trắng"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/products"));

        Product updated = productRepository.findByIdWithDetails(product.getId()).orElseThrow();
        assertEquals("Sản phẩm sau update", updated.getName());
        assertEquals(Gender.MALE, updated.getGender());
        assertEquals(0, new BigDecimal("250000").compareTo(updated.getPrice()));
        assertEquals(0, new BigDecimal("200000").compareTo(updated.getSalePrice()));
        assertEquals("https://example.com/after.jpg", updated.getImageUrl());
        assertEquals("Mô tả mới đã cập nhật", updated.getDescription());

        // Check variants: old S/Đen should be INACTIVE, new M/Trắng and L/Trắng should be ACTIVE
        List<ProductVariant> activeVariants = updated.getVariants().stream()
                .filter(v -> v.getStatus() == VariantStatus.ACTIVE)
                .toList();
        assertEquals(2, activeVariants.size());
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testDeleteProduct() throws Exception {
        Category category = new Category();
        category.setName("Danh mục delete test");
        category.setStatus(CategoryStatus.VISIBLE);
        category = categoryRepository.save(category);

        Product product = new Product();
        product.setName("Sản phẩm sẽ bị xóa");
        product.setCategory(category);
        product.setPrice(BigDecimal.valueOf(100000));
        product.setStatus(ProductStatus.ACTIVE);
        product = productRepository.save(product);
        Long productId = product.getId();

        mockMvc.perform(post("/admin/products/delete/" + productId).with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/products"));

        assertFalse(productRepository.findById(productId).isPresent());
    }

    @Test
    @WithMockUser(username = "admin1@fashionshop.vn", roles = {"ADMIN"})
    void testHideCategory_AutomaticallyHidesAssociatedProducts() throws Exception {
        Category category = new Category();
        category.setName("Danh mục ẩn tự động");
        category.setStatus(CategoryStatus.VISIBLE);
        category = categoryRepository.save(category);

        Product product1 = new Product();
        product1.setName("Sản phẩm liên kết 1");
        product1.setCategory(category);
        product1.setPrice(BigDecimal.valueOf(100000));
        product1.setStatus(ProductStatus.ACTIVE);
        product1 = productRepository.save(product1);

        Product product2 = new Product();
        product2.setName("Sản phẩm liên kết 2");
        product2.setCategory(category);
        product2.setPrice(BigDecimal.valueOf(200000));
        product2.setStatus(ProductStatus.ACTIVE);
        product2 = productRepository.save(product2);

        // Hide category
        mockMvc.perform(post("/admin/categories/hide/" + category.getId()).with(csrf()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/categories"));

        Category updatedCategory = categoryRepository.findById(category.getId()).orElseThrow();
        assertEquals(CategoryStatus.HIDDEN, updatedCategory.getStatus());

        Product updatedP1 = productRepository.findById(product1.getId()).orElseThrow();
        Product updatedP2 = productRepository.findById(product2.getId()).orElseThrow();
        assertEquals(ProductStatus.INACTIVE, updatedP1.getStatus());
        assertEquals(ProductStatus.INACTIVE, updatedP2.getStatus());
    }
}
