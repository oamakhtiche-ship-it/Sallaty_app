import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usersession.dart';
import 'apiservice.dart';

class ClientPublicProfilePage extends StatefulWidget {
  final String clientId;
  const ClientPublicProfilePage({super.key, required this.clientId});

  @override
  State<ClientPublicProfilePage> createState() =>
      _ClientPublicProfilePageState();
}

class _ClientPublicProfilePageState
    extends State<ClientPublicProfilePage> {
  final Color primary = const Color(0xFF72A843);
  bool _loading = true;
  Map<String, dynamic> _profile = {};

 
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── GET /api/profile/{userId} — profil public ─────────────────
  Future<void> _loadProfile() async {
    try {
      final token = UserSession().token ?? '';
      final res = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/profile/${widget.clientId}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('[ClientProfile] status: ${res.statusCode}');
      debugPrint('[ClientProfile] body: ${res.body}');

      if (res.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('[ClientProfile] error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        '${_profile['firstName'] ?? ''} ${_profile['surname'] ?? ''}'
            .trim();
    String photoUrl = _profile['profilePhoto']?.toString() ?? '';
    if (photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      photoUrl = '${ApiConfig.baseUrl}/$photoUrl';
    }
    final wilaya  = _profile['wilaya']?.toString()  ?? '';
    final contact = _profile['contact']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Client Profile',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: primary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ── Avatar ──────────────────────────────────
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFFD0E2C0),
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5F8C38)),
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // ── Nom ─────────────────────────────────────
                  Text(
                    name.isNotEmpty ? name : 'Client',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                  ),

                  const SizedBox(height: 24),

                  // ── Wilaya ──────────────────────────────────
                  if (wilaya.isNotEmpty)
                    _infoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: wilaya),

                  // ── Contact (masqué partiellement) ──────────
                  if (contact.isNotEmpty)
                    _infoTile(
                        icon: Icons.phone_outlined,
                        label: 'Contact',
                        value: _maskContact(contact)),
                ],
              ),
            ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF72A843), size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF9CA3AF))),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Masque le contact : 0555***678
  String _maskContact(String c) {
    if (c.length <= 4) return c;
    return '${c.substring(0, 4)}***${c.substring(c.length - 3)}';
  }
}