package com.Sallaty.Sallaty.controller;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.model.OffreFavori;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.OffreFavoriService;

@RestController
@RequestMapping("/api/favoris")
public class OffreFavoriController {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private OffreFavoriService offreFavoriService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  POST /api/favoris/toggle/{offreId}
    // ═══════════════════════════════════════════════
    @PostMapping("/toggle/{offreId}")
    public ResponseEntity<?> toggleFavori(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int offreId) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        boolean isFavori = offreFavoriService
            .toggleFavori(userId, offreId);

        return ResponseEntity.ok(
            Map.of(
                "success", true,
                "isFavori", isFavori,
                "message", isFavori
                    ? "Added to favorites ❤️"
                    : "Removed from the favorites 🤍"));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/favoris/my
    //  voir toutes mes offres favorites
    // ═══════════════════════════════════════════════
    @GetMapping("/my")
    public ResponseEntity<List<OffreFavori>>
            getMyFavoris(
                @AuthenticationPrincipal
                    UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            offreFavoriService.getMyFavoris(userId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/favoris/check/{offreId}
    //  ❤️ rouge ou 🤍 gris
    // ═══════════════════════════════════════════════
    @GetMapping("/check/{offreId}")
    public ResponseEntity<?> isFavori(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int offreId) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            Map.of(
                "isFavori",
                offreFavoriService
                    .isFavori(userId, offreId)));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/favoris/count/{offreId}
    //  nombre total de favoris d'une offre — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/count/{offreId}")
    public ResponseEntity<?> countFavoris(
            @PathVariable int offreId) {

        return ResponseEntity.ok(
            Map.of(
                "nbFavoris",
                offreFavoriService
                    .countFavoris(offreId)));
    }
}