import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ordersclient.dart';
import 'usersession.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const kBaseUrl           = 'https://headstand-rosy-chlorine.ngrok-free.dev';
const kPrimary           = Color(0xFFA4CF4A);
const kPrimaryDark       = Color(0xFF5F8C38);
const kCardBg            = Color(0xFFB9D4A1);
const kMerchantBadgeBg   = Color(0xFFD0E2C0);
const kMerchantBadgeText = Color(0xFF007665);
const kWhite             = Color(0xFFFFFFFF);
const kBorder            = Color(0xFFAFB0AE);
const kClientStatusBg    = Color(0xFFADE9EB);
const kClientStatusText  = Color(0xFF2BBBC0);

// ─────────────────────────────────────────────────────────────────────────────
//  API SERVICE — ClientDetail
// ─────────────────────────────────────────────────────────────────────────────
class ClientDetailApiService {
  static final _client = http.Client();

  static Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      };

  /// GET /api/admin/users/{id}
  static Future<Map<String, dynamic>> getUserProfile(
      int id, String token) async {
    final res = await _client.get(
      Uri.parse('$kBaseUrl/api/admin/users/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception('Profil introuvable');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  /// GET /api/admin/users/{id}/orders
  static Future<List<Map<String, dynamic>>> getUserOrders(
      int id, String token) async {
    final res = await _client.get(
      Uri.parse('$kBaseUrl/api/admin/users/$id/orders'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception('Erreur orders');
    final data = jsonDecode(res.body);
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data['orders'] != null) {
      // ✅ Fix: curly_braces_in_flow_control_structures
      return List<Map<String, dynamic>>.from(data['orders']);
    }
    return [];
  }

  /// PUT /api/users/block/{userId}
  static Future<void> blockUser(int id, String token) async {
    final res = await _client.put(
      Uri.parse('$kBaseUrl/api/users/block/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception('Block échoué');
  }

  /// PUT /api/users/unblock/{userId}
  static Future<void> unblockUser(int id, String token) async {
    final res = await _client.put(
      Uri.parse('$kBaseUrl/api/users/unblock/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception('Unblock échoué');
  }

  /// DELETE /api/users/delete/{userId}
  static Future<void> deleteUser(int id, String token) async {
    final res = await _client.delete(
      Uri.parse('$kBaseUrl/api/users/delete/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception('Suppression échouée');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ClientDetailPage extends StatefulWidget {
  final Map<String, dynamic> client;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDeleted;

  /// JWT admin token — optionnel, lu depuis UserSession si absent
  final String? token;

  /// Commandes pré-chargées (optionnel — rechargées si absentes)
  final List<Map<String, dynamic>> orders;

  const ClientDetailPage({
    super.key,
    required this.client,
    required this.onStatusChanged,
    required this.onDeleted,
    this.token,                    // ✅ Fix: plus required → optionnel
    this.orders = const [],
  });

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  late String _status;
  late Map<String, dynamic> _client;

  bool _loadingOrders = false;
  String? _ordersError;

  List<Map<String, dynamic>> _orders = [];

  // ── Token helper — préfère le token passé, sinon lit UserSession ──────────
  String get _token =>
      widget.token ?? UserSession().token ?? '';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _status = widget.client['status'] as String? ?? 'Active';
    _client = Map<String, dynamic>.from(widget.client);
    _orders = List<Map<String, dynamic>>.from(widget.orders);
  }

  // ── Helpers — extract numeric ID ──────────────────────────────────────────
  int get _clientId {
    final raw = _client['id'] ?? _client['userId'] ?? 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString().replaceAll('#', '')) ?? 0;
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _changeStatus(String newStatus) async {
    try {
      if (newStatus == 'Blocked') {
        await ClientDetailApiService.blockUser(_clientId, _token);
      } else {
        await ClientDetailApiService.unblockUser(_clientId, _token);
      }
      setState(() => _status = newStatus);
      widget.onStatusChanged(newStatus);
      _showSnack(newStatus == 'Blocked'
          ? 'Client bloqué ❌'
          : 'Client débloqué ✅');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  Future<void> _deleteClient() async {
    final confirm = await _confirmDialog(
        'Delete Client',
        'Are you sure you want to delete ${_client['name']}? This action cannot be undone.');
    if (!confirm) return;
    try {
      await ClientDetailApiService.deleteUser(_clientId, _token);
      widget.onDeleted();
      if (mounted) Navigator.pop(context);
      _showSnack('Client supprimé ✅');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  /// Charge les orders depuis l'API puis navigue
  Future<void> _openActivity() async {
    setState(() {
      _loadingOrders = true;
      _ordersError   = null;
    });

    try {
      if (_orders.isEmpty) {
        _orders = await ClientDetailApiService.getUserOrders(
            _clientId, _token);
      }
    } catch (e) {
      _ordersError = e.toString();
    } finally {
      setState(() => _loadingOrders = false);
    }

    if (!mounted) return;

    if (_ordersError != null) {
      _showSnack('Erreur chargement commandes : $_ordersError',
          isError: true);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientActivityPage(
          clientName: _client['name'] as String? ?? '',
          orders: _orders,
          token: _token, 
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF72A843),
    ));
  }

  Future<bool> _confirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kPrimaryDark)),
            content: Text(content,
                style:
                    const TextStyle(fontSize: 13, color: Colors.black54)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style:
                        TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c         = _client;
    final isActive  = _status == 'Active';
    final isBlocked = _status == 'Blocked';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: kPrimaryDark),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Client Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF72A843),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Avatar + Stats ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: kCardBg,
                                backgroundImage: c['photo'] != null
                                    ? NetworkImage(c['photo'])
                                    : null,
                                child: c['photo'] == null
                                    ? Text(
                                        _initials(c['name'] ?? '?'),
                                        style: const TextStyle(
                                          color: kPrimaryDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['name'] ?? '—',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        _badge('Client', kClientStatusBg,
                                            kClientStatusText),
                                        const SizedBox(width: 6),
                                        _statusBadge(_status),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      c['email'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9B9D9A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _statBox(
                                  '${c['orders'] ?? c['totalOrders'] ?? 0}',
                                  'Orders'),
                              const SizedBox(width: 8),
                              _statBox(
                                  '${c['favorites'] ?? c['totalFavoris'] ?? 0}',
                                  'Favorites'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section Title ──
                    const Text(
                      ' Personal Informations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Info Card ──
                    _sectionCard(rows: [
                      _infoRow('Name',
                          c['firstName'] ?? _firstName(c['name'])),
                      _infoRow('Surname',
                          c['lastName'] ?? _lastName(c['name'])),
                      _infoRow('ID User',
                          c['userId']?.toString() ??
                              '#${c['id'] ?? '000000'}'),
                      _infoRow('Email/Phone', c['email'] ?? ''),
                      _infoRow('Inscription date',
                          c['inscriptionDate'] ?? c['createdAt'] ?? '-'),
                      _infoRow('Last connexion',
                          c['lastConnexion'] ?? c['lastLogin'] ?? '-',
                          isLast: true),
                    ]),
                    const SizedBox(height: 24),

                    // ── Action Buttons ──
                    Row(
                      children: [
                        if (isActive) ...[
                          Expanded(
                            child: _fullButton(
                              label: 'Block',
                              color: Colors.red,
                              textColor: kWhite,
                              onTap: () => _changeStatus('Blocked'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (isBlocked) ...[
                          Expanded(
                            child: _fullButton(
                              label: 'Unblock',
                              color: kMerchantBadgeBg,
                              textColor: kPrimaryDark,
                              onTap: () => _changeStatus('Active'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: _fullButton(
                            label: 'Delete',
                            color: const Color(0xFF9B9D9A),
                            textColor: const Color(0xFF5E5E5E),
                            onTap: _deleteClient,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── See Orders Banner ──
                    GestureDetector(
                      onTap: _loadingOrders ? null : _openActivity,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              // ✅ Fix: withOpacity → withValues
                              color: const Color(0xFF72A843).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _loadingOrders
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: kWhite, strokeWidth: 2.5),
                              )
                            : const Text(
                                'See Orders →',
                                style: TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF8FBF6),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  String _firstName(String? name) {
    if (name == null) return '';
    final p = name.trim().split(' ');
    return p.isNotEmpty ? p.first : '';
  }

  String _lastName(String? name) {
    if (name == null) return '';
    final p = name.trim().split(' ');
    return p.length > 1 ? p.last : '';
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 1),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> rows}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: kBorder, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF000000))),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: textColor)),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color textColor;
    switch (status) {
      case 'Active':
        bg        = kMerchantBadgeBg;
        textColor = kMerchantBadgeText;
        break;
      case 'Blocked':
        bg        = const Color(0xFFFFBEBE);
        textColor = Colors.red;
        break;
      default:
        bg        = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: textColor)),
    );
  }

  Widget _fullButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor)),
      ),
    );
  }
}