/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'splashscreen1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _vegsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _vegsOpacity;
  late Animation<Offset> _vegsSlideBottom;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // ── Logo ──────────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // ── Texte ─────────────────────────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // ── Légumes ───────────────────────────────────────
    _vegsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _vegsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _vegsController, curve: Curves.easeIn),
    );
    _vegsSlideBottom = Tween<Offset>(
      begin: const Offset(0, 0.05), // smaller offset looks better full-screen
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _vegsController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _vegsController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SplashScreen1(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _vegsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFECF5E0),
              Color(0xFFF5FAEE),
              Color(0xFFE8F2D8),
            ],
          ),
        ),
        child: Stack(
          children: [

            // ══════════════════════════════════════════
            // UNE SEULE PHOTO de légumes en bas
            // ══════════════════════════════════════════
            Positioned.fill(
              child: FadeTransition(
                opacity: _vegsOpacity,
                child: SlideTransition(
                  position: _vegsSlideBottom,
                  child: Image.asset(
                    'assets/images/splashscreeen.png',
                    width: size.width,
                    height: size.height,
                    fit: BoxFit.fill, // stretches to fill entire screen including top corners
                  ),
                ),
              ),
            ),

            // ══════════════════════════════════════════
            // CENTRE : Logo + Texte
            // ══════════════════════════════════════════
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Logo S avec panier ──────────────
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: size.width * 0.40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Texte "Sallaty" indépendant ─────
                  FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Text(
                        'Sallaty',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 38,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3A6B1A),
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF3A6B1A).withValues(alpha: 0.15),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'splashscreen1.dart';
import 'usersession.dart'; // ← AJOUT
import 'home.dart';           // ← AJOUT : votre HomePage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _vegsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _vegsOpacity;
  late Animation<Offset> _vegsSlideBottom;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _vegsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _vegsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _vegsController, curve: Curves.easeIn),
    );
    _vegsSlideBottom = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _vegsController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _vegsController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    // ── ROUTAGE INTELLIGENT ────────────────────────────────────────
    // UserSession().isLoggedIn est true si un JWT a été chargé depuis
    // SharedPreferences dans main() → l'utilisateur était déjà connecté.
    //
    //   Connecté   → HomePage  (bypass onboarding + login)
    //   Pas connecté → SplashScreen1 (onboarding normal)
    // ──────────────────────────────────────────────────────────────
    final Widget destination = UserSession().isLoggedIn
        ? const HomePage()       // ✅ déjà connecté → accueil direct
        : const SplashScreen1(); // 🆕 première fois → onboarding

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _vegsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFECF5E0),
              Color(0xFFF5FAEE),
              Color(0xFFE8F2D8),
            ],
          ),
        ),
        child: Stack(
          children: [

            Positioned.fill(
              child: FadeTransition(
                opacity: _vegsOpacity,
                child: SlideTransition(
                  position: _vegsSlideBottom,
                  child: Image.asset(
                    'assets/images/splashscreeen.png',
                    width: size.width,
                    height: size.height,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: size.width * 0.40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Text(
                        'Sallaty',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 38,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3A6B1A),
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF3A6B1A).withValues(alpha: 0.15),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}