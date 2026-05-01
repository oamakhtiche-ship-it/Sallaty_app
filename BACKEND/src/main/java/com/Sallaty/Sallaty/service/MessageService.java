package com.Sallaty.Sallaty.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.Dto.MessageDTO;
import com.Sallaty.Sallaty.model.Message;
import com.Sallaty.Sallaty.repository.MessageRepository;
import com.Sallaty.Sallaty.repository.UserRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class MessageService {

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  HELPER — get user name native SQL
    // ═══════════════════════════════════════════════
    private String getUserName(int userId) {
        try {
            Object[] row = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT first_name, surname " +
                    "FROM users WHERE id = :id")
                .setParameter("id", userId)
                .getSingleResult();
            return row[0] + " " + row[1];
        } catch (Exception e) {
            return null;
        }
    }

    private boolean userExists(int userId) {
        Long count = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM users WHERE id = :id")
            .setParameter("id", userId)
            .getSingleResult()).longValue();
        return count > 0;
    }

    // ═══════════════════════════════════════════════
    //  sendMessage()
    // ═══════════════════════════════════════════════
    @Transactional
    public MessageDTO sendMessage(
            int senderId,
            int receiverId,
            String content) {

        if (!userExists(senderId))
            throw new RuntimeException("Sender non trouvé !");

        if (!userExists(receiverId))
            throw new RuntimeException("Receiver non trouvé !");

        if (content == null || content.trim().isEmpty())
            throw new IllegalArgumentException("Message vide !");

        String conversationId =
            computeConversationId(senderId, receiverId);

        Message message = new Message();
        message.setSenderId(senderId);
        message.setReceiverId(receiverId);
        message.setConversationId(conversationId);
        message.setContent(content.trim());
        message.setIsRead(false);

        messageRepository.save(message);

        MessageDTO dto = convertToDTO(message);

        messagingTemplate.convertAndSend(
            "/topic/messages/" + conversationId, dto);

        return dto;
    }

    // ═══════════════════════════════════════════════
    //  getConversation()
    // ═══════════════════════════════════════════════
    @Transactional(readOnly = true)
    public List<MessageDTO> getConversation(
            int userId1, int userId2) {

        String conversationId =
            computeConversationId(userId1, userId2);

        return messageRepository
            .findByConversationIdOrderBySentAtAsc(
                conversationId)
            .stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
    //  getAllConversations()
    // ═══════════════════════════════════════════════
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getAllConversations(
            int userId) {

        List<Message> recent = messageRepository
            .findTop100BySenderIdOrReceiverIdOrderBySentAtDesc(
                userId, userId);

        Map<String, Message> lastByConversation =
            new LinkedHashMap<>();
        for (Message m : recent)
            lastByConversation.putIfAbsent(
                m.getConversationId(), m);

        Map<String, Integer> unreadCounts = new HashMap<>();
        for (Object[] row : messageRepository
                .unreadCountsByReceiver(userId))
            unreadCounts.put(
                (String) row[0],
                ((Number) row[1]).intValue());

        List<Map<String, Object>> result = new ArrayList<>();

        for (var entry : lastByConversation.entrySet()) {
            String cid   = entry.getKey();
            Message last = entry.getValue();

            int otherId = last.getSenderId() == userId
                ? last.getReceiverId()
                : last.getSenderId();

            // ✅ native SQL — pas de cast JPA
            String otherUserName = getUserName(otherId);

            Map<String, Object> conv = new HashMap<>();
            conv.put("conversationId",  cid);
            conv.put("otherId",         otherId);
            conv.put("otherUserName",   otherUserName);
            conv.put("lastMessage",
                trimContent(last.getContent(), 100));
            conv.put("lastMessageTime", last.getSentAt());
            conv.put("unreadCount",
                unreadCounts.getOrDefault(cid, 0));

            result.add(conv);
        }

        return result;
    }

    // ═══════════════════════════════════════════════
    //  markAsRead()
    // ═══════════════════════════════════════════════
    @Transactional
    public void markAsRead(int userId, String conversationId) {
        if (!isParticipant(userId, conversationId))
            throw new RuntimeException("Accès refusé !");
        messageRepository.markConversationRead(
            conversationId, userId);
    }

    // ═══════════════════════════════════════════════
    //  countUnreadMessages()
    // ═══════════════════════════════════════════════
    @Transactional(readOnly = true)
    public int countUnreadMessages(int userId) {
        return messageRepository.countUnreadMessages(userId);
    }

    // ═══════════════════════════════════════════════
    //  deleteMessage()
    // ═══════════════════════════════════════════════
    @Transactional
    public void deleteMessage(int messageId, int userId) {
        Message message = messageRepository
            .findById(messageId)
            .orElseThrow(() ->
                new RuntimeException("Message non trouvé !"));

        if (message.getSenderId() != userId)
            throw new RuntimeException(
                "Vous ne pouvez pas supprimer ce message !");

        messageRepository.delete(message);
    }

    // ═══════════════════════════════════════════════
    //  computeConversationId()
    // ═══════════════════════════════════════════════
    public String computeConversationId(int id1, int id2) {
        int a = Math.min(id1, id2);
        int b = Math.max(id1, id2);
        return a + ":" + b;
    }

    // ═══════════════════════════════════════════════
    //  isParticipant()
    // ═══════════════════════════════════════════════
    private boolean isParticipant(
            int userId, String conversationId) {

        if (conversationId == null ||
            !conversationId.contains(":"))
            return false;

        String[] parts = conversationId.split(":");
        if (parts.length != 2) return false;

        try {
            int a = Integer.parseInt(parts[0]);
            int b = Integer.parseInt(parts[1]);
            return userId == a || userId == b;
        } catch (NumberFormatException ex) {
            return false;
        }
    }

    // ═══════════════════════════════════════════════
    //  convertToDTO()
    // ═══════════════════════════════════════════════
    public MessageDTO convertToDTO(Message message) {
        MessageDTO dto = new MessageDTO();
        dto.setId(message.getId());
        dto.setConversationId(message.getConversationId());
        dto.setSenderId(message.getSenderId());
        dto.setReceiverId(message.getReceiverId());
        dto.setContent(message.getContent());
        dto.setIsRead(message.getIsRead());
        dto.setSentAt(message.getSentAt());
        return dto;
    }

    // ═══════════════════════════════════════════════
    //  trimContent()
    // ═══════════════════════════════════════════════
    private String trimContent(String content, int max) {
        if (content == null) return null;
        String t = content.trim();
        if (t.length() <= max) return t;
        return t.substring(0, max - 1) + "…";
    }
}