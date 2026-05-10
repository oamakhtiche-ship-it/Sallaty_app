package com.Sallaty.Sallaty.service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.Sallaty.Sallaty.model.Notification;
import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.repository.NotificationRepository;
import com.Sallaty.Sallaty.repository.UserRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FCMService fcmService;

    @Autowired
    private UserSettingsService userSettingsService;

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  HELPER — get device token
    // ═══════════════════════════════════════════════
    private String getDeviceToken(int userId) {
        try {
            return (String) entityManager
                .createNativeQuery(
                    "SELECT device_token FROM users WHERE id = :id")
                .setParameter("id", userId)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════
    //  HELPER — get all users
    // ═══════════════════════════════════════════════
    @SuppressWarnings("unchecked")
    private List<Object[]> getAllUsers() {
        return entityManager
            .createNativeQuery(
                "SELECT id, device_token FROM users")
            .getResultList();
    }

    // ═══════════════════════════════════════════════
    //  HELPER — get clients
    // ═══════════════════════════════════════════════
    @SuppressWarnings("unchecked")
    private List<Object[]> getClients() {
        return entityManager
            .createNativeQuery(
                "SELECT id, device_token FROM users " +
                "WHERE account_type NOT IN ('ADMIN', 'MARCHANT')")
            .getResultList();
    }

    // ═══════════════════════════════════════════════
    //  HELPER — get marchands
    // ═══════════════════════════════════════════════
    @SuppressWarnings("unchecked")
    private List<Object[]> getMarchands() {
        return entityManager
            .createNativeQuery(
                "SELECT id, device_token FROM users " +
                "WHERE account_type = 'MARCHANT'")
            .getResultList();
    }

    // ═══════════════════════════════════════════════
    //  HELPER — user exists
    // ═══════════════════════════════════════════════
    private boolean userExists(int userId) {
        Long count = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM users WHERE id = :id")
            .setParameter("id", userId)
            .getSingleResult()).longValue();
        return count > 0;
    }

    // ═══════════════════════════════════════════════
    //  sendNotification()
    // ═══════════════════════════════════════════════
    public void sendNotification(
            int userId,
            String title,
            String message,
            NotificationType type) {

        if (!userExists(userId))
            throw new RuntimeException("User not found !");

        if (!userSettingsService.isNotificationAllowed(
                userId, type.name()))
            return;

        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setType(type);
        notificationRepository.save(notification);

        String deviceToken = getDeviceToken(userId);
        if (deviceToken != null) {
            fcmService.sendPush(
                deviceToken, title, message, type.name());
        }
    }

    // ═══════════════════════════════════════════════
    //  sendNotificationToAll()
    // ═══════════════════════════════════════════════
    public void sendNotificationToAll(
            String title, String message) {

        for (Object[] row : getAllUsers()) {
            int userId = ((Number) row[0]).intValue();
            sendNotification(
                userId, title, message,
                NotificationType.BROADCAST);
        }
    }

    // ═══════════════════════════════════════════════
    //  sendNotificationToClients()
    // ═══════════════════════════════════════════════
    public void sendNotificationToClients(
            String title, String message) {

        for (Object[] row : getClients()) {
            int userId = ((Number) row[0]).intValue();
            sendNotification(
                userId, title, message,
                NotificationType.BROADCAST);
        }
    }

    // ═══════════════════════════════════════════════
    //  sendNotificationToMarchands()
    // ═══════════════════════════════════════════════
    public void sendNotificationToMarchands(
            String title, String message) {

        for (Object[] row : getMarchands()) {
            int userId = ((Number) row[0]).intValue();
            sendNotification(
                userId, title, message,
                NotificationType.BROADCAST);
        }
    }

    // ═══════════════════════════════════════════════
    //  sendWarningNotification()
    // ═══════════════════════════════════════════════
    public void sendWarningNotification(int userId) {
        sendNotification(
            userId,
            "⚠️ Warning",
            "Your account will be blocked for violating the terms of service. " +
            "Violation of the terms of service.",
            NotificationType.WARNING);
    }

    // ═══════════════════════════════════════════════
    //  getNotifications() — ✅ fix today/thisWeek
    // ═══════════════════════════════════════════════
    public Map<String, List<Notification>> getNotifications(
            int userId) {

        if (!userExists(userId))
            throw new RuntimeException("User not found !");

        List<Notification> all = notificationRepository
            .findByUserIdOrderByCreatedAtDesc(userId);

        LocalDateTime now       = LocalDateTime.now();
        LocalDateTime startDay  = now.toLocalDate()
                                     .atStartOfDay();
        LocalDateTime startWeek = now.minusDays(7)
                                     .toLocalDate()
                                     .atStartOfDay();

        // ✅ today : à partir de minuit aujourd'hui
        List<Notification> today = all.stream()
            .filter(n -> !n.getCreatedAt()
                           .isBefore(startDay))
            .toList();

        // ✅ thisWeek : entre 7 jours et minuit aujourd'hui
        List<Notification> thisWeek = all.stream()
            .filter(n -> !n.getCreatedAt()
                           .isBefore(startWeek) &&
                          n.getCreatedAt()
                           .isBefore(startDay))
            .toList();

        // ✅ older : avant 7 jours
        List<Notification> older = all.stream()
            .filter(n -> n.getCreatedAt()
                          .isBefore(startWeek))
            .toList();

        Map<String, List<Notification>> result =
            new HashMap<>();
        result.put("today",    today);
        result.put("thisWeek", thisWeek);
        result.put("older",    older);
        return result;
    }

    // ═══════════════════════════════════════════════
    //  markAsRead()
    // ═══════════════════════════════════════════════
    public void markAsRead(int notificationId) {
        Notification notification = notificationRepository
            .findById(notificationId)
            .orElseThrow(() ->
                new RuntimeException(
                    "Notification not found !"));
        notification.setRead(true);
        notificationRepository.save(notification);
    }

    // ═══════════════════════════════════════════════
    //  markAllAsRead()
    // ═══════════════════════════════════════════════
    public void markAllAsRead(int userId) {
        List<Notification> unread = notificationRepository
            .findByUserIdAndIsReadFalse(userId);
        for (Notification n : unread)
            n.setRead(true);
        notificationRepository.saveAll(unread);
    }

    // ═══════════════════════════════════════════════
    //  countUnread()
    // ═══════════════════════════════════════════════
    public int countUnread(int userId) {
        return notificationRepository
            .countByUserIdAndIsReadFalse(userId);
    }

    // ═══════════════════════════════════════════════
    //  deleteNotification()
    // ═══════════════════════════════════════════════
    public void deleteNotification(
            int notificationId, int userId) {

        Notification notification = notificationRepository
            .findById(notificationId)
            .orElseThrow(() ->
                new RuntimeException(
                    "Notification not found !"));

        if (notification.getUserId() != userId)
            throw new RuntimeException("Access denied !");

        notificationRepository.delete(notification);
    }

    // ═══════════════════════════════════════════════
    //  deleteAllNotifications()
    // ═══════════════════════════════════════════════
    public void deleteAllNotifications(int userId) {
        if (!userExists(userId))
            throw new RuntimeException("User not found !");
        notificationRepository.deleteAllByUserId(userId);
    }

    // ═══════════════════════════════════════════════
    //  broadcast() — Admin → ALL/CLIENTS/MERCHANTS
    // ═══════════════════════════════════════════════
    public void broadcast(
            String title,
            String message,
            String recipients) {

        switch (recipients.toUpperCase()) {
            case "CLIENTS" -> {
                for (Object[] row : getClients()) {
                    int userId =
                        ((Number) row[0]).intValue();
                    sendNotification(
                        userId, title, message,
                        NotificationType.BROADCAST);
                }
            }
            case "MERCHANTS" -> {
                for (Object[] row : getMarchands()) {
                    int userId =
                        ((Number) row[0]).intValue();
                    sendNotification(
                        userId, title, message,
                        NotificationType.BROADCAST);
                }
            }
            default -> sendNotificationToAll(
                title, message);
        }
    }

    // ═══════════════════════════════════════════════
    //  supportNotification() — Admin → single user
    // ═══════════════════════════════════════════════
    public void supportNotification(
            int userId,
            String title,
            String message) {

        sendNotification(
            userId, title, message,
            NotificationType.BROADCAST);
    }
}