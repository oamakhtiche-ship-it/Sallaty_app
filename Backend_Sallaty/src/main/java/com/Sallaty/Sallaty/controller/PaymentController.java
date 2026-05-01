package com.Sallaty.Sallaty.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.Dto.PaymentRequest;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.PaymentService;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private PaymentService paymentService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  POST /api/payments/pay  — CLIENT
    // ═══════════════════════════════════════════════
    @PostMapping("/pay")
    public ResponseEntity<?> pay(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @RequestBody PaymentRequest request) {

        int buyerId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            paymentService.pay(buyerId, request));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/payments/ordre/{ordreId}  — PUBLIC
    // ═══════════════════════════════════════════════
    @GetMapping("/ordre/{ordreId}")
    public ResponseEntity<?> getPaymentByOrdre(
            @PathVariable int ordreId) {

        return ResponseEntity.ok(
            paymentService
                .getPaymentByOrdre(ordreId));
    }
}