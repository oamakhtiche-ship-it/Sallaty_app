package com.Sallaty.Sallaty.controller;

import java.util.HashMap;
import java.util.Map;

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
import java.util.List;
import com.Sallaty.Sallaty.model.User;
import com.Sallaty.Sallaty.repository.UserRepository;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.UserService;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CustomUserDetailsService userDetailsService;
    
    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  GET /api/users/me — AUTH
    //  ✅ NOUVEAU — appelé au démarrage de l'app Flutter
    //  Flutter envoie : Bearer token dans header Authorization
    //  Réponse : infos complètes du user connecté
    // ═══════════════════════════════════════════════
    @GetMapping("/me")
    public ResponseEntity<?> getMe(
            @AuthenticationPrincipal UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        User user = userRepository.findById(userId)
            .orElseThrow(() ->
                new RuntimeException("User non trouvé !"));

        Map<String, Object> response = new HashMap<>();
        response.put("success",      true);
        response.put("userId",       user.getId());
        response.put("firstName",    user.getFirstName());
        response.put("surname",      user.getSurname());
        response.put("contact",      user.getContact());
        response.put("profileImage", user.getProfileImage());
        response.put("balance",      user.getBalance());
        response.put("accountType",  user.getAccountType());
        response.put("accountState", user.getAccountState());
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/users/uploadImage/{userId} — PUBLIC
    // ═══════════════════════════════════════════════
    @PostMapping("/uploadImage/{userId}")
    public ResponseEntity<?> uploadImage(
            @PathVariable int userId,
            @RequestParam("file") MultipartFile file) {

        String fileName = userId + "_"
            + file.getOriginalFilename();
        String uploadDir = "uploads/";

        try {
            java.nio.file.Path path = java.nio.file.Paths
                .get(uploadDir + fileName);
            java.nio.file.Files.createDirectories(
                path.getParent());
            java.nio.file.Files.write(
                path, file.getBytes());
        } catch (Exception e) {
            throw new RuntimeException(
                "Erreur upload image !");
        }

        userService.uploadImage(
            userId, uploadDir + fileName);

        Map<String, Object> response = new HashMap<>();
        response.put("success",   true);
        response.put("imagePath", uploadDir + fileName);
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/users/update — AUTH
    // ═══════════════════════════════════════════════
    @PutMapping("/update")
    public ResponseEntity<?> updateUser(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) String firstName,
            @RequestParam(required = false) String surname,
            @RequestParam(required = false) String contact) {

        int userId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        userService.updateUser(userId, firstName, surname, contact);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Profil mis à jour !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  DELETE /api/users/deleteImage — AUTH
    // ═══════════════════════════════════════════════
    @DeleteMapping("/deleteImage")
    public ResponseEntity<?> deleteImage(
            @AuthenticationPrincipal UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        userService.deleteImage(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Image supprimée !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/users/logout — AUTH
    // ═══════════════════════════════════════════════
    @PostMapping("/logout")
    public ResponseEntity<?> logout(
            @AuthenticationPrincipal UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        userService.logout(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Déconnexion réussie !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  GET /api/users/balance — AUTH
    // ═══════════════════════════════════════════════
    @GetMapping("/balance")
    public ResponseEntity<?> getBalance(
            @AuthenticationPrincipal UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("balance", userService.getBalance(userId));
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/users/balance/topup — AUTH
    // ═══════════════════════════════════════════════
    @PutMapping("/balance/topup")
    public ResponseEntity<?> topUpBalance(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam double amount) {

        int userId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        userService.topUpBalance(userId, amount);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Solde rechargé !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/users/device-token — AUTH
    // ═══════════════════════════════════════════════
    @PutMapping("/device-token")
    public ResponseEntity<?> updateDeviceToken(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String token) {

        int userId = userDetailsService
            .getUserIdByEmail(userDetails.getUsername());

        userService.updateDeviceToken(userId, token);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Device token mis à jour !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/users/block/{userId} — ADMIN
    // ═══════════════════════════════════════════════
    @PutMapping("/block/{userId}")
    public ResponseEntity<?> blockUser(
            @PathVariable int userId) {

        userService.blockUser(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "User bloqué !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/users/unblock/{userId} — ADMIN
    // ═══════════════════════════════════════════════
    @PutMapping("/unblock/{userId}")
    public ResponseEntity<?> unblockUser(
            @PathVariable int userId) {

        userService.unblockUser(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "User débloqué !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  DELETE /api/users/delete/{userId} — ADMIN
    // ═══════════════════════════════════════════════
    @DeleteMapping("/delete/{userId}")
    public ResponseEntity<?> deleteUser(
            @PathVariable int userId) {

        userService.deleteUser(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "User supprimé !");
        return ResponseEntity.ok(response);
            }
    @GetMapping("/statistics")
public ResponseEntity<?> getStatistics(
        @AuthenticationPrincipal UserDetails userDetails) {

    int userId = userDetailsService.getUserIdByEmail(
            userDetails.getUsername());
    User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));

    boolean isMerchant = "MARCHANT".equalsIgnoreCase(user.getAccountType());

    Map<String, Object> stats = new java.util.LinkedHashMap<>();

    if (isMerchant) {
        // ── Données de base attendues par le frontend ───────────────────────────────────
        stats.put("totalOffers", user.getNbOffer());
        stats.put("totalOrders", user.getNbOrder());
        
        // ── Récupérer les données marchand ─────────────────────
        int totalRevenue = 0;
        int totalFollowers = 0;
        int totalLikes = 0;
        
        try {
            // Total revenue from marchands table
            Object[] m = (Object[]) entityManager.createNativeQuery(
                "SELECT COALESCE(nb_followers,0), COALESCE(revenue,0) FROM marchands WHERE user_id = :id")
                .setParameter("id", userId).getSingleResult();
            totalFollowers = ((Number)m[0]).intValue();
            totalRevenue = ((Number)m[1]).intValue();
            
            // Total likes (sum of nb_favoris from offres)
            Number likes = (Number) entityManager.createNativeQuery(
                "SELECT COALESCE(SUM(nb_favoris),0) FROM offres WHERE marchand_id = :id")
                .setParameter("id", userId).getSingleResult();
            totalLikes = likes.intValue();
            
        } catch (Exception e) {
            System.out.println("Error fetching marchand data: " + e.getMessage());
        }
        
        stats.put("totalRevenue", totalRevenue);
        stats.put("totalLikes", totalLikes);
        stats.put("totalFollowers", totalFollowers);

        // ── Revenus (uniquement reservations CONFIRMED/PICKED/COMPLETED) ──
        int revenueToday = 0, revenueWeek = 0, revenueMonth = 0;
        try {
            Number today = (Number) entityManager.createNativeQuery(
                "SELECT COALESCE(SUM(total_price),0) FROM reservations " +
                "WHERE marchand_id=:id AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                "AND DATE(created_at)=CURDATE()")
                .setParameter("id", userId).getSingleResult();
            revenueToday = today.intValue();

            Number week = (Number) entityManager.createNativeQuery(
                "SELECT COALESCE(SUM(total_price),0) FROM reservations " +
                "WHERE marchand_id=:id AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                "AND YEARWEEK(created_at,1)=YEARWEEK(CURDATE(),1)")
                .setParameter("id", userId).getSingleResult();
            revenueWeek = week.intValue();

            Number month = (Number) entityManager.createNativeQuery(
                "SELECT COALESCE(SUM(total_price),0) FROM reservations " +
                "WHERE marchand_id=:id AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                "AND MONTH(created_at)=MONTH(CURDATE()) AND YEAR(created_at)=YEAR(CURDATE())")
                .setParameter("id", userId).getSingleResult();
            revenueMonth = month.intValue();
        } catch (Exception e) {}
        
        stats.put("revenueToday", revenueToday);
        stats.put("revenueWeek", revenueWeek);
        stats.put("revenueMonth", revenueMonth);

        // ── Graphique des revenus (30 jours) ───────────────────
        java.util.List<Integer> chart = new java.util.ArrayList<>(
            java.util.Collections.nCopies(30, 0));
        try {
            @SuppressWarnings("unchecked")
            java.util.List<Object[]> rows = entityManager.createNativeQuery(
                "SELECT DAY(created_at), COALESCE(SUM(total_price),0) " +
                "FROM reservations WHERE marchand_id=:id " +
                "AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                "AND MONTH(created_at)=MONTH(CURDATE()) " +
                "AND YEAR(created_at)=YEAR(CURDATE()) " +
                "GROUP BY DAY(created_at)")
                .setParameter("id", userId).getResultList();
            for (Object[] r : rows) {
                int day = ((Number)r[0]).intValue();
                int rev = ((Number)r[1]).intValue();
                if (day >= 1 && day <= 30) chart.set(day-1, rev);
            }
        } catch (Exception e) {}
        stats.put("revenueChart", chart);

        // ── Top Selling Items (TOP 5) - Match frontend expectations ──
        java.util.List<Map<String,Object>> topItems = new java.util.ArrayList<>();
        try {
            @SuppressWarnings("unchecked")
            java.util.List<Object[]> rows = entityManager.createNativeQuery(
                "SELECT o.title, o.photo, COUNT(r.id) AS cnt " +
                "FROM reservations r JOIN offres o ON o.id=r.offre_id " +
                "WHERE r.marchand_id=:id AND UPPER(r.status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                "GROUP BY o.id, o.title, o.photo ORDER BY cnt DESC LIMIT 5")
                .setParameter("id", userId).getResultList();
            for (Object[] r : rows) {
                Map<String,Object> item = new java.util.LinkedHashMap<>();
                // Frontend expects 'title' for the offer name
                item.put("title", r[0] != null ? r[0].toString() : "");
                // Frontend expects 'photoUrl' for the image URL
                String p = r[1] != null ? r[1].toString() : "";
                item.put("photoUrl", p);
                // Frontend expects 'count' for the number of sales
                item.put("count", ((Number)r[2]).intValue());
                topItems.add(item);
            }
        } catch (Exception e) {}
        stats.put("topSellingItems", topItems);

        // ── New followers (TOP 5) - Match frontend expectations ──
        java.util.List<Map<String,Object>> followers = new java.util.ArrayList<>();
        try {
            @SuppressWarnings("unchecked")
            java.util.List<Object[]> rows = entityManager.createNativeQuery(
                "SELECT u.id, u.first_name, u.surname, u.profile_image " +
                "FROM subscribes s JOIN users u ON u.id=s.user_id " +
                "WHERE s.marchand_id=:id ORDER BY s.created_at DESC LIMIT 5")
                .setParameter("id", userId).getResultList();
            for (Object[] r : rows) {
                Map<String,Object> follower = new java.util.LinkedHashMap<>();
                // Frontend expects 'name' (can be firstName + surname) or 'clientName'
                String firstName = r[1] != null ? r[1].toString() : "";
                String lastName = r[2] != null ? r[2].toString() : "";
                String fullName = (firstName + " " + lastName).trim();
                if (fullName.isEmpty()) fullName = "Client";
                follower.put("name", fullName);
                // Frontend expects 'photoUrl' or 'profileImage'
                String photo = r[3] != null ? r[3].toString() : "";
                follower.put("photoUrl", photo);
                followers.add(follower);
            }
        } catch (Exception e) {}
        stats.put("newFollowers", followers);

    } else {
        // ── CLIENT VIEW ─────────────────────────────────────────────
        // Frontend client view expects these fields from OrderStore
        
        // Note: For client view, the Flutter code uses OrderStore.instance.clientOrders
        // which is populated by a separate endpoint. So this endpoint should return
        // minimal client data, but the main client orders come from a different API call.
        
        stats.put("isMerchant", false);
        
        // Optional: You could return some basic stats for the client
        long totalOrders = user.getNbOrder();
        stats.put("totalOrders", totalOrders);
        
        // You can also return order status breakdown if needed
        long confirmed = 0, pending = 0;
        try {
            confirmed = ((Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM reservations WHERE client_id=:id AND UPPER(status)='CONFIRMED'")
                .setParameter("id", userId).getSingleResult()).longValue();
            pending = ((Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM reservations WHERE client_id=:id AND UPPER(status)='PENDING'")
                .setParameter("id", userId).getSingleResult()).longValue();
        } catch (Exception e) {}
        
        stats.put("confirmed", confirmed);
        stats.put("pending", pending);
        
        // Total spent
        double totalSpent = 0;
        try {
            totalSpent = ((Number) entityManager.createNativeQuery(
                "SELECT COALESCE(SUM(total_price),0) FROM reservations " +
                "WHERE client_id=:id AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED')")
                .setParameter("id", userId).getSingleResult()).doubleValue();
        } catch (Exception e) {}
        stats.put("totalSpent", (int) totalSpent);
        
        // Note: The recentOrders in client view are handled by OrderStore.instance.fetchClientOrders()
        // which should be implemented separately
    }

    return ResponseEntity.ok(stats);
}
}
    