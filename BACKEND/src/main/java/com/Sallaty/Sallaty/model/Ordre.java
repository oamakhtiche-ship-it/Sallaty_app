package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reservations") // ✅ corrigé — AdminService utilise "reservations"
public class Ordre {

    public static final String PENDING   = "PENDING";
    public static final String CONFIRMED = "CONFIRMED";
    public static final String PICKED    = "PICKED";
    public static final String CANCELLED = "CANCELLED";
    public static final String COMPLETED = "COMPLETED"; // ✅ ajouté

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "client_id")
    private int clientId;

    @Column(name = "marchand_id")
    private int marchandId;

    @Column(name = "offre_id")
    private int offreId;

    @Column(name = "quantity")
    private int quantity;

    @Column(name = "total_price")
    private double totalPrice;

    @Column(name = "status")
    private String status;

    @Column(name = "pickup_time")
    private LocalDateTime pickupTime;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "confirmed_at")
    private LocalDateTime confirmedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "last_lat")
    private Double lastLat;

    @Column(name = "last_lng")
    private Double lastLng;

    @Column(name = "last_location_at")
    private LocalDateTime lastLocationAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null)
            createdAt = LocalDateTime.now();
    }

    public Ordre() {}

    public int           getId()             { return id; }
    public int           getClientId()       { return clientId; }
    public int           getMarchandId()     { return marchandId; }
    public int           getOffreId()        { return offreId; }
    public int           getQuantity()       { return quantity; }
    public double        getTotalPrice()     { return totalPrice; }
    public String        getStatus()         { return status; }
    public LocalDateTime getPickupTime()     { return pickupTime; }
    public LocalDateTime getCreatedAt()      { return createdAt; }
    public LocalDateTime getConfirmedAt()    { return confirmedAt; }
    public LocalDateTime getCompletedAt()    { return completedAt; }
    public Double        getLastLat()        { return lastLat; }
    public Double        getLastLng()        { return lastLng; }
    public LocalDateTime getLastLocationAt() { return lastLocationAt; }

    public void setId(int id)                             { this.id = id; }
    public void setClientId(int clientId)                 { this.clientId = clientId; }
    public void setMarchandId(int marchandId)             { this.marchandId = marchandId; }
    public void setOffreId(int offreId)                   { this.offreId = offreId; }
    public void setQuantity(int quantity)                 { this.quantity = quantity; }
    public void setTotalPrice(double totalPrice)          { this.totalPrice = totalPrice; }
    public void setStatus(String status)                  { this.status = status; }
    public void setPickupTime(LocalDateTime pickupTime)   { this.pickupTime = pickupTime; }
    public void setCreatedAt(LocalDateTime createdAt)     { this.createdAt = createdAt; }
    public void setConfirmedAt(LocalDateTime confirmedAt) { this.confirmedAt = confirmedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }
    public void setLastLat(Double lastLat)                { this.lastLat = lastLat; }
    public void setLastLng(Double lastLng)                { this.lastLng = lastLng; }
    public void setLastLocationAt(LocalDateTime t)        { this.lastLocationAt = t; }
}