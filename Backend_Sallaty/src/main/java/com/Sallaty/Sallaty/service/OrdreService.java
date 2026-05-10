package com.Sallaty.Sallaty.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
    //  Le client peut réserver librement.
    //  C'est le marchand qui gère le stock à la confirmation.
    // ═══════════════════════════════════════════════
    public Ordre createOrdre(
            int clientId,
            int offreId,
            int quantity) {

        if (quantity <= 0)
            throw new IllegalArgumentException("Invalid quantity!");

        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() ->
                new RuntimeException("Offer not found !"));

        if (offre.getMarchandId() == clientId)
            throw new RuntimeException(
                "You cannot book your own offer !");

        if (!offre.getStatus().equals(Offre.ACTIVE) &&
            !offre.getStatus().equals(Offre.RESERVED))
            throw new RuntimeException("Offer not available!");

        if (offreService.isExpired(offre))
            throw new RuntimeException("Offer expired\" !");

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

        String clientName = getClientName(clientId);

        notificationService.sendNotification(
            offre.getMarchandId(),
            "New reservation 📦",
            clientName + " has reserved \"" +
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
                new RuntimeException("Order not found !"));

        if (ordre.getClientId() != clientId)
            throw new RuntimeException("Not allowed !");

        if (ordre.getStatus().equals(Ordre.PICKED))
            throw new RuntimeException("Order already collected!");

        if (ordre.getStatus().equals(Ordre.CANCELLED))
            throw new RuntimeException("Order already canceled !");

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

        String clientName = getClientName(clientId);

        notificationService.sendNotification(
            ordre.getMarchandId(),
            "Réservation annulée ❌",
            clientName + " a annulé sa réservation #" +
            ordreId + ".",
            NotificationType.ORDER_CANCELLED);

        notificationService.sendNotification(
            clientId,
            "Reservation canceled ✅",
            "Your reservation#" + ordreId +
            " was successfully cancelled.",
            NotificationType.ORDER_CANCELLED);
    }

    // ═══════════════════════════════════════════════
    //  confirmOrdre()
    // ═══════════════════════════════════════════════
    public void confirmOrdre(int ordreId, int marchandId) {

        Ordre ordre = ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Order not found  !"));

        if (ordre.getMarchandId() != marchandId)
            throw new RuntimeException("not allowed !");

        if (!ordre.getStatus().equals(Ordre.PENDING))
            throw new RuntimeException("Order must be PENDING !");

        // ✅ Vérification stock au moment de la confirmation :
        //    quantité déjà confirmée + cette commande ≤ quantité déclarée
        Offre offre = offreRepository.findById(ordre.getOffreId())
            .orElseThrow(() ->
                new RuntimeException("Offer not found !"));

        int alreadyConfirmedQty = ordreRepository
            .findByOffreIdAndStatus(ordre.getOffreId(), Ordre.CONFIRMED)
            .stream()
            .mapToInt(Ordre::getQuantity)
            .sum();

        int remainingStock = offre.getQuantity() - alreadyConfirmedQty;

        if (ordre.getQuantity() > remainingStock)
            throw new RuntimeException(
                "Insufficient stock to confirm! " +
                "Remaining stock\r\n" + //
                                        ": " + remainingStock +
                ", request\r\n" + //
                                        " : " + ordre.getQuantity());

        offreService.decrementQuantity(
            ordre.getOffreId(), ordre.getQuantity());

        ordre.setStatus(Ordre.CONFIRMED);
        ordre.setConfirmedAt(LocalDateTime.now());
        ordreRepository.save(ordre);

        String offreTitle = (offre != null && offre.getTitle() != null)
            ? offre.getTitle() : "votre offre";

        notificationService.sendNotification(
            ordre.getClientId(),
            "Confirmed reservation ✅",
            "Your reservation for \"" + offreTitle +
            "\" Your order has been confirmed. You can now pay.",
            NotificationType.ORDER_CONFIRMED);
    }

    // ═══════════════════════════════════════════════
    //  completeOrdre()
    // ═══════════════════════════════════════════════
    public void completeOrdre(int ordreId, int clientId) {

        Ordre ordre = ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Order not found !"));

        if (ordre.getClientId() != clientId)
            throw new RuntimeException("not allowed !");

        if (!ordre.getStatus().equals(Ordre.CONFIRMED))
            throw new RuntimeException("Order must be CONFIRMED !");

        if (!paymentRepository.existsByOrdreId(ordreId))
            throw new RuntimeException("Payment not made !");

        ordre.setStatus(Ordre.PICKED);
        ordre.setCompletedAt(LocalDateTime.now());
        ordreRepository.save(ordre);

        clientService.updateTotalSpent(
            ordre.getClientId(), ordre.getTotalPrice());

        marchandService.updateRevenue(
            ordre.getMarchandId(), ordre.getTotalPrice());

        notificationService.sendNotification(
            clientId,
            "Order recovered ✅",
            "Your order #" + ordreId +
            " It has been successfully recovered. Thank you. !",
            NotificationType.ORDER_COMPLETED);

        notificationService.sendNotification(
            ordre.getMarchandId(),
            "Order completed ✅",
            "The order#" + ordreId +
            " was retrieved by the client.",
            NotificationType.PAYMENT_RECEIVED);
    }

    // ═══════════════════════════════════════════════
    //  rejectOrdre()
    // ═══════════════════════════════════════════════
    public void rejectOrdre(int ordreId, int marchandId) {

        Ordre ordre = ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Order not found !"));

        if (ordre.getMarchandId() != marchandId)
            throw new RuntimeException("not allowed !");

        offreService.decrementReservations(ordre.getOffreId());

        ordre.setStatus(Ordre.CANCELLED);
        ordreRepository.save(ordre);

        Offre offre = offreRepository
            .findById(ordre.getOffreId()).orElse(null);
        String offreTitle = offre != null
            ? offre.getTitle() : "votre offre";

        notificationService.sendNotification(
            ordre.getClientId(),
            "Reservation rejected ❌",
            "Your reservation for \"" + offreTitle +
            "\" was rejected by the merchant.",
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
                new RuntimeException("Order not found !"));

        if (ordre.getMarchandId() != marchandId)
            throw new RuntimeException("not allowed !");

        if (!ordre.getStatus().equals(Ordre.CONFIRMED))
            throw new RuntimeException(
                "Tracking available only for CONFIRMED orders !");

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
                new RuntimeException("Order not found !"));
        return locationRepository
            .findByOrdreIdOrderByTimestampDesc(ordreId);
    }

    // ═══════════════════════════════════════════════
    //  getOrdreById()
    // ═══════════════════════════════════════════════
    public Ordre getOrdreById(int ordreId) {
        return ordreRepository.findById(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Order not found !"));
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
    public List<Ordre> getPendingOrdresByMarchand(int marchandId) {
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
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("ordreId",    o.getId());
            map.put("status",     o.getStatus());
            map.put("totalPrice", o.getTotalPrice());
            map.put("quantity",   o.getQuantity());
            map.put("createdAt",  o.getCreatedAt());
            map.put("clientId",   o.getClientId());

            try {
                Object[] user = (Object[]) entityManager
                    .createNativeQuery(
                        "SELECT first_name, surname, profile_image " +
                        "FROM users WHERE id = :id")
                    .setParameter("id", o.getClientId())
                    .getSingleResult();

                map.put("firstName",    user[0] != null ? user[0] : "");
                map.put("surname",      user[1] != null ? user[1] : "");
                map.put("profilePhoto", user[2] != null ? user[2] : "");
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
    public List<Map<String, Object>> getOrdresByClientWithDetails(int clientId) {

        List<Ordre> ordres = ordreRepository.findByClientId(clientId);
        List<Map<String, Object>> result = new ArrayList<>();

        for (Ordre o : ordres) {
            Map<String, Object> map = new LinkedHashMap<>();

            map.put("ordreId",    o.getId());
            map.put("status",     o.getStatus());
            map.put("totalPrice", o.getTotalPrice());
            map.put("quantity",   o.getQuantity());
            map.put("createdAt",  o.getCreatedAt());

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
    }
}