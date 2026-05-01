package com.Sallaty.Sallaty.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "user_id")
    private int userId;

    @Column(name = "title")
    private String title;

    @Column(name = "message", columnDefinition = "TEXT")
    private String message;

    @Enumerated(EnumType.STRING)
    @Column(name = "type")
    private NotificationType type;

    @Column(name = "is_read")
    private boolean isRead = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    // ═══════════════════════════════════════════════
    //  ENUM
    // ═══════════════════════════════════════════════
    public enum NotificationType {

        // AUTH
        WELCOME,
        ACCOUNT_UPDATE,

        // ADMIN
        ADMIN_UPDATE,

        // ORDERS
        ORDER_CONFIRMED,
        ORDER_CANCELLED,
        ORDER_COMPLETED,
        ORDER_REJECTED,

        // PAYMENT
        PAYMENT_SUCCESS,
        PAYMENT_RECEIVED,
        PAYMENT_FAILED,

        // MARCHAND
        MARCHAND_VERIFIED,
        MARCHAND_CANCELLED,
        MARCHAND_REACTIVATED,
        NEW_MARCHAND_REQUEST,

        // OFFRE
        NEW_OFFER_AVAILABLE,
        EXPIRING_SOON,
        OFFER_BLOCKED,

        // PICKUP
        PICKUP_SCHEDULED,

        // BROADCAST
        BROADCAST,
        WARNING,

        NEW_DISCOUNT,
        NEW_FAVORITE,
        NEW_SUBSCRIBER
    }

    @PrePersist
    public void prePersist() {
        if (createdAt == null)
            createdAt = LocalDateTime.now();
    }

    public Notification() {}

    public int             getId()        { return id; }
    public int             getUserId()    { return userId; }
    public String          getTitle()     { return title; }
    public String          getMessage()   { return message; }
    public NotificationType getType()     { return type; }
    public boolean         isRead()       { return isRead; }
    public LocalDateTime   getCreatedAt() { return createdAt; }

    public void setId(int id)                         { this.id = id; }
    public void setUserId(int userId)                 { this.userId = userId; }
    public void setTitle(String title)                { this.title = title; }
    public void setMessage(String message)            { this.message = message; }
    public void setType(NotificationType type)        { this.type = type; }
    public void setRead(boolean isRead)               { this.isRead = isRead; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}