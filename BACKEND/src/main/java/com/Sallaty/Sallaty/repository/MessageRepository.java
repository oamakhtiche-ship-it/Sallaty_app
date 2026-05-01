package com.Sallaty.Sallaty.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.Message;

@Repository
public interface MessageRepository
        extends JpaRepository<Message, Integer> {

    // ─────────────────────────────────────────────
    // Historique conversation
    // ─────────────────────────────────────────────
    List<Message> findByConversationIdOrderBySentAtAsc(
        String conversationId);

    // ─────────────────────────────────────────────
    // Toutes conversations d'un user
    // ─────────────────────────────────────────────
    List<Message>
        findTop100BySenderIdOrReceiverIdOrderBySentAtDesc(
            int senderId, int receiverId);

    // ─────────────────────────────────────────────
    // Nb non lus par conversation
    // ─────────────────────────────────────────────
    @Query("SELECT m.conversationId, COUNT(m) " +
           "FROM Message m " +
           "WHERE m.receiverId = :userId " +
           "AND m.isRead = false " +
           "GROUP BY m.conversationId")
    List<Object[]> unreadCountsByReceiver(
        @Param("userId") int userId);

    // ─────────────────────────────────────────────
    // Marquer conversation comme lue
    // ─────────────────────────────────────────────
    @Modifying
    @Query("UPDATE Message m " +
           "SET m.isRead = true " +
           "WHERE m.conversationId = :conversationId " +
           "AND m.receiverId = :userId " +
           "AND m.isRead = false")
    int markConversationRead(
        @Param("conversationId") String conversationId,
        @Param("userId") int userId);

    // ─────────────────────────────────────────────
    // Compter messages non lus total
    // ─────────────────────────────────────────────
    @Query("SELECT COUNT(m) " +
           "FROM Message m " +
           "WHERE m.receiverId = :userId " +
           "AND m.isRead = false")
    int countUnreadMessages(
        @Param("userId") int userId);


    // ─────────────────────────────────────────────
    // Vérifier si conversation existe
    // ─────────────────────────────────────────────
    boolean existsByConversationId(
        String conversationId);
}