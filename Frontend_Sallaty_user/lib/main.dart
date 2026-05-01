import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'Pages/splashscreen.dart';
import 'Pages/usersession.dart';
import 'Pages/apiservice.dart';

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger la session
  final userSession = UserSession();
  await userSession.load();
  
  print('=== MAIN: isLoggedIn=${userSession.isLoggedIn}');
  print('=== MAIN: isMerchant=${userSession.isMerchant}');
  
  // Rafraîchir le profil si connecté
  if (userSession.isLoggedIn) {
    final refreshed = await ApiService.refreshProfile();
    print('=== MAIN: refreshProfile success=$refreshed');
    print('=== MAIN: isMerchant après refresh=${UserSession().isMerchant}');
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