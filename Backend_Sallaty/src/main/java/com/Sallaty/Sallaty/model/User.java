package com.Sallaty.Sallaty.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

@Entity
@Table(name = "users")
@Inheritance(strategy = InheritanceType.JOINED)
public class User {

    public static final String ACTIVE       = "ACTIVE";
    public static final String BLOCKED      = "BLOCKED";
    public static final String NOT_VERIFIED = "NOT_VERIFIED";

    public static final String phoneext = "phone";
    public static final String emailext = "email";
    public static final String gmailext = "gmail";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private int id;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "surname")
    private String surname;

    @Column(name = "contact", unique = true)
    private String contact;

    @Column(name = "passe_word")
    private String passeWord;

    @Column(name = "profile_image")
    private String profileImage;

    @Column(name = "account_type")
    private String accountType;

    @Column(name = "account_state")
    private String accountState;

    @Column(name = "device_token")
    private String deviceToken;

    @Column(name = "nb_offer")
    private int nbOffer;

    @Column(name = "nb_order")
    private int nbOrder;

    @Column(name = "date_time")
    private LocalDateTime dateTime;

    @Column(name = "balance")
    private double balance;

    @Column(name = "wilaya")
    private String wilaya;

    // ✅ ajouté — pour le filtre distance (search)
    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    // ✅ ajouté — pour admin getUserManagement()
    @Column(name = "is_blocked")
    private boolean isBlocked = false;

    // ✅ ajouté — pour admin getUserProfile()
    @Column(name = "last_connection")
    private LocalDateTime lastConnection;

    // ✅ ajouté — pour admin getUserProfile()
    @Column(name = "phone_number")
    private String phoneNumber;

    // ✅ ajouté — pour admin getUserProfile()
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Transient
    private Role role;

    public User() {}

    public int           getId()             { return id; }
    public String        getFirstName()      { return firstName; }
    public String        getSurname()        { return surname; }
    public String        getContact()        { return contact; }
    public String        getPasseWord()      { return passeWord; }
    public String        getProfileImage()   { return profileImage; }
    public String        getAccountType()    { return accountType; }
    public String        getAccountState()   { return accountState; }
    public String        getDeviceToken()    { return deviceToken; }
    public int           getNbOffer()        { return nbOffer; }
    public int           getNbOrder()        { return nbOrder; }
    public LocalDateTime getDateTime()       { return dateTime; }
    public double        getBalance()        { return balance; }
    public String        getWilaya()         { return wilaya; }
    public Double        getLatitude()       { return latitude; }
    public Double        getLongitude()      { return longitude; }
    public boolean       isBlocked()         { return isBlocked; }
    public LocalDateTime getLastConnection() { return lastConnection; }
    public String        getPhoneNumber()    { return phoneNumber; }
    public LocalDateTime getCreatedAt()      { return createdAt; }
    public Role          getRole()           { return role; }

    public void setId(int id)                              { this.id = id; }
    public void setFirstName(String firstName)             { this.firstName = firstName; }
    public void setSurname(String surname)                 { this.surname = surname; }
    public void setContact(String contact)                 { this.contact = contact; }
    public void setPasseWord(String passeWord)             { this.passeWord = passeWord; }
    public void setProfileImage(String profileImage)       { this.profileImage = profileImage; }
    public void setAccountType(String accountType)         { this.accountType = accountType; }
    public void setAccountState(String accountState)       { this.accountState = accountState; }
    public void setDeviceToken(String deviceToken)         { this.deviceToken = deviceToken; }
    public void setNbOffer(int nbOffer)                    { this.nbOffer = nbOffer; }
    public void setNbOrder(int nbOrder)                    { this.nbOrder = nbOrder; }
    public void setDateTime(LocalDateTime dateTime)        { this.dateTime = dateTime; }
    public void setBalance(double balance)                 { this.balance = balance; }
    public void setWilaya(String wilaya)                   { this.wilaya = wilaya; }
    public void setLatitude(Double latitude)               { this.latitude = latitude; }
    public void setLongitude(Double longitude)             { this.longitude = longitude; }
    public void setBlocked(boolean isBlocked)              { this.isBlocked = isBlocked; }
    public void setLastConnection(LocalDateTime v)         { this.lastConnection = v; }
    public void setPhoneNumber(String phoneNumber)         { this.phoneNumber = phoneNumber; }
    public void setCreatedAt(LocalDateTime createdAt)      { this.createdAt = createdAt; }
    public void setRole(Role role)                         { this.role = role; }
}