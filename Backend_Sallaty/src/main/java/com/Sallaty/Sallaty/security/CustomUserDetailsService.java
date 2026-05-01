package com.Sallaty.Sallaty.security;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.Sallaty.Sallaty.model.Role;
import com.Sallaty.Sallaty.repository.RoleRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class CustomUserDetailsService
        implements UserDetailsService {

    @Autowired
    private RoleRepository roleRepository;

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  loadUserByUsername() — native SQL
    // ═══════════════════════════════════════════════
    @Override
    public UserDetails loadUserByUsername(String email)
            throws UsernameNotFoundException {

        Object[] user;
        try {
            user = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT id, contact, passe_word " +
                    "FROM users WHERE contact = :contact")
                .setParameter("contact", email)
                .getSingleResult();
        } catch (Exception e) {
            throw new UsernameNotFoundException(
                "User non trouvé : " + email);
        }

        int    userId   = ((Number) user[0]).intValue();
        String contact  = (String) user[1];
        String password = (String) user[2];

        // Récupérer TOUS les rôles
        List<Role> roles = roleRepository
            .findAllByIduser(userId);

        // Convertir en authorities
        List<SimpleGrantedAuthority> authorities = roles
            .stream()
            .map(r -> new SimpleGrantedAuthority(
                r.getRolename()))
            .collect(Collectors.toList());

        // Si aucun rôle → CLIENT par défaut
        if (authorities.isEmpty())
            authorities.add(
                new SimpleGrantedAuthority("CLIENT"));

        return new org.springframework.security
            .core.userdetails.User(
                contact,
                password != null ? password : "",
                authorities);
    }

    // ═══════════════════════════════════════════════
    //  getUserIdByEmail() — native SQL
    // ═══════════════════════════════════════════════
    public int getUserIdByEmail(String email) {
        try {
            Object[] user = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT id, contact FROM users " +
                    "WHERE contact = :contact")
                .setParameter("contact", email)
                .getSingleResult();
            return ((Number) user[0]).intValue();
        } catch (Exception e) {
            throw new RuntimeException(
                "User non trouvé : " + email);
        }
    }
}