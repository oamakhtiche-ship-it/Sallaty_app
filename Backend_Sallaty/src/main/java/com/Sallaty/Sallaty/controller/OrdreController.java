package com.Sallaty.Sallaty.controller;

import java.security.Principal;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.Dto.OrderLocationUpdateDTO;
import com.Sallaty.Sallaty.model.Ordre;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.OrdreService;

@RestController
@RequestMapping("/api/ordres")
public class OrdreController {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private OrdreService ordreService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  POST /api/ordres/create  — CLIENT
    // ═══════════════════════════════════════════════
    @PostMapping("/create")
    public ResponseEntity<?> createOrdre(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @RequestParam int offreId,
            @RequestParam int quantity) {

        int clientId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        Ordre ordre = ordreService.createOrdre(
            clientId, offreId, quantity);

        return ResponseEntity.ok(
            Map.of(
                "success",    true,
                "ordreId",    ordre.getId(),
                "totalPrice", ordre.getTotalPrice(),
                "status",     ordre.getStatus()));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/ordres/cancel/{ordreId}  — CLIENT
    // ═══════════════════════════════════════════════
    @PutMapping("/cancel/{ordreId}")
    public ResponseEntity<?> cancelOrdre(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int ordreId) {

        int clientId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        ordreService.cancelOrdre(ordreId, clientId);

        return ResponseEntity.ok(
            Map.of(
                "success", true,
                "message", "Order canceled ❌"));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/ordres/confirm/{ordreId}  — MARCHAND
    // ═══════════════════════════════════════════════
    @PutMapping("/confirm/{ordreId}")
    public ResponseEntity<?> confirmOrdre(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int ordreId) {

        int marchandId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        ordreService.confirmOrdre(ordreId, marchandId);

        return ResponseEntity.ok(
            Map.of(
                "success", true,
                "message", "Order confirmed ✅"));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/ordres/complete/{ordreId}  — CLIENT
    // ═══════════════════════════════════════════════
    @PutMapping("/complete/{ordreId}")
    public ResponseEntity<?> completeOrdre(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int ordreId) {

        int clientId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        ordreService.completeOrdre(ordreId, clientId);

        return ResponseEntity.ok(
            Map.of(
                "success", true,
                "message", "Order completed ✅"));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/ordres/reject/{ordreId}  — MARCHAND
    // ═══════════════════════════════════════════════
    @PutMapping("/reject/{ordreId}")
    public ResponseEntity<?> rejectOrdre(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int ordreId) {

        int marchandId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        ordreService.rejectOrdre(ordreId, marchandId);

        return ResponseEntity.ok(
            Map.of(
                "success", true,
                "message", "Order rejected ❌"));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/{ordreId}  — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/{ordreId}")
    public ResponseEntity<?> getOrdreById(
            @PathVariable int ordreId) {

        Ordre ordre =
            ordreService.getOrdreById(ordreId);

        return ResponseEntity.ok(
            Map.of(
                "ordreId",     ordre.getId(),
                "clientId",    ordre.getClientId(),
                "marchandId",  ordre.getMarchandId(),
                "offreId",     ordre.getOffreId(),
                "quantity",    ordre.getQuantity(),
                "totalPrice",  ordre.getTotalPrice(),
                "status",      ordre.getStatus(),
                "createdAt",   ordre.getCreatedAt(),
                "confirmedAt", ordre.getConfirmedAt(),
                "completedAt", ordre.getCompletedAt()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/{ordreId}/location
    //  Localisation séparée — évite limite Map.of(10)
    // ═══════════════════════════════════════════════
    @GetMapping("/{ordreId}/location")
    public ResponseEntity<?> getOrdreLocation(
            @PathVariable int ordreId) {

        Ordre ordre =
            ordreService.getOrdreById(ordreId);

        return ResponseEntity.ok(
            Map.of(
                "lastLat",        ordre.getLastLat(),
                "lastLng",        ordre.getLastLng(),
                "lastLocationAt",
                    ordre.getLastLocationAt()));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/client  — CLIENT
    // ═══════════════════════════════════════════════

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/client/status  — CLIENT
    // ═══════════════════════════════════════════════
    @GetMapping("/client/status")
    public ResponseEntity<?> getOrdresByClientAndStatus(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @RequestParam String status) {

        int clientId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            ordreService.getOrdresByClientAndStatus(
                clientId, status));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/marchand  — MARCHAND
    // ═══════════════════════════════════════════════
    @GetMapping("/marchand")
    public ResponseEntity<?> getOrdresByMarchand(
            @AuthenticationPrincipal
                UserDetails userDetails) {

        int marchandId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            ordreService.getOrdresByMarchand(
                marchandId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/marchand/pending  — MARCHAND
    // ═══════════════════════════════════════════════
    @GetMapping("/marchand/pending")
    public ResponseEntity<?> getPendingOrdresByMarchand(
            @AuthenticationPrincipal
                UserDetails userDetails) {

        int marchandId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            ordreService.getPendingOrdresByMarchand(
                marchandId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/marchand/status  — MARCHAND
    // ═══════════════════════════════════════════════
    @GetMapping("/marchand/status")
    public ResponseEntity<?> getOrdresByMarchandAndStatus(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @RequestParam String status) {

        int marchandId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            ordreService.getOrdresByMarchandAndStatus(
                marchandId, status));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/history/client  — CLIENT
    // ═══════════════════════════════════════════════
    @GetMapping("/history/client")
    public ResponseEntity<?> getOrdreHistory(
            @AuthenticationPrincipal
                UserDetails userDetails) {

        int clientId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            ordreService.getOrdreHistory(clientId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/history/marchand  — MARCHAND
    // ═══════════════════════════════════════════════
    @GetMapping("/history/marchand")
    public ResponseEntity<?> getOrdreHistoryMarchand(
            @AuthenticationPrincipal
                UserDetails userDetails) {

        int marchandId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            ordreService.getOrdreHistoryMarchand(
                marchandId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/offre/{offreId}  — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/offre/{offreId}")
    public ResponseEntity<?> getOrdresByOffre(
            @PathVariable int offreId) {
        return ResponseEntity.ok(
            ordreService.getOrdresByOffre(offreId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/reservations/{offreId}
    // ═══════════════════════════════════════════════
    @GetMapping("/reservations/{offreId}")
    public ResponseEntity<?> getReservationsByOffre(
            @PathVariable int offreId) {
        return ResponseEntity.ok(
            ordreService.getReservationsByOffre(
                offreId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/ordres/location/{ordreId}
    // ═══════════════════════════════════════════════
    @GetMapping("/location/{ordreId}")
    public ResponseEntity<?> getLocationHistory(
            @PathVariable int ordreId) {
        return ResponseEntity.ok(
            ordreService.getLocationHistory(ordreId));
    }

    // ═══════════════════════════════════════════════
    //  WebSocket — updateLocation
    //  MARCHAND → /app/updateLocation
    //  CLIENT   ← /topic/location/{ordreId}
    // ═══════════════════════════════════════════════
    @MessageMapping("/updateLocation")
    public void updateLocation(
            @Payload OrderLocationUpdateDTO dto,
            Principal principal) {

        int marchandId = extractUserId(principal);
        ordreService.updateLocation(marchandId, dto);
    }

    // ═══════════════════════════════════════════════
    //  extractUserId() — WebSocket helper
    // ═══════════════════════════════════════════════
    private int extractUserId(Principal principal) {
        if (principal instanceof
                UsernamePasswordAuthenticationToken token) {
            Object inner = token.getPrincipal();
            if (inner instanceof UserDetails ud) {
                return userDetailsService
                    .getUserIdByEmail(
                        ud.getUsername());
            }
        }
        throw new RuntimeException(
            "Unauthenticated user !");
    }

    // ═══════════════════════════════════════════════
//  GET /api/ordres/client  — CLIENT
//  ✅ Retourne ordres avec détails offre + marchand
// ═══════════════════════════════════════════════
@GetMapping("/client")
public ResponseEntity<?> getOrdresByClient(
        @AuthenticationPrincipal UserDetails userDetails) {

    int clientId = userDetailsService
        .getUserIdByEmail(userDetails.getUsername());

    // ✅ utilise la nouvelle méthode avec détails
    return ResponseEntity.ok(
        ordreService.getOrdresByClientWithDetails(clientId));
}
}