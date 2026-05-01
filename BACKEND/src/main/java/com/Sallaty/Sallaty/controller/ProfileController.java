package com.Sallaty.Sallaty.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.Sallaty.Sallaty.model.User;
import com.Sallaty.Sallaty.repository.UserRepository;
import com.Sallaty.Sallaty.service.OtpcodeService;
import com.Sallaty.Sallaty.service.ProfileService;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    @Autowired private ProfileService  profileService;
    @Autowired private UserRepository  userRepository;
    @Autowired private OtpcodeService  otpcodeService;   // ✅ ajouté

    // ── HELPER ────────────────────────────────────────────────────
    private int resolveUserId(UserDetails userDetails) {
        String contact = userDetails.getUsername();
        User user = userRepository.findByContact(contact)
            .orElseThrow(() -> new RuntimeException("User non trouvé : " + contact));
        return user.getId();
    }

    // ─────────────────────────────────────────────────────────────
    //  GET /api/profile
    // ─────────────────────────────────────────────────────────────
    @GetMapping
    public ResponseEntity<Map<String, Object>> getMyProfile(
            @AuthenticationPrincipal UserDetails userDetails) {
        int userId = resolveUserId(userDetails);
        return ResponseEntity.ok(profileService.getMyProfile(userId));
    }

    // ─────────────────────────────────────────────────────────────
    //  PUT /api/profile/update
    // ─────────────────────────────────────────────────────────────
    @PutMapping("/update")
    public ResponseEntity<Map<String, Object>> updateProfile(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String surname,
            @RequestParam(required = false) String wilaya,
            @RequestParam(required = false) String businessName,
            @RequestParam(required = false) String businessType,
            @RequestParam(required = false) String phoneNumber) {

        int userId = resolveUserId(userDetails);
        profileService.updateProfile(
            userId, surname, name, null,
            wilaya, businessName, businessType, phoneNumber);

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Profile updated successfully");
        return ResponseEntity.ok(response);
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ POST /api/profile/contact/send-otp   ← NOUVEAU
    //  Envoie un OTP vers le NOUVEAU contact
    //  Body : newContact
    // ─────────────────────────────────────────────────────────────
    @PostMapping("/contact/send-otp")
    public ResponseEntity<Map<String, Object>> sendContactOtp(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String newContact) {

        int userId = resolveUserId(userDetails);

        // Envoie l'OTP directement au nouveau contact
        // sans vérifier s'il existe déjà dans la DB
        otpcodeService.sendVerifCodeLogin(newContact, userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "OTP envoyé à " + newContact);
        return ResponseEntity.ok(response);
    }

    // ─────────────────────────────────────────────────────────────
    //  PUT /api/profile/contact
    //  Body : newContact + otpCode
    // ─────────────────────────────────────────────────────────────
    @PutMapping("/contact")
    public ResponseEntity<Map<String, Object>> updateContact(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String newContact,
            @RequestParam String otpCode) {

        int userId = resolveUserId(userDetails);
        profileService.updateContact(userId, newContact, otpCode);

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Contact updated successfully");
        return ResponseEntity.ok(response);
    }

    // ─────────────────────────────────────────────────────────────
    //  PUT /api/profile/password
    //  Body : oldPassword + newPassword + confirm
    // ─────────────────────────────────────────────────────────────
    @PutMapping("/password")
    public ResponseEntity<Map<String, Object>> updatePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String oldPassword,
            @RequestParam String newPassword,
            @RequestParam String confirm) {

        int userId = resolveUserId(userDetails);
        profileService.updatePassword(userId, oldPassword, newPassword, confirm);

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Password updated successfully");
        return ResponseEntity.ok(response);
    }

    // ─────────────────────────────────────────────────────────────
    //  PUT /api/profile/photo
    //  Body (multipart) : photo = File
    // ─────────────────────────────────────────────────────────────
    @PutMapping("/photo")
    public ResponseEntity<Map<String, Object>> updateProfilePhoto(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam("photo") MultipartFile photo) {

        int userId = resolveUserId(userDetails);
        String photoPath = profileService.updateProfilePhoto(userId, photo);

        Map<String, Object> response = new HashMap<>();
        response.put("message",  "Photo updated successfully");
        response.put("photoUrl", photoPath);
        return ResponseEntity.ok(response);
    }

    // ─────────────────────────────────────────────────────────────
//  GET /api/profile/{userId} — profil public d'un client
// ─────────────────────────────────────────────────────────────
@GetMapping("/{userId}")
public ResponseEntity<Map<String, Object>> getPublicProfile(
        @PathVariable int userId) {
    return ResponseEntity.ok(
        profileService.getMyProfile(userId));
}
}