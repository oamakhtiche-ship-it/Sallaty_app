package com.Sallaty.Sallaty.Dto;

import java.time.LocalDateTime;

public class OrderLocationUpdateDTO {

    // ═══════════════════════════════
    // FIELDS
    // ═══════════════════════════════
    private int           ordreId;
    private double        lat;
    private double        lng;
    private LocalDateTime timestamp;

    // ═══════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════
    public OrderLocationUpdateDTO() {}

    public OrderLocationUpdateDTO(
            int ordreId,
            double lat,
            double lng,
            LocalDateTime timestamp) {
        this.ordreId   = ordreId;
        this.lat       = lat;
        this.lng       = lng;
        this.timestamp = timestamp;
    }

    // ═══════════════════════════════
    // GETTERS
    // ═══════════════════════════════
    public int           getOrdreId()   { return ordreId; }
    public double        getLat()       { return lat; }
    public double        getLng()       { return lng; }
    public LocalDateTime getTimestamp() { return timestamp; }

    // ═══════════════════════════════
    // SETTERS
    // ═══════════════════════════════
    public void setOrdreId(int ordreId)              { this.ordreId = ordreId; }
    public void setLat(double lat)                   { this.lat = lat; }
    public void setLng(double lng)                   { this.lng = lng; }
    public void setTimestamp(LocalDateTime timestamp){ this.timestamp = timestamp; }
}