import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'usersession.dart';

const _base      = 'http://localhost:8080';
const kPrimary   = Color(0xFF72A843);
const kTitleBlack = Color(0xFF0A0A0A);

Map<String, String> _headers() => {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer ${UserSession().token ?? ''}',
  'ngrok-skip-browser-warning': 'true',
};

class OffreItem {
  final int     id;
  final String  title;
  final String  categoryType;
  final double  price;
  final double? discountPrice;
  final int     quantity;
  final int     reservations;
  final String  status;
  final String  wilaya;
  final String? expireAt;
  final String? createdAt;
  final String? photoPath;

  OffreItem({
    required this.id,
    required this.title,
    required this.categoryType,
    required this.price,
    this.discountPrice,
    required this.quantity,
    required this.reservations,
    required this.status,
    required this.wilaya,
    this.expireAt,
    this.createdAt,
    this.photoPath,
  });

  factory OffreItem.fromJson(Map<String, dynamic> j) => OffreItem(
    id:            j['id']            ?? 0,
    title:         j['title']         ?? '',
    categoryType:  j['categoryType']  ?? '',
    price:         (j['price']        ?? 0).toDouble(),
    // ✅ FIX: discountPrice = null si absent OU si égal à 0
    discountPrice: (j['discountPrice'] != null && (j['discountPrice'] as num).toDouble() > 0)
        ? (j['discountPrice'] as num).toDouble()
        : null,
    quantity:      j['quantity']      ?? 0,
    reservations:  j['reservations']  ?? 0,
    status:        j['status']        ?? 'INACTIVE',
    wilaya:        j['wilaya']        ?? '',
    expireAt:      j['expireAt'],
    createdAt:     j['createdAt'],
    photoPath:     j['photoPath'],
  );

 // ─── Model ───────────────────────────────────────────────────────────────────

String get displayStatus {
  final role = UserSession().role?.toUpperCase() ?? '';
  
  switch (status.toUpperCase()) {
    case 'ACTIVE':   return 'Active';
    case 'SOLD_OUT': return 'Sold out';
    case 'EXPIRED':  return 'Expired';
    case 'ARCHIVED': return 'Archived';
    case 'INACTIVE':
      // ✅ FIX PRINCIPAL: INACTIVE = Blocked pour l'admin
      // car blockOffre() met INACTIVE dans la DB
      if (role == 'ADMIN') return 'Blocked';
      return 'Inactive'; // pour le marchand
    default: return status;
  }
}
}

class OfferManagementPage extends StatefulWidget {
  const OfferManagementPage({super.key});
  @override
  State<OfferManagementPage> createState() => _OfferManagementPageState();
}

class _OfferManagementPageState extends State<OfferManagementPage> {
  String  _selectedFilter = 'All';
  bool    _loading        = true;
  String? _error;
  List<OffreItem> _offers = [];
  final TextEditingController _searchController = TextEditingController();

  // ✅ FIX: Filtres dynamiques selon le rôle
  List<String> get _filters {
    final isAdmin = UserSession().role?.toUpperCase() == 'ADMIN';
    if (isAdmin) {
      // Admin: PAS d'Inactive, mais a Blocked
      return ['All', 'Active', 'Sold out', 'Expired', 'Archived', 'Blocked'];
    }
    // Marchand: PAS de Blocked
    return ['All', 'Active', 'Sold out', 'Expired', 'Archived'];
  }

  List<OffreItem> get _filtered => _offers.where((o) {
    // ✅ FIX: côté Admin, on masque les offres INACTIVE du filtre "All"
    final isAdmin = UserSession().role?.toUpperCase() == 'ADMIN';
    if (isAdmin && o.displayStatus == 'Inactive' && _selectedFilter == 'All') {
      return false;
    }
    final matchFilter = _selectedFilter == 'All' || o.displayStatus == _selectedFilter;
    final q = _searchController.text.toLowerCase();
    return o.title.toLowerCase().contains(q) && matchFilter;
  }).toList();

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOffers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = UserSession();
      final role = session.role?.toUpperCase() ?? '';
      Uri uri;
      if (role == 'ADMIN') {
        uri = Uri.parse('$_base/api/offres/all');
      } else {
        final marchandId = session.userId;
        if (marchandId == null) throw Exception('User ID not found');
        uri = Uri.parse('$_base/api/offres/marchand/$marchandId');
      }
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _offers  = data.map((j) => OffreItem.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Erreur ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _archiveOffer(OffreItem offer) async {
    if (!await _confirm('Archive Offer',
        'Archive "${offer.title}"? It will no longer be visible to clients.')) return;
    try {
      final res = await http.put(
          Uri.parse('$_base/api/offres/archive/${offer.id}'), headers: _headers());
      _showSnack(res.statusCode == 200 ? 'Offer archived ✅' : 'Error ${res.statusCode}');
      if (res.statusCode == 200) _fetchOffers();
    } catch (_) { _showSnack('Network error'); }
  }

  // ✅ FIX: Un seul bouton BLOCK/UNBLOCK qui toggle
  Future<void> _toggleBlockOffer(OffreItem offer) async {
    final isBlocked = offer.displayStatus == 'Blocked';
    if (!await _confirm(
      isBlocked ? 'Unblock Offer' : 'Block Offer',
      isBlocked
          ? 'Unblock "${offer.title}"? It will become visible again.'
          : 'Block "${offer.title}"? This will hide it from all users.',
    )) return;

    try {
      final uri = isBlocked
          ? Uri.parse('$_base/api/offres/unblock/${offer.id}')
          : Uri.parse('$_base/api/offres/block/${offer.id}');
      final res = await http.put(uri, headers: _headers());
      _showSnack(res.statusCode == 200
          ? (isBlocked ? 'Offer unblocked ✅' : 'Offer blocked ❌')
          : 'Error ${res.statusCode}');
      if (res.statusCode == 200) _fetchOffers();
    } catch (_) { _showSnack('Network error'); }
  }

  Future<void> _deleteOffer(OffreItem offer) async {
    if (!await _confirm('Delete Offer Permanently',
        '⚠️ PERMANENTLY DELETE "${offer.title}"? This cannot be undone!')) return;
    try {
      final res = await http.delete(
          Uri.parse('$_base/api/offres/${offer.id}'), headers: _headers());
      _showSnack(res.statusCode == 200 ? 'Offer deleted 🗑️' : 'Error ${res.statusCode}');
      if (res.statusCode == 200) _fetchOffers();
    } catch (_) { _showSnack('Network error'); }
  }

  Future<void> _applyDiscount(OffreItem offer) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apply Discount'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'New price (DA)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final price = double.tryParse(ctrl.text);
    if (price == null) { _showSnack('Invalid price'); return; }
    try {
      final res = await http.put(
          Uri.parse('$_base/api/offres/discount/${offer.id}?discountPrice=$price'),
          headers: _headers());
      _showSnack(res.statusCode == 200 ? 'Discount applied ✅' : 'Error ${res.statusCode}');
      if (res.statusCode == 200) _fetchOffers();
    } catch (_) { _showSnack('Network error'); }
  }

  Future<bool> _confirm(String title, String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ??
      false;

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

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
                    isAdmin ? 'Admin - Offer Management' : 'Offer Management',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w400, color: kPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.refresh, color: kPrimary),
                      onPressed: _fetchOffers),
                ],
              ),
              const SizedBox(height: 14),

              // Search
              PhysicalModel(
                color: const Color(0xFFD0E2C0),
                borderRadius: BorderRadius.circular(10),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD0E2C0),
                      borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style:
                        const TextStyle(color: Color(0xFF878986), fontSize: 13),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Color(0xFF878986), size: 20),
                      hintText: 'Search offer name',
                      hintStyle:
                          TextStyle(color: Color(0xFF878986), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filters
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
                          shadowColor: Colors.black.withOpacity(0.20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: sel ? kPrimary : const Color(0xFFD7D8D7),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : const Color(0xFF2D2E2D))),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    if (_error != null)
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchOffers,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ]),
      );
    if (_filtered.isEmpty)
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _offers.isEmpty ? 'No offers yet' : 'No offers match this filter',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ]),
      );

    return ListView.separated(
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _buildOfferCard(_filtered[i]),
    );
  }

  Widget _buildOfferCard(OffreItem offer) {
    final status    = offer.displayStatus;
    final isAdmin   = UserSession().role?.toUpperCase() == 'ADMIN';
    final isMarchand = UserSession().role?.toUpperCase() == 'MARCHANT';
    final isBlocked = status == 'Blocked';
    final isArchived = status == 'Archived';

    return Material(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.20),
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: DottedBorder(
        color: isBlocked ? Colors.red : const Color(0xFF0A0A0A),
        strokeWidth: isBlocked ? 2 : 1.4,
        dashPattern: const [5, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isBlocked ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8)),
                child: offer.photoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network('$_base/${offer.photoPath}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, color: kPrimary, size: 32)),
                      )
                    : const Icon(Icons.fastfood, color: kPrimary, size: 32),
              ),
              const SizedBox(width: 8),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kTitleBlack)),
                    const SizedBox(height: 2),
                    Text('Type : ${offer.categoryType}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('Wilaya : ${offer.wilaya}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('Qty : ${offer.quantity}   Reservations: ${offer.reservations}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    if (offer.createdAt != null)
                      Text(
                        'Created: ${_fmt(offer.createdAt!)}'
                        '${offer.expireAt != null ? '   Expires: ${_fmt(offer.expireAt!)}' : ''}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    // ✅ FIX: Affiche le discount seulement si > 0
                    if (offer.discountPrice != null && offer.discountPrice! > 0)
                      Text(
                        'Discount: ${offer.discountPrice!.toStringAsFixed(0)} DA',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Unit: ${offer.price.toStringAsFixed(0)} DA',
                      style: const TextStyle(
                          fontSize: 10,
                          color: kTitleBlack,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  // ✅ FIX: Pour admin, si INACTIVE → afficher badge neutre sans boutons inutiles
                  _statusBadge(status),
                  const SizedBox(height: 4),

                  // Marchand actions
                  if (isMarchand && !isArchived && !isBlocked) ...[
                    _actionBtn(
                      label: 'ARCHIVE',
                      bg: const Color(0xFFC3C4C3),
                      fg: const Color(0xFF5A5B59),
                      onTap: () => _archiveOffer(offer),
                    ),
                    const SizedBox(height: 4),
                    _actionBtn(
                      label: 'DISCOUNT',
                      bg: const Color(0xFFFFE082),
                      fg: const Color(0xFF795548),
                      onTap: () => _applyDiscount(offer),
                    ),
                  ],

                  // ✅ Admin actions: BLOCK/UNBLOCK toggle + DELETE
                  if (isAdmin) ...[
                    _actionBtn(
                      label: isBlocked ? 'UNBLOCK' : 'BLOCK',
                      bg: isBlocked ? Colors.green.shade100 : Colors.red.shade100,
                      fg: isBlocked ? Colors.green.shade700 : Colors.red.shade700,
                      onTap: () => _toggleBlockOffer(offer),
                    ),
                    const SizedBox(height: 4),
                    _actionBtn(
                      label: 'DELETE',
                      bg: Colors.grey.shade300,
                      fg: Colors.black87,
                      onTap: () => _deleteOffer(offer),
                    ),
                  ],
                ],
              ),
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
    } catch (_) { return raw; }
  }

  Widget _statusBadge(String status) {
    Color bg, fg;
    switch (status) {
      case 'Active':   bg = const Color(0xFF72A843); fg = Colors.white; break;
      case 'Sold out': bg = const Color(0xFFD7D8D7); fg = const Color(0xFF2D2E2D); break;
      case 'Expired':  bg = const Color(0xFFFFBEBE); fg = const Color(0xFFFF3B3B); break;
      case 'Archived': bg = const Color(0xFFE0E0E0); fg = const Color(0xFF757575); break;
      case 'Blocked':  bg = Colors.red.shade100;     fg = Colors.red.shade700; break;
      // ✅ FIX: INACTIVE → badge gris discret
      case 'Inactive': bg = const Color(0xFFEEEEEE); fg = const Color(0xFF9E9E9E); break;
      default:         bg = const Color(0xFFD7D8D7); fg = const Color(0xFF2D2E2D);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _actionBtn({
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
        ),
      );
}