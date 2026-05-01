package com.Sallaty.Sallaty.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.model.OffreFavori;

@Repository
public interface OffreFavoriRepository
        extends JpaRepository<OffreFavori, Integer> {

    // ─────────────────────────────────────────────
    // Toutes les offres favorites d'un user
    // ─────────────────────────────────────────────
    List<OffreFavori> findByUserId(int userId);

    // ─────────────────────────────────────────────
    // Vérifier si déjà en favori
    // ─────────────────────────────────────────────
    Optional<OffreFavori> findByUserIdAndOffreId(
        int userId, int offreId);

    boolean existsByUserIdAndOffreId(
        int userId, int offreId);

    // ─────────────────────────────────────────────
    // Compter favoris d'une offre
    // ─────────────────────────────────────────────
    int countByOffreId(int offreId);

    // ─────────────────────────────────────────────
    // ✅ Supprimer favori — @Modifying + @Transactional obligatoires
    // ─────────────────────────────────────────────
    @Modifying
    @Transactional
    @Query("DELETE FROM OffreFavori f WHERE f.userId = :userId AND f.offreId = :offreId")
    void deleteByUserIdAndOffreId(int userId, int offreId);

    // ─────────────────────────────────────────────
    // ✅ Supprimer tous les favoris d'un user
    // ─────────────────────────────────────────────
    @Modifying
    @Transactional
    @Query("DELETE FROM OffreFavori f WHERE f.userId = :userId")
    void deleteAllByUserId(int userId);
}