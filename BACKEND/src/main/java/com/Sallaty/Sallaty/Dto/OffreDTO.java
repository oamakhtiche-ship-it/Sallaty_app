package com.Sallaty.Sallaty.Dto;

import java.time.LocalDateTime;

import com.Sallaty.Sallaty.model.CategoryType;

public class OffreDTO {

    private int           id;
    private int           marchandId;
    private CategoryType  categoryType;  // ✅
    private String        title;
    private String        description;
    private double        price;
    private int           quantity;
    private String        wilaya;
    private String        status;
    private double        originalPrice;
    private double        discountPrice;
    private LocalDateTime expireAt;
    private int           nbReservations;
    private int           nbFavoris;
    private LocalDateTime createdAt;
    private String        photo;         // ✅ ajouté

    public OffreDTO() {}

    public OffreDTO(
            int id, int marchandId, CategoryType categoryType,
            String title, String description,
            double price, int quantity, String wilaya,
            String status, double originalPrice,
            double discountPrice, LocalDateTime expireAt,
            int nbReservations, int nbFavoris,
            LocalDateTime createdAt, String photo) {

        this.id             = id;
        this.marchandId     = marchandId;
        this.categoryType   = categoryType;
        this.title          = title;
        this.description    = description;
        this.price          = price;
        this.quantity       = quantity;
        this.wilaya         = wilaya;
        this.status         = status;
        this.originalPrice  = originalPrice;
        this.discountPrice  = discountPrice;
        this.expireAt       = expireAt;
        this.nbReservations = nbReservations;
        this.nbFavoris      = nbFavoris;
        this.createdAt      = createdAt;
        this.photo          = photo;
    }

    public int           getId()             { return id; }
    public int           getMarchandId()     { return marchandId; }
    public CategoryType  getCategoryType()   { return categoryType; }
    public String        getTitle()          { return title; }
    public String        getDescription()    { return description; }
    public double        getPrice()          { return price; }
    public int           getQuantity()       { return quantity; }
    public String        getWilaya()         { return wilaya; }
    public String        getStatus()         { return status; }
    public double        getOriginalPrice()  { return originalPrice; }
    public double        getDiscountPrice()  { return discountPrice; }
    public LocalDateTime getExpireAt()       { return expireAt; }
    public int           getNbReservations() { return nbReservations; }
    public int           getNbFavoris()      { return nbFavoris; }
    public LocalDateTime getCreatedAt()      { return createdAt; }
    public String        getPhoto()          { return photo; }

    public void setId(int id)                          { this.id = id; }
    public void setMarchandId(int marchandId)          { this.marchandId = marchandId; }
    public void setCategoryType(CategoryType c)        { this.categoryType = c; }
    public void setTitle(String title)                 { this.title = title; }
    public void setDescription(String description)     { this.description = description; }
    public void setPrice(double price)                 { this.price = price; }
    public void setQuantity(int quantity)              { this.quantity = quantity; }
    public void setWilaya(String wilaya)               { this.wilaya = wilaya; }
    public void setStatus(String status)               { this.status = status; }
    public void setOriginalPrice(double originalPrice) { this.originalPrice = originalPrice; }
    public void setDiscountPrice(double discountPrice) { this.discountPrice = discountPrice; }
    public void setExpireAt(LocalDateTime expireAt)    { this.expireAt = expireAt; }
    public void setNbReservations(int nb)              { this.nbReservations = nb; }
    public void setNbFavoris(int nbFavoris)            { this.nbFavoris = nbFavoris; }
    public void setCreatedAt(LocalDateTime createdAt)  { this.createdAt = createdAt; }
    public void setPhoto(String photo)                 { this.photo = photo; }
}