package com.Sallaty.Sallaty.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.FaqItem;

@Repository
public interface FaqItemRepository
        extends JpaRepository<FaqItem, Integer> {

    List<FaqItem> findByCategoryOrderByDisplayOrderAsc(String category);

    boolean existsByCategoryAndQuestion(String category, String question);
}