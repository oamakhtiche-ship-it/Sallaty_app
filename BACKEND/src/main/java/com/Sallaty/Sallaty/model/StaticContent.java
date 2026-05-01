package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;

@Entity
@Table(name = "static_content")
public class StaticContent {

    // TYPES : PRIVACY_POLICY | ABOUT | TERMS_CONDITIONS
    // (HELP supprimé → remplacé par FaqItem)

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "type", unique = true)
    private String type;

    @Column(name = "content", columnDefinition = "TEXT")
    private String content;

    public StaticContent() {}

    public StaticContent(String type, String content) {
        this.type    = type;
        this.content = content;
    }

    public int    getId()      { return id; }
    public String getType()    { return type; }
    public String getContent() { return content; }

    public void setId(int id)              { this.id = id; }
    public void setType(String type)       { this.type = type; }
    public void setContent(String content) { this.content = content; }
}