package com.Sallaty.Sallaty.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "roles")
public class Role {

    public static final String ADMIN    = "ADMIN";
    public static final String MARCHANT = "MARCHANT";
    public static final String CLIENT   = "CLIENT";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "iduser")           // ✅ corrigé
    private int iduser;

    @Column(name = "rolename")         // ✅ corrigé
    private String rolename;

    @Column(name = "createat")         // ✅ corrigé
    private LocalDateTime createat;

    @Column(name = "updated_as_marchand")
    private LocalDateTime updatedAsMarchand;

    @Column(name = "updated_as_client")
    private LocalDateTime updatedAsClient;

    @PrePersist
    public void prePersist() {
        if (createat == null)
            createat = LocalDateTime.now();
    }

    public Role() {}

    public Role(int id, int iduser,
                String rolename,
                LocalDateTime createat) {
        this.id       = id;
        this.iduser   = iduser;
        this.rolename = rolename;
        this.createat = LocalDateTime.now();
    }

    public int           getId()                { return id; }
    public int           getIduser()            { return iduser; }
    public String        getRolename()          { return rolename; }
    public LocalDateTime getCreateat()          { return createat; }
    public LocalDateTime getUpdatedAsMarchand() { return updatedAsMarchand; }
    public LocalDateTime getUpdatedAsClient()   { return updatedAsClient; }

    public void setId(int id)                                         { this.id = id; }
    public void setIduser(int iduser)                                 { this.iduser = iduser; }
    public void setRolename(String rolename)                          { this.rolename = rolename; }
    public void setCreateat(LocalDateTime createat)                   { this.createat = createat; }
    public void setUpdatedAsMarchand(LocalDateTime updatedAsMarchand) { this.updatedAsMarchand = updatedAsMarchand; }
    public void setUpdatedAsClient(LocalDateTime updatedAsClient)     { this.updatedAsClient = updatedAsClient; }
}