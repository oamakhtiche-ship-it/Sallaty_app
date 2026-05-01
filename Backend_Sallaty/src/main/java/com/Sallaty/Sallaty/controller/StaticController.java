package com.Sallaty.Sallaty.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.Sallaty.Sallaty.model.FaqItem;
import com.Sallaty.Sallaty.service.StaticService;

@RestController
@RequestMapping("/api/static")
public class StaticController {

    @Autowired
    private StaticService staticService;

    // ═══════════════════════════════════════════════
    //  GET — pages statiques (public)
    // ═══════════════════════════════════════════════

    @GetMapping("/privacy")
    public ResponseEntity<?> getPrivacy() {
        return ResponseEntity.ok(Map.of(
            "content", staticService.getPrivacyPolicy()));
    }

    @GetMapping("/about")
    public ResponseEntity<?> getAbout() {
        return ResponseEntity.ok(Map.of(
            "content", staticService.getAbout()));
    }

    @GetMapping("/terms")
    public ResponseEntity<?> getTerms() {
        return ResponseEntity.ok(Map.of(
            "content", staticService.getTermsConditions()));
    }

    // ═══════════════════════════════════════════════
    //  GET HELP — FAQ (public)
    // ═══════════════════════════════════════════════

    // GET /api/static/help
    @GetMapping("/help")
    public ResponseEntity<?> getAllFaq() {
        return ResponseEntity.ok(staticService.getAllFaq());
    }

    // GET /api/static/help/ORDERS_DELIVERY
    @GetMapping("/help/{category}")
    public ResponseEntity<?> getFaqByCategory(
            @PathVariable String category) {
        return ResponseEntity.ok(
            staticService.getFaqByCategory(category));
    }

    // GET /api/static/help/ORDERS_DELIVERY/1
    @GetMapping("/help/{category}/{questionId}")
    public ResponseEntity<?> getFaqAnswer(
            @PathVariable String category,
            @PathVariable int questionId) {
        return ResponseEntity.ok(
            staticService.getFaqAnswer(category, questionId));
    }

    // ═══════════════════════════════════════════════
    //  UPDATE pages statiques — Admin
    // ═══════════════════════════════════════════════

    @PutMapping("/privacy")
    public ResponseEntity<?> updatePrivacy(
            @RequestParam String content) {
        staticService.updatePrivacyPolicy(content);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Privacy Policy mise à jour ✅"));
    }

    @PutMapping("/about")
    public ResponseEntity<?> updateAbout(
            @RequestParam String content) {
        staticService.updateAbout(content);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "About mis à jour ✅"));
    }

    @PutMapping("/terms")
    public ResponseEntity<?> updateTerms(
            @RequestParam String content) {
        staticService.updateTermsConditions(content);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Terms mis à jour ✅"));
    }

    // ═══════════════════════════════════════════════
    //  FAQ CRUD — Admin seulement
    // ═══════════════════════════════════════════════

    // POST /api/static/help/add
    @PostMapping("/help/add")
    public ResponseEntity<?> addFaq(
            @RequestParam String category,
            @RequestParam String question,
            @RequestParam String answer,
            @RequestParam(defaultValue = "0") int displayOrder) {

        FaqItem item = staticService.addFaq(
            category, question, answer, displayOrder);
        return ResponseEntity.ok(item);
    }

    // PUT /api/static/help/ORDERS_DELIVERY/1
    @PutMapping("/help/{category}/{questionId}")
    public ResponseEntity<?> updateFaq(
            @PathVariable String category,
            @PathVariable int questionId,
            @RequestParam(required = false) String question,
            @RequestParam(required = false) String answer) {

        FaqItem item = staticService.updateFaq(
            category, questionId, question, answer);
        return ResponseEntity.ok(item);
    }

    // DELETE /api/static/help/ORDERS_DELIVERY/1
    @DeleteMapping("/help/{category}/{questionId}")
    public ResponseEntity<?> deleteFaq(
            @PathVariable String category,
            @PathVariable int questionId) {
        staticService.deleteFaq(category, questionId);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "FAQ supprimée ✅"));
    }
}