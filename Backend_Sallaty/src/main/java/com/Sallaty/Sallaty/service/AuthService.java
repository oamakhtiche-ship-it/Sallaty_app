package com.Sallaty.Sallaty.service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.Role;
import com.Sallaty.Sallaty.repository.ClientRepository;
import com.Sallaty.Sallaty.security.JwtUtil;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class AuthService {

    @Autowired private UserService userService;
    @Autowired private RoleService roleService;
    @Autowired private OtpcodeService otpcodeService;
    @Autowired private PasswordService passwordService;
    @Autowired private JwtUtil jwtUtil;
    @Autowired private NotificationService notificationService;
    @Autowired private ClientRepository clientRepository;

    @PersistenceContext
    private EntityManager entityManager;

    // ═══════════════════════════════════════════════
    //  HELPERS
    // ═══════════════════════════════════════════════
    private Object[] getUserByContact(String contact) {
        try {
            return (Object[]) entityManager
                .createNativeQuery(
                    "SELECT id, contact, passe_word, account_state, " +
                    "first_name, surname, wilaya, profile_image " +
                    "FROM users WHERE contact = :contact")
                .setParameter("contact", contact)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    private Object[] getUserById(int userId) {
        try {
            return (Object[]) entityManager
                .createNativeQuery(
                    "SELECT id, contact, passe_word, " +
                    "account_state, first_name, surname " +
                    "FROM users WHERE id = :id")
                .setParameter("id", userId)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════
    //  REGISTER STEP 1
    // ═══════════════════════════════════════════════
    @Transactional
    public Map<String, Object> registerStep1(
            String contact,
            String password,
            String password2) {

        boolean isPhone = userService.validatePhoneNumberFormat(contact);
        boolean isEmail = userService.validateEmailFormat(contact);

        if (!isPhone && !isEmail)
            throw new IllegalArgumentException("\r\n" + //
                                "Invalid contact !");
        if (userService.checkContactExists(contact))
            throw new RuntimeException("Contact already existing !");
        if (!userService.confirmPassword(password, password2))
            throw new IllegalArgumentException("Different passwords !");

        String accountType    = isPhone ? "PHONE" : "EMAIL";
        String hashedPassword = passwordService.hashPassword(password);

        entityManager.createNativeQuery(
            "INSERT INTO users (first_name, surname, contact, " +
            "passe_word, profile_image, account_type, " +
            "account_state, nb_offer, nb_order, balance, date_time) " +
            "VALUES ('', '', :contact, :password, " +
            "NULL, :accountType, 'NOT_VERIFIED', 0, 0, 0.0, :dateTime)")
            .setParameter("contact",     contact)
            .setParameter("password",    hashedPassword)
            .setParameter("accountType", accountType)
            .setParameter("dateTime",    LocalDateTime.now())
            .executeUpdate();

        Object[] newUser = getUserByContact(contact);
        int userId = ((Number) newUser[0]).intValue();

        otpcodeService.sendVerifCodeSignup(contact, userId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "\r\n" + //
                        "OTP sent to " + contact);
        response.put("userId",  userId);
        return response;
    }

    // ═══════════════════════════════════════════════
    //  REGISTER STEP 2
    // ═══════════════════════════════════════════════
    @Transactional
    public Map<String, Object> registerStep2(
            int userId,
            String otpCode) {

        Object[] user = getUserById(userId);
        if (user == null)
            throw new RuntimeException("User not found !");
        if (!otpcodeService.verifyCode(userId, otpCode))
            throw new RuntimeException("\r\n" + //
                                "Invalid OTP code !");

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "\r\n" + //
                        "OTP verified !");
        response.put("userId",  userId);
        return response;
    }

    // ═══════════════════════════════════════════════
    //  REGISTER STEP 3
    // ═══════════════════════════════════════════════
    @Transactional
    public Map<String, Object> registerStep3(
            int userId,
            String name,
            String surname) {

        Object[] user = getUserById(userId);
        if (user == null)
            throw new RuntimeException("User not found !");
        if (!userService.validateName(name) ||
            !userService.validateName(surname))
            throw new IllegalArgumentException(" invalide name !");

        entityManager.createNativeQuery(
            "UPDATE users SET " +
            "first_name = :name, " +
            "surname = :surname, " +
            "account_state = 'ACTIVE' " +
            "WHERE id = :id")
            .setParameter("name",    userService.adaptName(name))
            .setParameter("surname", userService.adaptName(surname))
            .setParameter("id",      userId)
            .executeUpdate();

        roleService.assignRole(userId, Role.CLIENT);

        if (clientRepository.countByUserId(userId) == 0) {
            entityManager.createNativeQuery(
                "INSERT INTO clients (user_id, nb_reservations, " +
                "nb_cancellations, total_spent) " +
                "VALUES (:userId, 0, 0, 0.0)")
                .setParameter("userId", userId)
                .executeUpdate();
        }

        notificationService.sendNotification(
            userId,
            "Welcome to Sallaty! 🎉",
            "Your account has been successfully created.",
            NotificationType.WELCOME);

        Object[] updatedUser = getUserById(userId);
        String contact = (String) updatedUser[1];

        String accessToken  = jwtUtil.generateToken(contact);
        String refreshToken = jwtUtil.generateRefreshToken(contact);

        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("id",      userId);
        userInfo.put("name",    name);
        userInfo.put("surname", surname);
        userInfo.put("contact", contact);

        Map<String, Object> response = new HashMap<>();
        response.put("success",      true);
        response.put("message",      "Successful registration !");
        response.put("userId",       userId);
        response.put("accessToken",  accessToken);
        response.put("refreshToken", refreshToken);
        response.put("user",         userInfo);
        return response;
    }

    // ═══════════════════════════════════════════════
    //  register() — ANCIEN (gardé pour compatibilité)
    // ═══════════════════════════════════════════════
    @Transactional
    public int register(
            String contact,
            String name,
            String surname,
            String password,
            String password2) {

        boolean isPhone = userService.validatePhoneNumberFormat(contact);
        boolean isEmail = userService.validateEmailFormat(contact);
        if (!isPhone && !isEmail)
            throw new IllegalArgumentException(" invalide Contact!");
        if (userService.checkContactExists(contact))
            throw new RuntimeException(
"Contact already existing !");
        if (!userService.validateName(name) ||
            !userService.validateName(surname))
            throw new IllegalArgumentException(" invalide name !");
        if (!userService.confirmPassword(password, password2))
            throw new IllegalArgumentException("\r\n" + //
                                "Different passwords !");

        String accountType    = isPhone ? "PHONE" : "EMAIL";
        String hashedPassword = passwordService.hashPassword(password);

        entityManager.createNativeQuery(
            "INSERT INTO users (first_name, surname, contact, " +
            "passe_word, profile_image, account_type, " +
            "account_state, nb_offer, nb_order, balance, date_time) " +
            "VALUES (:name, :surname, :contact, :password, " +
            "NULL, :accountType, 'NOT_VERIFIED', 0, 0, 0.0, :dateTime)")
            .setParameter("name",        userService.adaptName(name))
            .setParameter("surname",     userService.adaptName(surname))
            .setParameter("contact",     contact)
            .setParameter("password",    hashedPassword)
            .setParameter("accountType", accountType)
            .setParameter("dateTime",    LocalDateTime.now())
            .executeUpdate();

        Object[] newUser = getUserByContact(contact);
        int userId = ((Number) newUser[0]).intValue();
        otpcodeService.sendVerifCodeSignup(contact, userId);
        return userId;
    }

    // ═══════════════════════════════════════════════
    //  confirmEmail()
    // ═══════════════════════════════════════════════
    @Transactional
    public void confirmEmail(int userId, String otpCode) {

        Object[] user = getUserById(userId);
        if (user == null)
            throw new RuntimeException("User not found !");
        if (!otpcodeService.verifyCode(userId, otpCode))
            throw new RuntimeException("\r\n" + //
                                "Invalid OTP code !");

        entityManager.createNativeQuery(
            "UPDATE users SET account_state = 'ACTIVE' " +
            "WHERE id = :id")
            .setParameter("id", userId)
            .executeUpdate();

        roleService.assignRole(userId, Role.CLIENT);

        if (clientRepository.countByUserId(userId) == 0) {
            entityManager.createNativeQuery(
                "INSERT INTO clients (user_id, nb_reservations, " +
                "nb_cancellations, total_spent) " +
                "VALUES (:userId, 0, 0, 0.0)")
                .setParameter("userId", userId)
                .executeUpdate();
        }

        notificationService.sendNotification(
            userId,
            "Bienvenue sur Sallaty ! 🎉",
            "Votre compte a été créé avec succès.",
            NotificationType.WELCOME);
    }

    // ═══════════════════════════════════════════════
    //  resendOTP()
    // ═══════════════════════════════════════════════
    @Transactional
    public void resendOTP(int userId) {

        Object[] user = getUserById(userId);
        if (user == null)
            throw new RuntimeException("User not found !");

        String contact = (String) user[1];
        otpcodeService.sendVerifCodeSignup(contact, userId);
    }

    // ═══════════════════════════════════════════════
    //  LOGIN ✅
    // ═══════════════════════════════════════════════
    @Transactional
    public Map<String, Object> login(String contact, String password) {
        try {
            Object[] user = getUserByContact(contact);
            if (user == null)
                throw new RuntimeException("Contact not found !");

            int    userId       = ((Number) user[0]).intValue();
            String userContact  = (String)  user[1];
            String userPassword = (String)  user[2];
            String accountState = (String)  user[3];
            String firstName    = (String)  user[4];
            String surname      = (String)  user[5];
            String wilaya       = user[6] != null ? (String) user[6] : "";
            String profileImage = user[7] != null ? (String) user[7] : "";

            if (!passwordService.confirmPassword(password, userPassword))
                throw new RuntimeException("incorrect Password  !");
            if ("BLOCKED".equals(accountState))
                throw new RuntimeException("Blocked account !");
            if ("NOT_VERIFIED".equals(accountState))
                throw new RuntimeException("\r\n" + //
 "Unverified account!");

            System.out.println(">>> STEP 1: user found, id=" + userId);

            // ✅ Vérification des rôles
            boolean isMerchant = false;
            boolean isAdmin    = false;
            try {
                isMerchant = roleService.isMarchand(userId);

                // ✅ Vérifier ADMIN dans la table roles
                Number adminCount = (Number) entityManager.createNativeQuery(
                    "SELECT COUNT(*) FROM roles " +
                    "WHERE iduser = :id AND UPPER(rolename) = 'ADMIN'")
                    .setParameter("id", userId)
                    .getSingleResult();
                isAdmin = adminCount.intValue() > 0;

                System.out.println(">>> STEP 2: isMerchant=" + isMerchant +
                                   ", isAdmin=" + isAdmin);
            } catch (Exception e) {
                System.err.println(">>> role check FAILED: " + e.getMessage());
                e.printStackTrace();
            }

            // ✅ Infos marchand si applicable
            String businessName = "";
            String businessType = "";
            String phoneNumber  = "";

            if (isMerchant) {
                try {
                    Object[] marchand = (Object[]) entityManager
                        .createNativeQuery(
                            "SELECT m.business_name, m.business_type, u.phone_number " +
                            "FROM marchands m " +
                            "JOIN users u ON u.id = m.user_id " +
                            "WHERE m.user_id = :userId")
                        .setParameter("userId", userId)
                        .getSingleResult();
                    System.out.println(">>> STEP 3: marchand found");
                    if (marchand != null) {
                        businessName = marchand[0] != null ? (String) marchand[0] : "";
                        businessType = marchand[1] != null ? (String) marchand[1] : "";
                        phoneNumber  = marchand[2] != null ? (String) marchand[2] : "";
                    }
                } catch (Exception e) {
                    System.err.println(">>> marchand query FAILED: " + e.getMessage());
                    e.printStackTrace();
                }
            }

            System.out.println(">>> STEP 4: generating tokens");
            String accessToken  = jwtUtil.generateToken(userContact);
            String refreshToken = jwtUtil.generateRefreshToken(userContact);

            System.out.println(">>> STEP 5: building response");
            Map<String, Object> response = new HashMap<>();
            response.put("token",        accessToken);
            response.put("refreshToken", refreshToken);
            response.put("id",           userId);
            response.put("email",        userContact);
            response.put("name",         firstName != null ? firstName : "");
            response.put("surname",      surname   != null ? surname   : "");
            response.put("wilaya",       wilaya);
            response.put("isMerchant",   isMerchant);
            response.put("isAdmin",      isAdmin);       // ✅ NOUVEAU
            response.put("photoUrl",     profileImage);
            response.put("businessName", businessName);
            response.put("businessType", businessType);
            response.put("phone",        phoneNumber);
            response.put("accountState", accountState);

            System.out.println(">>> STEP 6: done! isAdmin=" + isAdmin);
            return response;

        } catch (Exception e) {
            System.err.println(">>> LOGIN CRASHED AT: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    // ═══════════════════════════════════════════════
    //  refresh()
    // ═══════════════════════════════════════════════
    public Map<String, Object> refresh(String refreshToken) {

        if (!jwtUtil.isTokenValid(refreshToken))
            throw new RuntimeException("Invalid refresh token!");
        if (jwtUtil.getTokenType(refreshToken) != JwtUtil.TokenType.REFRESH)
            throw new RuntimeException("\r\n" + //
                                "Invalid token type !");

        String contact = jwtUtil.getEmail(refreshToken);

        Object[] user = getUserByContact(contact);
        if (user == null)
            throw new RuntimeException("User not found !");

        String newAccessToken = jwtUtil.generateToken(contact);

        Map<String, Object> response = new HashMap<>();
        response.put("accessToken",  newAccessToken);
        response.put("refreshToken", refreshToken);
        return response;
    }

    // ═══════════════════════════════════════════════
    //  forgotPassword()
    // ═══════════════════════════════════════════════
    public void forgotPassword(String contact) {

        Object[] user = getUserByContact(contact);
        if (user == null)
            throw new RuntimeException("Contact not found !");

        int userId = ((Number) user[0]).intValue();
        otpcodeService.sendVerifCodeLogin(contact, userId);
    }

    // ═══════════════════════════════════════════════
    //  resetPassword()
    // ═══════════════════════════════════════════════
    @Transactional
    public void resetPassword(
            String contact,
            String otpCode,
            String newPassword,
            String confirm) {

        if (!newPassword.equals(confirm))
            throw new IllegalArgumentException("diffrents passwords !");

        Object[] user = getUserByContact(contact);
        if (user == null)
            throw new RuntimeException("Contact not found !");

        int userId = ((Number) user[0]).intValue();

        if (!otpcodeService.verifyCode(userId, otpCode))
            throw new RuntimeException("invalide otp code !");

        entityManager.createNativeQuery(
            "UPDATE users SET passe_word = :password WHERE id = :id")
            .setParameter("password", passwordService.hashPassword(newPassword))
            .setParameter("id",       userId)
            .executeUpdate();
    }
}