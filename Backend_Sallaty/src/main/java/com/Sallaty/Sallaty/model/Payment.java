package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payments")
public class Payment {

    // ═══════════════════════════════
    // FIELDS
    // ═══════════════════════════════
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "ordre_id", unique = true)
    private int ordreId;

    @Column(name = "user_id")
    private int userId;

    @Column(name = "amount", precision = 12, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(name = "method")
    private PaymentMethod method;        // ✅ enum

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private PaymentStatus status;

    @Column(name = "transport_cost",
            precision = 12, scale = 2)
    private BigDecimal transportCost;    // ➕ ajouté

    @Column(name = "platform_commission",
            precision = 12, scale = 2)
    private BigDecimal platformCommission;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    // ═══════════════════════════════
    // PRE PERSIST
    // ═══════════════════════════════
    @PrePersist
    public void prePersist() {
        if (createdAt == null)
                createdAt = LocalDateTime.now();
    }

    // ═══════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════
    public Payment() {}

    // ═══════════════════════════════
    // GETTERS
    // ═══════════════════════════════
    public int            getId()                  { return id; }
    public int            getOrdreId()             { return ordreId; }
    public int            getUserId()              { return userId; }
    public BigDecimal     getAmount()              { return amount; }
    public PaymentMethod  getMethod()              { return method; }
    public PaymentStatus  getStatus()              { return status; }
    public BigDecimal     getTransportCost()       { return transportCost; }
    public BigDecimal     getPlatformCommission()  { return platformCommission; }
    public LocalDateTime  getCreatedAt()           { return createdAt; }

    // ═══════════════════════════════
    // SETTERS
    // ═══════════════════════════════
    public void setId(int id)                                    { this.id = id; }
    public void setOrdreId(int ordreId)                          { this.ordreId = ordreId; }
    public void setUserId(int userId)                            { this.userId = userId; }
    public void setAmount(BigDecimal amount)                     { this.amount = amount; }
    public void setMethod(PaymentMethod method)                  { this.method = method; }
    public void setStatus(PaymentStatus status)                  { this.status = status; }
    public void setTransportCost(BigDecimal transportCost)       { this.transportCost = transportCost; }
    public void setPlatformCommission(BigDecimal commission)     { this.platformCommission = commission; }
    public void setCreatedAt(LocalDateTime createdAt)            { this.createdAt = createdAt; }
}