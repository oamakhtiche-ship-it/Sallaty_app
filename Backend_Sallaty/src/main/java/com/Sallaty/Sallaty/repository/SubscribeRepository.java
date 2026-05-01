package com.Sallaty.Sallaty.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.Subscribe;

@Repository
public interface SubscribeRepository
        extends JpaRepository<Subscribe, Integer> {

    List<Subscribe> findByUserId(int userId);

    // ➕ manquant
    List<Subscribe> findByMarchandId(int marchandId);

    boolean existsByUserIdAndMarchandId(
        int userId, int marchandId);

    Optional<Subscribe> findByUserIdAndMarchandId(
        int userId, int marchandId);

    void deleteByUserIdAndMarchandId(
        int userId, int marchandId);

    // ➕ manquant
    int countByMarchandId(int marchandId);
}