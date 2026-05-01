package com.Sallaty.Sallaty.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.model.Role;

@Repository
public interface RoleRepository
        extends JpaRepository<Role, Integer> {

    // ✅ Retourne TOUS les rôles
    List<Role> findAllByIduser(int iduser);

    Optional<Role> findByIduser(int iduser);

    boolean existsByIduser(int iduser);

    boolean existsByIduserAndRolename(
        int iduser, String rolename);

    @Modifying
    @Transactional
    void deleteByIduser(int iduser);
}