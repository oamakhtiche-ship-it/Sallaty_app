package com.Sallaty.Sallaty.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.service.AuthService;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    // ═══════════════════════════════════════════════
    //  POST /api/auth/register/step1
    //  Body: contact + password + password2
    //  → crée user NOT_VERIFIED + envoie OTP
    //  → retourne userId
    // ═══════════════════════════════════════════════
    @PostMapping("/register/step1")
    public ResponseEntity<Map<String, Object>> registerStep1(
            @RequestParam String contact,
            @RequestParam String password,
            @RequestParam String password2) {

        Map<String, Object> result =
            authService.registerStep1(contact, password, password2);
        return ResponseEntity.ok(result);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/auth/register/step2
    //  Body: userId + otpCode
    //  → vérifie OTP
    // ═══════════════════════════════════════════════
    @PostMapping("/register/step2")
    public ResponseEntity<Map<String, Object>> registerStep2(
            @RequestParam int userId,
            @RequestParam String otpCode) {

        Map<String, Object> result =
            authService.registerStep2(userId, otpCode);
        return ResponseEntity.ok(result);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/auth/register/step3
    //  Body: userId + name + surname
    //  → active compte + retourne accessToken + refreshToken
    // ═══════════════════════════════════════════════
    @PostMapping("/register/step3")
    public ResponseEntity<Map<String, Object>> registerStep3(
            @RequestParam int userId,
            @RequestParam String name,
            @RequestParam String surname) {

        Map<String, Object> result =
            authService.registerStep3(userId, name, surname);
        return ResponseEntity.ok(result);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/auth/login
    //  Body: contact + password
    //  → retourne accessToken + refreshToken + user info
    // ═══════════════════════════════════════════════
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(
            @RequestParam String contact,
            @RequestParam String password) {

        Map<String, Object> result =
            authService.login(contact, password);
        return ResponseEntity.ok(result);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/auth/refresh
    //  Body: refreshToken
    //  → retourne nouveau accessToken
    // ═══════════════════════════════════════════════
    @PostMapping("/refresh")
    public ResponseEntity<Map<String, Object>> refresh(
            @RequestParam String refreshToken) {

        Map<String, Object> result =
            authService.refresh(refreshToken);
        return ResponseEntity.ok(result);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/auth/forgot-password
    //  Body: contact
    //  → envoie OTP reset
    // ═══════════════════════════════════════════════
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, Object>> forgotPassword(
            @RequestParam String contact) {

        authService.forgotPassword(contact);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "OTP envoyé à " + contact);
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/auth/reset-password
    //  Body: contact + otpCode + newPassword + confirm
    //  → reset password
    // ═══════════════════════════════════════════════
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, Object>> resetPassword(
            @RequestParam String contact,
            @RequestParam String otpCode,
            @RequestParam String newPassword,
            @RequestParam String confirm) {

        authService.resetPassword(contact, otpCode, newPassword, confirm);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Password réinitialisé !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/auth/resend-otp
    //  Body: userId
    //  → renvoie OTP
    // ═══════════════════════════════════════════════
    @PostMapping("/resend-otp")
    public ResponseEntity<Map<String, Object>> resendOtp(
            @RequestParam int userId) {

        authService.resendOTP(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "OTP renvoyé !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  POST /api/auth/register  ← ANCIEN (compatibilité)
    // ═══════════════════════════════════════════════
    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(
            @RequestParam String contact,
            @RequestParam String name,
            @RequestParam String surname,
            @RequestParam String password,
            @RequestParam String password2) {

        int userId = authService.register(
            contact, name, surname, password, password2);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Inscription réussie !");
        response.put("userId",  userId);
        return ResponseEntity.ok(response);
    }
}