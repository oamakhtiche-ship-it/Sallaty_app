package com.Sallaty.Sallaty.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "otpcodes")
public class Otpcode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "user_id")
    private int userId;          // ✅ camelCase — plus d'underscore

    @Column(name = "code")
    private String code;

    @Column(name = "expire_at")
    private LocalDateTime expireAt;   // ✅ camelCase

    @Column(name = "utilise")
    private Boolean utilise;

    @Column(name = "created_at")     // ✅ corrigé — était "createdAt"
    private LocalDateTime createdAt;

    // ═══════════════════════════════════════════
    //  Constructeur principal
    // ═══════════════════════════════════════════
    public Otpcode(int userId, String code) {
        this.userId    = userId;
        this.code      = code;
        this.expireAt  = LocalDateTime.now().plusMinutes(10);
        this.utilise   = false;
        this.createdAt = LocalDateTime.now();
    }

    // ═══════════════════════════════════════════
    //  Constructeur vide
    // ═══════════════════════════════════════════
    public Otpcode() {}

    // ═══════════════════════════════════════════
    //  Getters
    // ═══════════════════════════════════════════
    public int           getId()        { return id; }
    public int           getUserId()    { return userId; }
    public String        getCode()      { return code; }
    public LocalDateTime getExpireAt()  { return expireAt; }
    public boolean       isUtilise()    { return utilise; }
    public LocalDateTime getCreatedAt() { return createdAt; }

    // ═══════════════════════════════════════════
    //  Setters
    // ═══════════════════════════════════════════
    public void setId(int id)                    { this.id = id; }
    public void setUserId(int userId)            { this.userId = userId; }
    public void setCode(String code)             { this.code = code; }
    public void setExpireAt(LocalDateTime date)  { this.expireAt = date; }
    public void setUtilise(boolean utilise)      { this.utilise = utilise; }
    public void setCreatedAt(LocalDateTime date) { this.createdAt = date; }
}