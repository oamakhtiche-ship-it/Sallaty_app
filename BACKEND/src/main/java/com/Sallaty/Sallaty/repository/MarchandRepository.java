package com.Sallaty.Sallaty.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.Marchand;

@Repository
public interface MarchandRepository extends JpaRepository<Marchand, Integer> {

    boolean existsByBusinessName(String businessName);

    @Query(value = "SELECT COUNT(*) FROM marchands WHERE user_id = :userId", nativeQuery = true)
    int countByUserId(@Param("userId") int userId);

    @Query(value = "SELECT COUNT(*) FROM marchands WHERE user_id = :userId AND status_marchand = :status", nativeQuery = true)
    int countByUserIdAndStatus(@Param("userId") int userId, @Param("status") String status);

    @Query(value =
        "SELECT m.*, u.* FROM marchands m " +
        "JOIN users u ON u.id = m.user_id " +
        "WHERE m.status_marchand = 'PENDING'", nativeQuery = true)
    List<Marchand> findPending();

    @Query(value =
        "SELECT m.*, u.* FROM marchands m " +
        "JOIN users u ON u.id = m.user_id " +
        "WHERE m.status_marchand = 'VERIFIED'", nativeQuery = true)
    List<Marchand> findVerified();

    @Query(value =
        "SELECT m.*, u.* FROM marchands m " +
        "JOIN users u ON u.id = m.user_id " +
        "WHERE m.status_marchand = 'CANCELLED'", nativeQuery = true)
    List<Marchand> findCancelled();

    @Query(value =
        "SELECT m.*, u.* FROM marchands m " +
        "JOIN users u ON u.id = m.user_id " +
        "WHERE m.status_marchand = :status", nativeQuery = true)
    List<Marchand> findByStatusMarchand(@Param("status") String status);
}