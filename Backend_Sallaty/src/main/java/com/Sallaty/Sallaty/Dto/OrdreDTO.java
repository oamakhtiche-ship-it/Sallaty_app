package com.Sallaty.Sallaty.Dto;

import java.time.LocalDateTime;

public class OrdreDTO {

    // ═══════════════════════════════
    // FIELDS
    // ═══════════════════════════════
    private int           id;
    private int           clientId;
    private int           marchandId;
    private int           offreId;
    private int           quantity;
    private double        totalPrice;
    private String        status;
    private LocalDateTime pickupTime;
    private LocalDateTime createdAt;
    private LocalDateTime confirmedAt;
    private LocalDateTime completedAt;
    // ➕ Location fields
    private Double        lastLat;
    private Double        lastLng;
    private LocalDateTime lastLocationAt;

    // ═══════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════
    public OrdreDTO() {}

    public OrdreDTO(
            int id,
            int clientId,
            int marchandId,
            int offreId,
            int quantity,
            double totalPrice,
            String status,
            LocalDateTime pickupTime,
            LocalDateTime createdAt,
            LocalDateTime confirmedAt,
            LocalDateTime completedAt) {

        this.id          = id;
        this.clientId    = clientId;
        this.marchandId  = marchandId;
        this.offreId     = offreId;
        this.quantity    = quantity;
        this.totalPrice  = totalPrice;
        this.status      = status;
        this.pickupTime  = pickupTime;
        this.createdAt   = createdAt;
        this.confirmedAt = confirmedAt;
        this.completedAt = completedAt;
    }

    // ═══════════════════════════════
    // GETTERS
    // ═══════════════════════════════
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

    // ═══════════════════════════════
    // SETTERS
    // ═══════════════════════════════
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