package com.Sallaty.Sallaty.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.OrderLocation;

@Repository
public interface OrderLocationRepository
        extends JpaRepository<OrderLocation, Integer> {

    // ─────────────────────────────────────────────
    // Historique locations d'un ordre
    // trié par timestamp DESC
    // ─────────────────────────────────────────────
    List<OrderLocation> findByOrdreIdOrderByTimestampDesc(
        int ordreId);
}