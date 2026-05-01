package com.Sallaty.Sallaty.controller;

import java.security.Principal;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.Dto.MessageDTO;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.service.MessageService;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private MessageService messageService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  WebSocket — sendMessage
    // ═══════════════════════════════════════════════
    @MessageMapping("/sendMessage")
    public void sendMessage(
            @Payload MessageDTO dto,
            Principal principal) {

        int senderId = extractUserId(principal);

        messageService.sendMessage(
            senderId,
            dto.getReceiverId(),
            dto.getContent());
    }

    // ═══════════════════════════════════════════════
    //  GET /api/messages/conversation/{otherUserId}
    // ═══════════════════════════════════════════════
    @GetMapping("/conversation/{otherUserId}")
    public ResponseEntity<?> getConversation(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int otherUserId) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            messageService.getConversation(
                userId, otherUserId));
    }

    // ═══════════════════════════════════════════════
    //  GET /api/messages/conversations
    // ═══════════════════════════════════════════════
    @GetMapping("/conversations")
    public ResponseEntity<?> getAllConversations(
            @AuthenticationPrincipal
                UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            messageService.getAllConversations(
                userId));
    }

    // ═══════════════════════════════════════════════
    //  PUT /api/messages/read/{conversationId}
    // ═══════════════════════════════════════════════
    @PutMapping("/read/{conversationId}")
    public ResponseEntity<?> markAsRead(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable String conversationId) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        messageService.markAsRead(
            userId, conversationId);

        return ResponseEntity.ok(true);
    }

    // ═══════════════════════════════════════════════
    //  GET /api/messages/unread
    // ═══════════════════════════════════════════════
    @GetMapping("/unread")
    public ResponseEntity<?> countUnreadMessages(
            @AuthenticationPrincipal
                UserDetails userDetails) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        return ResponseEntity.ok(
            messageService.countUnreadMessages(
                userId));
    }

    // ═══════════════════════════════════════════════
    //  DELETE /api/messages/delete/{messageId}
    // ═══════════════════════════════════════════════
    @DeleteMapping("/delete/{messageId}")
    public ResponseEntity<?> deleteMessage(
            @AuthenticationPrincipal
                UserDetails userDetails,
            @PathVariable int messageId) {

        int userId = userDetailsService
            .getUserIdByEmail(
                userDetails.getUsername());

        messageService.deleteMessage(
            messageId, userId);

        return ResponseEntity.ok(true);
    }

    // ═══════════════════════════════════════════════
    //  extractUserId() — WebSocket
    // ═══════════════════════════════════════════════
    private int extractUserId(Principal principal) {
        if (principal instanceof
                UsernamePasswordAuthenticationToken
                    token) {
            Object inner = token.getPrincipal();
            if (inner instanceof
                    UserDetails userDetails) {
                return userDetailsService
                    .getUserIdByEmail(
                        userDetails.getUsername());
            }
        }
        throw new RuntimeException(
            "User non authentifié !");
    }
}