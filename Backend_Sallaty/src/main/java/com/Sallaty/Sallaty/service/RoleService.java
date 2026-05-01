package com.Sallaty.Sallaty.service;

import java.time.LocalDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.Sallaty.Sallaty.Dto.RoleDTO;
import com.Sallaty.Sallaty.model.Role;
import com.Sallaty.Sallaty.repository.RoleRepository;

@Service
public class RoleService {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private RoleRepository roleRepository;

    // ═══════════════════════════════════════════════
    //  assignRole()
    // ═══════════════════════════════════════════════
    public void assignRole(int iduser, String rolename) {


        // 2. Vérifier rôle valide
        if (!isValidRole(rolename))
            throw new IllegalArgumentException(
                "Rôle invalide : " + rolename);

        // 3. Créer le rôle
        Role role = new Role();
        role.setIduser(iduser);
        role.setRolename(rolename);
        role.setCreateat(LocalDateTime.now());

        roleRepository.save(role);
    }

    // ═══════════════════════════════════════════════
    //  updateRole()
    // ═══════════════════════════════════════════════
    public void updateRole(int iduser, String newRole) {

        // 1. Vérifier rôle valide
        if (!isValidRole(newRole))
            throw new IllegalArgumentException(
                "Rôle invalide : " + newRole);

        // 2. Récupérer le rôle
        Role role = roleRepository
            .findByIduser(iduser)
            .orElseThrow(() ->
                new RuntimeException(
                    "Role non trouvé !"));

        // 3. Mettre à jour rolename
        role.setRolename(newRole);

        // 4. ➕ Timestamp selon rôle
        if (newRole.equals(Role.MARCHANT))
            role.setUpdatedAsMarchand(
                LocalDateTime.now());

        if (newRole.equals(Role.CLIENT))
            role.setUpdatedAsClient(
                LocalDateTime.now());

        roleRepository.save(role);
    }

    // ═══════════════════════════════════════════════
    //  getRoleById()
    // ═══════════════════════════════════════════════
    public Role getRoleById(int roleId) {
        return roleRepository.findById(roleId)
            .orElseThrow(() ->
                new RuntimeException(
                    "Role non trouvé !"));
    }

    // ═══════════════════════════════════════════════
    //  getRoleByUser()
    // ═══════════════════════════════════════════════
    public RoleDTO getRoleByUser(int iduser) {
        Role role = roleRepository
            .findByIduser(iduser)
            .orElseThrow(() ->
                new RuntimeException(
                    "Role non trouvé !"));
        return convertToDTO(role);
    }

    // ═══════════════════════════════════════════════
    //  isMarchand()
    // ═══════════════════════════════════════════════
    public boolean isMarchand(int iduser) {
        return roleRepository
            .existsByIduserAndRolename(
                iduser, Role.MARCHANT);
    }

    // ═══════════════════════════════════════════════
    //  isClient()
    // ═══════════════════════════════════════════════
    public boolean isClient(int iduser) {
        return roleRepository
            .existsByIduserAndRolename(
                iduser, Role.CLIENT);
    }

    // ═══════════════════════════════════════════════
    //  isAdmin()
    // ═══════════════════════════════════════════════
    public boolean isAdmin(int iduser) {
        return roleRepository
            .existsByIduserAndRolename(
                iduser, Role.ADMIN);
    }

    // ═══════════════════════════════════════════════
    //  deleteRole()
    // ═══════════════════════════════════════════════
    public void deleteRole(int iduser) {
        if (!roleRepository.existsByIduser(iduser))
            throw new RuntimeException(
                "Role non trouvé !");
        roleRepository.deleteByIduser(iduser);
    }

    // ═══════════════════════════════════════════════
    //  isValidRole()  — helper
    // ═══════════════════════════════════════════════
    private boolean isValidRole(String rolename) {
        return rolename.equals(Role.CLIENT)   ||
               rolename.equals(Role.MARCHANT) ||
               rolename.equals(Role.ADMIN);
    }

    // ═══════════════════════════════════════════════
    //  convertToDTO()  ✅ mis à jour
    // ═══════════════════════════════════════════════
    public RoleDTO convertToDTO(Role role) {
        return new RoleDTO(
            role.getId(),
            role.getIduser(),
            role.getRolename(),
            role.getCreateat(),
            role.getUpdatedAsMarchand(),
            role.getUpdatedAsClient());
    }
}