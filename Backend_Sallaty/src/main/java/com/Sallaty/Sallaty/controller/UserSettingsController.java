package com.Sallaty.Sallaty.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.model.User;
import com.Sallaty.Sallaty.model.UserSettings;
import com.Sallaty.Sallaty.repository.UserRepository;
import com.Sallaty.Sallaty.service.UserSettingsService;

// ═══════════════════════════════════════════════════════════════════
// UserSettingsController.java
//
// ENDPOINTS :
//   GET    /api/settings                    → getSettings()
//   PUT    /api/settings                    → updateSettings()
//   PUT    /api/settings/toggle/{type}      → toggleNotification()
//   PUT    /api/settings/language/{language} → updateLanguage()
//   DELETE /api/settings/account            → deleteAccount()
//
// SÉCURITÉ :
//   L'userId est TOUJOURS résolu depuis le JWT (@AuthenticationPrincipal)
//   Jamais exposé dans l'URL — un user ne peut modifier que ses propres settings.
// ═══════════════════════════════════════════════════════════════════
@RestController
@RequestMapping("/api/settings")
public class UserSettingsController {

    @Autowired
    private UserSettingsService userSettingsService;

    @Autowired
    private UserRepository userRepository;

    // ── Helper : résoudre userId depuis le JWT ────────────────────
    private int resolveUserId(UserDetails userDetails) {
        String contact = userDetails.getUsername();
        User user = userRepository.findByContact(contact)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return user.getId();
    }

    // ─────────────────────────────────────────────────────────────
    // GET /api/settings
    // Récupérer les settings de l'utilisateur connecté
    // ─────────────────────────────────────────────────────────────
    @GetMapping
    public ResponseEntity<UserSettings> getSettings(
            @AuthenticationPrincipal UserDetails userDetails) {

        int userId = resolveUserId(userDetails);
        return ResponseEntity.ok(userSettingsService.getSettings(userId));
    }

    // ─────────────────────────────────────────────────────────────
    // PUT /api/settings
    // Modifier tous les settings d'un coup
    // ─────────────────────────────────────────────────────────────
    @PutMapping
    public ResponseEntity<UserSettings> updateSettings(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UserSettings newSettings) {

        int userId = resolveUserId(userDetails);
        return ResponseEntity.ok(
                userSettingsService.updateSettings(userId, newSettings));
    }

    // ─────────────────────────────────────────────────────────────
    // PUT /api/settings/toggle/{type}
    // Toggle une notification ON/OFF
    // type : orderConfirmed | newMessage | newDiscount | systemAlerts
    // ─────────────────────────────────────────────────────────────
    @PutMapping("/toggle/{type}")
    public ResponseEntity<UserSettings> toggleNotification(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String type) {

        int userId = resolveUserId(userDetails);
        return ResponseEntity.ok(
                userSettingsService.toggleNotification(userId, type));
    }

    // ─────────────────────────────────────────────────────────────
    // PUT /api/settings/language/{language}
    // Modifier la langue : fr | ar | en
    // ─────────────────────────────────────────────────────────────
    @PutMapping("/language/{language}")
    public ResponseEntity<UserSettings> updateLanguage(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String language) {

        int userId = resolveUserId(userDetails);
        return ResponseEntity.ok(
                userSettingsService.updateLanguage(userId, language));
    }

    // ─────────────────────────────────────────────────────────────
    // DELETE /api/settings/account
    // Supprimer le compte de l'utilisateur connecté
    // ─────────────────────────────────────────────────────────────
    @DeleteMapping("/account")
    public ResponseEntity<?> deleteAccount(
            @AuthenticationPrincipal UserDetails userDetails) {

        int userId = resolveUserId(userDetails);
        userSettingsService.deleteAccount(userId);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Account deleted successfully ✅"));
    }
}