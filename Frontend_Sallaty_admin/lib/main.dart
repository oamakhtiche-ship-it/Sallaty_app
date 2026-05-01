import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/splash_screen.dart';
import 'pages/usersession.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore saved session BEFORE runApp so SplashScreen routing works
  await UserSession().loadFromPrefs();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sallaty Admin',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FBF6),
        fontFamily: 'poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF72A843),
          primary: const Color(0xFF72A843),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}