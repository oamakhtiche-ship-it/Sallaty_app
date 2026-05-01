package com.Sallaty.Sallaty.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.StaticContent;

@Repository
public interface StaticContentRepository
        extends JpaRepository<StaticContent, Integer> {

    Optional<StaticContent> findByType(String type);

    boolean existsByType(String type);
}