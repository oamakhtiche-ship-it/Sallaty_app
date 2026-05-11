import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'usersession.dart';

const _base     = 'https://headstand-rosy-chlorine.ngrok-free.dev';
const kPrimary  = Color(0xFF72A843);
const kTextDark = Color(0xFF2D2E2D);

// ─────────────────────────────────────────────────────────────────────────────
//  IMAGE URL HELPER — converts relative paths to full URLs
// ─────────────────────────────────────────────────────────────────────────────
String? fullImageUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final p = path.trim();
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (p.startsWith('//')) return 'https:$p';
  return '$_base${p.startsWith('/') ? '' : '/'}$p';
}

Map<String, String> _headers() => {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer ${UserSession().token ?? ''}',
  'ngrok-skip-browser-warning': 'true',
};

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ReservationItem {
  final int    id;
  final int    clientId;
  final int    offreId;
  final String offreName;
  final String clientName;
  final int    quantity;
  final double totalPrice;
  final String status;
  final String? payment;
  final String? createdAt;
  // ✅ NEW: client photo URL (fully qualified)
  final String? clientPhotoUrl;

  ReservationItem({
    required this.id,
    required this.clientId,
    required this.offreId,
    required this.offreName,
    required this.clientName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    this.payment,
    this.createdAt,
    this.clientPhotoUrl,
  });

  factory ReservationItem.fromJson(Map<String, dynamic> j) {
    final clientName = _buildClientName(j);
    final offreName  = j['offreName']  ?? j['title'] ?? j['offreTitle'] ?? 'Offer';

    // ✅ FIX: extract and normalize the client photo URL
    final rawPhoto = j['clientPhoto']?.toString()
        ?? j['profileImage']?.toString()
        ?? j['photo']?.toString()
        ?? j['clientProfileImage']?.toString();

    return ReservationItem(
      id:             j['ordreId']   ?? j['id']       ?? 0,
      clientId:       j['clientId']  ?? 0,
      offreId:        j['offreId']   ?? 0,
      offreName:      offreName,
      clientName:     clientName,
      quantity:       j['quantity']  ?? 1,
      totalPrice:     (j['totalPrice'] ?? 0).toDouble(),
      status:         j['status']    ?? 'PENDING',
      payment:        j['paymentMethod'] ?? j['payment'],
      createdAt:      j['createdAt']?.toString(),
      clientPhotoUrl: fullImageUrl(rawPhoto),  // ✅ full URL
    );
  }

  static String _buildClientName(Map<String, dynamic> j) {
    if (j['clientName'] != null && j['clientName'].toString().isNotEmpty) {
      return j['clientName'];
    }
    final first   = j['firstName']   ?? j['clientFirstName'] ?? '';
    final surname = j['surname']     ?? j['clientSurname']   ?? '';
    if (first.isNotEmpty || surname.isNotEmpty) {
      return '$first $surname'.trim();
    }
    return 'Client';
  }

  String get displayStatus {
    switch (status.toUpperCase()) {
      case 'PENDING':   return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'COMPLETED': return 'Picked';
      case 'CANCELLED': return 'Cancelled';
      case 'REJECTED':  return 'Rejected';
      default:          return status;
    }
  }

  String get initials {
    final parts = clientName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clientName.isNotEmpty ? clientName[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ReservationManagementPage extends StatefulWidget {
  const ReservationManagementPage({super.key});
  @override
  State<ReservationManagementPage> createState() => _ReservationManagementPageState();
}

class _ReservationManagementPageState extends State<ReservationManagementPage> {
  String _selectedFilter = 'All';
  bool   _loading        = true;
  String? _error;
  List<ReservationItem> _reservations = [];

  final List<String> _filters = ['All', 'Pending', 'Confirmed', 'Picked', 'Cancelled'];

  List<ReservationItem> get _filtered => _reservations
      .where((r) => _selectedFilter == 'All' || r.displayStatus == _selectedFilter)
      .toList();

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> _fetchReservations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = UserSession();
      final role    = session.role?.toUpperCase() ?? '';

      Uri uri;
      if (role == 'ADMIN') {
        uri = Uri.parse('$_base/api/admin/reservations');
      } else {
        final marchandId = session.userId;
        if (marchandId == null) throw Exception('User ID not found');
        uri = Uri.parse('$_base/api/ordres/marchand/$marchandId');
      }

      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _reservations = data
              .map((j) => ReservationItem.fromJson(j as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Error ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _confirmOrder(ReservationItem item) async {
    if (!await _confirm('Confirm Order',
        'Confirm order #${item.id} for ${item.clientName}?')) return;
    await _put('$_base/api/ordres/confirm/${item.id}', 'Order confirmed ✅');
  }

  Future<void> _rejectOrder(ReservationItem item) async {
    if (!await _confirm('Reject Order',
        'Reject order #${item.id}? This cannot be undone.')) return;
    await _put('$_base/api/ordres/reject/${item.id}', 'Order rejected ❌');
  }

  Future<void> _markPicked(ReservationItem item) async {
    if (!await _confirm('Mark as Picked',
        'Mark order #${item.id} as picked up?')) return;
    await _put('$_base/api/ordres/complete/${item.id}', 'Marked as picked ✅');
  }

  Future<void> _put(String url, String successMsg) async {
    try {
      final res = await http.put(Uri.parse(url), headers: _headers());
      if (res.statusCode == 200) {
        _showSnack(successMsg);
        _fetchReservations();
      } else {
        _showSnack('Error ${res.statusCode}');
      }
    } catch (_) {
      _showSnack('Network error');
    }
  }

  Future<bool> _confirm(String title, String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(msg),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ?? false;

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAdmin = UserSession().role?.toUpperCase() == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isAdmin ? 'Reservation Management' : 'Order Management',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w400, color: kPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final sel = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: PhysicalModel(
                          color: sel ? kPrimary : const Color(0xFFD7D8D7),
                          borderRadius: BorderRadius.circular(8),
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : kTextDark)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final pending   = _reservations.where((r) => r.displayStatus == 'Pending').length;
    final confirmed = _reservations.where((r) => r.displayStatus == 'Confirmed').length;
    final total     = _reservations.length;

    return Row(children: [
      _chip('Total',     total.toString(),     const Color(0xFFE8F5E9), kPrimary),
      const SizedBox(width: 8),
      _chip('Pending',   pending.toString(),   const Color(0xFFFFF9C4), const Color(0xFFF57F17)),
      const SizedBox(width: 8),
      _chip('Confirmed', confirmed.toString(), const Color(0xFFD0E2C0), kPrimary),
    ]);
  }

  Widget _chip(String label, String value, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: RichText(
      text: TextSpan(children: [
        TextSpan(text: '$label ', style: TextStyle(fontSize: 11, color: fg)),
        TextSpan(
            text: value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
      ]),
    ),
  );

  Widget _buildBody() {
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    if (_error != null)
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchReservations,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ]),
      );
    if (_filtered.isEmpty)
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _reservations.isEmpty ? 'No orders yet' : 'No orders match this filter',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ]),
      );

    return ListView.separated(
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _buildCard(_filtered[i]),
    );
  }

  Widget _buildCard(ReservationItem item) {
    final status  = item.displayStatus;
    final isAdmin = UserSession().role?.toUpperCase() == 'ADMIN';

    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: DottedBorder(
        color: Colors.black,
        dashPattern: const [5, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ✅ FIX: show client photo if available, fallback to initials
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFD0E2C0),
                    child: item.clientPhotoUrl != null
                        ? ClipOval(
                      child: Image.network(
                        item.clientPhotoUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          item.initials,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kPrimary),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Text(
                            item.initials,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimary),
                          );
                        },
                      ),
                    )
                        : Text(
                      item.initials,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: kPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.clientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(item.offreName,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black87)),
                        Text('Qty: ${item.quantity}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        if (item.createdAt != null)
                          Text('Date: ${_fmt(item.createdAt!)}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        if (item.payment != null && item.payment!.isNotEmpty)
                          Text('Payment: ${item.payment}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.totalPrice.toStringAsFixed(0)} DA',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      _statusBadge(status),
                    ],
                  ),
                ],
              ),

              // ── Action buttons (Marchand only) ──
              if (!isAdmin &&
                  (status == 'Pending' || status == 'Confirmed')) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'Pending') ...[
                      _actionBtn(
                        label: 'Reject',
                        color: const Color(0xFFFFBEBE),
                        textColor: const Color(0xFFD32F2F),
                        onTap: () => _rejectOrder(item),
                      ),
                      const SizedBox(width: 8),
                      _actionBtn(
                        label: 'Confirm',
                        color: kPrimary,
                        textColor: Colors.white,
                        onTap: () => _confirmOrder(item),
                      ),
                    ],
                    if (status == 'Confirmed')
                      _actionBtn(
                        label: 'Mark Picked',
                        color: const Color(0xFFD0E2C0),
                        textColor: const Color(0xFF388E3C),
                        onTap: () => _markPicked(item),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Widget _statusBadge(String status) {
    Color bg, text;
    switch (status) {
      case 'Confirmed': bg = const Color(0xFFD0E2C0); text = const Color(0xFF5F8C38); break;
      case 'Pending':   bg = const Color(0xFFFFF9C4); text = const Color(0xFFF57F17); break;
      case 'Picked':    bg = const Color(0xFFD7D8D7); text = const Color(0xFF2D2E2D); break;
      case 'Cancelled': bg = const Color(0xFFFFBEBE); text = const Color(0xFFD32F2F); break;
      case 'Rejected':  bg = const Color(0xFFFFCDD2); text = const Color(0xFFB71C1C); break;
      default:          bg = Colors.grey.shade200;    text = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: text)),
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ),
      );
}