package com.Sallaty.Sallaty.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.Dto.ClientDTO;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class ClientService {

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  HELPER — get client row
    // ═══════════════════════════════════════════════
    private Object[] getClientRow(int clientId) {
        try {
            return (Object[]) entityManager
                .createNativeQuery(
                    "SELECT u.id, u.first_name, u.surname, " +
                    "u.contact, u.profile_image, u.account_state, " +
                    "c.nb_reservations, c.nb_cancellations, c.total_spent " +
                    "FROM users u " +
                    "JOIN clients c ON u.id = c.user_id " +
                    "WHERE c.user_id = :id")
                .setParameter("id", clientId)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════
    //  getClientById()
    // ═══════════════════════════════════════════════
    public ClientDTO getClientById(int clientId) {
        Object[] row = getClientRow(clientId);
        if (row == null)
            throw new RuntimeException("Client not found !");
        return rowToDTO(row);
    }

    // ═══════════════════════════════════════════════
    //  updateNbReservations()
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateNbReservations(int clientId) {
        if (getClientRow(clientId) == null)
            throw new RuntimeException("Client not found !");

        entityManager.createNativeQuery(
            "UPDATE clients SET nb_reservations = " +
            "nb_reservations + 1 WHERE user_id = :id")
            .setParameter("id", clientId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  updateNbCancellations()
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateNbCancellations(int clientId) {
        if (getClientRow(clientId) == null)
            throw new RuntimeException("Client not found !");

        entityManager.createNativeQuery(
            "UPDATE clients SET nb_cancellations = " +
            "nb_cancellations + 1 WHERE user_id = :id")
            .setParameter("id", clientId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  updateTotalSpent()
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateTotalSpent(int clientId, double amount) {
        if (amount <= 0)
            throw new IllegalArgumentException(" invalide Montant !");

        if (getClientRow(clientId) == null)
            throw new RuntimeException("Client not found !");

        entityManager.createNativeQuery(
            "UPDATE clients SET total_spent = " +
            "total_spent + :amount WHERE user_id = :id")
            .setParameter("amount", amount)
            .setParameter("id", clientId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  rowToDTO()
    // ═══════════════════════════════════════════════
    private ClientDTO rowToDTO(Object[] row) {
        return new ClientDTO(
            ((Number) row[0]).intValue(),
            (String) row[1],
            (String) row[2],
            (String) row[3],
            (String) row[4],
            (String) row[5],
            row[6] != null ? ((Number) row[6]).intValue() : 0,
            row[7] != null ? ((Number) row[7]).intValue() : 0,
            row[8] != null ? ((Number) row[8]).doubleValue() : 0.0);
    }
}