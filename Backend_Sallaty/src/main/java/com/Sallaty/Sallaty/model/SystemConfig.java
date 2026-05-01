package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;

@Entity
@Table(name = "system_config")
public class SystemConfig {

    // ═══════════════════════════════════════════════
    //  ID = 1 toujours (une seule ligne dans DB)
    // ═══════════════════════════════════════════════
    @Id
    private int id = 1;

    // ═══════════════════════════════════════════════
    //  FINANCIAL
    // ═══════════════════════════════════════════════
    @Column(name = "commission_rate")
    private double commissionRate = 0.10; // 10%

    @Column(name = "transport_cost")
    private double transportCost = 1.50; // 1.50 DA

    @Column(name = "min_top_up")
    private double minTopUp = 100.0; // 100 DA

    // ═══════════════════════════════════════════════
    //  NOTIFICATIONS
    // ═══════════════════════════════════════════════
    @Column(name = "hours_before_expiry")
    private int hoursBeforeExpiry = 24; // 24h

    // ═══════════════════════════════════════════════
    //  ORDERS
    // ═══════════════════════════════════════════════
    @Column(name = "cancel_deadline")
    private int cancelDeadline = 5;// 1h

    // ═══════════════════════════════════════════════
    //  CONSTRUCTORS
    // ═══════════════════════════════════════════════
    public SystemConfig() {}

    // ═══════════════════════════════════════════════
    //  GETTERS
    // ═══════════════════════════════════════════════
    public int    getId()                { return id; }
    public double getCommissionRate()    { return commissionRate; }
    public double getTransportCost()     { return transportCost; }
    public double getMinTopUp()          { return minTopUp; }
    public int    getHoursBeforeExpiry() { return hoursBeforeExpiry; }
    public int    getCancelDeadline()    { return cancelDeadline; }

    // ═══════════════════════════════════════════════
    //  SETTERS
    // ═══════════════════════════════════════════════
    public void setId(int id)                        { this.id = id; }
    public void setCommissionRate(double v)          { this.commissionRate = v; }
    public void setTransportCost(double v)           { this.transportCost = v; }
    public void setMinTopUp(double v)                { this.minTopUp = v; }
    public void setHoursBeforeExpiry(int v)          { this.hoursBeforeExpiry = v; }
    public void setCancelDeadline(int v)             { this.cancelDeadline = v; }
}