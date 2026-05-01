package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "order_locations")
public class OrderLocation {

    // ═══════════════════════════════
    // FIELDS
    // ═══════════════════════════════
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "ordre_id")
    private int ordreId;

    @Column(name = "lat")
    private double lat;

    @Column(name = "lng")
    private double lng;

    @Column(name = "timestamp")
    private LocalDateTime timestamp;

    // ═══════════════════════════════
    // PRE PERSIST
    // ═══════════════════════════════
    @PrePersist
    public void prePersist() {
        if (timestamp == null)
            timestamp = LocalDateTime.now();
    }

    // ═══════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════
    public OrderLocation() {}

    // ═══════════════════════════════
    // GETTERS
    // ═══════════════════════════════
    public int           getId()        { return id; }
    public int           getOrdreId()   { return ordreId; }
    public double        getLat()       { return lat; }
    public double        getLng()       { return lng; }
    public LocalDateTime getTimestamp() { return timestamp; }

    // ═══════════════════════════════
    // SETTERS
    // ═══════════════════════════════
    public void setId(int id)                        { this.id = id; }
    public void setOrdreId(int ordreId)              { this.ordreId = ordreId; }
    public void setLat(double lat)                   { this.lat = lat; }
    public void setLng(double lng)                   { this.lng = lng; }
    public void setTimestamp(LocalDateTime timestamp){ this.timestamp = timestamp; }
}