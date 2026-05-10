package com.Sallaty.Sallaty.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.Sallaty.Sallaty.Dto.RoleDTO;
import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.Offre;
import com.Sallaty.Sallaty.model.StatusMarchand;
import com.Sallaty.Sallaty.repository.ClientRepository;
import com.Sallaty.Sallaty.repository.MarchandRepository;
import com.Sallaty.Sallaty.repository.OffreFavoriRepository;
import com.Sallaty.Sallaty.repository.OffreRepository;
import com.Sallaty.Sallaty.repository.SubscribeRepository;
import com.Sallaty.Sallaty.repository.UserRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class ProfileService {

    @Autowired private UserRepository       userRepository;
    @Autowired private ClientRepository     clientRepository;
    @Autowired private MarchandRepository   marchandRepository;
    @Autowired private OffreRepository      offreRepository;
    @Autowired private SubscribeRepository  subscribeRepository;
    @Autowired private OffreFavoriRepository offreFavoriRepository;
    @Autowired private UserService          userService;
    @Autowired private RoleService          roleService;
    @Autowired private ImageService         imageService;
    @Autowired private PasswordService      passwordService;
    @Autowired private OtpcodeService       otpcodeService;
    @Autowired private NotificationService  notificationService;

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  HELPER — vérifie existence user
    // ═══════════════════════════════════════════════
    private void checkUserExists(int userId) {
        Long count = (Long) entityManager
            .createNativeQuery(
                "SELECT COUNT(*) FROM users WHERE id = :id")
            .setParameter("id", userId)
            .getSingleResult();
        if (count == null || count == 0)
            throw new RuntimeException("User not found !");
    }

    // ═══════════════════════════════════════════════
    //  HELPER — user data SQL pur
    // ═══════════════════════════════════════════════
    private Object[] getUserData(int userId) {
        try {
            return (Object[]) entityManager
                .createNativeQuery(
                    "SELECT id, first_name, surname, contact, " +
                    "profile_image, wilaya, balance, account_state, created_at " +
                    "FROM users WHERE id = :id")
                .setParameter("id", userId)
                .getSingleResult();
        } catch (Exception e) {
            throw new RuntimeException("User not found !");
        }
    }

    // ═══════════════════════════════════════════════
    //  HELPER — contact du user
    // ═══════════════════════════════════════════════
    private String getUserContact(int userId) {
        return (String) entityManager
            .createNativeQuery(
                "SELECT contact FROM users WHERE id = :id")
            .setParameter("id", userId)
            .getSingleResult();
    }

    // ═══════════════════════════════════════════════
    //  HELPER — password du user
    // ═══════════════════════════════════════════════
    private String getUserPassword(int userId) {
        return (String) entityManager
            .createNativeQuery(
                "SELECT passe_word FROM users WHERE id = :id")
            .setParameter("id", userId)
            .getSingleResult();
    }

    // ═══════════════════════════════════════════════
    //  HELPER — client data SQL pur
    // ═══════════════════════════════════════════════
    private void addClientData(int userId, Map<String, Object> response) {
        try {
            if (clientRepository.countByUserId(userId) > 0) {
                Object[] result = (Object[]) entityManager
                    .createNativeQuery(
                        "SELECT nb_reservations, nb_cancellations, total_spent " +
                        "FROM clients WHERE user_id = :userId")
                    .setParameter("userId", userId)
                    .getSingleResult();
                if (result != null) {
                    response.put("nbReservations",  result[0]);
                    response.put("nbCancellations", result[1]);
                    response.put("totalSpent",      result[2]);
                }
            }
        } catch (Exception e) {
            // pas un client
        }
    }

    // ═══════════════════════════════════════════════
    //  HELPER — marchand data SQL pur
    //  ✅ FIX : JOIN users pour récupérer phone_number
    //           car phone_number est dans users, pas marchands
    // ═══════════════════════════════════════════════
    private Map<String, Object> getMarchandData(int userId) {
        try {
            Object[] result = (Object[]) entityManager
                .createNativeQuery(
                    "SELECT m.full_name, m.business_name, m.business_type, " +
                    "u.phone_number, m.trade_register, m.status_marchand, " +
                    "m.revenue, m.nb_followers " +
                    "FROM marchands m " +
                    "JOIN users u ON u.id = m.user_id " +
                    "WHERE m.user_id = :userId")
                .setParameter("userId", userId)
                .getSingleResult();

            if (result == null) return null;

            Map<String, Object> data = new HashMap<>();
            data.put("fullName",       result[0]);
            data.put("businessName",   result[1]);
            data.put("businessType",   result[2]);
            data.put("phoneNumber",    result[3]);   // ✅ vient de users
            data.put("tradeRegister",  result[4]);
            data.put("statusMarchand",
                result[5] != null
                    ? StatusMarchand.valueOf((String) result[5])
                    : null);
            data.put("revenue",
                result[6] != null ? ((Number) result[6]).doubleValue() : 0.0);
            data.put("nbFollowers",
                result[7] != null ? ((Number) result[7]).intValue() : 0);
            return data;

        } catch (Exception e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════
    //  getMyProfile()
    // ═══════════════════════════════════════════════
    public Map<String, Object> getMyProfile(int userId) {

        Object[] u = getUserData(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("id",           u[0]);
        response.put("name",         u[1]);
        response.put("surname",      u[2]);
        response.put("contact",      u[3]);
        response.put("profileImage", u[4]);
        response.put("wilaya",       u[5]);
        response.put("balance",      u[6]);
        response.put("accountState", u[7]);

        RoleDTO roleDTO = roleService.getRoleByUser(userId);
        response.put("role", roleDTO.getRolename());

        addClientData(userId, response);

        if (roleService.isMarchand(userId)) {
            Map<String, Object> marchandData = getMarchandData(userId);
            if (marchandData == null)
                throw new RuntimeException("Marchand not found !");
            response.putAll(marchandData);
        }

        return response;
    }

    // ═══════════════════════════════════════════════
    //  updateProfile() — 100% native SQL
    //  ✅ FIX : phone_number → UPDATE users (pas marchands)
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateProfile(
            int userId,
            String surname,
            String name,
            MultipartFile photo,
            String wilaya,
            String businessName,
            String businessType,
            String phoneNumber) {

        checkUserExists(userId);

        if (surname != null && !surname.isEmpty()) {
            if (!userService.validateName(surname))
                throw new IllegalArgumentException("Name invalide !");
            entityManager.createNativeQuery(
                "UPDATE users SET surname = :val WHERE id = :userId")
                .setParameter("val", userService.adaptName(surname))
                .setParameter("userId", userId)
                .executeUpdate();
        }

        if (name != null && !name.isEmpty()) {
            if (!userService.validateName(name))
                throw new IllegalArgumentException("surname invalide !");
            entityManager.createNativeQuery(
                "UPDATE users SET first_name = :val WHERE id = :userId")
                .setParameter("val", userService.adaptName(name))
                .setParameter("userId", userId)
                .executeUpdate();
        }

        if (photo != null && !photo.isEmpty()) {
            String imagePath = imageService.saveImage(photo, userId);
            entityManager.createNativeQuery(
                "UPDATE users SET profile_image = :val WHERE id = :userId")
                .setParameter("val", imagePath)
                .setParameter("userId", userId)
                .executeUpdate();
        }

        if (wilaya != null && !wilaya.isEmpty())
            entityManager.createNativeQuery(
                "UPDATE users SET wilaya = :val WHERE id = :userId")
                .setParameter("val", wilaya)
                .setParameter("userId", userId)
                .executeUpdate();

        // ✅ FIX : phone_number est dans users, pas dans marchands
        if (phoneNumber != null && !phoneNumber.isEmpty()) {
            if (!userService.validatePhoneNumberFormat(phoneNumber))
                throw new IllegalArgumentException("Numero invalide !");
            entityManager.createNativeQuery(
                "UPDATE users SET phone_number = :val WHERE id = :userId")
                .setParameter("val", phoneNumber)
                .setParameter("userId", userId)
                .executeUpdate();
        }

        if (roleService.isMarchand(userId)) {

            if (businessName != null && !businessName.isEmpty()) {
                Object currentName = entityManager
                    .createNativeQuery(
                        "SELECT business_name FROM marchands WHERE user_id = :userId")
                    .setParameter("userId", userId)
                    .getSingleResult();

                if (marchandRepository.existsByBusinessName(businessName) &&
                    !businessName.equals(currentName))
                    throw new RuntimeException("Business name aleardy used !");

                entityManager.createNativeQuery(
                    "UPDATE marchands SET business_name = :val WHERE user_id = :userId")
                    .setParameter("val", businessName)
                    .setParameter("userId", userId)
                    .executeUpdate();
            }

            if (businessType != null && !businessType.isEmpty())
                entityManager.createNativeQuery(
                    "UPDATE marchands SET business_type = :val WHERE user_id = :userId")
                    .setParameter("val", businessType)
                    .setParameter("userId", userId)
                    .executeUpdate();
        }
    }

    // ═══════════════════════════════════════════════
    //  updateContact() — 100% native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateContact(int userId, String newContact, String otpCode) {

        checkUserExists(userId);

        String currentContact = getUserContact(userId);

        boolean isPhone = userService.validatePhoneNumberFormat(newContact);
        boolean isEmail = userService.validateEmailFormat(newContact);

        if (!isPhone && !isEmail)
            throw new IllegalArgumentException("Contact invalide !");

        if (userService.checkContactExists(newContact) &&
            !newContact.equals(currentContact))
            throw new RuntimeException("Contact aleardy used!");

        if (!otpcodeService.verifyCode(userId, otpCode))
            throw new RuntimeException("Code OTP invalide !");

        entityManager.createNativeQuery(
            "UPDATE users SET contact = :val WHERE id = :userId")
            .setParameter("val", newContact)
            .setParameter("userId", userId)
            .executeUpdate();

        notificationService.sendNotification(
            userId, "Contact changed ✅",
            "Your contact has been successfully modified.",
            NotificationType.ACCOUNT_UPDATE);
    }

    // ═══════════════════════════════════════════════
    //  updatePassword() — 100% native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void updatePassword(
            int userId,
            String oldPassword,
            String newPassword,
            String confirm) {

        checkUserExists(userId);

        String currentPassword = getUserPassword(userId);

        if (!passwordService.confirmPassword(oldPassword, currentPassword))
            throw new RuntimeException("Old incorrect password !");

        if (!newPassword.equals(confirm))
            throw new IllegalArgumentException("Different passwords !");

        if (passwordService.confirmPassword(newPassword, currentPassword))
            throw new RuntimeException("New password identical to the old one !");

        entityManager.createNativeQuery(
            "UPDATE users SET passe_word = :val WHERE id = :userId")
            .setParameter("val", passwordService.hashPassword(newPassword))
            .setParameter("userId", userId)
            .executeUpdate();

        notificationService.sendNotification(
            userId, "Password changed ✅",
            "Your password has been successfully changed..",
            NotificationType.ACCOUNT_UPDATE);
    }

    // ═══════════════════════════════════════════════
    //  updateProfilePhoto() — 100% native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public String updateProfilePhoto(int userId, MultipartFile file) {

        checkUserExists(userId);

        String imagePath = imageService.saveImage(file, userId);

        entityManager.createNativeQuery(
            "UPDATE users SET profile_image = :val WHERE id = :userId")
            .setParameter("val", imagePath)
            .setParameter("userId", userId)
            .executeUpdate();

        return imagePath;
    }

    // ═══════════════════════════════════════════════
    //  getPublicProfile()
    // ═══════════════════════════════════════════════
    public Map<String, Object> getPublicProfile(int userId) {

        Object[] u = getUserData(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("id",           u[0]);
        response.put("name",         u[1]);
        response.put("surname",      u[2]);
        response.put("profileImage", u[4]);
        response.put("wilaya",       u[5]);
        response.put("memberSince",  u[8]);
        response.put("role", roleService.getRoleByUser(userId).getRolename());

        try {
            if (clientRepository.countByUserId(userId) > 0) {
                Object nbRes = entityManager
                    .createNativeQuery(
                        "SELECT nb_reservations FROM clients WHERE user_id = :userId")
                    .setParameter("userId", userId)
                    .getSingleResult();
                response.put("nbReservations", nbRes);
            }
        } catch (Exception e) {
            // ignore
        }

        if (roleService.isMarchand(userId)) {
            Map<String, Object> marchandData = getMarchandData(userId);
            if (marchandData != null) {
                response.put("businessName",   marchandData.get("businessName"));
                response.put("businessType",   marchandData.get("businessType"));
                response.put("phoneNumber",    marchandData.get("phoneNumber"));
                response.put("statusMarchand", marchandData.get("statusMarchand"));
                response.put("nbFollowers",
                    subscribeRepository.countByMarchandId(userId));

                List<Offre> offres = offreRepository.findByMarchandId(userId);
                int totalFavoris = 0;
                for (Offre offre : offres)
                    totalFavoris += offreFavoriRepository
                        .countByOffreId(offre.getId());
                response.put("nbFavoris", totalFavoris);
            }
        }

        return response;
    }
}