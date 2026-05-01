package com.Sallaty.Sallaty.Dto;

import java.time.LocalDateTime;

public class MessageDTO {

    // ═══════════════════════════════
    // FIELDS
    // ═══════════════════════════════
    private int           id;
    private String        conversationId;
    private int           senderId;
    private int           receiverId;
    private String        content;
    private boolean       isRead;
    private LocalDateTime sentAt;

    // ═══════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════
    public MessageDTO() {}

    public MessageDTO(
            int id,
            String conversationId,
            int senderId,
            int receiverId,
            String content,
            boolean isRead,
            LocalDateTime sentAt) {

        this.id             = id;
        this.conversationId = conversationId;
        this.senderId       = senderId;
        this.receiverId     = receiverId;
        this.content        = content;
        this.isRead         = isRead;
        this.sentAt         = sentAt;
    }

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