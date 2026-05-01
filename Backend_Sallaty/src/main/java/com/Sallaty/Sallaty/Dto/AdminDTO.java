package com.Sallaty.Sallaty.Dto;

public class AdminDTO {

    private int    userId;
    private String firstName;
    private String lastName;
    private String email;
    private String profileImage;
    private String roleadmin;
    private String permissions;

    public AdminDTO() {}

    public AdminDTO(int userId, String firstName,
                    String lastName, String email,
                    String profileImage, String roleadmin,
                    String permissions) {
        this.userId       = userId;
        this.firstName    = firstName;
        this.lastName     = lastName;
        this.email        = email;
        this.profileImage = profileImage;
        this.roleadmin         = roleadmin;
        this.permissions  = permissions;
    }

    public int    getUserId()      { return userId; }
    public String getFirstName()   { return firstName; }
    public String getLastName()    { return lastName; }
    public String getEmail()       { return email; }
    public String getProfileImage(){ return profileImage; }
    public String getRoleadmin()        { return roleadmin; }
    public String getPermissions() { return permissions; }

    public void setUserId(int v)          { this.userId = v; }
    public void setFirstName(String v)    { this.firstName = v; }
    public void setLastName(String v)     { this.lastName = v; }
    public void setEmail(String v)        { this.email = v; }
    public void setProfileImage(String v) { this.profileImage = v; }
    public void setRoleadmin(String v)         { this.roleadmin = v; }
    public void setPermissions(String v)  { this.permissions = v; }
}