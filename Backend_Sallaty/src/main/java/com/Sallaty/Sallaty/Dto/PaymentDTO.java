package com.Sallaty.Sallaty.Dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.Sallaty.Sallaty.model.PaymentMethod;
import com.Sallaty.Sallaty.model.PaymentStatus;

public class PaymentDTO {

    // ═══════════════════════════════
    // FIELDS
    // ═══════════════════════════════
    private int           id;
    private int           ordreId;
    private int           userId;
    private BigDecimal    amount;
    private PaymentMethod method;
    private PaymentStatus status;
    private BigDecimal    transportCost;       // ➕ ajouté
    private BigDecimal    platformCommission;
    private LocalDateTime createdAt;

    // ═══════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════
    public PaymentDTO() {}

    public PaymentDTO(
            int id,
            int ordreId,
            int userId,
            BigDecimal amount,
            PaymentMethod method,
            PaymentStatus status,
            BigDecimal transportCost,
            BigDecimal platformCommission,
            LocalDateTime createdAt) {

        this.id                 = id;
        this.ordreId            = ordreId;
        this.userId             = userId;
        this.amount             = amount;
        this.method             = method;
        this.status             = status;
        this.transportCost      = transportCost;
        this.platformCommission = platformCommission;
        this.createdAt          = createdAt;
    }

    // ═══════════════════════════════
    // GETTERS
    // ═══════════════════════════════
    public int           getId()                 { return id; }
    public int           getOrdreId()            { return ordreId; }
    public int           getUserId()             { return userId; }
    public BigDecimal    getAmount()             { return amount; }
    public PaymentMethod getMethod()             { return method; }
    public PaymentStatus getStatus()             { return status; }
    public BigDecimal    getTransportCost()      { return transportCost; }
    public BigDecimal    getPlatformCommission() { return platformCommission; }
    public LocalDateTime getCreatedAt()          { return createdAt; }

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