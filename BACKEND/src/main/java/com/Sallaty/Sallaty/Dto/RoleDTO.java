package com.Sallaty.Sallaty.Dto;

import java.time.LocalDateTime;

public class RoleDTO {

    // ═══════════════════════════════════════════════
    //  FIELDS
    // ═══════════════════════════════════════════════
    private int           id;
    private int           iduser;
    private String        rolename;
    private LocalDateTime createat;
    private LocalDateTime updatedAsMarchand;  // ➕
    private LocalDateTime updatedAsClient;    // ➕

    // ═══════════════════════════════════════════════
    //  CONSTRUCTORS
    // ═══════════════════════════════════════════════
    public RoleDTO() {}

    public RoleDTO(
            int id,
            int iduser,
            String rolename,
            LocalDateTime createat,
            LocalDateTime updatedAsMarchand,
            LocalDateTime updatedAsClient) {

        this.id                = id;
        this.iduser            = iduser;
        this.rolename          = rolename;
        this.createat          = createat;
        this.updatedAsMarchand = updatedAsMarchand;
        this.updatedAsClient   = updatedAsClient;
    }

    // ═══════════════════════════════════════════════
    //  GETTERS
    // ═══════════════════════════════════════════════
    public int           getId()                { return id; }
    public int           getIduser()            { return iduser; }
    public String        getRolename()          { return rolename; }
    public LocalDateTime getCreateat()          { return createat; }
    public LocalDateTime getUpdatedAsMarchand() { return updatedAsMarchand; }
    public LocalDateTime getUpdatedAsClient()   { return updatedAsClient; }

    // ═══════════════════════════════════════════════
    //  SETTERS
    // ═══════════════════════════════════════════════
    public void setId(int id)                                        { this.id = id; }
    public void setIduser(int iduser)                                { this.iduser = iduser; }
    public void setRolename(String rolename)                         { this.rolename = rolename; }
    public void setCreateat(LocalDateTime createat)                  { this.createat = createat; }
    public void setUpdatedAsMarchand(LocalDateTime updatedAsMarchand){ this.updatedAsMarchand = updatedAsMarchand; }
    public void setUpdatedAsClient(LocalDateTime updatedAsClient)    { this.updatedAsClient = updatedAsClient; }
}