package com.Sallaty.Sallaty.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.model.UserSettings;
import com.Sallaty.Sallaty.repository.NotificationRepository;
import com.Sallaty.Sallaty.repository.UserRepository;
import com.Sallaty.Sallaty.repository.UserSettingsRepository;

@Service
public class UserSettingsService {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private UserSettingsRepository userSettingsRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    // ═══════════════════════════════════════════════
    //  getSettings()
    // ═══════════════════════════════════════════════
    public UserSettings getSettings(int userId) {

        if (!userRepository.existsById(userId))
            throw new RuntimeException("User not found !");

        return userSettingsRepository
            .findByUserId(userId)
            .orElseGet(() -> {
                UserSettings settings =
                    new UserSettings(userId);
                return userSettingsRepository.save(settings);
            });
    }

    // ═══════════════════════════════════════════════
    //  updateSettings()
    // ═══════════════════════════════════════════════
    public UserSettings updateSettings(
            int userId,
            UserSettings newSettings) {

        UserSettings settings = getSettings(userId);

        // Common
        settings.setGeneralNotification(
            newSettings.isGeneralNotification());
        settings.setSound(
            newSettings.isSound());
        settings.setVibrate(
            newSettings.isVibrate());

        // Orders
        settings.setOrderConfirmed(
            newSettings.isOrderConfirmed());
        settings.setOrderCancelled(
            newSettings.isOrderCancelled());
        settings.setOrderCompleted(
            newSettings.isOrderCompleted());
        settings.setPaymentSuccess(
            newSettings.isPaymentSuccess());

        // Promotions
        settings.setNewDiscount(
            newSettings.isNewDiscount());
        settings.setExpiringOffer(
            newSettings.isExpiringOffer());
        settings.setNewOfferNearby(
            newSettings.isNewOfferNearby());

        // Others
        settings.setBroadcastMessage(
            newSettings.isBroadcastMessage());
        settings.setMarchandVerified(
            newSettings.isMarchandVerified());

        return userSettingsRepository.save(settings);
    }

    // ═══════════════════════════════════════════════
    //  toggleNotification()
    // ═══════════════════════════════════════════════
    public UserSettings toggleNotification(
            int userId,
            String type) {

        UserSettings settings = getSettings(userId);

        switch (type) {
            case "generalNotification" ->
                settings.setGeneralNotification(
                    !settings.isGeneralNotification());
            case "sound" ->
                settings.setSound(
                    !settings.isSound());
            case "vibrate" ->
                settings.setVibrate(
                    !settings.isVibrate());
            case "orderConfirmed" ->
                settings.setOrderConfirmed(
                    !settings.isOrderConfirmed());
            case "orderCancelled" ->
                settings.setOrderCancelled(
                    !settings.isOrderCancelled());
            case "orderCompleted" ->
                settings.setOrderCompleted(
                    !settings.isOrderCompleted());
            case "paymentSuccess" ->
                settings.setPaymentSuccess(
                    !settings.isPaymentSuccess());
            case "newDiscount" ->
                settings.setNewDiscount(
                    !settings.isNewDiscount());
            case "expiringOffer" ->
                settings.setExpiringOffer(
                    !settings.isExpiringOffer());
            case "newOfferNearby" ->
                settings.setNewOfferNearby(
                    !settings.isNewOfferNearby());
            case "broadcastMessage" ->
                settings.setBroadcastMessage(
                    !settings.isBroadcastMessage());
            case "marchandVerified" ->
                settings.setMarchandVerified(
                    !settings.isMarchandVerified());
            default ->
                throw new RuntimeException(
                    "Type invalide !");
        }

        return userSettingsRepository.save(settings);
    }

    // ═══════════════════════════════════════════════
    //  updateLanguage()
    // ═══════════════════════════════════════════════
    public UserSettings updateLanguage(
            int userId,
            String language) {

        if (!language.equals("FR") &&
            !language.equals("AR") &&
            !language.equals("EN"))
            throw new RuntimeException(
                "Invalid language ! (FR / AR / EN)");

        UserSettings settings = getSettings(userId);
        settings.setLanguage(language);
        return userSettingsRepository.save(settings);
    }

    // ═══════════════════════════════════════════════
    //  isNotificationAllowed()
    //  appelée par NotificationService
    // ═══════════════════════════════════════════════
    public boolean isNotificationAllowed(
            int userId,
            String type) {

        UserSettings settings = getSettings(userId);

        if (!settings.isGeneralNotification())
            return false;

        return switch (type) {
            case "ORDER_CONFIRMED"   -> settings.isOrderConfirmed();
            case "ORDER_CANCELLED"   -> settings.isOrderCancelled();
            case "ORDER_COMPLETED"   -> settings.isOrderCompleted();
            case "PAYMENT_SUCCESS"   -> settings.isPaymentSuccess();
            case "PAYMENT_RECEIVED"  -> settings.isPaymentSuccess();
            case "NEW_DISCOUNT"      -> settings.isNewDiscount();
            case "EXPIRING_SOON"     -> settings.isExpiringOffer();
            case "NEW_OFFER"         -> settings.isNewOfferNearby();
            case "BROADCAST"         -> settings.isBroadcastMessage();
            case "MARCHAND_VERIFIED" -> settings.isMarchandVerified();
            case "WARNING"           -> true;
            default                  -> true;
        };
    }

    // ═══════════════════════════════════════════════
    //  deleteAccount()
    // ═══════════════════════════════════════════════
    @Transactional
    public void deleteAccount(int userId) {

        if (!userRepository.existsById(userId))
            throw new RuntimeException("User not found !");

        // 1. Supprimer settings
        userSettingsRepository.deleteByUserId(userId);

        // 2. Supprimer notifications
        notificationRepository.deleteAllByUserId(userId);

        // 3. Supprimer user
        userRepository.deleteById(userId);
    }
}