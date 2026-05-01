import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'merchantsorders_merchant.dart'; // MerchantActivityPage
import 'usersession.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const _kBase            = 'http://localhost:8080';
const _kPrimary         = Color(0xFF72A843);
const _kPrimaryDark     = Color(0xFF02531E);
const _kCardBg          = Color(0xFFB9D4A1);
const _kMerchantBadgeBg = Color(0xFFD0E2C0);
const _kMerchantBadgeTx = Color(0xFF007665);
const _kWhite           = Color(0xFFFFFFFF);
const _kBorder          = Color(0xFFAFB0AE);
const _kTextGrey        = Color(0xFF717270);

// ─────────────────────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class _MerchantDetailApi {
  static final _client = http.Client();

  static Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      };

  static Future<void> blockUser(int id, String token) async {
    final res = await _client.put(
        Uri.parse('$_kBase/api/users/block/$id'), headers: _h(token));
    if (res.statusCode != 200) throw Exception('Block échoué');
  }

  static Future<void> unblockUser(int id, String token) async {
    final res = await _client.put(
        Uri.parse('$_kBase/api/users/unblock/$id'), headers: _h(token));
    if (res.statusCode != 200) throw Exception('Unblock échoué');
  }

  static Future<void> verifyMarchand(int id, String token) async {
    final res = await _client.put(
        Uri.parse('$_kBase/api/marchand/verify/$id'), headers: _h(token));
    if (res.statusCode != 200) throw Exception('Vérification échouée');
  }

  static Future<void> deleteUser(int id, String token) async {
    final res = await _client.delete(
        Uri.parse('$_kBase/api/users/delete/$id'), headers: _h(token));
    if (res.statusCode != 200) throw Exception('Suppression échouée');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────────────────────
class MerchantDetailPage extends StatefulWidget {
  final Map<String, dynamic> merchant;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDeleted;

  /// JWT admin token — optional, read from UserSession if absent
  final String? token;

  const MerchantDetailPage({
    super.key,
    required this.merchant,
    required this.onStatusChanged,
    required this.onDeleted,
    this.token,
  });

  @override
  State<MerchantDetailPage> createState() => _MerchantDetailPageState();
}

class _MerchantDetailPageState extends State<MerchantDetailPage> {
  late String _status;
  late Map<String, dynamic> _merchant;

  // Token: prefer passed token, fallback to UserSession
  String get _token => widget.token ?? UserSession().token ?? '';

  // Extract numeric merchant ID
  int get _merchantId {
    final raw = _merchant['id'] ?? _merchant['userId'] ?? 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString().replaceAll('#', '')) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _merchant = Map<String, dynamic>.from(widget.merchant);
    _status   = _merchant['status'] as String? ?? 'Active';
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _changeStatus(String newStatus) async {
    try {
      if (newStatus == 'Blocked') {
        await _MerchantDetailApi.blockUser(_merchantId, _token);
      } else if (newStatus == 'Active' && _status == 'Pending') {
        await _MerchantDetailApi.verifyMarchand(_merchantId, _token);
      } else {
        await _MerchantDetailApi.unblockUser(_merchantId, _token);
      }
      setState(() => _status = newStatus);
      widget.onStatusChanged(newStatus);
      _showSnack(newStatus == 'Blocked'
          ? 'Marchand bloqué ❌'
          : 'Marchand activé ✅');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  Future<void> _deleteMerchant() async {
    final confirm = await _confirmDialog(
      'Delete Merchant',
      'Are you sure you want to delete ${_merchant['name']}? This action cannot be undone.',
    );
    if (!confirm) return;
    try {
      await _MerchantDetailApi.deleteUser(_merchantId, _token);
      widget.onDeleted();
      if (mounted) Navigator.pop(context);
      _showSnack('Marchand supprimé ✅');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  void _openActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantActivityPage(
          merchantId:   _merchantId,
          merchantName: _merchant['name'] as String? ?? '',
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
                    fontWeight: FontWeight.bold, color: _kPrimaryDark)),
            content: Text(content,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final m         = _merchant;
    final isActive  = _status == 'Active';
    final isBlocked = _status == 'Blocked';
    final isPending = _status == 'Pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: _kPrimaryDark),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Merchant Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
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
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: _kCardBg,
                                backgroundImage: m['photo'] != null
                                    ? NetworkImage(m['photo'])
                                    : null,
                                child: m['photo'] == null
                                    ? Text(
                                        _initials(m['name'] ?? '?'),
                                        style: const TextStyle(
                                          color: _kPrimaryDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m['name'] ?? '—',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        _badge('Merchant', _kMerchantBadgeBg,
                                            _kMerchantBadgeTx),
                                        const SizedBox(width: 6),
                                        _statusBadge(_status),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      m['email'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12, color: _kTextGrey),
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
                                  '${m['offers'] ?? m['totalOffers'] ?? 0}',
                                  'Offers'),
                              const SizedBox(width: 8),
                              _statBox(
                                  '${m['orders'] ?? m['totalOrders'] ?? 0}',
                                  'Orders'),
                              const SizedBox(width: 8),
                              _statBox(
                                  '${m['revenue'] ?? m['totalRevenue'] ?? 0} DA',
                                  'Revenue'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Personal Info ──
                    const Text(
                      ' Personal Informations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _sectionCard(rows: [
                      _infoRow('Name',    m['firstName'] ?? _firstName(m['name'])),
                      _infoRow('Surname', m['lastName']  ?? _lastName(m['name'])),
                      _infoRow('ID User', m['userId']?.toString() ?? '#${m['id'] ?? '000000'}'),
                      _infoRow('Email',   m['email'] ?? ''),
                      _infoRow('Phone',   m['phone'] ?? '-'),
                      _infoRow('Inscription date',
                          m['inscriptionDate'] ?? m['createdAt'] ?? '-'),
                      _infoRow('Last connexion',
                          m['lastConnexion'] ?? m['lastLogin'] ?? '-',
                          isLast: true),
                    ]),
                    const SizedBox(height: 20),

                    // ── Store Info ──
                    const Text(
                      ' Store Informations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _sectionCard(rows: [
                      _infoRow('Store Name',     m['storeName'] ?? '-'),
                      _infoRow('Business Type',  m['businessType'] ?? '-'),
                      _infoRow('Address',         m['address'] ?? '-',
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
                              textColor: _kWhite,
                              onTap: () => _changeStatus('Blocked'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (isBlocked) ...[
                          Expanded(
                            child: _fullButton(
                              label: 'Unblock',
                              color: _kMerchantBadgeBg,
                              textColor: _kPrimaryDark,
                              onTap: () => _changeStatus('Active'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (isPending) ...[
                          Expanded(
                            child: _fullButton(
                              label: 'Verify',
                              color: _kPrimary,
                              textColor: _kWhite,
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
                            onTap: _deleteMerchant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── See Activity Banner ──
                    GestureDetector(
                      onTap: _openActivity,
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
                              color: const Color(0xFF72A843).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'See Activity →',
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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
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
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
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
                bottom: BorderSide(color: _kBorder, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF000000))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _statusBadge(String status) {
    Color bg, textColor;
    switch (status) {
      case 'Active':
        bg = _kMerchantBadgeBg; textColor = _kMerchantBadgeTx; break;
      case 'Blocked':
        bg = const Color(0xFFFFBEBE); textColor = Colors.red; break;
      default: // Pending
        bg = const Color(0xFFFFF3CD); textColor = const Color(0xFF856404);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: textColor)),
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