package com.Sallaty.Sallaty.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
    name = "offre_favoris",
    uniqueConstraints = @UniqueConstraint(
        columnNames = {"user_id", "offre_id"} // ➕ évite doublons
    )
)
public class OffreFavori {

    // ═══════════════════════════════════════════════
    //  FIELDS
    // ═══════════════════════════════════════════════
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "user_id", nullable = false)
    private int userId;

    @Column(name = "offre_id", nullable = false)
    private int offreId;

    @Column(name = "added_at")
    private LocalDateTime addedAt;

    // ═══════════════════════════════════════════════
    //  PRE PERSIST
    // ═══════════════════════════════════════════════
    @PrePersist
    public void prePersist() {
        if (addedAt == null)
            addedAt = LocalDateTime.now();
    }

    // ═══════════════════════════════════════════════
    //  CONSTRUCTORS
    // ═══════════════════════════════════════════════
    public OffreFavori() {}

    public OffreFavori(int userId, int offreId) {
        this.userId  = userId;
        this.offreId = offreId;
    }

    // ═══════════════════════════════════════════════
    //  GETTERS / SETTERS
    // ═══════════════════════════════════════════════
    public int           getId()      { return id; }
    public int           getUserId()  { return userId; }
    public int           getOffreId() { return offreId; }
    public LocalDateTime getAddedAt() { return addedAt; }

    public void setId(int id)                     { this.id = id; }
    public void setUserId(int userId)             { this.userId = userId; }
    public void setOffreId(int offreId)           { this.offreId = offreId; }
    public void setAddedAt(LocalDateTime addedAt) { this.addedAt = addedAt; }
}