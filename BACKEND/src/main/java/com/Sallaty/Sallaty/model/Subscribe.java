package com.Sallaty.Sallaty.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
    name = "subscribes",
    uniqueConstraints = @UniqueConstraint(
        columnNames = {"user_id", "marchand_id"}
    )
)
public class Subscribe {

    // ═══════════════════════════════════════════════
    //  FIELDS
    // ═══════════════════════════════════════════════
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "user_id", nullable = false)
    private int userId;

    @Column(name = "marchand_id", nullable = false)
    private int marchandId;

    @Column(name = "created_at")
    private LocalDateTime createdAt =
        LocalDateTime.now();

    // ═══════════════════════════════════════════════
    //  CONSTRUCTORS
    // ═══════════════════════════════════════════════
    public Subscribe() {}

    public Subscribe(int userId, int marchandId) {
        this.userId     = userId;
        this.marchandId = marchandId;
        this.createdAt  = LocalDateTime.now();
    }

    // ═══════════════════════════════════════════════
    //  GETTERS / SETTERS
    // ═══════════════════════════════════════════════
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) {
        this.userId = userId; }

    public int getMarchandId() { return marchandId; }
    public void setMarchandId(int marchandId) {
        this.marchandId = marchandId; }

    public LocalDateTime getCreatedAt() {
        return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt; }
}