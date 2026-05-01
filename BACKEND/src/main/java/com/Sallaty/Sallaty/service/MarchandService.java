package com.Sallaty.Sallaty.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.Dto.MarchandDTO;
import com.Sallaty.Sallaty.model.Marchand;
import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.Offre;
import com.Sallaty.Sallaty.model.StatusMarchand;
import com.Sallaty.Sallaty.model.User;
import com.Sallaty.Sallaty.repository.MarchandRepository;
import com.Sallaty.Sallaty.repository.OffreRepository;
import com.Sallaty.Sallaty.repository.UserRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class MarchandService {

    @Autowired private MarchandRepository marchandRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private RoleService roleService;
    @Autowired private NotificationService notificationService;
    @Autowired private OffreRepository offreRepository;

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  HELPER — SQL pur, zéro cast JPA
    //  colonnes: 0=user_id, 1=full_name, 2=business_name,
    //            3=business_type, 4=trade_register,
    //            5=status_marchand, 6=revenue,
    //            7=nb_followers, 8=wilaya, 9=phone_number
    // ═══════════════════════════════════════════════
    private Object[] getMarchandRow(int userId) {
        try {
            return (Object[]) entityManager
                .createNativeQuery(
                    "SELECT m.user_id, m.full_name, m.business_name, " +
                    "m.business_type, m.trade_register, " +
                    "m.status_marchand, m.revenue, m.nb_followers, " +
                    "u.wilaya, u.phone_number " +
                    "FROM marchands m " +
                    "JOIN users u ON u.id = m.user_id " +
                    "WHERE m.user_id = :userId")
                .setParameter("userId", userId)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════
    //  HELPER — Object[] → MarchandDTO
    // ═══════════════════════════════════════════════
    private MarchandDTO rowToDTO(Object[] row) {
        MarchandDTO dto = new MarchandDTO();
        dto.setId(           row[0] != null ? ((Number) row[0]).intValue() : 0);
        dto.setFullName(     (String) row[1]);
        dto.setBusinessName( (String) row[2]);
        dto.setBusinessType( (String) row[3]);
        dto.setTradeRegister((String) row[4]);
        dto.setStatusMarchand(
            row[5] != null ? StatusMarchand.valueOf((String) row[5]) : null);
        dto.setRevenue(
            row[6] != null ? ((Number) row[6]).doubleValue() : 0.0);
        dto.setNbFollowers(
            row[7] != null ? ((Number) row[7]).intValue() : 0);
        dto.setWilaya(      (String) row[8]);
        dto.setPhoneNumber( (String) row[9]);
        return dto;
    }

    // ═══════════════════════════════════════════════
    //  HELPER — convertToDTO(Marchand)
    //  phoneNumber vient de User (héritage)
    // ═══════════════════════════════════════════════
    public MarchandDTO convertToDTO(Marchand marchand) {
        MarchandDTO dto = new MarchandDTO();
        dto.setId(            marchand.getId());
        dto.setFullName(      marchand.getFullName());
        dto.setBusinessName(  marchand.getBusinessName());
        dto.setBusinessType(  marchand.getBusinessType());
        dto.setWilaya(        marchand.getWilaya());
        dto.setPhoneNumber(   marchand.getPhoneNumber()); // vient de User
        dto.setTradeRegister( marchand.getTradeRegister());
        dto.setStatusMarchand(marchand.getStatusMarchand());
        dto.setRevenue(       marchand.getRevenue());
        dto.setNbFollowers(   marchand.getNbFollowers());
        return dto;
    }

    // ═══════════════════════════════════════════════
    //  registerAsMarchand()
    // ═══════════════════════════════════════════════
    @Transactional
    public void registerAsMarchand(
            int userId,
            String fullName,
            String shopName,
            String typeOfActivity,
            String wilaya,
            String phoneNumber,
            String tradeRegister) {

        if (!userRepository.existsById(userId))
            throw new RuntimeException("User non trouvé !");

        if (marchandRepository.existsByBusinessName(shopName))
            throw new RuntimeException("Shop name déjà utilisé !");

        if (tradeRegister == null || tradeRegister.trim().isEmpty())
            throw new IllegalArgumentException("Trade register obligatoire !");

        if (!validatePhoneNumberFormat(phoneNumber))
            throw new IllegalArgumentException("Numéro de téléphone invalide !");

        // phone_number et wilaya → dans users
        entityManager.createNativeQuery(
            "UPDATE users SET phone_number = :phoneNumber, wilaya = :wilaya " +
            "WHERE id = :userId")
            .setParameter("phoneNumber", phoneNumber)
            .setParameter("wilaya",      wilaya)
            .setParameter("userId",      userId)
            .executeUpdate();

        // INSERT marchands — sans phone_number ni nb_offres
        entityManager.createNativeQuery(
            "INSERT INTO marchands (user_id, full_name, business_name, " +
            "business_type, trade_register, status_marchand, revenue, nb_followers) " +
            "VALUES (:userId, :fullName, :shopName, :typeOfActivity, " +
            ":tradeRegister, 'PENDING', 0.0, 0)")
            .setParameter("userId",         userId)
            .setParameter("fullName",       fullName)
            .setParameter("shopName",       shopName)
            .setParameter("typeOfActivity", typeOfActivity)
            .setParameter("tradeRegister",  tradeRegister)
            .executeUpdate();

        List<User> admins = userRepository.findByAccountType("ADMIN");
        for (User admin : admins) {
            notificationService.sendNotification(
                admin.getId(),
                "Nouvelle demande marchand 🏪",
                "Le marchand \"" + shopName + "\" attend votre vérification.",
                NotificationType.NEW_MARCHAND_REQUEST);
        }
    }

    // ═══════════════════════════════════════════════
    //  validatePhoneNumberFormat()
    // ═══════════════════════════════════════════════
    private boolean validatePhoneNumberFormat(String phone) {
        if (phone == null || phone.isEmpty()) return false;
        return phone.matches("^(\\+213|0)[567][0-9]{8}$");
    }

    // ═══════════════════════════════════════════════
    //  getMarchandById()
    // ═══════════════════════════════════════════════
    public MarchandDTO getMarchandById(int userId) {
        Object[] row = getMarchandRow(userId);
        if (row == null)
            throw new RuntimeException("Marchand non trouvé : " + userId);
        return rowToDTO(row);
    }

    // ═══════════════════════════════════════════════
    //  getPendingMarchands()
    // ═══════════════════════════════════════════════
    public List<MarchandDTO> getPendingMarchands() {
        return marchandRepository.findPending()
            .stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
    //  getVerifiedMarchands()
    // ═══════════════════════════════════════════════
    public List<MarchandDTO> getVerifiedMarchands() {
        return marchandRepository.findVerified()
            .stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
    //  getCancelledMarchands()
    // ═══════════════════════════════════════════════
    public List<MarchandDTO> getCancelledMarchands() {
        return marchandRepository.findCancelled()
            .stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
    //  getMarchandsByStatus()
    // ═══════════════════════════════════════════════
    public List<MarchandDTO> getMarchandsByStatus(StatusMarchand status) {
        return marchandRepository.findByStatusMarchand(status.name())
            .stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
    //  getTradeRegister()
    // ═══════════════════════════════════════════════
    public String getTradeRegister(int userId) {
        Object[] row = getMarchandRow(userId);
        if (row == null)
            throw new RuntimeException("Marchand non trouvé : " + userId);
        return (String) row[4];
    }

    // ═══════════════════════════════════════════════
    //  verifyMarchand()
    // ═══════════════════════════════════════════════
    @Transactional
    public void verifyMarchand(int userId) {
        Object[] row = getMarchandRow(userId);
        if (row == null)
            throw new RuntimeException("Marchand non trouvé : " + userId);

        if (StatusMarchand.VERIFIED.name().equals((String) row[5]))
            throw new RuntimeException("Marchand déjà vérifié !");

        entityManager.createNativeQuery(
            "UPDATE marchands SET status_marchand = 'VERIFIED' WHERE user_id = :userId")
            .setParameter("userId", userId)
            .executeUpdate();

        roleService.updateRole(userId, "MARCHANT");

        notificationService.sendNotification(
            userId, "Compte vérifié ✅",
            "Votre compte marchand \"" + row[2] + "\" a été vérifié !",
            NotificationType.MARCHAND_VERIFIED);
    }

    // ═══════════════════════════════════════════════
    //  cancelMarchand()
    // ═══════════════════════════════════════════════
    @Transactional
    public void cancelMarchand(int userId) {
        Object[] row = getMarchandRow(userId);
        if (row == null)
            throw new RuntimeException("Marchand non trouvé : " + userId);

        if (StatusMarchand.CANCELLED.name().equals((String) row[5]))
            throw new RuntimeException("Marchand déjà annulé !");

        entityManager.createNativeQuery(
            "UPDATE marchands SET status_marchand = 'CANCELLED' WHERE user_id = :userId")
            .setParameter("userId", userId)
            .executeUpdate();

        roleService.updateRole(userId, "CLIENT");

        notificationService.sendNotification(
            userId, "Demande refusée ❌",
            "Votre demande marchand \"" + row[2] + "\" a été refusée.",
            NotificationType.MARCHAND_CANCELLED);
    }

    // ═══════════════════════════════════════════════
    //  reactivateMarchand()
    // ═══════════════════════════════════════════════
    @Transactional
    public void reactivateMarchand(int userId) {
        Object[] row = getMarchandRow(userId);
        if (row == null)
            throw new RuntimeException("Marchand non trouvé : " + userId);

        if (StatusMarchand.PENDING.name().equals((String) row[5]))
            throw new RuntimeException("Marchand déjà en attente !");

        entityManager.createNativeQuery(
            "UPDATE marchands SET status_marchand = 'PENDING' WHERE user_id = :userId")
            .setParameter("userId", userId)
            .executeUpdate();

        roleService.updateRole(userId, "CLIENT");

        notificationService.sendNotification(
            userId, "Compte réactivé 🔄",
            "Votre compte marchand \"" + row[2] + "\" a été réactivé.",
            NotificationType.MARCHAND_REACTIVATED);
    }

    // ═══════════════════════════════════════════════
    //  updateRevenue()
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateRevenue(int userId, double amount) {
        if (getMarchandRow(userId) == null)
            throw new RuntimeException("Marchand non trouvé : " + userId);

        if (amount <= 0)
            throw new IllegalArgumentException("Montant invalide : " + amount);

        entityManager.createNativeQuery(
            "UPDATE marchands SET revenue = revenue + :amount WHERE user_id = :userId")
            .setParameter("amount", amount)
            .setParameter("userId", userId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  updateNbFollowers()
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateNbFollowers(int userId, int count) {
        if (getMarchandRow(userId) == null)
            throw new RuntimeException("Marchand non trouvé : " + userId);

        entityManager.createNativeQuery(
            "UPDATE marchands SET nb_followers = :count WHERE user_id = :userId")
            .setParameter("count", count)
            .setParameter("userId", userId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  getTotalFavoris()
    // ═══════════════════════════════════════════════
    public int getTotalFavoris(int marchandId) {
        return offreRepository
            .findByMarchandId(marchandId)
            .stream()
            .mapToInt(Offre::getNbFavoris)
            .sum();
    }

    // ═══════════════════════════════════════════════
    //  getStatistics()
    // ═══════════════════════════════════════════════
    @SuppressWarnings("unchecked")
public Map<String, Object> getStatistics(int marchandId) {

    Map<String, Object> stats = new java.util.LinkedHashMap<>();

    // ── Total Offres ──────────────────────────────────────────────
    long totalOffres = ((Number) entityManager
        .createNativeQuery(
            "SELECT COUNT(*) FROM offres WHERE marchand_id = :id")
        .setParameter("id", marchandId)
        .getSingleResult()).longValue();

    // ── Total Orders ──────────────────────────────────────────────
    long totalOrders = ((Number) entityManager
        .createNativeQuery(
            "SELECT COUNT(*) FROM ordres WHERE marchand_id = :id")
        .setParameter("id", marchandId)
        .getSingleResult()).longValue();

    // ── Total Completed ───────────────────────────────────────────
    long totalCompleted = ((Number) entityManager
        .createNativeQuery(
            "SELECT COUNT(*) FROM ordres " +
            "WHERE marchand_id = :id AND UPPER(status) = 'COMPLETED'")
        .setParameter("id", marchandId)
        .getSingleResult()).longValue();

    // ── Total Revenue ─────────────────────────────────────────────
    double totalRevenue = ((Number) entityManager
        .createNativeQuery(
            "SELECT COALESCE(SUM(total_price), 0) FROM ordres " +
            "WHERE marchand_id = :id AND UPPER(status) = 'COMPLETED'")
        .setParameter("id", marchandId)
        .getSingleResult()).doubleValue();

    // ── Total Followers ───────────────────────────────────────────
    long totalFollowers = 0;
    try {
        totalFollowers = ((Number) entityManager
            .createNativeQuery(
                "SELECT COALESCE(nb_followers, 0) FROM marchands " +
                "WHERE user_id = :id")
            .setParameter("id", marchandId)
            .getSingleResult()).longValue();
    } catch (Exception ignored) {}

    // ── Active Offres ─────────────────────────────────────────────
    long activeOffres = ((Number) entityManager
        .createNativeQuery(
            "SELECT COUNT(*) FROM offres " +
            "WHERE marchand_id = :id AND UPPER(status) = 'ACTIVE'")
        .setParameter("id", marchandId)
        .getSingleResult()).longValue();

    // ── Total Likes (nb_favoris) ──────────────────────────────────
    long totalLikes = 0;
    try {
        totalLikes = ((Number) entityManager
            .createNativeQuery(
                "SELECT COALESCE(SUM(nb_favoris), 0) FROM offres " +
                "WHERE marchand_id = :id")
            .setParameter("id", marchandId)
            .getSingleResult()).longValue();
    } catch (Exception ignored) {}

    // ── Revenue Today ─────────────────────────────────────────────
    double revenueToday = 0;
    try {
        revenueToday = ((Number) entityManager
            .createNativeQuery(
                "SELECT COALESCE(SUM(total_price), 0) FROM ordres " +
                "WHERE marchand_id = :id " +
                "AND UPPER(status) = 'COMPLETED' " +
                "AND DATE(created_at) = CURDATE()")
            .setParameter("id", marchandId)
            .getSingleResult()).doubleValue();
    } catch (Exception ignored) {}

    // ── Revenue This Week ─────────────────────────────────────────
    double revenueWeek = 0;
    try {
        revenueWeek = ((Number) entityManager
            .createNativeQuery(
                "SELECT COALESCE(SUM(total_price), 0) FROM ordres " +
                "WHERE marchand_id = :id " +
                "AND UPPER(status) = 'COMPLETED' " +
                "AND YEARWEEK(created_at, 1) = YEARWEEK(CURDATE(), 1)")
            .setParameter("id", marchandId)
            .getSingleResult()).doubleValue();
    } catch (Exception ignored) {}

    // ── Revenue This Month ────────────────────────────────────────
    double revenueMonth = 0;
    try {
        revenueMonth = ((Number) entityManager
            .createNativeQuery(
                "SELECT COALESCE(SUM(total_price), 0) FROM ordres " +
                "WHERE marchand_id = :id " +
                "AND UPPER(status) = 'COMPLETED' " +
                "AND MONTH(created_at) = MONTH(CURDATE()) " +
                "AND YEAR(created_at)  = YEAR(CURDATE())")
            .setParameter("id", marchandId)
            .getSingleResult()).doubleValue();
    } catch (Exception ignored) {}

    // ── Revenue Chart (30 days) ───────────────────────────────────
    List<Integer> revenueChart = new java.util.ArrayList<>(
        java.util.Collections.nCopies(30, 0));
    try {
        List<Object[]> chartRows = entityManager
            .createNativeQuery(
                "SELECT DAY(created_at) AS day, " +
                "COALESCE(SUM(total_price), 0) AS rev " +
                "FROM ordres " +
                "WHERE marchand_id = :id " +
                "AND UPPER(status) = 'COMPLETED' " +
                "AND MONTH(created_at) = MONTH(CURDATE()) " +
                "AND YEAR(created_at)  = YEAR(CURDATE()) " +
                "GROUP BY DAY(created_at)")
            .setParameter("id", marchandId)
            .getResultList();

        for (Object[] row : chartRows) {
            int day = ((Number) row[0]).intValue();
            int rev = ((Number) row[1]).intValue();
            if (day >= 1 && day <= 30) {
                revenueChart.set(day - 1, rev);
            }
        }
    } catch (Exception ignored) {}

    // ── Top Selling Items ─────────────────────────────────────────
    List<Map<String, Object>> topItems = new java.util.ArrayList<>();
    try {
        List<Object[]> topRows = entityManager
            .createNativeQuery(
                "SELECT o.title, o.photo, COUNT(r.id) AS cnt " +
                "FROM ordres r " +
                "JOIN offres o ON o.id = r.offre_id " +
                "WHERE r.marchand_id = :id " +
                "GROUP BY o.id, o.title, o.photo " +
                "ORDER BY cnt DESC LIMIT 5")
            .setParameter("id", marchandId)
            .getResultList();

        for (Object[] row : topRows) {
            Map<String, Object> item = new java.util.LinkedHashMap<>();
            item.put("title", row[0] != null ? row[0].toString() : "");
            String photoPath = row[1] != null ? row[1].toString() : "";
            item.put("photoUrl", photoPath.isEmpty() ? ""
                : (photoPath.startsWith("http") ? photoPath
                   : "https://ethanol-hemstitch-strongbox.ngrok-free.dev/" + photoPath));
            item.put("count", ((Number) row[2]).intValue());
            topItems.add(item);
        }
    } catch (Exception ignored) {}

    // ── New Followers ─────────────────────────────────────────────
    List<Map<String, Object>> newFollowers = new java.util.ArrayList<>();
    try {
        List<Object[]> followerRows = entityManager
            .createNativeQuery(
                "SELECT u.id, u.first_name, u.surname, u.profile_image " +
                "FROM subscribes s " +
                "JOIN users u ON u.id = s.user_id " +
                "WHERE s.marchand_id = :id " +
                "ORDER BY s.created_at DESC LIMIT 5")
            .setParameter("id", marchandId)
            .getResultList();

        for (Object[] row : followerRows) {
            Map<String, Object> f = new java.util.LinkedHashMap<>();
            f.put("clientId", row[0]);
            f.put("name",
                (row[1] != null ? row[1].toString() : "") + " " +
                (row[2] != null ? row[2].toString() : ""));
            String profileImg = row[3] != null ? row[3].toString() : "";
            f.put("profilePhoto", profileImg.isEmpty() ? ""
                : (profileImg.startsWith("http") ? profileImg
                   : "https://ethanol-hemstitch-strongbox.ngrok-free.dev/" + profileImg));
            newFollowers.add(f);
        }
    } catch (Exception ignored) {}

    // ── Build response ────────────────────────────────────────────
    stats.put("totalOffers",     totalOffres);
    stats.put("totalOrders",     totalOrders);
    stats.put("totalCompleted",  totalCompleted);
    stats.put("totalRevenue",    (int) totalRevenue);
    stats.put("totalFollowers",  totalFollowers);
    stats.put("totalLikes",      totalLikes);
    stats.put("activeOffres",    activeOffres);
    stats.put("revenueToday",    (int) revenueToday);
    stats.put("revenueWeek",     (int) revenueWeek);
    stats.put("revenueMonth",    (int) revenueMonth);
    stats.put("revenueChart",    revenueChart);
    stats.put("topSellingItems", topItems);
    stats.put("newFollowers",    newFollowers);

    return stats;
}
}