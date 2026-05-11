import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';
import 'Pages/splashscreen.dart';
import 'Pages/usersession.dart';
import 'Pages/apiservice.dart';
import 'Pages/fcm_token_service.dart';   
import 'Pages/otifications.dart';

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase WITH options (required for web)
  try {
    await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey:            "AIzaSy...",  
    authDomain:        "sallaty-97a49.firebaseapp.com",
    projectId:         "sallaty-97a49",
    storageBucket:     "sallaty-97a49.firebasestorage.app",
    messagingSenderId: "965359190240",
    appId:             "1:965359190240:android:c74bb28e9c92fb5e085085",
  ),
);
    // 2. Initialize FCM
    await FcmTokenService.init();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // 3. Load user session
  final userSession = UserSession();
  await userSession.load();

  // 4. Refresh profile + upload FCM token if already logged in
  if (userSession.isLoggedIn) {
    await ApiService.refreshProfile();
    FcmTokenService.uploadToken(); 
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const OnboardingScreen(),
        );
      },
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SplashScreen());
  }
}