package com.Sallaty.Sallaty.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.Sallaty.Sallaty.model.SystemConfig;
import com.Sallaty.Sallaty.service.SystemConfigService;

@RestController
@RequestMapping("/api/config")
public class SystemConfigController {

    @Autowired
    private SystemConfigService systemConfigService;

    // ─────────────────────────────────────────────
    // GET /api/config
    // Admin → voir tous les paramètres
    // ─────────────────────────────────────────────
    @GetMapping
    public ResponseEntity<SystemConfig>
            getConfig() {
        return ResponseEntity.ok(
            systemConfigService.getConfig());
    }

    // ─────────────────────────────────────────────
    // PUT /api/config/commission/{rate}
    // Admin → modifier commission
    // ─────────────────────────────────────────────
    @PutMapping("/commission/{rate}")
    public ResponseEntity<SystemConfig>
            updateCommission(
                @PathVariable double rate) {
        return ResponseEntity.ok(
            systemConfigService
                .updateCommissionRate(rate));
    }

    // ─────────────────────────────────────────────
    // PUT /api/config/transport/{cost}
    // Admin → modifier transport
    // ─────────────────────────────────────────────
    @PutMapping("/transport/{cost}")
    public ResponseEntity<SystemConfig>
            updateTransport(
                @PathVariable double cost) {
        return ResponseEntity.ok(
            systemConfigService
                .updateTransportCost(cost));
    }

    // ─────────────────────────────────────────────
    // PUT /api/config/mintopup/{amount}
    // Admin → modifier min recharge
    // ─────────────────────────────────────────────
    @PutMapping("/mintopup/{amount}")
    public ResponseEntity<SystemConfig>
            updateMinTopUp(
                @PathVariable double amount) {
        return ResponseEntity.ok(
            systemConfigService
                .updateMinTopUp(amount));
    }

    // ─────────────────────────────────────────────
    // PUT /api/config/expiry/{hours}
    // Admin → modifier heures avant expiration
    // ─────────────────────────────────────────────
    @PutMapping("/expiry/{hours}")
    public ResponseEntity<SystemConfig>
            updateExpiry(
                @PathVariable int hours) {
        return ResponseEntity.ok(
            systemConfigService
                .updateHoursBeforeExpiry(hours));
    }

    // ─────────────────────────────────────────────
    // PUT /api/config/cancel/{hours}
    // Admin → modifier délai annulation
    // ─────────────────────────────────────────────
    @PutMapping("/cancel/{hours}")
    public ResponseEntity<SystemConfig>
            updateCancel(
                @PathVariable int hours) {
        return ResponseEntity.ok(
            systemConfigService
                .updateCancelDeadline(hours));
    }
}