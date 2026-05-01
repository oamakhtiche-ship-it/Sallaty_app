package com.Sallaty.Sallaty.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.Category;

@Repository
public interface CategoryRepository
    extends JpaRepository<Category, Integer> {

    // trouver par nom
    Optional<Category> findByName(String name);

    // vérifier si existe
    boolean existsByName(String name);
}