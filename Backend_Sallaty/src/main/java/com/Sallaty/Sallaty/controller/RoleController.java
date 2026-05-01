package com.Sallaty.Sallaty.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.RoleService;

@RestController
@RequestMapping("/api/roles")
public class RoleController {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private RoleService roleService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  POST /api/roles/assign — ADMIN
    // ═══════════════════════════════════════════════
    @PostMapping("/assign")
    public ResponseEntity<?> assignRole(
            @RequestParam int iduser,
            @RequestParam String rolename) {

        roleService.assignRole(iduser, rolename);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message",
            "Role assigné avec succès !");
        return ResponseEntity.ok(response);
    }

    // ═══════════════════════════════════════════════
    //  GET /api/roles — AUTH
    //  userId depuis token ✅
    // ═══════════════════════════════════════════════
    @GetMapping
    public ResponseEntity<?> getRoleByUser(
            @AuthenticationPrincipal
                UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            roleService.getRoleByUser(userId));
    }

    // ═══════════════════════════════════════════════
    //  DELETE /api/roles/delete/{userId} — ADMIN
    // ═══════════════════════════════════════════════
    @DeleteMapping("/delete/{userId}")
    public ResponseEntity<?> deleteRole(
            @PathVariable int userId) {

        roleService.deleteRole(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message",
            "Role supprimé avec succès !");
        return ResponseEntity.ok(response);
    }
}