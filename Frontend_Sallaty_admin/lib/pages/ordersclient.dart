import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const kBaseUrl  = 'http://localhost:8080';
const kPrimary     = Color(0xFF72A843);
const kPrimaryDark = Color(0xFF5F8C38);
const kWhite       = Color(0xFFFFFFFF);
const kBorder      = Color(0xFFAFB0AE);

// ─── API Service ──────────────────────────────────────────────────────────────

class OrdersApiService {
  static Future<List<Map<String, dynamic>>> fetchClientOrders(String token) async {
    final uri = Uri.parse('$kBaseUrl/api/ordres/client');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    }
    throw Exception('Failed to load orders: ${res.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchClientOrdersByStatus(
      String token, String status) async {
    final uri = Uri.parse('$kBaseUrl/api/ordres/client/status?status=$status');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    }
    throw Exception('Failed to load orders by status: ${res.statusCode}');
  }

  static Future<bool> cancelOrder(String token, int ordreId) async {
    final uri = Uri.parse('$kBaseUrl/api/ordres/cancel/$ordreId');
    final res = await http.put(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    return res.statusCode == 200;
  }
}

// ─── Helper: map raw API order → UI-friendly map ─────────────────────────────

Map<String, dynamic> _mapOrder(Map<String, dynamic> raw) {
  return {
    'ordreId':     raw['id'] ?? raw['ordreId'],
    'productName': raw['offreName'] ?? raw['productName'] ?? 'Produit',
    'imageUrl':    raw['offreImage'] ?? raw['imageUrl'],
    'totalPrice':  raw['totalPrice'] ?? raw['montantTotal'] ?? 0,
    'quantity':    raw['quantity'] ?? raw['quantite'] ?? 1,
    'status':      _mapStatus(raw['status'] ?? raw['statut'] ?? ''),
    'from':        raw['marchandName'] ?? raw['shopName'],
    'payment':     raw['paymentMethod'] ?? raw['modePaiement'],
    'createdAt':   _shortDate(raw['createdAt']),
    'confirmedAt': _shortDate(raw['confirmedAt']),
    'pickedAt':    _shortDate(raw['pickedAt']),
    'cancelledAt': _shortDate(raw['cancelledAt']),
  };
}

String _mapStatus(String s) {
  switch (s.toUpperCase()) {
    case 'CONFIRMED': return 'Confirmed';
    case 'PENDING':   return 'Pending';
    case 'CANCELLED': return 'Cancelled';
    case 'PICKED':    return 'Picked';
    default:          return s;
  }
}

String? _shortDate(dynamic raw) {
  if (raw == null) return null;
  try {
    final dt = DateTime.parse(raw.toString());
    return '${dt.day}/${dt.month} ${dt.hour}h${dt.minute.toString().padLeft(2,'0')}';
  } catch (_) {
    return raw.toString();
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class ClientActivityPage extends StatefulWidget {
  final String clientName;
  final String token;

  // Optionally pass pre-loaded orders (offline/test mode)
  final List<Map<String, dynamic>>? orders;

  const ClientActivityPage({
    super.key,
    required this.clientName,
    required this.token,
    this.orders,
  });

  @override
  State<ClientActivityPage> createState() => _ClientActivityPageState();
}

class _ClientActivityPageState extends State<ClientActivityPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.orders != null) {
      _orders  = widget.orders!;
      _loading = false;
    } else {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await OrdersApiService.fetchClientOrders(widget.token);
      setState(() {
        _orders  = raw.map(_mapOrder).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _cancelOrder(int ordreId) async {
    final ok = await OrdersApiService.cancelOrder(widget.token, ordreId);
    if (ok) {
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande annulée ✅')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l\'annulation ❌')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = _orders.where((o) => o['status'] == 'Confirmed').length;
    final pending   = _orders.where((o) => o['status'] == 'Pending').length;
    final cancelled = _orders.where((o) => o['status'] == 'Cancelled').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: kPrimaryDark),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Activity _ ',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w400, color: kPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.clientName,
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: kPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh, color: kPrimaryDark),
                    onPressed: _loadOrders,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimary))
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: _loadOrders)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Orders Tab ──
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Orders',
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: kWhite,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // ── Stats Row ──
                              Row(
                                children: [
                                  _statChip('$confirmed', 'Confirmed',
                                      const Color(0xFFD0E2C0), const Color(0xFF007665)),
                                  const SizedBox(width: 8),
                                  _statChip('$pending', 'Pending',
                                      const Color(0xFFFFF3CD), const Color(0xFF856404)),
                                  const SizedBox(width: 8),
                                  _statChip('$cancelled', 'Cancelled',
                                      const Color(0xFFFFBEBE), Colors.red),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_orders.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text(
                                      'Aucune commande trouvée.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ..._orders.map((order) => _orderCard(order)),

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

  // ── Stat chip ──
  Widget _statChip(String value, String label, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: textColor)),
          ],
        ),
      ),
    );
  }

  // ── Order card ──
  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    Color statusBg, statusText;
    switch (status) {
      case 'Confirmed':
        statusBg = const Color(0xFFD0E2C0); statusText = const Color(0xFF007665); break;
      case 'Pending':
        statusBg = const Color(0xFFFFF3CD); statusText = const Color(0xFF856404); break;
      case 'Cancelled':
        statusBg = const Color(0xFFFFBEBE); statusText = Colors.red; break;
      case 'Picked':
        statusBg = const Color(0xFFD6EEFF); statusText = const Color(0xFF2979FF); break;
      default:
        statusBg = const Color(0xFFEEEEEE); statusText = Colors.grey;
    }

    final ordreId = order['ordreId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: order['imageUrl'] != null
                ? Image.network(order['imageUrl'], width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(order['productName'] ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('Total: ${order['totalPrice']} DA',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  ],
                ),
                const SizedBox(height: 4),
                if (order['from'] != null)
                  Text('From: ${order['from']}', style: const TextStyle(fontSize: 10, color: Color(0xFF717270))),
                if (order['quantity'] != null)
                  Text('Qty: ${order['quantity']}', style: const TextStyle(fontSize: 10, color: Color(0xFF717270))),
                if (order['payment'] != null)
                  Text('Payment: ${order['payment']}', style: const TextStyle(fontSize: 10, color: Color(0xFF717270))),
                const SizedBox(height: 2),
                _buildTimeline(order),

                // Cancel button only for pending
                if (status == 'Pending' && ordreId != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showCancelDialog(ordreId),
                      style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.zero),
                      child: const Text('Annuler', style: TextStyle(fontSize: 11)),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
            child: Text(status,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusText)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(int ordreId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Non')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _cancelOrder(ordreId); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> order) {
    final parts = <String>[];
    if (order['createdAt']   != null) parts.add('Created: ${order['createdAt']}');
    if (order['confirmedAt'] != null) parts.add('Confirmed: ${order['confirmedAt']}');
    if (order['pickedAt']    != null) parts.add('Picked: ${order['pickedAt']}');
    if (order['cancelledAt'] != null) parts.add('Cancelled: ${order['cancelledAt']}');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join(' · '), style: const TextStyle(fontSize: 9, color: Color(0xFF9B9D9A)));
  }

  Widget _imagePlaceholder() => Container(
    width: 60, height: 60,
    decoration: BoxDecoration(color: const Color(0xFFD0E2C0), borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF5F8C38), size: 28),
  );
}

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
