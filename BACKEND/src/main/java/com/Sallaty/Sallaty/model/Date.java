package com.Sallaty.Sallaty.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Date {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    int day;
    int month;
    int year;

    // Constructeur vide obligatoire pour Spring Boot !
    public Date() {}

    // Constructeur avec paramètres
    public Date(int day, int month, int year) {
        this.day   = day;
        this.month = month;
        this.year  = year;
    }

    public int getDay()   { return day; }
    public int getMonth() { return month; }
    public int getYear()  { return year; }
}

