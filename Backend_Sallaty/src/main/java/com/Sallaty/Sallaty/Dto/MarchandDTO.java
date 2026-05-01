package com.Sallaty.Sallaty.Dto;

import com.Sallaty.Sallaty.model.StatusMarchand;

public class MarchandDTO {

    private int            id;
    private String         fullName;
    private String         businessName;
    private String         businessType;
    private String         wilaya;
    private String         phoneNumber;
    private String         tradeRegister;
    private StatusMarchand statusMarchand;
    private double         revenue;
    private int            nbFollowers;

    public MarchandDTO() {}

    public int            getId()             { return id; }
    public String         getFullName()       { return fullName; }
    public String         getBusinessName()   { return businessName; }
    public String         getBusinessType()   { return businessType; }
    public String         getWilaya()         { return wilaya; }
    public String         getPhoneNumber()    { return phoneNumber; }
    public String         getTradeRegister()  { return tradeRegister; }
    public StatusMarchand getStatusMarchand() { return statusMarchand; }
    public double         getRevenue()        { return revenue; }
    public int            getNbFollowers()    { return nbFollowers; }


    public void setId(int id)                                    { this.id = id; }
    public void setFullName(String v)                            { this.fullName = v; }
    public void setBusinessName(String v)                        { this.businessName = v; }
    public void setBusinessType(String v)                        { this.businessType = v; }
    public void setWilaya(String v)                              { this.wilaya = v; }
    public void setPhoneNumber(String v)                         { this.phoneNumber = v; }
    public void setTradeRegister(String v)                       { this.tradeRegister = v; }
    public void setStatusMarchand(StatusMarchand statusMarchand) { this.statusMarchand = statusMarchand; }
    public void setRevenue(double v)                             { this.revenue = v; }
    public void setNbFollowers(int v)                            { this.nbFollowers = v; }

}