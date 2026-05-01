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
import org.springframework.web.bind.annotation.PostMapping; // ✅ security pas service
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.model.Notification;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.NotificationService;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ── helper
    private int getUserId(UserDetails userDetails) {
        return userDetailsService
            .getUserIdByEmail(userDetails.getUsername());
    }

    // GET /api/notifications/my
    @GetMapping("/my")
    public ResponseEntity<Map<String, List<Notification>>> getMyNotifications(
            @AuthenticationPrincipal UserDetails userDetails) {

        return ResponseEntity.ok(
            notificationService.getNotifications(getUserId(userDetails)));
    }

    // PUT /api/notifications/read/{id}
    @PutMapping("/read/{id}")
    public ResponseEntity<Map<String, Object>> markAsRead(
            @PathVariable int id) {

        notificationService.markAsRead(id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    // PUT /api/notifications/read-all
    @PutMapping("/read-all")
    public ResponseEntity<Map<String, Object>> markAllAsRead(
            @AuthenticationPrincipal UserDetails userDetails) {

        notificationService.markAllAsRead(getUserId(userDetails));
        return ResponseEntity.ok(Map.of("success", true));
    }

    // GET /api/notifications/unread-count
    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Object>> countUnread(
            @AuthenticationPrincipal UserDetails userDetails) {

        return ResponseEntity.ok(Map.of("count",
            notificationService.countUnread(getUserId(userDetails))));
    }

    // DELETE /api/notifications/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteNotification(
            @PathVariable int id,
            @AuthenticationPrincipal UserDetails userDetails) {

        notificationService.deleteNotification(id, getUserId(userDetails));
        return ResponseEntity.ok(Map.of("success", true));
    }

    // DELETE /api/notifications/all
    @DeleteMapping("/all")
    public ResponseEntity<Map<String, Object>> deleteAllNotifications(
            @AuthenticationPrincipal UserDetails userDetails) {

        notificationService.deleteAllNotifications(getUserId(userDetails));
        return ResponseEntity.ok(Map.of("success", true));
    }

    // POST /api/notifications/broadcast  ← ADMIN
    @PostMapping("/broadcast")
    public ResponseEntity<Map<String, Object>> broadcast(
            @RequestBody Map<String, String> body) {

        notificationService.broadcast(
            body.get("title"),
            body.get("message"),
            body.getOrDefault("recipients", "ALL"));
        return ResponseEntity.ok(Map.of("success", true));
    }

    // POST /api/notifications/support/{userId}  ← ADMIN
    @PostMapping("/support/{userId}")
    public ResponseEntity<Map<String, Object>> supportNotification(
            @PathVariable int userId,
            @RequestBody Map<String, String> body) {

        notificationService.supportNotification(
            userId,
            body.get("title"),
            body.get("message"));
        return ResponseEntity.ok(Map.of("success", true));
    }
}