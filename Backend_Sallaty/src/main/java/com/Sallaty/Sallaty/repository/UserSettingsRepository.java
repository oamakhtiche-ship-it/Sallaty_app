package com.Sallaty.Sallaty.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.UserSettings;

@Repository
public interface UserSettingsRepository
        extends JpaRepository<UserSettings, Integer> {

    // ─────────────────────────────────────────────
    // Récupérer settings par userId
    // ─────────────────────────────────────────────
    Optional<UserSettings> findByUserId(int userId);

    // ─────────────────────────────────────────────
    // Vérifier si settings existent
    // ─────────────────────────────────────────────
    boolean existsByUserId(int userId);

    // ─────────────────────────────────────────────
    // Supprimer settings par userId
    // ─────────────────────────────────────────────
    void deleteByUserId(int userId);
}