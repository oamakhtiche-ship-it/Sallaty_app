package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;

@Entity
@Table(name = "user_settings")
public class UserSettings {

    // ═══════════════════════════════════════════════
    //  ID = userId (relation 1-1 avec User)
    // ═══════════════════════════════════════════════
    @Id
    @Column(name = "user_id")
    private int userId;

    // ═══════════════════════════════════════════════
    //  COMMON
    // ═══════════════════════════════════════════════
    @Column(name = "general_notification")
    private boolean generalNotification = true;

    @Column(name = "sound")
    private boolean sound = true;

    @Column(name = "vibrate")
    private boolean vibrate = true;

    // ═══════════════════════════════════════════════
    //  ORDERS
    // ═══════════════════════════════════════════════
    @Column(name = "order_confirmed")
    private boolean orderConfirmed = true;

    @Column(name = "order_cancelled")
    private boolean orderCancelled = true;

    @Column(name = "order_completed")
    private boolean orderCompleted = true;

    @Column(name = "payment_success")
    private boolean paymentSuccess = true;

    // ═══════════════════════════════════════════════
    //  PROMOTIONS
    // ═══════════════════════════════════════════════
    @Column(name = "new_discount")
    private boolean newDiscount = true;

    @Column(name = "expiring_offer")
    private boolean expiringOffer = true;

    @Column(name = "new_offer_nearby")
    private boolean newOfferNearby = true;

    // ═══════════════════════════════════════════════
    //  OTHERS
    // ═══════════════════════════════════════════════
    @Column(name = "broadcast_message")
    private boolean broadcastMessage = true;

    @Column(name = "marchand_verified")
    private boolean marchandVerified = true;

    // ═══════════════════════════════════════════════
    //  LANGUAGE
    // ═══════════════════════════════════════════════
    @Column(name = "language")
    private String language = "FR";

    // ═══════════════════════════════════════════════
    //  CONSTRUCTORS
    // ═══════════════════════════════════════════════
    public UserSettings() {}

    public UserSettings(int userId) {
        this.userId = userId;
    }

    // ═══════════════════════════════════════════════
    //  GETTERS
    // ═══════════════════════════════════════════════
    public int     getUserId()            { return userId; }
    public boolean isGeneralNotification(){ return generalNotification; }
    public boolean isSound()              { return sound; }
    public boolean isVibrate()            { return vibrate; }
    public boolean isOrderConfirmed()     { return orderConfirmed; }
    public boolean isOrderCancelled()     { return orderCancelled; }
    public boolean isOrderCompleted()     { return orderCompleted; }
    public boolean isPaymentSuccess()     { return paymentSuccess; }
    public boolean isNewDiscount()        { return newDiscount; }
    public boolean isExpiringOffer()      { return expiringOffer; }
    public boolean isNewOfferNearby()     { return newOfferNearby; }
    public boolean isBroadcastMessage()   { return broadcastMessage; }
    public boolean isMarchandVerified()   { return marchandVerified; }
    public String  getLanguage()          { return language; }

    // ═══════════════════════════════════════════════
    //  SETTERS
    // ═══════════════════════════════════════════════
    public void setUserId(int userId)                        { this.userId = userId; }
    public void setGeneralNotification(boolean v)            { this.generalNotification = v; }
    public void setSound(boolean v)                          { this.sound = v; }
    public void setVibrate(boolean v)                        { this.vibrate = v; }
    public void setOrderConfirmed(boolean v)                 { this.orderConfirmed = v; }
    public void setOrderCancelled(boolean v)                 { this.orderCancelled = v; }
    public void setOrderCompleted(boolean v)                 { this.orderCompleted = v; }
    public void setPaymentSuccess(boolean v)                 { this.paymentSuccess = v; }
    public void setNewDiscount(boolean v)                    { this.newDiscount = v; }
    public void setExpiringOffer(boolean v)                  { this.expiringOffer = v; }
    public void setNewOfferNearby(boolean v)                 { this.newOfferNearby = v; }
    public void setBroadcastMessage(boolean v)               { this.broadcastMessage = v; }
    public void setMarchandVerified(boolean v)               { this.marchandVerified = v; }
    public void setLanguage(String language)                 { this.language = language; }
}