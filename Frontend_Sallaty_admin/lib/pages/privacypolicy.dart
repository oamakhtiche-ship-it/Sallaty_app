import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════
//  PRIVACY POLICY PAGE
//  GET  /api/static/privacy  → charger le contenu
//  PUT  /api/static/privacy?content=  → sauvegarder (ADMIN)
// ═══════════════════════════════════════════════

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // ─────────────────────────────────────────────
  //  CONSTANTS
  // ─────────────────────────────────────────────
  static const String _baseUrl =
      'http://localhost:8080';

  // ─────────────────────────────────────────────
  //  STATE
  // ─────────────────────────────────────────────
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // ─────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchPrivacyPolicy();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  GET /api/static/privacy
  // ─────────────────────────────────────────────
  Future<void> _fetchPrivacyPolicy() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/static/privacy'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _controller.text = data['content'] ?? '';
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connexion impossible : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  //  PUT /api/static/privacy?content=
  // ─────────────────────────────────────────────
  Future<void> _savePrivacyPolicy() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      _showSnackBar('Le contenu ne peut pas être vide.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await http.put(
        Uri.parse(
            '$_baseUrl/api/static/privacy?content=${Uri.encodeComponent(content)}'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          // TODO: Ajouter le token JWT ici
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _showSnackBar('Privacy Policy mise à jour ✅');
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['message'] ?? 'Erreur lors de la sauvegarde.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Connexion impossible : $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF72A843),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF72A843),
            fontFamily: 'poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // ─── Text Area ───────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF72A843),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'poppins',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _fetchPrivacyPolicy,
                                  icon: const Icon(Icons.refresh,
                                      color: Color(0xFF72A843)),
                                  label: const Text(
                                    'Réessayer',
                                    style:
                                        TextStyle(color: Color(0xFF72A843)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TextField(
                            controller: _controller,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF333333),
                              height: 1.6,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter about privacy policy here...',
                              hintStyle: TextStyle(
                                fontFamily: 'poppins',
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF878986),
                                fontSize: 16,
                              ),
                              contentPadding: EdgeInsets.all(16),
                              border: InputBorder.none,
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Save Changes Button ──────────────────────────────────
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF72A843),
                    Color(0xFFA0CA09),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF72A843).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (_isLoading || _isSaving)
                    ? null
                    : _savePrivacyPolicy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontFamily: 'poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF8FBF6),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}