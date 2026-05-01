package com.Sallaty.Sallaty.exception;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // ═══════════════════════════════════════════════
    //  RuntimeException → 400
    // ═══════════════════════════════════════════════
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<?> handleRuntimeException(
            RuntimeException e) {

        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", e.getMessage());
        return ResponseEntity.badRequest().body(response);
    }

    // ═══════════════════════════════════════════════
    //  IllegalArgumentException → 400
    // ═══════════════════════════════════════════════
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<?> handleIllegalArgument(
            IllegalArgumentException e) {

        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", e.getMessage());
        return ResponseEntity.badRequest().body(response);
    }

    // ═══════════════════════════════════════════════
    //  Exception → 500 — affiche la vraie erreur
    // ═══════════════════════════════════════════════
    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleException(
            Exception e) {

        e.printStackTrace(); // voir dans le terminal

        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", e.getMessage());
        return ResponseEntity.internalServerError()
            .body(response);
    }
}