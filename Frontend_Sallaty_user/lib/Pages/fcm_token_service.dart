import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usersession.dart';
import 'apiservice.dart';

// ─────────────────────────────────────────────
//  TOP-LEVEL handler (required by FCM)
// ─────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled automatically by FCM
  // No need to initialize Firebase here — it's already initialized
}

// ─────────────────────────────────────────────
//  FCM SERVICE
//  Call FcmTokenService.init() once in main.dart
//  after Firebase.initializeApp()
//  Call FcmTokenService.uploadToken() after login
// ─────────────────────────────────────────────
class FcmTokenService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // ── Initialize FCM + local notifications ───────────────────
  static Future<void> init() async {
    // 1. Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup local notifications (for foreground messages)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // 3. Create notification channel (Android 8+)
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'sallaty_channel',
          'Sallaty Notifications',
          description: 'Notifications from Sallaty',
          importance: Importance.high,
        ));

    // 4. Background handler
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // 5. Foreground handler — show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotif.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'sallaty_channel',
              'Sallaty Notifications',
              channelDescription: 'Notifications from Sallaty',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });

    // 6. Token refresh handler
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToBackend(newToken);
    });
  }

  // ── Call after successful login ─────────────────────────────
  static Future<void> uploadToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      // Silently fail — notifications still work via in-app polling
    }
  }

  // ── Save device token to Spring Boot backend ────────────────
  static Future<void> _saveTokenToBackend(String deviceToken) async {
    final userToken = UserSession().token;
    if (userToken == null) return; // Not logged in yet

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'deviceToken': deviceToken}),
      );
      if (res.statusCode == 200) {
      } else {
      }
    } catch (e) {
      // Silently fail
    }
  }

  // ── Call on logout to remove token ─────────────────────────
  static Future<void> removeToken() async {
    final userToken = UserSession().token;
    if (userToken == null) return;
    try {
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/users/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );
      await _messaging.deleteToken();
    } catch (_) {}
  }
}