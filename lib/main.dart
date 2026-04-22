import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'Pages/splashscreen.dart';
import 'Pages/usersession.dart';
import 'Pages/apiservice.dart';

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

// ── AJOUT : main() devient async ────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charge le JWT + profil depuis le disque (SharedPreferences)
  // → après cette ligne, UserSession().isLoggedIn est fiable
  await UserSession().loadFromPrefs();

  // Re-sync silencieuse avec le backend si déjà connecté
  // → un 401 déclenche logout() automatiquement dans refreshProfile()
  // TODO: retirez cette ligne si GET /api/user/me n'est pas encore prêt
  if (UserSession().isLoggedIn) {
    await ApiService.refreshProfile();
  }

  runApp(const MyApp());
}
// ────────────────────────────────────────────────────────────────────

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
    // SplashScreen gère lui-même le routage (voir splashscreen.dart)
    return const Scaffold(body: SplashScreen());
  }
}