package com.Sallaty.Sallaty.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.model.Otpcode;

@Repository
public interface OtpcodeRepository
        extends JpaRepository<Otpcode, Integer> {

    Optional<Otpcode> findByUserId(int userId);

    Optional<Otpcode> findByCode(String code);

    @Modifying
    @Transactional  // ✅ ajouté
    @Query("DELETE FROM Otpcode o WHERE o.userId = :userId")
    void deleteByUserId(@Param("userId") int userId);
}