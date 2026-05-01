package com.Sallaty.Sallaty.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.Sallaty.Sallaty.model.Category;
import com.Sallaty.Sallaty.service.CategoryService;

@RestController
@RequestMapping("/api/categories")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    // ═══════════════════════════════════════════════
    //  GET /api/categories — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping
    public ResponseEntity<?> getAllCategories() {
        return ResponseEntity.ok(
            categoryService.getAllCategories());
    }

    // ═══════════════════════════════════════════════
    //  GET /api/categories/{id} — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/{id}")
    public ResponseEntity<?> getCategoryById(
            @PathVariable int id) {
        return ResponseEntity.ok(
            categoryService.getCategoryById(id));
    }

    // ═══════════════════════════════════════════════
    //  POST /api/categories/create — ADMIN
    // ═══════════════════════════════════════════════
    @PostMapping("/create")
    public ResponseEntity<?> createCategory(
            @RequestParam String name,
            @RequestParam String icon,
            @RequestParam(required = false) String description) {

        categoryService.createCategory(name, icon, description);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Category created successfully");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  DELETE /api/categories/delete/{id} — ADMIN
    // ═══════════════════════════════════════════════
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<?> deleteCategory(
            @PathVariable int id) {

        categoryService.deleteCategory(id);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Category deleted successfully");
        return ResponseEntity.ok(response);
    }
}