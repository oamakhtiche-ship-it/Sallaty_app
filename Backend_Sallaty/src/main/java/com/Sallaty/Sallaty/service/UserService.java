package com.Sallaty.Sallaty.service;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.Dto.UserDTO;
import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.User;
import com.Sallaty.Sallaty.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ImageService imageService;

    @Autowired
    private NotificationService notificationService;

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  HELPER — get user row
    // ═══════════════════════════════════════════════
    private Object[] getUserRow(int userId) {
        try {
            return (Object[]) entityManager
                .createNativeQuery(
                    "SELECT id, first_name, surname, contact, " +
                    "profile_image, account_state, account_type, " +
                    "nb_offer, nb_order, date_time, balance, " +
                    "wilaya, device_token, passe_word " +
                    "FROM users WHERE id = :id")
                .setParameter("id", userId)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════
    //  VALIDATION
    // ═══════════════════════════════════════════════
    public boolean validateEmailFormat(String email) {
        if (email == null || email.isEmpty()) return false;
        return email.matches(
            "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");
    }

    public boolean validatePhoneNumberFormat(String phone) {
        if (phone == null || phone.isEmpty()) return false;
        return phone.matches("^(\\+213|0)[567][0-9]{8}$");
    }

    public boolean validateName(String name) {
        if (name == null || name.isEmpty()) return false;
        return name.matches("[a-zA-ZÀ-ÿ ]{2,50}");
    }

    public boolean checkContactExists(String contact) {
        return userRepository.existsByContact(contact);
    }

    public boolean confirmPassword(
            String password1, String password2) {
        return password1.equals(password2);
    }

    // ═══════════════════════════════════════════════
    //  HELPERS
    // ═══════════════════════════════════════════════
    public String adaptName(String name) {
        if (name == null || name.isEmpty()) return "";
        name = name.trim();
        return Character.toUpperCase(name.charAt(0))
             + name.substring(1).toLowerCase();
    }

    public Map<String, String> decodeGoogleToken(String token) {
        try {
            String[] parts = token.split("\\.");
            String payload = parts[1];
            byte[] decoded = java.util.Base64
                .getDecoder().decode(payload);
            String json = new String(decoded);
            ObjectMapper mapper = new ObjectMapper();
            return mapper.readValue(json, Map.class);
        } catch (Exception e) {
            throw new RuntimeException("Token Google invalide !");
        }
    }

    // ═══════════════════════════════════════════════
    //  uploadImage() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void uploadImage(int userId, String imagePath) {
        if (getUserRow(userId) == null)
            throw new RuntimeException("User not found !");

        entityManager.createNativeQuery(
            "UPDATE users SET profile_image = :path WHERE id = :id")
            .setParameter("path", imagePath)
            .setParameter("id", userId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  deleteImage() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void deleteImage(int userId) {
        Object[] row = getUserRow(userId);
        if (row == null)
            throw new RuntimeException("User not found !");

        String profileImage = (String) row[4];
        if (profileImage == null || profileImage.isEmpty())
            throw new RuntimeException("no picture !");

        imageService.deleteOldImage(userId);

        entityManager.createNativeQuery(
            "UPDATE users SET profile_image = NULL WHERE id = :id")
            .setParameter("id", userId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  logout() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void logout(int userId) {
        if (getUserRow(userId) == null)
            throw new RuntimeException("User not found !");

        entityManager.createNativeQuery(
            "UPDATE users SET device_token = NULL WHERE id = :id")
            .setParameter("id", userId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  blockUser() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void blockUser(int userId) {
        Object[] row = getUserRow(userId);
        if (row == null)
            throw new RuntimeException("User not found !");

        String accountState = (String) row[5];
        if ("BLOCKED".equals(accountState))
            throw new RuntimeException("User already blocked !");

        entityManager.createNativeQuery(
            "UPDATE users SET account_state = 'BLOCKED' WHERE id = :id")
            .setParameter("id", userId)
            .executeUpdate();

        notificationService.sendNotification(
            userId, "Blocked account\r\n" + //
                                "",
            "Your account has been blocked by the administrator.",
            NotificationType.ADMIN_UPDATE);
    }

    // ═══════════════════════════════════════════════
    //  unblockUser() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void unblockUser(int userId) {
        Object[] row = getUserRow(userId);
        if (row == null)
            throw new RuntimeException("User not found !");

        String accountState = (String) row[5];
        if (!"BLOCKED".equals(accountState))
            throw new RuntimeException("User not blocked !");

        entityManager.createNativeQuery(
            "UPDATE users SET account_state = 'ACTIVE' WHERE id = :id")
            .setParameter("id", userId)
            .executeUpdate();

        notificationService.sendNotification(
            userId, "Account unlocked",
            "Your account has been unlocked by the administrator.",
            NotificationType.ADMIN_UPDATE);
    }

    // ═══════════════════════════════════════════════
    //  deleteUser() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void deleteUser(int userId) {
        if (getUserRow(userId) == null)
            throw new RuntimeException("User not found !");

        entityManager.createNativeQuery(
            "DELETE FROM users WHERE id = :id")
            .setParameter("id", userId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  topUpBalance() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void topUpBalance(int userId, double amount) {
        if (amount <= 0)
            throw new IllegalArgumentException("Montant invalide !");

        if (getUserRow(userId) == null)
            throw new RuntimeException("User not found !");

        entityManager.createNativeQuery(
            "UPDATE users SET balance = balance + :amount WHERE id = :id")
            .setParameter("amount", amount)
            .setParameter("id", userId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  getBalance() — native SQL
    // ═══════════════════════════════════════════════
    public double getBalance(int userId) {
        Object[] row = getUserRow(userId);
        if (row == null)
            throw new RuntimeException("User not found !");
        return row[10] != null ? ((Number) row[10]).doubleValue() : 0.0;
    }

    // ═══════════════════════════════════════════════
    //  deductBalance() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void deductBalance(int userId, double amount) {
        if (amount <= 0)
            throw new IllegalArgumentException("Montant invalide !");

        Object[] row = getUserRow(userId);
        if (row == null)
            throw new RuntimeException("User not found !");

        double balance = row[10] != null
            ? ((Number) row[10]).doubleValue() : 0.0;

        if (balance < amount)
            throw new RuntimeException("Insufficient balance !");

        entityManager.createNativeQuery(
            "UPDATE users SET balance = balance - :amount WHERE id = :id")
            .setParameter("amount", amount)
            .setParameter("id", userId)
            .executeUpdate();
    }

    // ═══════════════════════════════════════════════
    //  updateDeviceToken() — native SQL
    // ═══════════════════════════════════════════════
    @Transactional
    public void updateDeviceToken(int userId, String token) {
        if (getUserRow(userId) == null)
            throw new RuntimeException("User not found !");

        entityManager.createNativeQuery(
            "UPDATE users SET device_token = :token WHERE id = :id")
            .setParameter("token", token)
            .setParameter("id", userId)
            .executeUpdate();
    }
    // ═══════════════════════════════════════════════
//  updateUser() — modifier firstName, surname, contact
// ═══════════════════════════════════════════════
@Transactional
public void updateUser(
        int userId,
        String firstName,
        String surname,
        String contact) {

    User user = userRepository.findById(userId)
        .orElseThrow(() ->
            new RuntimeException("User not found !"));

    if (firstName != null && !firstName.isEmpty())
        user.setFirstName(firstName);

    if (surname != null && !surname.isEmpty())
        user.setSurname(surname);

    if (contact != null && !contact.isEmpty()) {
        if (userRepository.existsByContact(contact))
            throw new RuntimeException(
                "Contact déjà utilisé !");
        user.setContact(contact);
    }

    userRepository.save(user);
}
    // ═══════════════════════════════════════════════
    //  convertToDTO() — native SQL
    // ═══════════════════════════════════════════════
    public UserDTO convertToDTO(User user, String token) {
    return new UserDTO(
        user.getId(),
        user.getFirstName(),
        user.getSurname(),
        user.getContact(),
        user.getProfileImage(),
        user.getAccountState(),
        user.getAccountType(),
        user.getNbOffer(),
        user.getNbOrder(),
        user.getDateTime(),
        user.getBalance(),
        user.getWilaya(),
        token);
}
}