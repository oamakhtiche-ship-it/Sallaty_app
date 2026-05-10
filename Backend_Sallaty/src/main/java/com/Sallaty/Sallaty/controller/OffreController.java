package com.Sallaty.Sallaty.controller;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.Sallaty.Sallaty.model.CategoryType;
import com.Sallaty.Sallaty.model.Offre;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.OffreService;

@RestController
@RequestMapping("/api/offres")
public class OffreController {

    @Autowired
    private OffreService offreService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  POST /api/offres/create — MARCHAND
    //  ✅ foodtype String → CategoryType.valueOf()
    // ═══════════════════════════════════════════════
    @PostMapping("/create")
    public ResponseEntity<?> createOffre(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String foodtype,
            @RequestParam String title,
            @RequestParam(required = false) String description,
            @RequestParam double price,
            @RequestParam int quantity,
            @RequestParam String wilaya,
            @RequestParam(required = false) LocalDateTime expireAt,
            @RequestParam(required = false) String status) {

        int marchandId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        // ✅ String → CategoryType
        CategoryType categoryType =
            CategoryType.valueOf(foodtype.toUpperCase());

        Offre offre = offreService.createOffre(
            marchandId, categoryType, title,
            description, price, quantity,
            wilaya, expireAt, status);

        return ResponseEntity.ok(
            offreService.convertToDTO(offre));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/offres/update/{offreId} — MARCHAND
    //  ✅ foodtype String → CategoryType.valueOf()
    // ═══════════════════════════════════════════════
    @PutMapping("/update/{offreId}")
    public ResponseEntity<?> updateOffre(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable int offreId,
            @RequestParam(required = false) String foodtype,
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String description,
            @RequestParam(required = false, defaultValue = "0") double price,
            @RequestParam(required = false, defaultValue = "0") int quantity,
            @RequestParam(required = false) String wilaya,
            @RequestParam(required = false) LocalDateTime expireAt,
            @RequestParam(required = false) String status) {

        int marchandId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        // ✅ String → CategoryType (null si pas fourni)
        CategoryType categoryType = null;
        if (foodtype != null && !foodtype.isEmpty())
            categoryType = CategoryType.valueOf(
                foodtype.toUpperCase());

        Offre offre = offreService.updateOffre(
            offreId, marchandId, categoryType,
            title, description, price,
            quantity, wilaya, expireAt, status);

        return ResponseEntity.ok(
            offreService.convertToDTO(offre));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/offres/archive/{offreId} — MARCHAND
    // ═══════════════════════════════════════════════
    @PutMapping("/archive/{offreId}")
    public ResponseEntity<?> archiveOffre(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable int offreId) {

        int marchandId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        offreService.archiveOffre(offreId, marchandId);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Archived offer ✅"));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/offres/discount/{offreId} — MARCHAND
    // ═══════════════════════════════════════════════
    @PutMapping("/discount/{offreId}")
    public ResponseEntity<?> discountOffre(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable int offreId,
            @RequestParam double discountPrice) {

        int marchandId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        Offre offre = offreService.discountOffre(
            marchandId, offreId, discountPrice);

        return ResponseEntity.ok(
            offreService.convertToDTO(offre));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/offres/block/{offreId} — ADMIN
    // ═══════════════════════════════════════════════
    @PutMapping("/block/{offreId}")
    public ResponseEntity<?> blockOffre(
            @PathVariable int offreId) {
        offreService.blockOffre(offreId);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Offer blocked ❌"));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/offres/unblock/{offreId} — ADMIN
    // ═══════════════════════════════════════════════
    @PutMapping("/unblock/{offreId}")
    public ResponseEntity<?> unblockOffre(
            @PathVariable int offreId) {
        offreService.unblockOffre(offreId);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Offer unlocked ✅"));
    }

    // ═══════════════════════════════════════════════
    //  DELETE /api/offres/{offreId} — ADMIN
    // ═══════════════════════════════════════════════
    @DeleteMapping("/{offreId}")
    public ResponseEntity<?> deleteOffre(
            @PathVariable int offreId) {
        offreService.deleteOffre(offreId);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Offer removed ✅"));
    }

    // ═══════════════════════════════════════════════
    //  POST /api/offres/photo/{offreId} — MARCHAND
    //  ✅ MultipartFile (pas String imagePath)
    // ═══════════════════════════════════════════════
    @PostMapping("/photo/{offreId}")
    public ResponseEntity<?> uploadOffrePhoto(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable int offreId,
            @RequestParam("file") MultipartFile file) {

        String imagePath = offreService
            .uploadOffrePhoto(offreId, file);

        return ResponseEntity.ok(Map.of(
            "success",   true,
            "imagePath", imagePath));
    }

    // ═══════════════════════════════════════════════
    //  DELETE /api/offres/photo/{offreId} — MARCHAND
    // ═══════════════════════════════════════════════
    @DeleteMapping("/photo/{offreId}")
    public ResponseEntity<?> deleteOffrePhoto(
            @PathVariable int offreId) {
        offreService.deleteOffrePhoto(offreId);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Photo deleted"));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/{offreId} — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/{offreId}")
    public ResponseEntity<?> getOffreById(
            @PathVariable int offreId) {
        return ResponseEntity.ok(
            offreService.convertToDTO(
                offreService.getOffreById(offreId)));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/all — ADMIN
    // ═══════════════════════════════════════════════
    @GetMapping("/all")
    public ResponseEntity<?> getAllOffres() {
        return ResponseEntity.ok(
            offreService.getAllOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/available — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/available")
    public ResponseEntity<?> getActivesAndReserved() {
        return ResponseEntity.ok(
            offreService.getActivesAndReserved().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/marchand/{marchandId} — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/marchand/{marchandId}")
    public ResponseEntity<?> getOffresByMarchand(
            @PathVariable int marchandId) {
        return ResponseEntity.ok(
            offreService.getOffresByMarchand(marchandId)
                .stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/category/{categoryType} — PUBLIC
    //  ✅ String → CategoryType.valueOf()
    // ═══════════════════════════════════════════════
    @GetMapping("/category/{categoryType}")
    public ResponseEntity<?> getOffresByCategory(
            @PathVariable String categoryType) {

        CategoryType type = CategoryType.valueOf(
            categoryType.toUpperCase());

        return ResponseEntity.ok(
            offreService.getOffresByCategory(type)
                .stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/wilaya/{wilaya} — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/wilaya/{wilaya}")
    public ResponseEntity<?> getOffresByWilaya(
            @PathVariable String wilaya) {
        return ResponseEntity.ok(
            offreService.getOffresByWilaya(wilaya)
                .stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/price — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/price")
    public ResponseEntity<?> getOffresByPrice(
            @RequestParam double minPrice,
            @RequestParam double maxPrice) {
        return ResponseEntity.ok(
            offreService.getOffresByPrice(minPrice, maxPrice)
                .stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/most-reserved — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/most-reserved")
    public ResponseEntity<?> getMostReservedOffres() {
        return ResponseEntity.ok(
            offreService.getMostReservedOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/sold-out — MARCHAND
    // ═══════════════════════════════════════════════
    @GetMapping("/sold-out")
    public ResponseEntity<?> getSoldOutOffres() {
        return ResponseEntity.ok(
            offreService.getSoldOutOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/archived — ADMIN
    // ═══════════════════════════════════════════════
    @GetMapping("/archived")
    public ResponseEntity<?> getArchivedOffres() {
        return ResponseEntity.ok(
            offreService.getArchivedOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/expired — MARCHAND + ADMIN
    // ═══════════════════════════════════════════════
    @GetMapping("/expired")
    public ResponseEntity<?> getExpiredOffres() {
        return ResponseEntity.ok(
            offreService.getExpiredOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/active — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/active")
    public ResponseEntity<?> getActiveOffres() {
        return ResponseEntity.ok(
            offreService.getActiveOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/inactive — MARCHAND + ADMIN
    // ═══════════════════════════════════════════════
    @GetMapping("/inactive")
    public ResponseEntity<?> getInactiveOffres() {
        return ResponseEntity.ok(
            offreService.getInactiveOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/recent — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/recent")
    public ResponseEntity<?> getRecentOffres() {
        return ResponseEntity.ok(
            offreService.getRecentOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/discount — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/discount")
    public ResponseEntity<?> getDiscountOffres() {
        return ResponseEntity.ok(
            offreService.getDiscountOffres().stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/offres/search — PUBLIC
    //  ✅ categoryType String → CategoryType (null-safe)
    // ═══════════════════════════════════════════════
    @GetMapping("/search")
    public ResponseEntity<?> search(
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String wilaya,
            @RequestParam(required = false) String categoryType,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) String marchandName,
            @RequestParam(required = false) String sortBy) {

        CategoryType type = null;
        if (categoryType != null && !categoryType.isEmpty())
            type = CategoryType.valueOf(
                categoryType.toUpperCase());

        return ResponseEntity.ok(
            offreService.searchAndFilter(
                title, wilaya, type,
                minPrice, maxPrice, marchandName, sortBy)
                .stream()
                .map(offreService::convertToDTO)
                .collect(Collectors.toList()));
    }
}