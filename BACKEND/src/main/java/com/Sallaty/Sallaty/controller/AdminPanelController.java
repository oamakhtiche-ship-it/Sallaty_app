package com.Sallaty.Sallaty.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.service.AdminService;

@RestController
@RequestMapping("/api/admin")
public class AdminPanelController {

    @Autowired
    private AdminService adminService;

    // ═══════════════════════════════════════════════
    //  GET /api/admin/dashboard — ADMIN
    // ═══════════════════════════════════════════════
    @GetMapping("/dashboard")
    public ResponseEntity<?> getDashboard() {
        Map<String, Object> response = new HashMap<>();
        response.put("stats",
            adminService.getDashboardStats());
        response.put("topMerchants",
            adminService.getTopMerchants());
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  GET /api/admin/charts — ADMIN
    //  Retourne les 3 graphiques en une seule requête
    // ═══════════════════════════════════════════════
    @GetMapping("/charts")
    public ResponseEntity<?> getCharts() {
        Map<String, Object> response = new HashMap<>();
        response.put("topMerchants",
            adminService.getTopMerchantsChart());
        response.put("revenuePerMonth",
            adminService.getRevenuePerMonth());
        response.put("userDistribution",
            adminService.getUserDistribution());
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  GET /api/admin/charts/top-merchants — ADMIN
    // ═══════════════════════════════════════════════
    @GetMapping("/charts/top-merchants")
    public ResponseEntity<?> getTopMerchantsChart() {
        return ResponseEntity.ok(
            adminService.getTopMerchantsChart());
    }

    // ═══════════════════════════════════════════════
    //  GET /api/admin/charts/revenue — ADMIN
    // ═══════════════════════════════════════════════
    @GetMapping("/charts/revenue")
    public ResponseEntity<?> getRevenuePerMonth() {
        return ResponseEntity.ok(
            adminService.getRevenuePerMonth());
    }

    // ═══════════════════════════════════════════════
    //  GET /api/admin/charts/users — ADMIN
    // ═══════════════════════════════════════════════
    @GetMapping("/charts/users")
    public ResponseEntity<?> getUserDistribution() {
        return ResponseEntity.ok(
            adminService.getUserDistribution());
    }

    // ═══════════════════════════════════════════════
    //  ADMINS
    // ═══════════════════════════════════════════════
    @GetMapping("/admins")
    public ResponseEntity<?> getAllAdmins() {
        return ResponseEntity.ok(
            adminService.getAllAdmins());
    }

    @PostMapping("/admins/create")
public ResponseEntity<?> createAdmin(
        @RequestParam String firstName,
        @RequestParam String lastName,
        @RequestParam String email,
        @RequestParam String password,
        @RequestParam String role,
        @RequestParam(required = false, defaultValue = "")
            String permissions) {
    try {
        return ResponseEntity.ok(
            adminService.createAdmin(
                firstName, lastName, email,
                password, role, permissions));
    } catch (RuntimeException e) {
        // ✅ Retourne le vrai message d'erreur
        return ResponseEntity
            .badRequest()
            .body(Map.of("message", e.getMessage()));
    }
}

    @DeleteMapping("/admins/{id}")
    public ResponseEntity<?> deleteAdmin(
            @PathVariable int id) {

        adminService.deleteAdmin(id);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Admin supprimé ✅");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  USERS
    // ═══════════════════════════════════════════════
    @GetMapping("/users")
    public ResponseEntity<?> getUsers(
            @RequestParam(required = false) String filter) {
        return ResponseEntity.ok(
            adminService.getUserManagement(filter));
    }

    @GetMapping("/users/{id}")
    public ResponseEntity<?> getUserProfile(
            @PathVariable int id) {
        return ResponseEntity.ok(
            adminService.getUserProfile(id));
    }

    @GetMapping("/users/{id}/orders")
    public ResponseEntity<?> getUserOrders(
            @PathVariable int id) {
        return ResponseEntity.ok(
            adminService.getUserOrders(id));
    }

    // ═══════════════════════════════════════════════
    //  MERCHANTS
    // ═══════════════════════════════════════════════
    @GetMapping("/merchants")
    public ResponseEntity<?> getMerchants(
            @RequestParam(required = false) String filter) {
        return ResponseEntity.ok(
            adminService.getMerchantManagement(filter));
    }

    @GetMapping("/merchants/{id}")
    public ResponseEntity<?> getMerchantProfile(
            @PathVariable int id) {
        return ResponseEntity.ok(
            adminService.getMerchantProfile(id));
    }

    @GetMapping("/merchants/{id}/orders")
    public ResponseEntity<?> getMerchantOrders(
            @PathVariable int id) {
        return ResponseEntity.ok(
            adminService.getMerchantOrders(id));
    }

    @GetMapping("/merchants/{id}/offers")
    public ResponseEntity<?> getMerchantOffers(
            @PathVariable int id) {
        return ResponseEntity.ok(
            adminService.getMerchantOffers(id));
    }

    // ═══════════════════════════════════════════════
    //  OFFERS
    // ═══════════════════════════════════════════════
    @GetMapping("/offers")
    public ResponseEntity<?> getOffers(
            @RequestParam(required = false) String filter) {
        return ResponseEntity.ok(
            adminService.getOfferManagement(filter));
    }

    // ═══════════════════════════════════════════════
    //  RESERVATIONS
    // ═══════════════════════════════════════════════
    @GetMapping("/reservations")
    public ResponseEntity<?> getReservations(
            @RequestParam(required = false) String filter) {
        return ResponseEntity.ok(
            adminService.getReservationManagement(filter));
    }
}