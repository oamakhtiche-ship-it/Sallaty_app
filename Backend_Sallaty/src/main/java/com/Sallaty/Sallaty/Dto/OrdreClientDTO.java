package com.Sallaty.Sallaty.Dto;

public class OrdreClientDTO {

    private int    ordreId;
    private int    clientId;
    private String clientFirstName;
    private String clientSurname;
    private String clientProfileImage;
    private int    quantity;
    private double totalPrice;
    private String status;

    // ═══════════════════════════════════════════════
    //  CONSTRUCTORS
    // ═══════════════════════════════════════════════
    public OrdreClientDTO(int ordreId, int clientId,
                          String clientFirstName,
                          String clientSurname,
                          String clientProfileImage,
                          int quantity,
                          double totalPrice,
                          String status) {
        this.ordreId            = ordreId;
        this.clientId           = clientId;
        this.clientFirstName    = clientFirstName;
        this.clientSurname      = clientSurname;
        this.clientProfileImage = clientProfileImage;
        this.quantity           = quantity;
        this.totalPrice         = totalPrice;
        this.status             = status;
    }

    public OrdreClientDTO() {}

    // GETTERS
    public int    getOrdreId()            { return ordreId; }
    public int    getClientId()           { return clientId; }
    public String getClientFirstName()    { return clientFirstName; }
    public String getClientSurname()      { return clientSurname; }
    public String getClientProfileImage() { return clientProfileImage; }
    public int    getQuantity()           { return quantity; }
    public double getTotalPrice()         { return totalPrice; }
    public String getStatus()             { return status; }

    // SETTERS
    public void setOrdreId(int ordreId)                        { this.ordreId = ordreId; }
    public void setClientId(int clientId)                      { this.clientId = clientId; }
    public void setClientFirstName(String clientFirstName)     { this.clientFirstName = clientFirstName; }
    public void setClientSurname(String clientSurname)         { this.clientSurname = clientSurname; }
    public void setClientProfileImage(String clientProfileImage){ this.clientProfileImage = clientProfileImage; }
    public void setQuantity(int quantity)                      { this.quantity = quantity; }
    public void setTotalPrice(double totalPrice)               { this.totalPrice = totalPrice; }
    public void setStatus(String status)                       { this.status = status; }
}