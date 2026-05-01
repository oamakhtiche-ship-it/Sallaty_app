package com.Sallaty.Sallaty.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.PrimaryKeyJoinColumn;
import jakarta.persistence.Table;

@Entity
@Table(name = "clients")
@PrimaryKeyJoinColumn(name = "user_id")  // ✅ user_id comme dans la DB
public class Client extends User {

    @Column(name = "nb_reservations")
    private int nbReservations;

    @Column(name = "nb_cancellations")
    private int nbCancellations;

    @Column(name = "total_spent")
    private double totalSpent;

    public Client() {}

    public int    getNbReservations()     { return nbReservations; }
    public int    getNbCancellations()    { return nbCancellations; }
    public double getTotalSpent()         { return totalSpent; }

    public void setNbReservations(int v)  { this.nbReservations = v; }
    public void setNbCancellations(int v) { this.nbCancellations = v; }
    public void setTotalSpent(double v)   { this.totalSpent = v; }
}