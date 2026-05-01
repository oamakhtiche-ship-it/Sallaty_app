package com.Sallaty.Sallaty.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.Sallaty.Sallaty.model.Category;
import com.Sallaty.Sallaty.repository.CategoryRepository;

@Service
public class CategoryService {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private CategoryRepository categoryRepository;

    // ═══════════════════════════════════════════════
    //  getAllCategories()
    // ═══════════════════════════════════════════════
    public List<Category> getAllCategories() {
        return categoryRepository.findAll();
    }

    // ═══════════════════════════════════════════════
    //  getCategoryById()
    // ═══════════════════════════════════════════════
    public Category getCategoryById(int id) {
        return categoryRepository.findById(id)
            .orElseThrow(() ->
                new RuntimeException(
                    "Category non trouvée !"));
    }

    // ═══════════════════════════════════════════════
    //  createCategory()  — ADMIN
    // ═══════════════════════════════════════════════
    public void createCategory(
            String name,
            String icon,
            String description) {

        // 1. Vérifier nom obligatoire
        if (name == null || name.isEmpty())
            throw new IllegalArgumentException(
                "Nom obligatoire !");

        // 2. Vérifier icône obligatoire
        if (icon == null || icon.isEmpty())
            throw new IllegalArgumentException(
                "Icône obligatoire !");

        // 3. Vérifier si existe déjà
        if (categoryRepository.existsByName(name))
            throw new RuntimeException(
                "Category déjà existante !");

        // 4. Créer la category
        Category category = new Category();
        category.setName(name);
        category.setIcon(icon);
        category.setDescription(description);

        categoryRepository.save(category);
    }

    // ═══════════════════════════════════════════════
    //  deleteCategory()  — ADMIN
    // ═══════════════════════════════════════════════
    public void deleteCategory(int id) {

        if (!categoryRepository.existsById(id))
            throw new RuntimeException(
                "Category non trouvée !");

        categoryRepository.deleteById(id);
    }
}
