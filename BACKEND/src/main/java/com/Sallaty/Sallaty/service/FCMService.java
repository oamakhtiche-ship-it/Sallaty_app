package com.Sallaty.Sallaty.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

@Service
public class FCMService {

    // ═══════════════════════════════════════════════
    //  sendPush()
    //  envoyer push notification via Firebase FCM
    // ═══════════════════════════════════════════════
    public void sendPush(
            String deviceToken,
            String title,
            String message,
            String type) {

        // Si pas de deviceToken → ignorer
        if (deviceToken == null || deviceToken.isEmpty())
            return;

        try {
            Message fcmMessage = Message.builder()
                .setNotification(
                    Notification.builder()
                        .setTitle(title)
                        .setBody(message)
                        .build()
                )
                .putData("type", type)
                .setToken(deviceToken)
                .build();

            String response = FirebaseMessaging
                .getInstance()
                .send(fcmMessage);

            System.out.println(
                "FCM sent successfully: " + response);

        } catch (Exception e) {
            System.err.println(
                "FCM error: " + e.getMessage());
            // Ne pas bloquer l'app si FCM échoue
        }
    }

    // ═══════════════════════════════════════════════
    //  sendPushToMultiple()
    //  envoyer à plusieurs tokens
    // ═══════════════════════════════════════════════
    public void sendPushToMultiple(
            java.util.List<String> deviceTokens,
            String title,
            String message,
            String type) {

        for (String token : deviceTokens) {
            sendPush(token, title, message, type);
        }
    }
}