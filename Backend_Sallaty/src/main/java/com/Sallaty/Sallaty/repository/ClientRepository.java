package com.Sallaty.Sallaty.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.Client;

@Repository
public interface ClientRepository extends JpaRepository<Client, Integer> {

    // ✅ native query — évite le cast JPA
    @Query(value = "SELECT * FROM users u JOIN clients c ON u.id = c.user_id WHERE c.user_id = :contact", nativeQuery = true)
    Optional<Client> findByContact(@Param("contact") String contact);

    @Query(value = "SELECT COUNT(*) > 0 FROM clients c JOIN users u ON u.id = c.user_id WHERE u.contact = :contact", nativeQuery = true)
    boolean existsByContact(@Param("contact") String contact);

    // ✅ compte direct dans table clients
    @Query(value = "SELECT COUNT(*) FROM clients WHERE user_id = :userId", nativeQuery = true)
    int countByUserId(@Param("userId") int userId);
}