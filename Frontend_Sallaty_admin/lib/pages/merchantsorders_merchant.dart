import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'usersession.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const _base = 'https://headstand-rosy-chlorine.ngrok-free.dev';

Map<String, String> _headers() => {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer ${UserSession().token ?? ''}',
  'ngrok-skip-browser-warning': 'true',
};

// ─── Helpers ─────────────────────────────────────────────────────────────────
String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return raw;
  }
}

String _orderDisplayStatus(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'PENDING':   return 'Pending';
    case 'CONFIRMED': return 'Confirmed';
    case 'COMPLETED': return 'Picked';
    case 'CANCELLED': return 'Cancelled';
    case 'REJECTED':  return 'Rejected';
    default:          return s ?? '';
  }
}

String _offerDisplayStatus(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'ACTIVE':   return 'Active';
    case 'SOLD_OUT': return 'Sold out';
    case 'EXPIRED':  return 'Expired';
    case 'ARCHIVED': return 'Archived';
    default:         return s ?? '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────────────────────
class MerchantActivityPage extends StatefulWidget {
  final int    merchantId;
  final String merchantName;

  const MerchantActivityPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
  });

  @override
  State<MerchantActivityPage> createState() => _MerchantActivityPageState();
}

class _MerchantActivityPageState extends State<MerchantActivityPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  // ── state ──
  bool   _ordersLoading = true;
  bool   _offersLoading = true;
  String? _ordersError;
  String? _offersError;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _offers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
    _fetchOffers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  API CALLS
  // ══════════════════════════════════════════════════════════════════════════

  // GET /api/admin/merchants/{marchandId}/orders
  Future<void> _fetchOrders() async {
    setState(() { _ordersLoading = true; _ordersError = null; });
    try {
      final uri = Uri.parse('$_base/api/admin/merchants/${widget.merchantId}/orders');
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _orders = data.cast<Map<String, dynamic>>();
          _ordersLoading = false;
        });
      } else {
        setState(() { _ordersError = 'Error ${res.statusCode}'; _ordersLoading = false; });
      }
    } catch (e) {
      setState(() { _ordersError = e.toString(); _ordersLoading = false; });
    }
  }

  // GET /api/admin/merchants/{marchandId}/offers
  Future<void> _fetchOffers() async {
    setState(() { _offersLoading = true; _offersError = null; });
    try {
      final uri = Uri.parse('$_base/api/admin/merchants/${widget.merchantId}/offers');
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _offers = data.cast<Map<String, dynamic>>();
          _offersLoading = false;
        });
      } else {
        setState(() { _offersError = 'Error ${res.statusCode}'; _offersLoading = false; });
      }
    } catch (e) {
      setState(() { _offersError = e.toString(); _offersLoading = false; });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
        ),
        title: Text(
          'Activity _ ${widget.merchantName}',
          style: const TextStyle(
            color: Color(0xFF72A843), fontSize: 18, fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF72A843)),
            onPressed: () { _fetchOrders(); _fetchOffers(); },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            // ── Tab Bar ──
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD0E6A5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF72A843),
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFAFB0AE),
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: 'Orders'), Tab(text: 'Offers')],
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersTab(),
                  _buildOffersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ORDERS TAB ───────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    if (_ordersLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF72A843)));
    if (_ordersError != null) return _errorWidget(_ordersError!, _fetchOrders);

    final confirmed = _orders.where((o) => _orderDisplayStatus(o['status'] as String?) == 'Confirmed').length;
    final pending   = _orders.where((o) => _orderDisplayStatus(o['status'] as String?) == 'Pending').length;
    final cancelled = _orders.where((o) => _orderDisplayStatus(o['status'] as String?) == 'Cancelled').length;

    return Column(
      children: [
        Row(
          children: [
            _SummaryBox('$confirmed', 'Confirmed', const Color(0xFF4CAF50), const Color(0xFFE8F5E9)),
            const SizedBox(width: 8),
            _SummaryBox('$pending',   'Pending',   const Color(0xFFFF9800), const Color(0xFFFFF9C4)),
            const SizedBox(width: 8),
            _SummaryBox('$cancelled', 'Cancelled', const Color(0xFFFF3B3B), const Color(0xFFFDECEA)),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _orders.isEmpty
              ? _emptyState('No orders yet', Icons.receipt_long_outlined)
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (_, i) {
                    final o = _orders[i];
                    final status = _orderDisplayStatus(o['status'] as String?);
                    return _OrderCard(
                      title:       (o['offreName'] ?? o['title'] ?? 'Order').toString(),
                      price:       '${(o['totalPrice'] ?? 0)} DA',
                      from:        (o['clientName'] ?? '').toString(),
                      quantity:    '${o['quantity'] ?? ''}',
                      payment:     (o['paymentMethod'] ?? '-').toString(),
                      created:     _fmtDate(o['createdAt'] as String?),
                      extra:       _buildOrderExtra(o),
                      status:      status,
                      statusColor: _orderStatusColor(status),
                      statusBg:    _orderStatusBg(status),
                      imageUrl:    o['photoPath'] != null ? '$_base/${o['photoPath']}' : null,
                      emoji:       '🛒',
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── OFFERS TAB ───────────────────────────────────────────────────────────
  Widget _buildOffersTab() {
    if (_offersLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF72A843)));
    if (_offersError != null) return _errorWidget(_offersError!, _fetchOffers);

    final active  = _offers.where((o) => _offerDisplayStatus(o['status'] as String?) == 'Active').length;
    final soldOut = _offers.where((o) => _offerDisplayStatus(o['status'] as String?) == 'Sold out').length;
    final expired = _offers.where((o) => _offerDisplayStatus(o['status'] as String?) == 'Expired').length;

    return Column(
      children: [
        Row(
          children: [
            _SummaryBox('$active',  'Active',   const Color(0xFF4CAF50), const Color(0xFFE8F5E9)),
            const SizedBox(width: 8),
            _SummaryBox('$soldOut', 'Sold Out', const Color(0xFF717270), const Color(0xFFD7D8D7)),
            const SizedBox(width: 8),
            _SummaryBox('$expired', 'Expired',  const Color(0xFFFF3B3B), const Color(0xFFFDECEA)),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _offers.isEmpty
              ? _emptyState('No offers yet', Icons.inventory_2_outlined)
              : ListView.builder(
                  itemCount: _offers.length,
                  itemBuilder: (_, i) {
                    final o = _offers[i];
                    final status = _offerDisplayStatus(o['status'] as String?);
                    return _OfferCard(
                      title:        (o['title'] ?? '').toString(),
                      unitPrice:    '${(o['price'] ?? 0)} DA',
                      type:         (o['categoryType'] ?? '').toString(),
                      quantity:     '${o['quantity'] ?? ''}',
                      reservations: '${o['reservations'] ?? '0'}',
                      created:      _fmtDate(o['createdAt'] as String?),
                      expired:      _fmtDate(o['expireAt'] as String?),
                      status:       status,
                      statusColor:  _offerStatusColor(status),
                      statusBg:     _offerStatusBg(status),
                      imageUrl:     o['photoPath'] != null ? '$_base/${o['photoPath']}' : null,
                      emoji:        '🛍️',
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _buildOrderExtra(Map<String, dynamic> o) {
    if (o['confirmedAt'] != null) return 'Confirmed: ${_fmtDate(o['confirmedAt'] as String?)}';
    if (o['completedAt'] != null) return 'Picked: ${_fmtDate(o['completedAt'] as String?)}';
    if (o['cancelledAt'] != null) return 'Cancelled: ${_fmtDate(o['cancelledAt'] as String?)}';
    return '';
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'Confirmed': return const Color(0xFF4CAF50);
      case 'Picked':    return const Color(0xFF4CAF50);
      case 'Pending':   return const Color(0xFFFF9800);
      case 'Cancelled':
      case 'Rejected':  return const Color(0xFFFF3B3B);
      default:          return const Color(0xFF717270);
    }
  }

  Color _orderStatusBg(String status) {
    switch (status) {
      case 'Confirmed':
      case 'Picked':    return const Color(0xFFE8F5E9);
      case 'Pending':   return const Color(0xFFFFF9C4);
      case 'Cancelled':
      case 'Rejected':  return const Color(0xFFFDECEA);
      default:          return const Color(0xFFD7D8D7);
    }
  }

  Color _offerStatusColor(String status) {
    switch (status) {
      case 'Active':   return const Color(0xFF4CAF50);
      case 'Sold out': return const Color(0xFF717270);
      case 'Expired':  return const Color(0xFFFF3B3B);
      default:         return const Color(0xFF717270);
    }
  }

  Color _offerStatusBg(String status) {
    switch (status) {
      case 'Active':   return const Color(0xFFE8F5E9);
      case 'Sold out': return const Color(0xFFD7D8D7);
      case 'Expired':  return const Color(0xFFFDECEA);
      default:         return const Color(0xFFD7D8D7);
    }
  }

  Widget _errorWidget(String msg, VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF72A843)),
            onPressed: retry,
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ─── SUMMARY BOX ─────────────────────────────────────────────────────────────
class _SummaryBox extends StatelessWidget {
  final String number, label;
  final Color color, bgColor;
  const _SummaryBox(this.number, this.label, this.color, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(number, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            Text(label,  style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── ORDER CARD ──────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final String title, price, from, quantity, payment, created, extra, status;
  final Color statusColor, statusBg;
  final String? imageUrl;
  final String emoji;

  const _OrderCard({
    required this.title, required this.price, required this.from,
    required this.quantity, required this.payment, required this.created,
    required this.extra, required this.status,
    required this.statusColor, required this.statusBg,
    this.imageUrl, required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DottedBorder(
        color: const Color(0xFF0A0A0A), strokeWidth: 0.8,
        dashPattern: const [5, 5], borderType: BorderType.RRect,
        radius: const Radius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null
                    ? Image.network(imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _emojiBox())
                    : _emojiBox(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(
                      'Client: $from\nQty: $quantity  Payment: $payment\nCreated: $created  $extra',
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total: $price',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0A0A0A), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiBox() => Container(
    width: 50, height: 50,
    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
  );
}

// ─── OFFER CARD ──────────────────────────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  final String title, unitPrice, type, quantity, reservations, status;
  final String? created, expired, imageUrl;
  final Color statusColor, statusBg;
  final String emoji;

  const _OfferCard({
    required this.title, required this.unitPrice, required this.type,
    required this.quantity, required this.reservations,
    this.created, this.expired, required this.status,
    required this.statusColor, required this.statusBg,
    this.imageUrl, required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final StringBuffer meta = StringBuffer();
    meta.write('Type: $type\n');
    meta.write('Qty: $quantity  Reservations: $reservations\n');
    if (created != null && created!.isNotEmpty && expired != null && expired!.isNotEmpty) {
      meta.write('Created: $created  Expired: $expired');
    } else if (created != null && created!.isNotEmpty) {
      meta.write('Created: $created');
    } else if (expired != null && expired!.isNotEmpty) {
      meta.write('Expired: $expired');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DottedBorder(
        color: const Color(0xFF0A0A0A), strokeWidth: 0.8,
        dashPattern: const [5, 5], borderType: BorderType.RRect,
        radius: const Radius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null
                    ? Image.network(imageUrl!, width: 55, height: 55, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _emojiBox())
                    : _emojiBox(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(meta.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Unit: $unitPrice',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0A0A0A), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiBox() => Container(
    width: 55, height: 55,
    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
  );
}