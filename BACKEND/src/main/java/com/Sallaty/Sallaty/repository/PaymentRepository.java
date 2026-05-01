package com.Sallaty.Sallaty.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.Payment;

@Repository
public interface PaymentRepository
    extends JpaRepository<Payment, Integer> {  // ✅ Long → Integer

    Optional<Payment> findByOrdreId(int ordreId);
    boolean existsByOrdreId(int ordreId);
}