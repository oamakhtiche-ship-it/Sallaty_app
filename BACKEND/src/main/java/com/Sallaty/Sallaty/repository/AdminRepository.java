package com.Sallaty.Sallaty.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.Admin;

@Repository
public interface AdminRepository
        extends JpaRepository<Admin, Integer> {

    default Optional<Admin> findByUserId(int userId) {
        return findById(userId);
    }

    default boolean existsByUserId(int userId) {
        return existsById(userId);
    }

    List<Admin> findByRoleadmin(String roleadmin);

    @Query(value =
        "SELECT a.user_id, u.first_name, u.surname, " +
        "u.contact AS email, u.profile_image, " +
        "a.roleadmin, a.permissions " +
        "FROM admins a " +
        "JOIN users u ON u.id = a.user_id",
        nativeQuery = true)
    List<Object[]> findAllWithUserInfo();
}