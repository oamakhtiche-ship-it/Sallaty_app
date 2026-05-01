import 'package:flutter/material.dart';
import 'privacypolicy.dart';
import 'help.dart';
import 'aboutsallaty.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sallaty',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      home: const AppContentScreen(),
    );
  }
}

// ─── App Content Screen ───────────────────────────────────────────────────────

class AppContentScreen extends StatelessWidget {
  const AppContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF72A843),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'App Content',
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF72A843),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),

              // ── Tiles ────────────────────────────────────────────────────
              _AppContentTile(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AppContentTile(
                icon: Icons.headset_mic_outlined,
                label: 'Help / FAQ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AppContentTile(
                icon: Icons.info_outline_rounded,
                label: 'About Sallaty',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutsallatyPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── App Content Tile ─────────────────────────────────────────────────────────

class _AppContentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppContentTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDCE9C8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF72A843)),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF72A843),
              ),
            ),
          ],
        ),
      ),
    );
  }
}