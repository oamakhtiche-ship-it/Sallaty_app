package com.Sallaty.Sallaty.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class PasswordService {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private PasswordEncoder passwordEncoder;

    // ═══════════════════════════════════════════════
    //  hashPassword()
    //  Hasher le password avec BCrypt
    // ═══════════════════════════════════════════════
    public String hashPassword(String password) {

        if (password == null || password.isEmpty())
            throw new IllegalArgumentException(
                "Password obligatoire !");

        return passwordEncoder.encode(password);
    }

    // ═══════════════════════════════════════════════
    //  confirmPassword()
    //  Vérifier password contre hash BCrypt
    // ═══════════════════════════════════════════════
    public boolean confirmPassword(
            String rawPassword,
            String hashedPassword) {

        if (rawPassword == null || rawPassword.isEmpty())
            throw new IllegalArgumentException(
                "Password obligatoire !");

        return passwordEncoder.matches(
            rawPassword, hashedPassword);
    }
}
