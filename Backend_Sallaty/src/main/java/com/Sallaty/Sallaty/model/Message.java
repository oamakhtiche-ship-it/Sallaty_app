package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "messages")
public class Message {

    // ═══════════════════════════════
    // FIELDS
    // ═══════════════════════════════
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "conversation_id",
            nullable = false, length = 128)
    private String conversationId;

    @Column(name = "sender_id", nullable = false)
    private int senderId;

    @Column(name = "receiver_id", nullable = false)
    private int receiverId;

    @Lob
    @Column(name = "content", nullable = false)
    private String content;

    @Column(name = "is_read", nullable = false)
    private boolean isRead = false;

    @Column(name = "sent_at", nullable = false)
    private LocalDateTime sentAt;

    // ═══════════════════════════════
    // PRE PERSIST
    // ═══════════════════════════════
    @PrePersist
    public void prePersist() {
        if (sentAt == null)
            sentAt = LocalDateTime.now();
    }

    // ═══════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════
    public Message() {}

    // ═══════════════════════════════
    // GETTERS
    // ═══════════════════════════════
    public int           getId()             { return id; }
    public String        getConversationId() { return conversationId; }
    public int           getSenderId()       { return senderId; }
    public int           getReceiverId()     { return receiverId; }
    public String        getContent()        { return content; }
    public boolean       getIsRead()         { return isRead; }
    public LocalDateTime getSentAt()         { return sentAt; }

    // ═══════════════════════════════
    // SETTERS
    // ═══════════════════════════════
    public void setId(int id)                          { this.id = id; }
    public void setConversationId(String cId)          { this.conversationId = cId; }
    public void setSenderId(int senderId)              { this.senderId = senderId; }
    public void setReceiverId(int receiverId)          { this.receiverId = receiverId; }
    public void setContent(String content)             { this.content = content; }
    public void setIsRead(boolean isRead)              { this.isRead = isRead; }
    public void setSentAt(LocalDateTime sentAt)        { this.sentAt = sentAt; }
}