package com.Sallaty.Sallaty.Dto;

public class ClientDTO {

    private int    id;
    private String firstName;
    private String surname;
    private String contact;
    private String profileImage;
    private String accountState;
    private int    nbReservations;
    private int    nbCancellations;
    private double totalSpent;

    public ClientDTO(int id, String firstName,
                     String surname, String contact,
                     String profileImage,
                     String accountState,
                     int nbReservations,
                     int nbCancellations,
                     double totalSpent) {
        this.id              = id;
        this.firstName       = firstName;
        this.surname         = surname;
        this.contact         = contact;
        this.profileImage    = profileImage;
        this.accountState    = accountState;
        this.nbReservations  = nbReservations;
        this.nbCancellations = nbCancellations;
        this.totalSpent      = totalSpent;
    }

    public ClientDTO() {}

    // GETTERS
    public int    getId()               { return id; }
    public String getFirstName()        { return firstName; }
    public String getSurname()          { return surname; }
    public String getContact()          { return contact; }
    public String getProfileImage()     { return profileImage; }
    public String getAccountState()     { return accountState; }
    public int    getNbReservations()   { return nbReservations; }
    public int    getNbCancellations()  { return nbCancellations; }
    public double getTotalSpent()       { return totalSpent; }

    // SETTERS
    public void setId(int id)                            { this.id = id; }
    public void setFirstName(String firstName)           { this.firstName = firstName; }
    public void setSurname(String surname)               { this.surname = surname; }
    public void setContact(String contact)               { this.contact = contact; }
    public void setProfileImage(String profileImage)     { this.profileImage = profileImage; }
    public void setAccountState(String accountState)     { this.accountState = accountState; }
    public void setNbReservations(int nbReservations)    { this.nbReservations = nbReservations; }
    public void setNbCancellations(int nbCancellations)  { this.nbCancellations = nbCancellations; }
    public void setTotalSpent(double totalSpent)         { this.totalSpent = totalSpent; }
}