package com.Sallaty.Sallaty.model;

import java.time.LocalDateTime;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

@Entity
@Table(name = "offres")
public class Offre {

    public static final String ACTIVE   = "ACTIVE";
    public static final String INACTIVE = "INACTIVE";
    public static final String ARCHIVED = "ARCHIVED";
    public static final String EXPIRED  = "EXPIRED";
    public static final String SOLD_OUT = "SOLD_OUT";
    public static final String RESERVED = "RESERVED";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "marchand_id")
    private int marchandId;

    // ✅ categoryType enum — plus de categoryId
    @Enumerated(EnumType.STRING)
    @Column(name = "category_type")
    private CategoryType categoryType;

    @Column(name = "title")
    private String title;

    @Column(name = "description")
    private String description;

    @Column(name = "price")
    private double price;

    @Column(name = "quantity")
    private int quantity;

    @Column(name = "wilaya")
    private String wilaya;

    @Column(name = "photo")
    private String photo;

    @Column(name = "status")
    private String status;

    @Column(name = "original_price")
    private double originalPrice;

    @Column(name = "discount_price")
    private double discountPrice;

    @Column(name = "expire_at")
    private LocalDateTime expireAt;

    @Column(name = "nb_reservations")
    private int nbReservations;

    @Column(name = "nb_favoris")
    private int nbFavoris = 0;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public Offre() {}

    public int           getId()             { return id; }
    public int           getMarchandId()     { return marchandId; }
    public CategoryType  getCategoryType()   { return categoryType; }
    public String        getTitle()          { return title; }
    public String        getDescription()    { return description; }
    public double        getPrice()          { return price; }
    public int           getQuantity()       { return quantity; }
    public String        getWilaya()         { return wilaya; }
    public String        getPhoto()          { return photo; }
    public String        getStatus()         { return status; }
    public double        getOriginalPrice()  { return originalPrice; }
    public double        getDiscountPrice()  { return discountPrice; }
    public LocalDateTime getExpireAt()       { return expireAt; }
    public int           getNbReservations() { return nbReservations; }
    public int           getNbFavoris()      { return nbFavoris; }
    public LocalDateTime getCreatedAt()      { return createdAt; }
    public LocalDateTime getUpdatedAt()      { return updatedAt; }

    public void setId(int id)                          { this.id = id; }
    public void setMarchandId(int marchandId)          { this.marchandId = marchandId; }
    public void setCategoryType(CategoryType c)        { this.categoryType = c; }
    public void setTitle(String title)                 { this.title = title; }
    public void setDescription(String description)     { this.description = description; }
    public void setPrice(double price)                 { this.price = price; }
    public void setQuantity(int quantity)              { this.quantity = quantity; }
    public void setWilaya(String wilaya)               { this.wilaya = wilaya; }
    public void setPhoto(String photo)                 { this.photo = photo; }
    public void setStatus(String status)               { this.status = status; }
    public void setOriginalPrice(double originalPrice) { this.originalPrice = originalPrice; }
    public void setDiscountPrice(double discountPrice) { this.discountPrice = discountPrice; }
    public void setExpireAt(LocalDateTime expireAt)    { this.expireAt = expireAt; }
    public void setNbReservations(int nb)              { this.nbReservations = nb; }
    public void setNbFavoris(int nbFavoris)            { this.nbFavoris = nbFavoris; }
    public void setCreatedAt(LocalDateTime createdAt)  { this.createdAt = createdAt; }
    public void setUpdatedAt(LocalDateTime updatedAt)  { this.updatedAt = updatedAt; }
}