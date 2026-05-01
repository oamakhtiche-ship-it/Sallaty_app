import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'seetings.dart';
import 'controlcenter.dart';
import 'dashboard.dart';
import 'notifadmin.dart';
import 'usersession.dart'; // ✅ Ajouté pour accéder au token

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FBF6),
      ),
      home: const MainScreen(initialIndex: 1),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 1});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  late int _page;

  // ✅ Récupérer le token depuis UserSession
  String get _token => UserSession().token ?? '';

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
  }

  static const List<IconData> _icons = [
    Icons.bar_chart_rounded,
    Icons.group,
    Icons.notifications_outlined,
    Icons.settings_outlined,
  ];

  Widget _navItem(IconData icon, bool isSelected) {
    if (isSelected) {
      return Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(icon, size: 28, color: Colors.white),
      );
    }
    return Icon(icon, size: 28, color: Colors.white);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(token: _token); // ✅ token ajouté
      case 1:
        return const ControlCenterBody();
      case 2:
        return NotificationsPage(token: _token); // ✅ token ajouté
      case 3:
        return SettingsBody(token: _token); // ✅ token ajouté
      default:
        return const ControlCenterBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      body: SafeArea(child: _buildPage(_page)),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 75,
        items: List.generate(
          _icons.length,
          (i) => _navItem(_icons[i], i == _page),
        ),
        color: const Color(0xFF89B926),
        buttonBackgroundColor: Colors.transparent,
        backgroundColor: const Color(0xFFF6F8F3),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) => setState(() => _page = index),
      ),
    );
  }
}