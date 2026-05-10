package com.Sallaty.Sallaty.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import com.Sallaty.Sallaty.security.CustomUserDetailsService;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api/statistics")
public class StatisticsController {

    private static final Logger log = LoggerFactory.getLogger(StatisticsController.class);

    private static final String KEY_PHOTO_URL = "photoUrl";
    private static final String KEY_TITLE     = "title";
    private static final String KEY_NAME      = "name";

    @Autowired
    private CustomUserDetailsService userDetailsService;

    @PersistenceContext
    private EntityManager entityManager;

    private boolean isMerchantByRole(int userId) {
        try {
            Number count = (Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM roles " +
                "WHERE iduser = :id " +
                "AND UPPER(rolename) IN ('MARCHANT','MERCHANT','MARCHAND')")
                .setParameter("id", userId)
                .getSingleResult();
            return count.intValue() > 0;
        } catch (Exception e) {
            log.error("[Statistics] isMerchantByRole error: {}", e.getMessage());
            return false;
        }
    }

    // ════════════════════════════════════════════════════════════
    //  MERCHANT  —  GET /api/statistics/marchand
    // ════════════════════════════════════════════════════════════
    @GetMapping("/marchand")
    public ResponseEntity<Map<String, Object>> getMerchantStatistics(
            @AuthenticationPrincipal UserDetails userDetails) {

        if (userDetails == null) {
            log.warn("[Statistics] /marchand — userDetails is NULL");
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Not authenticated"));
        }
        log.info("[Statistics] /marchand — user={}, roles={}",
                userDetails.getUsername(),
                userDetails.getAuthorities());

        try {
            int userId = userDetailsService.getUserIdByEmail(userDetails.getUsername());
            log.info("[Statistics] /marchand called for userId={}", userId);

            if (!isMerchantByRole(userId)) {
                return ResponseEntity.status(403)
                        .body(Map.of("error", "Access denied: not a merchant"));
            }

            Map<String, Object> stats = new LinkedHashMap<>();

            // Total offers & orders
            long totalOffers = 0, totalOrders = 0;
            try {
                totalOffers = queryLong(
                    "SELECT COUNT(*) FROM offres WHERE marchand_id=:id", userId);
                totalOrders = queryLong(
                    "SELECT COUNT(*) FROM reservations WHERE marchand_id=:id", userId);
            } catch (Exception e) {
                log.error("[Statistics] totalOffers/totalOrders: {}", e.getMessage());
            }
            stats.put("totalOffers", totalOffers);
            stats.put("totalOrders", totalOrders);

            // Followers + Revenue
            int totalRevenue = 0, totalFollowers = 0, totalLikes = 0;
            try {
                Object[] m = (Object[]) entityManager.createNativeQuery(
                    "SELECT COALESCE(nb_followers,0), COALESCE(revenue,0) " +
                    "FROM marchands WHERE user_id = :id")
                    .setParameter("id", userId).getSingleResult();
                totalFollowers = ((Number) m[0]).intValue();
                totalRevenue   = ((Number) m[1]).intValue();
            } catch (Exception e) {
                log.error("[Statistics] marchands table: {}", e.getMessage());
            }
            try {
                Number likes = (Number) entityManager.createNativeQuery(
                    "SELECT COALESCE(SUM(nb_favoris),0) FROM offres WHERE marchand_id = :id")
                    .setParameter("id", userId).getSingleResult();
                totalLikes = likes.intValue();
            } catch (Exception e) {
                log.error("[Statistics] totalLikes: {}", e.getMessage());
            }
            stats.put("totalRevenue",   totalRevenue);
            stats.put("totalLikes",     totalLikes);
            stats.put("totalFollowers", totalFollowers);

            // ✅ Revenue periods — PostgreSQL
            int revenueToday = 0, revenueWeek = 0, revenueMonth = 0;
            try {
                revenueToday = queryInt(
                    "SELECT COALESCE(SUM(total_price),0) FROM reservations " +
                    "WHERE marchand_id=:id " +
                    "AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                    "AND DATE(created_at) = CURRENT_DATE", userId);

                revenueWeek = queryInt(
                    "SELECT COALESCE(SUM(total_price),0) FROM reservations " +
                    "WHERE marchand_id=:id " +
                    "AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                    "AND created_at >= DATE_TRUNC('week', CURRENT_DATE)", userId);

                revenueMonth = queryInt(
                    "SELECT COALESCE(SUM(total_price),0) FROM reservations " +
                    "WHERE marchand_id=:id " +
                    "AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                    "AND EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM CURRENT_DATE) " +
                    "AND EXTRACT(YEAR FROM created_at)  = EXTRACT(YEAR FROM CURRENT_DATE)", userId);

            } catch (Exception e) {
                log.error("[Statistics] revenue periods: {}", e.getMessage());
            }
            stats.put("revenueToday", revenueToday);
            stats.put("revenueWeek",  revenueWeek);
            stats.put("revenueMonth", revenueMonth);
            stats.put("revenueChart", buildRevenueChart(userId, "marchand_id"));

            // Top 5 selling items
            List<Map<String, Object>> topItems = new ArrayList<>();
            try {
                @SuppressWarnings("unchecked")
                List<Object[]> rows = entityManager.createNativeQuery(
                    "SELECT o.title, o.photo, COUNT(r.id) AS cnt " +
                    "FROM reservations r JOIN offres o ON o.id = r.offre_id " +
                    "WHERE r.marchand_id=:id " +
                    "AND UPPER(r.status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                    "GROUP BY o.id, o.title, o.photo ORDER BY cnt DESC LIMIT 5")
                    .setParameter("id", userId).getResultList();
                for (Object[] r : rows) {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put(KEY_TITLE,     r[0] != null ? r[0].toString() : "");
                    item.put(KEY_PHOTO_URL, r[1] != null ? r[1].toString() : "");
                    item.put("count",       ((Number) r[2]).intValue());
                    topItems.add(item);
                }
            } catch (Exception e) {
                log.error("[Statistics] top items: {}", e.getMessage());
            }
            stats.put("topSellingItems", topItems);

            // New 5 followers
            List<Map<String, Object>> followers = new ArrayList<>();
            try {
                @SuppressWarnings("unchecked")
                List<Object[]> rows = entityManager.createNativeQuery(
                    "SELECT u.id, u.first_name, u.surname, u.profile_image " +
                    "FROM subscribes s JOIN users u ON u.id = s.user_id " +
                    "WHERE s.marchand_id=:id ORDER BY s.created_at DESC LIMIT 5")
                    .setParameter("id", userId).getResultList();
                for (Object[] r : rows) {
                    Map<String, Object> follower = new LinkedHashMap<>();
                    String fn = r[1] != null ? r[1].toString() : "";
                    String ln = r[2] != null ? r[2].toString() : "";
                    String fullName = (fn + " " + ln).trim();
                    if (fullName.isEmpty()) fullName = "Client";
                    follower.put(KEY_NAME,      fullName);
                    follower.put(KEY_PHOTO_URL, r[3] != null ? r[3].toString() : "");
                    followers.add(follower);
                }
            } catch (Exception e) {
                log.error("[Statistics] followers: {}", e.getMessage());
            }
            stats.put("newFollowers", followers);

            return ResponseEntity.ok(stats);

        } catch (Exception e) {
            log.error("[Statistics] getMerchantStatistics FATAL: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(Map.of("error", e.getMessage() != null
                            ? e.getMessage() : "Internal error"));
        }
    }

    // ════════════════════════════════════════════════════════════
    //  CLIENT  —  GET /api/statistics/client
    // ════════════════════════════════════════════════════════════
    @GetMapping("/client")
    public ResponseEntity<Map<String, Object>> getClientStatistics(
            @AuthenticationPrincipal UserDetails userDetails) {

        if (userDetails == null) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Not authenticated"));
        }

        try {
            int userId = userDetailsService.getUserIdByEmail(userDetails.getUsername());

            if (isMerchantByRole(userId)) {
                return ResponseEntity.status(403)
                        .body(Map.of("error", "Access denied: merchants use /api/statistics/marchand"));
            }

            Map<String, Object> stats = new LinkedHashMap<>();

            long totalOrders = 0, confirmed = 0, pending = 0, cancelled = 0;
            try {
                totalOrders = queryLong(
                    "SELECT COUNT(*) FROM reservations WHERE client_id=:id", userId);
                confirmed = queryLong(
                    "SELECT COUNT(*) FROM reservations WHERE client_id=:id AND UPPER(status)='CONFIRMED'", userId);
                pending = queryLong(
                    "SELECT COUNT(*) FROM reservations WHERE client_id=:id AND UPPER(status)='PENDING'", userId);
                cancelled = queryLong(
                    "SELECT COUNT(*) FROM reservations WHERE client_id=:id AND UPPER(status)='CANCELLED'", userId);
            } catch (Exception e) {
                log.error("[Statistics] client counts: {}", e.getMessage());
            }
            stats.put("totalOrders", totalOrders);
            stats.put("confirmed",   confirmed);
            stats.put("pending",     pending);
            stats.put("cancelled",   cancelled);

            int totalSpent = 0;
            try {
                totalSpent = queryInt(
                    "SELECT COALESCE(SUM(total_price),0) FROM reservations " +
                    "WHERE client_id=:id " +
                    "AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED')", userId);
            } catch (Exception e) {
                log.error("[Statistics] client totalSpent: {}", e.getMessage());
            }
            stats.put("totalSpent", totalSpent);

            List<Map<String, Object>> recentOrders = new ArrayList<>();
            try {
                @SuppressWarnings("unchecked")
                List<Object[]> rows = entityManager.createNativeQuery(
                    "SELECT r.id, o.title, o.photo, r.total_price, r.status, r.created_at " +
                    "FROM reservations r JOIN offres o ON o.id = r.offre_id " +
                    "WHERE r.client_id=:id ORDER BY r.created_at DESC LIMIT 5")
                    .setParameter("id", userId).getResultList();
                for (Object[] r : rows) {
                    Map<String, Object> order = new LinkedHashMap<>();
                    order.put("id",          r[0] != null ? r[0].toString() : "");
                    order.put(KEY_TITLE,     r[1] != null ? r[1].toString() : "");
                    order.put(KEY_PHOTO_URL, r[2] != null ? r[2].toString() : "");
                    order.put("price",       r[3] != null ? ((Number) r[3]).intValue() : 0);
                    order.put("status",      r[4] != null ? r[4].toString() : "");
                    order.put("createdAt",   r[5] != null ? r[5].toString() : "");
                    recentOrders.add(order);
                }
            } catch (Exception e) {
                log.error("[Statistics] client recentOrders: {}", e.getMessage());
            }
            stats.put("recentOrders", recentOrders);
            stats.put("spendChart", buildRevenueChart(userId, "client_id"));

            return ResponseEntity.ok(stats);

        } catch (Exception e) {
            log.error("[Statistics] getClientStatistics FATAL: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(Map.of("error", e.getMessage() != null
                            ? e.getMessage() : "Internal error"));
        }
    }

    // ════════════════════════════════════════════════════════════
    //  HELPERS
    // ════════════════════════════════════════════════════════════
    private int queryInt(String sql, int id) {
        return ((Number) entityManager.createNativeQuery(sql)
                .setParameter("id", id).getSingleResult()).intValue();
    }

    private long queryLong(String sql, int id) {
        return ((Number) entityManager.createNativeQuery(sql)
                .setParameter("id", id).getSingleResult()).longValue();
    }

    // ✅ buildRevenueChart — PostgreSQL
    private List<Integer> buildRevenueChart(int userId, String idColumn) {
        List<Integer> chart = new ArrayList<>(Collections.nCopies(30, 0));
        try {
            @SuppressWarnings("unchecked")
            List<Object[]> rows = entityManager.createNativeQuery(
                "SELECT EXTRACT(DAY FROM created_at), " +
                "COALESCE(SUM(total_price),0) " +
                "FROM reservations WHERE " + idColumn + "=:id " +
                "AND UPPER(status) IN ('CONFIRMED','PICKED','COMPLETED') " +
                "AND EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM CURRENT_DATE) " +
                "AND EXTRACT(YEAR FROM created_at)  = EXTRACT(YEAR FROM CURRENT_DATE) " +
                "GROUP BY EXTRACT(DAY FROM created_at)")
                .setParameter("id", userId).getResultList();
            for (Object[] r : rows) {
                int day = ((Number) r[0]).intValue();
                int val = ((Number) r[1]).intValue();
                if (day >= 1 && day <= 30) chart.set(day - 1, val);
            }
        } catch (Exception e) {
            log.error("[Statistics] chart ({}): {}", idColumn, e.getMessage());
        }
        return chart;
    }
}