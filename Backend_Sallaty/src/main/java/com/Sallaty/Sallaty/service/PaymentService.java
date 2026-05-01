package com.Sallaty.Sallaty.service;

import java.math.BigDecimal;
import java.math.RoundingMode;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.Dto.PaymentDTO;
import com.Sallaty.Sallaty.Dto.PaymentRequest;
import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.Ordre;
import com.Sallaty.Sallaty.model.Payment;
import com.Sallaty.Sallaty.model.PaymentMethod;
import com.Sallaty.Sallaty.model.PaymentStatus;
import com.Sallaty.Sallaty.repository.OrdreRepository;
import com.Sallaty.Sallaty.repository.PaymentRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class PaymentService {

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private OrdreRepository ordreRepository;

    @Autowired
    private NotificationService notificationService;

    @PersistenceContext
    private EntityManager entityManager;

    @Value("${app.platform.commission-rate:0.10}")
    private BigDecimal commissionRate;

    @Value("${app.transport.base-cost:450}")
    private BigDecimal baseTransportCost;

    // ═══════════════════════════════════════════════
    //  HELPER — native SQL
    // ═══════════════════════════════════════════════
    private Object[] getUserRow(int userId) {
        try {
            return (Object[]) entityManager
                .createNativeQuery(
                    "SELECT id, account_state " +
                    "FROM users WHERE id = :id")
                .setParameter("id", userId)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════
    //  pay()
    // ═══════════════════════════════════════════════
    @Transactional
    public PaymentDTO pay(int buyerId, PaymentRequest request) {

        if (request.getOrdreId() <= 0)
            throw new IllegalArgumentException("OrdreId invalide !");

        Ordre ordre = ordreRepository
            .findById(request.getOrdreId())
            .orElseThrow(() ->
                new RuntimeException("Ordre non trouvé !"));

        if (ordre.getClientId() != buyerId)
            throw new RuntimeException("Pas autorisé !");

        if (ordre.getStatus().equals(Ordre.CANCELLED))
            throw new RuntimeException("Ordre annulé !");

        if (!ordre.getStatus().equals(Ordre.CONFIRMED))
            throw new RuntimeException("Ordre doit être CONFIRMED !");

        if (paymentRepository.existsByOrdreId(request.getOrdreId()))
            throw new RuntimeException("Ordre déjà payé !");

        if (request.getMethod() == null)
            throw new IllegalArgumentException(
                "Méthode de paiement obligatoire !");

        // ✅ Validation carte
        if (request.getMethod() == PaymentMethod.CARD) {
            if (request.getCardNumber() == null ||
                request.getCardNumber().isEmpty())
                throw new IllegalArgumentException(
                    "Numéro de carte obligatoire !");
            if (request.getExpiryDate() == null ||
                request.getExpiryDate().isEmpty())
                throw new IllegalArgumentException(
                    "Date d'expiration obligatoire !");
            if (request.getCvv() == null ||
                request.getCvv().isEmpty())
                throw new IllegalArgumentException(
                    "CVV obligatoire !");
            if (request.getCardholderName() == null ||
                request.getCardholderName().isEmpty())
                throw new IllegalArgumentException(
                    "Nom du titulaire obligatoire !");
        }

        // ✅ native SQL — pas de cast JPA
        Object[] buyer = getUserRow(buyerId);
        if (buyer == null)
            throw new RuntimeException("User non trouvé !");

        String accountState = (String) buyer[1];
        if ("BLOCKED".equals(accountState))
            throw new RuntimeException("Compte bloqué !");

        BigDecimal transportCost = baseTransportCost
            .setScale(2, RoundingMode.HALF_UP);

        BigDecimal platformCommission = BigDecimal
            .valueOf(ordre.getTotalPrice())
            .multiply(commissionRate)
            .setScale(2, RoundingMode.HALF_UP);

        BigDecimal amount = BigDecimal
            .valueOf(ordre.getTotalPrice())
            .add(transportCost)
            .add(platformCommission)
            .setScale(2, RoundingMode.HALF_UP);

        BigDecimal marchandAmount = BigDecimal
            .valueOf(ordre.getTotalPrice())
            .subtract(platformCommission)
            .setScale(2, RoundingMode.HALF_UP);

        Payment payment = new Payment();
        payment.setOrdreId(request.getOrdreId());
        payment.setUserId(buyerId);
        payment.setMethod(request.getMethod());
        payment.setTransportCost(transportCost);
        payment.setPlatformCommission(platformCommission);
        payment.setAmount(amount);
        payment.setStatus(PaymentStatus.SUCCESS);

        Payment savedPayment = paymentRepository.save(payment);

        notificationService.sendNotification(
            buyerId,
            "Paiement réussi ✅",
            "Votre paiement de " + amount +
            " DA pour la commande #" +
            request.getOrdreId() +
            " a été effectué avec succès.",
            NotificationType.PAYMENT_SUCCESS);

        notificationService.sendNotification(
            ordre.getMarchandId(),
            "Paiement reçu 💰",
            "Vous avez reçu un paiement de " +
            marchandAmount + " DA pour la commande #" +
            request.getOrdreId() + ".",
            NotificationType.PAYMENT_RECEIVED);

        return convertToDTO(savedPayment);
    }

    // ═══════════════════════════════════════════════
    //  calculateCommission()
    // ═══════════════════════════════════════════════
    public BigDecimal calculateCommission(
            BigDecimal totalPrice) {

        if (totalPrice == null ||
            totalPrice.compareTo(BigDecimal.ZERO) <= 0)
            throw new IllegalArgumentException("Prix invalide !");

        return totalPrice
            .multiply(commissionRate)
            .setScale(2, RoundingMode.HALF_UP);
    }

    // ═══════════════════════════════════════════════
    //  getPaymentByOrdre()
    // ═══════════════════════════════════════════════
    public PaymentDTO getPaymentByOrdre(int ordreId) {
        Payment payment = paymentRepository
            .findByOrdreId(ordreId)
            .orElseThrow(() ->
                new RuntimeException("Payment non trouvé !"));
        return convertToDTO(payment);
    }

    // ═══════════════════════════════════════════════
    //  convertToDTO()
    // ═══════════════════════════════════════════════
    public PaymentDTO convertToDTO(Payment payment) {
        return new PaymentDTO(
            payment.getId(),
            payment.getOrdreId(),
            payment.getUserId(),
            payment.getAmount(),
            payment.getMethod(),
            payment.getStatus(),
            payment.getTransportCost(),
            payment.getPlatformCommission(),
            payment.getCreatedAt());
    }
}