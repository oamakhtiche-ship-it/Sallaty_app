package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;

@Entity
@Table(name = "admins")
@PrimaryKeyJoinColumn(name = "user_id")
public class Admin extends User {

    // SUPER_ADMIN ou NORMAL_ADMIN
    @Column(name = "roleadmin")
    private String roleadmin;

    // JSON string : ["USERS","MERCHANTS","OFFERS","ORDERS"]
    @Column(name = "permissions",
            columnDefinition = "TEXT")
    private String permissions;

    public Admin() {}

    public Admin(String roleadmin, String permissions) {
        this.roleadmin        = roleadmin;
        this.permissions = permissions;
    }

    public String getroleadmin()        { return roleadmin; }
    public String getPermissions() { return permissions; }

    public void setroleadmin(String roleadmin)        { this.roleadmin = roleadmin; }
    public void setPermissions(String v)    { this.permissions = v; }
}