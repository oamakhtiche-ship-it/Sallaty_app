package com.Sallaty.Sallaty.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional; // Ajouté pour gérer les transactions

import com.Sallaty.Sallaty.model.User;

@Repository
@Transactional // ✅ Indispensable pour que les méthodes @Modifying fonctionnent
public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByContact(String contact);
    
    boolean existsByContact(String contact);
    
    List<User> findByAccountState(String accountState);
    
    List<User> findByAccountType(String accountType);
    
    long countByAccountState(String accountState);

    // ✅ Native query
    @Query(value = "SELECT * FROM users WHERE id = :id", nativeQuery = true)
    Optional<User> findUserByIdJpql(@Param("id") int id);

    @Modifying
    @Query("UPDATE User u SET u.balance = u.balance + :amount WHERE u.id = :userId")
    void topUpBalance(@Param("userId") int userId, @Param("amount") double amount);

    @Modifying
    @Query("UPDATE User u SET u.balance = u.balance - :amount WHERE u.id = :userId AND u.balance >= :amount")
    int deductBalance(@Param("userId") int userId, @Param("amount") double amount);

    @Modifying
    @Query("UPDATE User u SET u.deviceToken = :token WHERE u.id = :userId")
    void updateDeviceToken(@Param("userId") int userId, @Param("token") String token);

    @Modifying
    @Query("UPDATE User u SET u.accountState = :state WHERE u.id = :userId")
    void updateAccountState(@Param("userId") int userId, @Param("state") String state);

    @Query("SELECT COUNT(u) FROM User u")
    long countTotalUsers();
}