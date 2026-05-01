package com.Sallaty.Sallaty.Dto;

public class MarchandSearchDTO {

    private int    userId;
    private String businessName;
    private String fullName;
    private String profileImage;
    private String businessType;
    private String wilaya;
    private int    nbFollowers;
    private String statusMarchand;
    private int    nbOffres;

    public MarchandSearchDTO() {}

    public MarchandSearchDTO(
            int userId,
            String businessName,
            String fullName,
            String profileImage,
            String businessType,
            String wilaya,
            int nbFollowers,
            String statusMarchand,
            int nbOffres) {

        this.userId         = userId;
        this.businessName   = businessName;
        this.fullName       = fullName;
        this.profileImage   = profileImage;
        this.businessType   = businessType;
        this.wilaya         = wilaya;
        this.nbFollowers    = nbFollowers;
        this.statusMarchand = statusMarchand;
        this.nbOffres       = nbOffres;
    }

    public int    getUserId()         { return userId; }
    public String getBusinessName()   { return businessName; }
    public String getFullName()       { return fullName; }
    public String getProfileImage()   { return profileImage; }
    public String getBusinessType()   { return businessType; }
    public String getWilaya()         { return wilaya; }
    public int    getNbFollowers()    { return nbFollowers; }
    public String getStatusMarchand() { return statusMarchand; }
    public int    getNbOffres()       { return nbOffres; }

    public void setUserId(int v)            { this.userId = v; }
    public void setBusinessName(String v)   { this.businessName = v; }
    public void setFullName(String v)       { this.fullName = v; }
    public void setProfileImage(String v)   { this.profileImage = v; }
    public void setBusinessType(String v)   { this.businessType = v; }
    public void setWilaya(String v)         { this.wilaya = v; }
    public void setNbFollowers(int v)       { this.nbFollowers = v; }
    public void setStatusMarchand(String v) { this.statusMarchand = v; }
    public void setNbOffres(int v)          { this.nbOffres = v; }
}