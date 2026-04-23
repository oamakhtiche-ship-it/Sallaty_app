
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {

  static const String _base = 'http://10.0.2.2:8080';

  // Texte de fallback si le backend est inaccessible
  static const String _fallback =
      'Our privacy policy is currently unavailable. '
      'Please try again later or contact support.';

  String? _content;
  bool    _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPrivacy();
  }

  // ── GET /api/static/privacy ───────────────────────────────────
  Future<void> _fetchPrivacy() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final resp = await http
          .get(Uri.parse('$_base/api/static/privacy'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body    = jsonDecode(resp.body) as Map<String, dynamic>;
        final content = body['content']?.toString() ?? '';
        setState(() {
          _content   = content.isNotEmpty ? content : _fallback;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error     = 'Server error (${resp.statusCode})';
          _content   = _fallback;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = 'Unable to load. Check your connection.';
        _content   = _fallback;
        _isLoading = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Loading ───────────────────────────────────────────────
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF72A843),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Bandeau erreur + retry ─────────────────────────
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_outlined,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchPrivacy,
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Contenu retourné par le backend ────────────────
          // Le backend stocke le texte comme un bloc unique.
          // On l'affiche directement avec le style cohérent.
          Text(
            _content ?? _fallback,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

