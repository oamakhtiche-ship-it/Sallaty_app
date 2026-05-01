package com.Sallaty.Sallaty.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Map;
import java.util.LinkedHashMap;

import com.Sallaty.Sallaty.Dto.OrderLocationUpdateDTO;
import com.Sallaty.Sallaty.Dto.OrdreClientDTO;
import com.Sallaty.Sallaty.Dto.OrdreDTO;
import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.Offre;
import com.Sallaty.Sallaty.model.OrderLocation;
import com.Sallaty.Sallaty.model.Ordre;
import com.Sallaty.Sallaty.repository.OffreRepository;
import com.Sallaty.Sallaty.repository.OrderLocationRepository;
import com.Sallaty.Sallaty.repository.OrdreRepository;
import com.Sallaty.Sallaty.repository.PaymentRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class OrdreService {

    @Autowired private OrdreRepository ordreRepository;
    @Autowired private OffreRepository offreRepository;
    @Autowired private OffreService offreService;
    @Autowired private ClientService clientService;
    @Autowired private MarchandService marchandService;
    @Autowired private PaymentRepository paymentRepository;
    @Autowired private OrderLocationRepository locationRepository;
    @Autowired private SimpMessagingTemplate messagingTemplate;
    @Autowired private NotificationService notificationService;

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  HELPER — get client name native SQL
    // ═══════════════════════════════════════════════
    private String getClientName(int clientId) {
        try {
            Object[] row = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT first_name, surname " +
                    "FROM users WHERE id = :id")
                .setParameter("id", clientId)
                .getSingleResult();
            return row[0] + " " + row[1];
        } catch (Exception e) {
            return "Un client";
        }
    }

    // ═══════════════════════════════════════════════
    //  HELPER — get client row native SQL
    // ═══════════════════════════════════════════════
    private Object[] getClientRow(int clientId) {
        try {
            return (Object[]) entityManager
                .createNativeQuery(
                    "SELECT id, first_name, surname, profile_image " +
                    "FROM users WHERE id = :id")
                .setParameter("id", clientId)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════
    //  createOrdre()
    // ═══════════════════════════════════════════════
    public Ordre createOrdre(
            int clientId,
            int offreId,
            int quantity) {

        if (quantity <= 0)
            throw new IllegalArgumentException("Quantité invalide !");

        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() ->
                new RuntimeException("Offre non trouvée !"));

        if (!offre.getStatus().equals(Offre.ACTIVE) &&
            !offre.getStatus().equals(Offre.RESERVED))
            throw new RuntimeException("Offre non disponible !");

        if (offreService.isExpired(offre))
            throw new RuntimeException("Offre expirée !");

        double totalPrice = offre.getDiscountPrice() > 0
            ? offre.getDiscountPrice() * quantity
            : offre.getPrice() * quantity;

        Ordre ordre = new Ordre();
        ordre.setClientId(clientId);
        ordre.setMarchandId(offre.getMarchandId());
        ordre.setOffreId(offreId);
        ordre.setQuantity(quantity);
        ordre.setTotalPrice(totalPrice);
        ordre.setStatus(Ordre.PENDING);

        Ordre savedOrdre = ordreRepository.save(ordre);

        clientService.updateNbReservations(clientId);
        offreService.incrementReservations(offreId);

        // ✅ native SQL — pas de cast JPA
        String clientName = getClientName(clientId);

        notificationService.sendNotification(
            offre.getMarchandId(),
            "Nouvelle réservation 📦",
            clientName + " a réservé \"" +
            offre.getTitle() + "\" x" + quantity + ".",
            NotificationType.ORDER_CONFIRMED);

        return savedOrdre;
    }

    // ═══════════════════════════════════════════════
    //  cancelOrdre()
    // ═══════════════════════════════════════════════
    public void cancelOrdre(int ordreId, int clientId) {

        Ordre ordre = ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Ordre non trouvé !"));

        if (ordre.getClientId() != clientId)
            throw new RuntimeException("Pas autorisé !");

        if (ordre.getStatus().equals(Ordre.PICKED))
            throw new RuntimeException("Ordre déjà récupéré !");

        if (ordre.getStatus().equals(Ordre.CANCELLED))
            throw new RuntimeException("Ordre déjà annulé !");

        if (ordre.getStatus().equals(Ordre.PENDING))
            offreService.decrementReservations(ordre.getOffreId());

        if (ordre.getStatus().equals(Ordre.CONFIRMED)) {
            offreService.decrementReservations(ordre.getOffreId());
            offreService.incrementQuantity(
                ordre.getOffreId(), ordre.getQuantity());
        }

        ordre.setStatus(Ordre.CANCELLED);
        ordreRepository.save(ordre);

        clientService.updateNbCancellations(ordre.getClientId());

        // ✅ native SQL — pas de cast JPA
        String clientName = getClientName(clientId);

        notificationService.sendNotification(
            ordre.getMarchandId(),
            "Réservation annulée ❌",
            clientName + " a annulé sa réservation #" +
            ordreId + ".",
            NotificationType.ORDER_CANCELLED);

        notificationService.sendNotification(
            clientId,
            "Réservation annulée ✅",
            "Votre réservation #" + ordreId +
            " a été annulée avec succès.",
            NotificationType.ORDER_CANCELLED);
    }

    // ═══════════════════════════════════════════════
    //  confirmOrdre()
    // ═══════════════════════════════════════════════
    public void confirmOrdre(int ordreId, int marchandId) {

        Ordre ordre = ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Ordre non trouvé !"));

        if (ordre.getMarchandId() != marchandId)
            throw new RuntimeException("Pas autorisé !");

        if (!ordre.getStatus().equals(Ordre.PENDING))
            throw new RuntimeException("Ordre doit être PENDING !");

        offreService.decrementQuantity(
            ordre.getOffreId(), ordre.getQuantity());

        ordre.setStatus(Ordre.CONFIRMED);
        ordre.setConfirmedAt(LocalDateTime.now());
        ordreRepository.save(ordre);

        Offre offre = offreRepository
            .findById(ordre.getOffreId()).orElse(null);
        String offreTitle = offre != null
            ? offre.getTitle() : "votre offre";

        notificationService.sendNotification(
            ordre.getClientId(),
            "Réservation confirmée ✅",
            "Votre réservation pour \"" + offreTitle +
            "\" a été confirmée. Vous pouvez maintenant payer.",
            NotificationType.ORDER_CONFIRMED);
    }

    // ═══════════════════════════════════════════════
    //  completeOrdre()
    // ═══════════════════════════════════════════════
    public void completeOrdre(int ordreId, int clientId) {

        Ordre ordre = ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Ordre non trouvé !"));

        if (ordre.getClientId() != clientId)
            throw new RuntimeException("Pas autorisé !");

        if (!ordre.getStatus().equals(Ordre.CONFIRMED))
            throw new RuntimeException("Ordre doit être CONFIRMED !");

        if (!paymentRepository.existsByOrdreId(ordreId))
            throw new RuntimeException("Paiement non effectué !");

        ordre.setStatus(Ordre.PICKED);
        ordre.setCompletedAt(LocalDateTime.now());
        ordreRepository.save(ordre);

        clientService.updateTotalSpent(
            ordre.getClientId(), ordre.getTotalPrice());

        marchandService.updateRevenue(
            ordre.getMarchandId(), ordre.getTotalPrice());

        notificationService.sendNotification(
            clientId,
            "Commande récupérée ✅",
            "Votre commande #" + ordreId +
            " a été récupérée avec succès. Merci !",
            NotificationType.ORDER_COMPLETED);

        notificationService.sendNotification(
            ordre.getMarchandId(),
            "Commande complétée ✅",
            "La commande #" + ordreId +
            " a été récupérée par le client.",
            NotificationType.PAYMENT_RECEIVED);
    }

    // ═══════════════════════════════════════════════
    //  rejectOrdre()
    // ═══════════════════════════════════════════════
    public void rejectOrdre(int ordreId, int marchandId) {

        Ordre ordre = ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Ordre non trouvé !"));

        if (ordre.getMarchandId() != marchandId)
            throw new RuntimeException("Pas autorisé !");

        offreService.decrementReservations(ordre.getOffreId());

        ordre.setStatus(Ordre.CANCELLED);
        ordreRepository.save(ordre);

        Offre offre = offreRepository
            .findById(ordre.getOffreId()).orElse(null);
        String offreTitle = offre != null
            ? offre.getTitle() : "votre offre";

        notificationService.sendNotification(
            ordre.getClientId(),
            "Réservation rejetée ❌",
            "Votre réservation pour \"" + offreTitle +
            "\" a été rejetée par le marchand.",
            NotificationType.ORDER_REJECTED);
    }

    // ═══════════════════════════════════════════════
    //  updateLocation()
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateLocation(
            int marchandId,
            OrderLocationUpdateDTO dto) {

        Ordre ordre = ordreRepository
            .findById(dto.getOrdreId())
            .orElseThrow(() ->
                new RuntimeException("Ordre non trouvé !"));

        if (ordre.getMarchandId() != marchandId)
            throw new RuntimeException("Pas autorisé !");

        if (!ordre.getStatus().equals(Ordre.CONFIRMED))
            throw new RuntimeException(
                "Tracking disponible seulement pour les ordres CONFIRMED !");

        LocalDateTime ts = dto.getTimestamp() != null
            ? dto.getTimestamp()
            : LocalDateTime.now();

        ordre.setLastLat(dto.getLat());
        ordre.setLastLng(dto.getLng());
        ordre.setLastLocationAt(ts);
        ordreRepository.save(ordre);

        OrderLocation point = new OrderLocation();
        point.setOrdreId(dto.getOrdreId());
        point.setLat(dto.getLat());
        point.setLng(dto.getLng());
        point.setTimestamp(ts);
        locationRepository.save(point);

        messagingTemplate.convertAndSend(
            "/topic/location/" + dto.getOrdreId(),
            new OrderLocationUpdateDTO(
                dto.getOrdreId(),
                dto.getLat(),
                dto.getLng(),
                ts));
    }

    // ═══════════════════════════════════════════════
    //  getLocationHistory()
    // ═══════════════════════════════════════════════
    public List<OrderLocation> getLocationHistory(int ordreId) {
        ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Ordre non trouvé !"));
        return locationRepository
            .findByOrdreIdOrderByTimestampDesc(ordreId);
    }

    // ═══════════════════════════════════════════════
    //  getOrdreById()
    // ═══════════════════════════════════════════════
    public Ordre getOrdreById(int ordreId) {
        return ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Ordre non trouvé !"));
    }

    // ═══════════════════════════════════════════════
    //  getOrdresByClient()
    // ═══════════════════════════════════════════════
    public List<Ordre> getOrdresByClient(int clientId) {
        return ordreRepository.findByClientId(clientId);
    }

    // ═══════════════════════════════════════════════
    //  getOrdresByClientAndStatus()
    // ═══════════════════════════════════════════════
    public List<Ordre> getOrdresByClientAndStatus(
            int clientId, String status) {
        return ordreRepository
            .findByClientIdAndStatus(clientId, status);
    }

    // ═══════════════════════════════════════════════
    //  getOrdresByMarchand()
    // ═══════════════════════════════════════════════
    public List<Ordre> getOrdresByMarchand(int marchandId) {
        return ordreRepository.findByMarchandId(marchandId);
    }

    // ═══════════════════════════════════════════════
    //  getPendingOrdresByMarchand()
    // ═══════════════════════════════════════════════
    public List<Ordre> getPendingOrdresByMarchand(
            int marchandId) {
        return ordreRepository
            .findByMarchandIdAndStatus(marchandId, Ordre.PENDING);
    }

    // ═══════════════════════════════════════════════
    //  getOrdresByMarchandAndStatus()
    // ═══════════════════════════════════════════════
    public List<Ordre> getOrdresByMarchandAndStatus(
            int marchandId, String status) {
        return ordreRepository
            .findByMarchandIdAndStatus(marchandId, status);
    }

    // ═══════════════════════════════════════════════
    //  getOrdreHistory() — CLIENT
    // ═══════════════════════════════════════════════
    public List<Ordre> getOrdreHistory(int clientId) {
        return ordreRepository
            .findByClientIdAndStatusIn(
                clientId, List.of(Ordre.PICKED, Ordre.CANCELLED));
    }

    // ═══════════════════════════════════════════════
    //  getOrdreHistoryMarchand() — MARCHAND
    // ═══════════════════════════════════════════════
    public List<Ordre> getOrdreHistoryMarchand(int marchandId) {
        return ordreRepository
            .findByMarchandIdAndStatusIn(
                marchandId, List.of(Ordre.PICKED, Ordre.CANCELLED));
    }

    // ═══════════════════════════════════════════════
    //  getOrdresByOffre()
    // ═══════════════════════════════════════════════
    public List<Ordre> getOrdresByOffre(int offreId) {
        return ordreRepository.findByOffreId(offreId);
    }

    // ═══════════════════════════════════════════════
    //  getOrdresByStatus() — ADMIN
    // ═══════════════════════════════════════════════
    public List<Ordre> getOrdresByStatus(String status) {
        return ordreRepository.findByStatus(status);
    }

    // ═══════════════════════════════════════════════
    //  getReservationsByOffre() — native SQL
    // ═══════════════════════════════════════════════
    @SuppressWarnings("unchecked")
public List<Map<String, Object>> getReservationsByOffre(int offreId) {
    List<Ordre> ordres = ordreRepository.findByOffreId(offreId);
    List<Map<String, Object>> result = new ArrayList<>();

    for (Ordre o : ordres) {
        Map<String, Object> map = new java.util.LinkedHashMap<>();
        map.put("ordreId",    o.getId());
        map.put("status",     o.getStatus());
        map.put("totalPrice", o.getTotalPrice());
        map.put("quantity",   o.getQuantity());
        map.put("createdAt",  o.getCreatedAt());
        map.put("clientId",   o.getClientId());   // ✅ AJOUTER

        // ✅ Infos client (firstName, surname, profilePhoto)
        try {
            Object[] user = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT first_name, surname, profile_image " +
                    "FROM users WHERE id = :id")
                .setParameter("id", o.getClientId())
                .getSingleResult();

            map.put("firstName",    user[0] != null ? user[0] : "");
            map.put("surname",      user[1] != null ? user[1] : "");
            map.put("profilePhoto", user[2] != null ? user[2] : ""); // ✅
        } catch (Exception e) {
            map.put("firstName",    "Client");
            map.put("surname",      "");
            map.put("profilePhoto", "");
        }

        result.add(map);
    }
    return result;
}

    // ═══════════════════════════════════════════════
    //  convertToDTO()
    // ═══════════════════════════════════════════════
    public OrdreDTO convertToDTO(Ordre ordre) {
        OrdreDTO dto = new OrdreDTO(
            ordre.getId(),
            ordre.getClientId(),
            ordre.getMarchandId(),
            ordre.getOffreId(),
            ordre.getQuantity(),
            ordre.getTotalPrice(),
            ordre.getStatus(),
            ordre.getPickupTime(),
            ordre.getCreatedAt(),
            ordre.getConfirmedAt(),
            ordre.getCompletedAt());

        dto.setLastLat(ordre.getLastLat());
        dto.setLastLng(ordre.getLastLng());
        dto.setLastLocationAt(ordre.getLastLocationAt());

        return dto;
    }

   // ═══════════════════════════════════════════════
//  getOrdresByClientWithDetails() — CLIENT
//  GET /api/ordres/client
//  Retourne ordres + infos offre + marchand
// ═══════════════════════════════════════════════
@SuppressWarnings("unchecked")
public List<java.util.Map<String, Object>> getOrdresByClientWithDetails(int clientId) {

    List<Ordre> ordres = ordreRepository.findByClientId(clientId);
    List<java.util.Map<String, Object>> result = new ArrayList<>();

    for (Ordre o : ordres) {
        java.util.Map<String, Object> map = new java.util.LinkedHashMap<>();

        // ── Infos ordre ──────────────────────────────────
        map.put("ordreId",    o.getId());
        map.put("status",     o.getStatus());
        map.put("totalPrice", o.getTotalPrice());
        map.put("quantity",   o.getQuantity());
        map.put("createdAt",  o.getCreatedAt());

        // ── Infos offre (native SQL) ──────────────────────
        try {
            Object[] offre = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT title, photo, wilaya, expire_at " +
                    "FROM offres WHERE id = :id")
                .setParameter("id", o.getOffreId())
                .getSingleResult();

            map.put("title",    offre[0] != null ? offre[0] : "");
            map.put("photo",    offre[1] != null ? offre[1] : "");
            map.put("wilaya",   offre[2] != null ? offre[2] : "");
            map.put("expireAt", offre[3] != null ? offre[3].toString() : "");
        } catch (Exception e) {
            map.put("title",    "");
            map.put("photo",    "");
            map.put("wilaya",   "");
            map.put("expireAt", "");
        }

        // ── Infos marchand (native SQL) ───────────────────
        try {
            Object[] marchand = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT business_name " +
                    "FROM marchands WHERE user_id = :id")
                .setParameter("id", o.getMarchandId())
                .getSingleResult();

            map.put("merchantName",
                marchand[0] != null ? marchand[0] : "");
        } catch (Exception e) {
            map.put("merchantName", "");
        }

        result.add(map);
    }

    return result;
} // GET /api/ordres/client — retourne les ordres avec infos offre + marchand

}