package com.Sallaty.Sallaty.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.Sallaty.Sallaty.model.SystemConfig;
import com.Sallaty.Sallaty.repository.SystemConfigRepository;

@Service
public class SystemConfigService {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private SystemConfigRepository systemConfigRepository;

    // ═══════════════════════════════════════════════
    //  getConfig()
    //  récupérer config — crée par défaut si vide
    // ═══════════════════════════════════════════════
    public SystemConfig getConfig() {
        return systemConfigRepository
            .findById(1)
            .orElseGet(() -> {
                SystemConfig config = new SystemConfig();
                return systemConfigRepository.save(config);
            });
    }

    // ═══════════════════════════════════════════════
    //  UPDATE — Admin seulement
    // ═══════════════════════════════════════════════
    public SystemConfig updateCommissionRate(
            double rate) {

        if (rate < 0 || rate > 1)
            throw new RuntimeException(
                "Commission must be between 0 and 1!");

        SystemConfig config = getConfig();
        config.setCommissionRate(rate);
        return systemConfigRepository.save(config);
    }

    public SystemConfig updateTransportCost(
            double cost) {

        if (cost < 0)
            throw new RuntimeException(
                "Transportation cost invalid !");

        SystemConfig config = getConfig();
        config.setTransportCost(cost);
        return systemConfigRepository.save(config);
    }

    public SystemConfig updateMinTopUp(
            double minTopUp) {

        if (minTopUp < 0)
            throw new RuntimeException(
                "Min top up invalid !");

        SystemConfig config = getConfig();
        config.setMinTopUp(minTopUp);
        return systemConfigRepository.save(config);
    }

    public SystemConfig updateHoursBeforeExpiry(
            int hours) {

        if (hours < 1)
            throw new RuntimeException(
                "Invalid Hours !");

        SystemConfig config = getConfig();
        config.setHoursBeforeExpiry(hours);
        return systemConfigRepository.save(config);
    }

    public SystemConfig updateCancelDeadline(
            int hours) {

        if (hours < 0)
            throw new RuntimeException(
                "Ancel deadline invalid\r\n" + //
                                        "!");

        SystemConfig config = getConfig();
        config.setCancelDeadline(hours);
        return systemConfigRepository.save(config);
    }

    // ═══════════════════════════════════════════════
    //  GETTERS — appelés par d'autres Services
    // ═══════════════════════════════════════════════
    public double getCommissionRate() {
        return getConfig().getCommissionRate();
    }

    public double getTransportCost() {
        return getConfig().getTransportCost();
    }

    public double getMinTopUp() {
        return getConfig().getMinTopUp();
    }

    public int getHoursBeforeExpiry() {
        return getConfig().getHoursBeforeExpiry();
    }

    public int getCancelDeadline() {
        return getConfig().getCancelDeadline();
    }
}