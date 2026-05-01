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

import com.Sallaty.Sallaty.model.Subscribe;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.SubscribeService;

@RestController
@RequestMapping("/api/subscribe")
public class SubscribeController {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private SubscribeService subscribeService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  POST /api/subscribe/{marchandId}
    //  S'abonner à un marchand — AUTH
    // ═══════════════════════════════════════════════
    @PostMapping("/{marchandId}")
    public ResponseEntity<?> subscribe(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int marchandId) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        subscribeService.subscribe(userId, marchandId);

        return ResponseEntity.ok(
            Map.of(
                "success", true,
                "message", "Abonné avec succès 🔔"));
    }

    // ═══════════════════════════════════════════════
    //  DELETE /api/subscribe/{marchandId}
    //  Se désabonner — AUTH
    // ═══════════════════════════════════════════════
    @DeleteMapping("/{marchandId}")
    public ResponseEntity<?> unsubscribe(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int marchandId) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        subscribeService.unsubscribe(userId, marchandId);

        return ResponseEntity.ok(
            Map.of(
                "success", true,
                "message", "Désabonné ✅"));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/subscribe/my
    //  Voir mes abonnements — AUTH
    // ═══════════════════════════════════════════════
    @GetMapping("/my")
    public ResponseEntity<List<Subscribe>>
            getMySubscriptions(
                @AuthenticationPrincipal
                    UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            subscribeService
                .getMySubscriptions(userId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/subscribe/{marchandId}/subscribers
    //  Voir les subscribers d'un marchand — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/{marchandId}/subscribers")
    public ResponseEntity<List<Subscribe>>
            getSubscribers(
                @PathVariable int marchandId) {

        return ResponseEntity.ok(
            subscribeService
                .getSubscribers(marchandId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/subscribe/{marchandId}/check
    //  Vérifier si abonné — AUTH
    // ═══════════════════════════════════════════════
    @GetMapping("/{marchandId}/check")
    public ResponseEntity<?> isSubscribed(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int marchandId) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            Map.of("isSubscribed",
                subscribeService
                    .isSubscribed(userId, marchandId)));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/subscribe/{marchandId}/count
    //  Compter les subscribers — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/{marchandId}/count")
    public ResponseEntity<?> countSubscribers(
            @PathVariable int marchandId) {

        return ResponseEntity.ok(
            Map.of("count",
                subscribeService
                    .countSubscribers(marchandId)));
    }
}