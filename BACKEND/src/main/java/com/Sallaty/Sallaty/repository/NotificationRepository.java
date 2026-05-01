package com.Sallaty.Sallaty.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.Notification;
import com.Sallaty.Sallaty.model.Notification.NotificationType;

@Repository
public interface NotificationRepository
        extends JpaRepository<Notification, Integer> {

    // ─────────────────────────────────────────────
    // Toutes les notifications d'un user
    // ─────────────────────────────────────────────
    List<Notification> findByUserIdOrderByCreatedAtDesc(
        int userId);

    // ─────────────────────────────────────────────
    // Notifications non lues d'un user
    // ─────────────────────────────────────────────
    List<Notification> findByUserIdAndIsReadFalse(
        int userId);

    // ─────────────────────────────────────────────
    // Compter notifications non lues
    // ─────────────────────────────────────────────
    int countByUserIdAndIsReadFalse(int userId);

    // ─────────────────────────────────────────────
    // Notifications par type
    // ─────────────────────────────────────────────
    List<Notification> findByUserIdAndType(
        int userId, NotificationType type);

    // ─────────────────────────────────────────────
    // Supprimer toutes les notifications d'un user
    // ─────────────────────────────────────────────
    void deleteAllByUserId(int userId);
}