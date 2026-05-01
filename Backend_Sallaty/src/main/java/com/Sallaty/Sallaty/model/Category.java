package com.Sallaty.Sallaty.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "categories")
public class Category {

    // ═══════════════════════════════
    // FIELDS
    // ═══════════════════════════════
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "name")
    private String name;

    @Column(name = "icon")
    private String icon;

    @Column(name = "description")
    private String description;

    // ═══════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════
    public Category(int id, String name, 
                    String icon, String description) {
        this.id          = id;
        this.name        = name;
        this.icon        = icon;
        this.description = description;
    }

    public Category() {}

    // ═══════════════════════════════
    // GETTERS
    // ═══════════════════════════════
    public int    getId()          { return id; }
    public String getName()        { return name; }
    public String getIcon()        { return icon; }
    public String getDescription() { return description; }

    // ═══════════════════════════════
    // SETTERS
    // ═══════════════════════════════
    public void setId(int id)                { this.id = id; }
    public void setName(String name)         { this.name = name; }
    public void setIcon(String icon)         { this.icon = icon; }
    public void setDescription(String desc)  { this.description = desc; }
}