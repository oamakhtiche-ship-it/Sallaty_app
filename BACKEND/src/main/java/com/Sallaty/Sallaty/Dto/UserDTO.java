package com.Sallaty.Sallaty.Dto;

import java.time.LocalDateTime;

public class UserDTO {

    private int           id;
    private String        firstName;
    private String        surname;
    private String        contact;
    private String        profileImage;
    private String        accountState;
    private String        accountType;
    private int           nbOffer;
    private int           nbOrder;
    private LocalDateTime dateTime;
    private double        balance;
    private String        wilaya;      // ➕
    private String        token;

    public UserDTO() {}

    public UserDTO(
            int id,
            String firstName,
            String surname,
            String contact,
            String profileImage,
            String accountState,
            String accountType,
            int nbOffer,
            int nbOrder,
            LocalDateTime dateTime,
            double balance,
            String wilaya,
            String token) {

        this.id           = id;
        this.firstName    = firstName;
        this.surname      = surname;
        this.contact      = contact;
        this.profileImage = profileImage;
        this.accountState = accountState;
        this.accountType  = accountType;
        this.nbOffer      = nbOffer;
        this.nbOrder      = nbOrder;
        this.dateTime     = dateTime;
        this.balance      = balance;
        this.wilaya       = wilaya;
        this.token        = token;
    }

    public int           getId()           { return id; }
    public String        getFirstName()    { return firstName; }
    public String        getSurname()      { return surname; }
    public String        getContact()      { return contact; }
    public String        getProfileImage() { return profileImage; }
    public String        getAccountState() { return accountState; }
    public String        getAccountType()  { return accountType; }
    public int           getNbOffer()      { return nbOffer; }
    public int           getNbOrder()      { return nbOrder; }
    public LocalDateTime getDateTime()     { return dateTime; }
    public double        getBalance()      { return balance; }
    public String        getWilaya()       { return wilaya; }
    public String        getToken()        { return token; }

    public void setId(int id)                        { this.id = id; }
    public void setFirstName(String firstName)       { this.firstName = firstName; }
    public void setSurname(String surname)           { this.surname = surname; }
    public void setContact(String contact)           { this.contact = contact; }
    public void setProfileImage(String profileImage) { this.profileImage = profileImage; }
    public void setAccountState(String accountState) { this.accountState = accountState; }
    public void setAccountType(String accountType)   { this.accountType = accountType; }
    public void setNbOffer(int nbOffer)              { this.nbOffer = nbOffer; }
    public void setNbOrder(int nbOrder)              { this.nbOrder = nbOrder; }
    public void setDateTime(LocalDateTime dateTime)  { this.dateTime = dateTime; }
    public void setBalance(double balance)           { this.balance = balance; }
    public void setWilaya(String wilaya)             { this.wilaya = wilaya; }
    public void setToken(String token)               { this.token = token; }
}