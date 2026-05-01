package com.Sallaty.Sallaty.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.PrimaryKeyJoinColumn;
import jakarta.persistence.Table;

@Entity
@Table(name = "marchands")
@PrimaryKeyJoinColumn(name = "user_id")
public class Marchand extends User {

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "business_name", unique = true)
    private String businessName;

    @Column(name = "business_type")
    private String businessType;

    @Column(name = "trade_register")
    private String tradeRegister;

    @Enumerated(EnumType.STRING)
    @Column(name = "status_marchand")
    private StatusMarchand statusMarchand = StatusMarchand.PENDING;

    @Column(name = "revenue")
    private double revenue = 0.0;

    @Column(name = "nb_followers")
    private int nbFollowers = 0;

    public Marchand() {}

    public String         getFullName()       { return fullName; }
    public String         getBusinessName()   { return businessName; }
    public String         getBusinessType()   { return businessType; }
    public String         getTradeRegister()  { return tradeRegister; }
    public StatusMarchand getStatusMarchand() { return statusMarchand; }
    public double         getRevenue()        { return revenue; }
    public int            getNbFollowers()    { return nbFollowers; }

    public void setFullName(String v)               { this.fullName = v; }
    public void setBusinessName(String v)           { this.businessName = v; }
    public void setBusinessType(String v)           { this.businessType = v; }
    public void setTradeRegister(String v)          { this.tradeRegister = v; }
    public void setStatusMarchand(StatusMarchand s) { this.statusMarchand = s; }
    public void setRevenue(double v)                { this.revenue = v; }
    public void setNbFollowers(int v)               { this.nbFollowers = v; }

    public String getWilayaMarchand() { return super.getWilaya(); }
}