package com.Sallaty.Sallaty.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.MarchandService;

@RestController
@RequestMapping("/api/marchand")
public class MarchandController {

    @Autowired
    private MarchandService marchandService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  POST /api/marchand/register — CLIENT
    // ═══════════════════════════════════════════════
    @PostMapping(value = "/register", consumes = "multipart/form-data")
    public ResponseEntity<?> registerAsMarchand(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam("fullName")       String fullName,
            @RequestParam("shopName")       String shopName,
            @RequestParam("typeOfActivity") String typeOfActivity,
            @RequestParam("wilaya")         String wilaya,
            @RequestParam("phoneNumber")    String phoneNumber,
            @RequestParam("tradeRegister")  MultipartFile tradeRegisterFile) {

        try {
            int userId = userDetailsService.getUserIdByEmail(userDetails.getUsername());

            String fileName  = userId + "_trade_" + tradeRegisterFile.getOriginalFilename();
            String uploadDir = "uploads/trade/";

            java.nio.file.Path path = java.nio.file.Paths.get(uploadDir + fileName);
            java.nio.file.Files.createDirectories(path.getParent());
            java.nio.file.Files.write(path, tradeRegisterFile.getBytes());

            marchandService.registerAsMarchand(
                userId, fullName, shopName,
                typeOfActivity, wilaya,
                phoneNumber, uploadDir + fileName);

            Map<String, Object> res = new HashMap<>();
            res.put("success", true);
            res.put("message", "Request sent! Awaiting verification.");
            return ResponseEntity.ok(res);

        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  GET /api/marchand/get/{userId} — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/get/{userId}")
    public ResponseEntity<?> getMarchandById(@PathVariable int userId) {
        try {
            return ResponseEntity.ok(marchandService.getMarchandById(userId));
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  GET /api/marchand/total-favoris/{marchandId} — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/total-favoris/{marchandId}")
    public ResponseEntity<?> getTotalFavoris(@PathVariable int marchandId) {
        try {
            Map<String, Object> res = new HashMap<>();
            res.put("totalFavoris", marchandService.getTotalFavoris(marchandId));
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  GET /api/marchand/statistics — MARCHAND
    // ═══════════════════════════════════════════════
    @GetMapping("/statistics")
    public ResponseEntity<?> getStatistics(
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            int marchandId = userDetailsService.getUserIdByEmail(userDetails.getUsername());
            return ResponseEntity.ok(marchandService.getStatistics(marchandId));
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  ADMIN — GET /api/marchand/pending
    // ═══════════════════════════════════════════════
    @GetMapping("/pending")
    public ResponseEntity<?> getPendingMarchands() {
        try {
            return ResponseEntity.ok(marchandService.getPendingMarchands());
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  ADMIN — GET /api/marchand/verified
    // ═══════════════════════════════════════════════
    @GetMapping("/verified")
    public ResponseEntity<?> getVerifiedMarchands() {
        try {
            return ResponseEntity.ok(marchandService.getVerifiedMarchands());
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  ADMIN — GET /api/marchand/cancelled
    // ═══════════════════════════════════════════════
    @GetMapping("/cancelled")
    public ResponseEntity<?> getCancelledMarchands() {
        try {
            return ResponseEntity.ok(marchandService.getCancelledMarchands());
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  ADMIN — GET /api/marchand/trade-register/{userId}
    // ═══════════════════════════════════════════════
    @GetMapping("/trade-register/{userId}")
    public ResponseEntity<?> getTradeRegister(@PathVariable int userId) {
        try {
            Map<String, Object> res = new HashMap<>();
            res.put("tradeRegister", marchandService.getTradeRegister(userId));
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  ADMIN — PUT /api/marchand/verify/{userId}
    // ═══════════════════════════════════════════════
    @PutMapping("/verify/{userId}")
    public ResponseEntity<?> verifyMarchand(@PathVariable int userId) {
        try {
            marchandService.verifyMarchand(userId);
            Map<String, Object> res = new HashMap<>();
            res.put("success", true);
            res.put("message", "Verified merchant ✅");
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  ADMIN — PUT /api/marchand/cancel/{userId}
    // ═══════════════════════════════════════════════
    @PutMapping("/cancel/{userId}")
    public ResponseEntity<?> cancelMarchand(@PathVariable int userId) {
        try {
            marchandService.cancelMarchand(userId);
            Map<String, Object> res = new HashMap<>();
            res.put("success", true);
            res.put("message", "Merchant canceled ❌");
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }

    // ═══════════════════════════════════════════════
    //  ADMIN — PUT /api/marchand/reactivate/{userId}
    // ═══════════════════════════════════════════════
    @PutMapping("/reactivate/{userId}")
    public ResponseEntity<?> reactivateMarchand(@PathVariable int userId) {
        try {
            marchandService.reactivateMarchand(userId);
            Map<String, Object> res = new HashMap<>();
            res.put("success", true);
            res.put("message", "Merchant reactivated 🔄");
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(err);
        }
    }
}