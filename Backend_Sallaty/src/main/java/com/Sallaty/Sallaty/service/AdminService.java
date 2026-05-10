package com.Sallaty.Sallaty.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.Dto.AdminDTO;
import com.Sallaty.Sallaty.repository.AdminRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class AdminService {

    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    private AdminRepository adminRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public List<AdminDTO> getAllAdmins() {
        return adminRepository.findAllWithUserInfo()
            .stream()
            .map(row -> new AdminDTO(
                ((Number) row[0]).intValue(),
                (String) row[1],
                (String) row[2],
                (String) row[3],
                (String) row[4],
                (String) row[5],
                (String) row[6]))
            .collect(Collectors.toList());
    }

    @Transactional
    public AdminDTO createAdmin(
            String firstName,
            String lastName,
            String email,
            String password,
            String roleadmin,
            String permissions) {

        Long exists = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM users " +
                "WHERE contact = :email")
            .setParameter("email", email)
            .getSingleResult()).longValue();

        if (exists > 0)
            throw new RuntimeException("Email déjà utilisé !");

        if (!roleadmin.equals("SUPER_ADMIN") &&
            !roleadmin.equals("NORMAL_ADMIN"))
            throw new RuntimeException(
                "Role invalide ! (SUPER_ADMIN / NORMAL_ADMIN)");

        entityManager.createNativeQuery(
            "INSERT INTO users " +
            "(first_name, surname, contact, " +
            "passe_word, account_type, " +
            "account_state, nb_offer, nb_order, " +
            "balance, created_at) " +
            "VALUES (:firstName, :lastName, " +
            ":email, :password, " +
            "'ADMIN', 'ACTIVE', 0, 0, 0.0, NOW())")
            .setParameter("firstName", firstName)
            .setParameter("lastName",  lastName)
            .setParameter("email",     email)
            .setParameter("password",
                passwordEncoder.encode(password))
            .executeUpdate();

        entityManager.flush();
        entityManager.clear();

        int newUserId = ((Number) entityManager
            .createNativeQuery(
                "SELECT id FROM users WHERE contact = :email")
            .setParameter("email", email)
            .getSingleResult()).intValue();

        entityManager.createNativeQuery(
            "INSERT INTO admins (user_id, roleadmin, permissions) " +
            "VALUES (:userId, :roleadmin, :permissions)")
            .setParameter("userId",      newUserId)
            .setParameter("roleadmin",   roleadmin)
            .setParameter("permissions",
                permissions != null ? permissions : "")
            .executeUpdate();

        entityManager.createNativeQuery(
            "INSERT INTO roles (iduser, rolename, createat) " +
            "VALUES (:userId, 'ADMIN', NOW())")
            .setParameter("userId", newUserId)
            .executeUpdate();

        return new AdminDTO(
            newUserId, firstName, lastName,
            email, null, roleadmin,
            permissions != null ? permissions : "");
    }

    @Transactional
    public void deleteAdmin(int userId) {

        if (!adminRepository.existsByUserId(userId))
            throw new RuntimeException("Admin not found !");

        entityManager.createNativeQuery(
            "DELETE FROM roles WHERE iduser = :id")
            .setParameter("id", userId)
            .executeUpdate();

        entityManager.createNativeQuery(
            "DELETE FROM admins WHERE user_id = :id")
            .setParameter("id", userId)
            .executeUpdate();

        entityManager.createNativeQuery(
            "DELETE FROM users WHERE id = :id")
            .setParameter("id", userId)
            .executeUpdate();
    }

    public Map<String, Object> getDashboardStats() {

        long totalUsers = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM users " +
                "WHERE account_type != 'ADMIN'")
            .getSingleResult()).longValue();

        long totalMerchants = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM marchands " +
                "WHERE status_marchand = 'VERIFIED'")
            .getSingleResult()).longValue();

        long totalOffers = ((Number) entityManager
            .createNativeQuery("SELECT COUNT(*) FROM offres")
            .getSingleResult()).longValue();

        long totalOrders = ((Number) entityManager
            .createNativeQuery("SELECT COUNT(*) FROM reservations")
            .getSingleResult()).longValue();

        double totalRevenue = ((Number) entityManager
            .createNativeQuery(
                "SELECT COALESCE(SUM(revenue), 0) FROM marchands")
            .getSingleResult()).doubleValue();

        double foodSaved = ((Number) entityManager
            .createNativeQuery(
                "SELECT COALESCE(SUM(quantity), 0) FROM offres " +
                "WHERE status IN ('SOLD_OUT','RESERVED')")
            .getSingleResult()).doubleValue();

        return Map.of(
            "totalUsers",     totalUsers,
            "totalMerchants", totalMerchants,
            "totalOffers",    totalOffers,
            "totalOrders",    totalOrders,
            "totalRevenue",   totalRevenue,
            "foodSaved",      foodSaved);
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getTopMerchants() {

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT m.business_name, m.revenue " +
                "FROM marchands m " +
                "WHERE m.status_marchand = 'VERIFIED' " +
                "ORDER BY m.revenue DESC LIMIT 5")
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("businessName", (String) row[0]);
                map.put("revenue",
                    ((Number) row[1]).doubleValue());
                return map;
            })
            .collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getUserManagement(String filter) {

        String condition = switch (
                filter != null ? filter.toUpperCase() : "ALL") {
            case "ACTIVE"  -> "WHERE u.account_state = 'ACTIVE' ";
            case "BLOCKED" -> "WHERE u.account_state = 'BLOCKED' ";
            default        -> "";
        };

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT u.id, u.first_name, u.surname, u.contact, " +
                "u.account_state, u.created_at, " +
                "u.last_connection, u.profile_image " +
                "FROM users u "
                + condition +
                "ORDER BY u.created_at DESC")
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("id",             ((Number) row[0]).intValue());
                map.put("firstName",      (String) row[1]);
                map.put("surname",        (String) row[2]);
                map.put("contact",        (String) row[3]);
                map.put("accountState",   row[4]);
                map.put("createdAt",      row[5]);
                map.put("lastConnection", row[6]);
                map.put("profileImage",   (String) row[7]);
                return map;
            })
            .collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> getUserProfile(int userId) {

        Object[] row;
        try {
            row = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT u.id, u.first_name, u.surname, u.contact, " +
                    "u.phone_number, u.wilaya, u.account_state, " +
                    "u.created_at, u.last_connection, u.profile_image " +
                    "FROM users u WHERE u.id = :id")
                .setParameter("id", userId)
                .getSingleResult();
        } catch (Exception e) {
            throw new RuntimeException("User not found !");
        }

        long totalOrders = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM reservations WHERE client_id = :id")
            .setParameter("id", userId)
            .getSingleResult()).longValue();

        long totalFavoris = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM offre_favoris WHERE user_id = :id")
            .setParameter("id", userId)
            .getSingleResult()).longValue();

        Map<String, Object> map = new HashMap<>();
        map.put("id",             ((Number) row[0]).intValue());
        map.put("firstName",      (String) row[1]);
        map.put("surname",        (String) row[2]);
        map.put("contact",        (String) row[3]);
        map.put("phoneNumber",    (String) row[4]);
        map.put("wilaya",         (String) row[5]);
        map.put("accountState",   row[6]);
        map.put("createdAt",      row[7]);
        map.put("lastConnection", row[8]);
        map.put("profileImage",   (String) row[9]);
        map.put("totalOrders",    totalOrders);
        map.put("totalFavoris",   totalFavoris);
        return map;
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getUserOrders(int userId) {

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT r.id, o.title, o.photo, o.price, " +
                "r.quantity, r.total_price, r.status, r.created_at, " +
                "m.business_name, u.wilaya " +
                "FROM reservations r " +
                "JOIN offres o ON o.id = r.offre_id " +
                "JOIN marchands m ON m.user_id = r.marchand_id " +
                "JOIN users u ON u.id = r.marchand_id " +
                "WHERE r.client_id = :id " +
                "ORDER BY r.created_at DESC")
            .setParameter("id", userId)
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("ordreId",      ((Number) row[0]).intValue());
                map.put("title",        (String) row[1]);
                map.put("photo",        (String) row[2]);
                map.put("price",        ((Number) row[3]).doubleValue());
                map.put("quantity",     ((Number) row[4]).intValue());
                map.put("totalPrice",   ((Number) row[5]).doubleValue());
                map.put("status",       (String) row[6]);
                map.put("createdAt",    row[7]);
                map.put("businessName", (String) row[8]);
                map.put("wilaya",       (String) row[9]);
                return map;
            })
            .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
//  getMerchantManagement()  — UPDATED
//  Replaces stored m.revenue with live SUM()
//  and uses getMerchantRevenue() per merchant
// ═══════════════════════════════════════════════
@SuppressWarnings("unchecked")
public List<Map<String, Object>> getMerchantManagement(String filter) {

    String condition = switch (
            filter != null ? filter.toUpperCase() : "ALL") {
        case "ACTIVE"  -> "AND m.status_marchand = 'VERIFIED' ";
        case "PENDING" -> "AND m.status_marchand = 'PENDING' ";
        case "BLOCKED" -> "AND m.status_marchand = 'CANCELLED' ";
        default        -> "";
    };

    // ✅ nbOffres computed live via subquery (already correct)
    // ✅ revenue now computed live via getMerchantRevenue()
    //    instead of relying on the stored m.revenue column
    List<Object[]> rows = entityManager
        .createNativeQuery(
            "SELECT m.user_id, m.business_name, m.full_name, " +
            "u.contact, m.status_marchand, " +
            "(SELECT COUNT(*) FROM offres o " +
            " WHERE o.marchand_id = m.user_id) AS nb_offres, " +
            "u.profile_image, u.wilaya " +
            "FROM marchands m " +
            "JOIN users u ON u.id = m.user_id "
            + condition +
            "ORDER BY m.full_name ASC")
        .getResultList();

    return rows.stream()
        .map(row -> {
            int userId = ((Number) row[0]).intValue();

            Map<String, Object> map = new HashMap<>();
            map.put("userId",       userId);
            map.put("businessName", (String) row[1]);
            map.put("fullName",     (String) row[2]);
            map.put("contact",      (String) row[3]);
            map.put("status",       (String) row[4]);
            map.put("nbOffres",     ((Number) row[5]).intValue());

            // ✅ Live revenue from completed reservations
            map.put("revenue",      getMerchantRevenue(userId));

            map.put("profileImage", (String) row[6]);
            map.put("wilaya",       (String) row[7]);
            return map;
        })
        .collect(Collectors.toList());
}

    @SuppressWarnings("unchecked")
    public Map<String, Object> getMerchantProfile(int userId) {

        Object[] row;
        try {
            row = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT m.user_id, u.first_name, u.surname, u.contact, " +
                    "u.phone_number, u.wilaya, m.business_name, m.business_type, " +
                    "m.trade_register, m.status_marchand, " +
                    "(SELECT COUNT(*) FROM offres o " +
                    " WHERE o.marchand_id = m.user_id) AS nb_offres, " +
                    "m.revenue, m.nb_followers, u.profile_image, " +
                    "u.created_at, u.last_connection " +
                    "FROM marchands m " +
                    "JOIN users u ON u.id = m.user_id " +
                    "WHERE m.user_id = :id")
                .setParameter("id", userId)
                .getSingleResult();
        } catch (Exception e) {
            throw new RuntimeException("Marchand not found !");
        }

        Map<String, Object> map = new HashMap<>();
        map.put("userId",         ((Number) row[0]).intValue());
        map.put("firstName",      (String) row[1]);
        map.put("surname",        (String) row[2]);
        map.put("contact",        (String) row[3]);
        map.put("phoneNumber",    (String) row[4]);
        map.put("wilaya",         (String) row[5]);
        map.put("businessName",   (String) row[6]);
        map.put("businessType",   (String) row[7]);
        map.put("tradeRegister",  (String) row[8]);
        map.put("status",         (String) row[9]);
        map.put("nbOffres",       ((Number) row[10]).intValue());
        map.put("revenue",        ((Number) row[11]).doubleValue());
        map.put("nbFollowers",    ((Number) row[12]).intValue());
        map.put("profileImage",   (String) row[13]);
        map.put("createdAt",      row[14]);
        map.put("lastConnection", row[15]);
        return map;
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getMerchantOrders(int userId) {

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT r.id, o.title, o.photo, r.total_price, " +
                "r.status, r.created_at, u.first_name, u.surname " +
                "FROM reservations r " +
                "JOIN offres o ON o.id = r.offre_id " +
                "JOIN users u ON u.id = r.client_id " +
                "WHERE r.marchand_id = :id " +
                "ORDER BY r.created_at DESC")
            .setParameter("id", userId)
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("ordreId",    ((Number) row[0]).intValue());
                map.put("title",      (String) row[1]);
                map.put("photo",      (String) row[2]);
                map.put("totalPrice", ((Number) row[3]).doubleValue());
                map.put("status",     (String) row[4]);
                map.put("createdAt",  row[5]);
                map.put("clientName", row[6] + " " + row[7]);
                return map;
            })
            .collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getMerchantOffers(int userId) {

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT o.id, o.title, o.photo, o.price, " +
                "o.quantity, o.status, o.created_at, o.expire_at " +
                "FROM offres o " +
                "WHERE o.marchand_id = :id " +
                "ORDER BY o.created_at DESC")
            .setParameter("id", userId)
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("offreId",   ((Number) row[0]).intValue());
                map.put("title",     (String) row[1]);
                map.put("photo",     (String) row[2]);
                map.put("price",     ((Number) row[3]).doubleValue());
                map.put("quantity",  ((Number) row[4]).intValue());
                map.put("status",    (String) row[5]);
                map.put("createdAt", row[6]);
                map.put("expireAt",  row[7]);
                return map;
            })
            .collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getOfferManagement(String filter) {

        String condition = switch (
                filter != null ? filter.toUpperCase() : "ALL") {
            case "ACTIVE"   -> "AND o.status = 'ACTIVE' ";
            case "SOLD_OUT" -> "AND o.status = 'SOLD_OUT' ";
            case "EXPIRED"  -> "AND o.status = 'EXPIRED' ";
            default         -> "";
        };

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT o.id, o.title, o.photo, o.price, " +
                "o.quantity, o.status, o.created_at, " +
                "m.business_name, u.wilaya " +
                "FROM offres o " +
                "JOIN marchands m ON m.user_id = o.marchand_id " +
                "JOIN users u ON u.id = o.marchand_id "
                + condition +
                "ORDER BY o.created_at DESC")
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("offreId",      ((Number) row[0]).intValue());
                map.put("title",        (String) row[1]);
                map.put("photo",        (String) row[2]);
                map.put("price",        ((Number) row[3]).doubleValue());
                map.put("quantity",     ((Number) row[4]).intValue());
                map.put("status",       (String) row[5]);
                map.put("createdAt",    row[6]);
                map.put("businessName", (String) row[7]);
                map.put("wilaya",       (String) row[8]);
                return map;
            })
            .collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getReservationManagement(String filter) {

        String condition = switch (
                filter != null ? filter.toUpperCase() : "ALL") {
            case "PENDING"   -> "AND r.status = 'PENDING' ";
            case "CONFIRMED" -> "AND r.status = 'CONFIRMED' ";
            case "PICKED"    -> "AND r.status = 'COMPLETED' ";
            default          -> "";
        };

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT r.id, o.title, o.photo, r.total_price, " +
                "r.status, r.created_at, " +
                "u.first_name, u.surname, m.business_name " +
                "FROM reservations r " +
                "JOIN offres o ON o.id = r.offre_id " +
                "JOIN users u ON u.id = r.client_id " +
                "JOIN marchands m ON m.user_id = r.marchand_id "
                + condition +
                "ORDER BY r.created_at DESC")
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("ordreId",      ((Number) row[0]).intValue());
                map.put("title",        (String) row[1]);
                map.put("photo",        (String) row[2]);
                map.put("totalPrice",   ((Number) row[3]).doubleValue());
                map.put("status",       (String) row[4]);
                map.put("createdAt",    row[5]);
                map.put("clientName",   row[6] + " " + row[7]);
                map.put("businessName", (String) row[8]);
                return map;
            })
            .collect(Collectors.toList());
    }

    // ✅ CORRIGÉ — PostgreSQL
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getRevenuePerMonth() {

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT EXTRACT(MONTH FROM r.created_at) AS month, " +
                "EXTRACT(YEAR FROM r.created_at) AS year, " +
                "COALESCE(SUM(r.total_price), 0) AS revenue " +
                "FROM reservations r " +
                "WHERE r.status = 'COMPLETED' " +
                "AND r.created_at >= NOW() - INTERVAL '6 months' " +
                "GROUP BY EXTRACT(YEAR FROM r.created_at), " +
                "         EXTRACT(MONTH FROM r.created_at) " +
                "ORDER BY EXTRACT(YEAR FROM r.created_at), " +
                "         EXTRACT(MONTH FROM r.created_at)")
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("month",   ((Number) row[0]).intValue());
                map.put("year",    ((Number) row[1]).intValue());
                map.put("revenue", ((Number) row[2]).doubleValue());
                return map;
            })
            .collect(Collectors.toList());
    }

    public Map<String, Object> getUserDistribution() {

        long totalClients = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM users " +
                "WHERE account_type NOT IN ('ADMIN', 'MARCHANT')")
            .getSingleResult()).longValue();

        long totalMarchands = ((Number) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM users " +
                "WHERE account_type = 'MARCHANT'")
            .getSingleResult()).longValue();

        long total = totalClients + totalMarchands;

        double clientPercent  = total > 0
            ? Math.round((totalClients  * 100.0 / total) * 10.0) / 10.0 : 0;
        double marchandPercent = total > 0
            ? Math.round((totalMarchands * 100.0 / total) * 10.0) / 10.0 : 0;

        Map<String, Object> map = new HashMap<>();
        map.put("totalClients",    totalClients);
        map.put("totalMarchands",  totalMarchands);
        map.put("clientPercent",   clientPercent);
        map.put("marchandPercent", marchandPercent);
        return map;
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> getTopMerchantsChart() {

        List<Object[]> rows = entityManager
            .createNativeQuery(
                "SELECT m.business_name, " +
                "COALESCE(m.revenue, 0) AS revenue, " +
                "(SELECT COUNT(*) FROM offres o " +
                " WHERE o.marchand_id = m.user_id) AS nb_offres, " +
                "m.nb_followers " +
                "FROM marchands m " +
                "WHERE m.status_marchand = 'VERIFIED' " +
                "ORDER BY m.revenue DESC LIMIT 10")
            .getResultList();

        return rows.stream()
            .map(row -> {
                Map<String, Object> map = new HashMap<>();
                map.put("businessName", (String) row[0]);
                map.put("revenue",      ((Number) row[1]).doubleValue());
                map.put("nbOffres",     ((Number) row[2]).intValue());
                map.put("nbFollowers",  ((Number) row[3]).intValue());
                return map;
            })
            .collect(Collectors.toList());
    }

    // ═══════════════════════════════════════════════
//  getMerchantOfferCount()
//  Returns total number of offers for a merchant
//  Used in: getMerchantManagement() DTO
// ═══════════════════════════════════════════════
public int getMerchantOfferCount(int userId) {
    Number count = (Number) entityManager
        .createNativeQuery(
            "SELECT COUNT(*) " +
            "FROM offres o " +
            "WHERE o.marchand_id = :id")
        .setParameter("id", userId)
        .getSingleResult();
    return count.intValue();
}


public double getMerchantRevenue(int userId) {
    Number revenue = (Number) entityManager
        .createNativeQuery(
            "SELECT COALESCE(SUM(r.total_price), 0) " +
            "FROM reservations r " +
            "WHERE r.marchand_id = :id " +
            "AND r.status = 'COMPLETED'")
        .setParameter("id", userId)
        .getSingleResult();
    return revenue.doubleValue();
}
}