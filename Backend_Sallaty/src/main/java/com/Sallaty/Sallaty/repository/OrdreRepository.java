package com.Sallaty.Sallaty.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.Sallaty.Sallaty.model.Ordre;

@Repository
public interface OrdreRepository
    extends JpaRepository<Ordre, Integer> {

    // par client
    List<Ordre> findByClientId(int clientId);

    // par marchand
    List<Ordre> findByMarchandId(int marchandId);

    // par offre
    List<Ordre> findByOffreId(int offreId);

    // par status
    List<Ordre> findByStatus(String status);

    // par client + status
    List<Ordre> findByClientIdAndStatus(
        int clientId, String status);

    // par marchand + status
    List<Ordre> findByMarchandIdAndStatus(
        int marchandId, String status);

    // ═══════════════════════════════════════════════
//  historique client
// ═══════════════════════════════════════════════
List<Ordre> findByClientIdAndStatusIn(
    int clientId, List<String> statuses);

// ═══════════════════════════════════════════════
//  historique marchand
// ═══════════════════════════════════════════════
List<Ordre> findByMarchandIdAndStatusIn(
    int marchandId, List<String> statuses);


    List<Ordre> findByOffreIdAndStatus(int offreId, String status);

    
// ➕ utilisé dans WebSocketConfig.authorizeSubscribe()
    // vérifie que l'ordre appartient au client ou au marchand
    @Query("SELECT COUNT(o) > 0 FROM Ordre o " +
           "WHERE o.id = :ordreId " +
           "AND (o.clientId = :userId " +
           "OR o.marchandId = :userId)")
    boolean existsByIdAndParticipant(
        @Param("ordreId") int ordreId,
        @Param("userId")  int userId);

}

