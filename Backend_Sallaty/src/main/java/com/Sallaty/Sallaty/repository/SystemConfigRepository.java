package com.Sallaty.Sallaty.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.SystemConfig;

@Repository
public interface SystemConfigRepository
        extends JpaRepository<SystemConfig, Integer> {
    // ID = 1 toujours → findById(1) suffit ✅
}