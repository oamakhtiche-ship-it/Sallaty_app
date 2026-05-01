import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'marchantprofile.dart';
import 'usersession.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const kBaseUrl     = 'http://localhost:8080';
const kPrimary     = Color(0xFF72A843);
const kPrimaryDark = Color(0xFF02531E);
const kWhite       = Color(0xFFFFFFFF);
const kTextDark    = Color(0xFF2D2E2D);
const kTextGrey    = Color(0xFF717270);
const kBorderGrey  = Color(0xFFC3C4C3);

// ─────────────────────────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────────────────────────


class MerchandApiService {
  static final _client = http.Client();

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// GET /api/admin/merchants
  /// Récupère TOUS les marchands sans filtre backend
  /// Le filtrage se fait côté Flutter (local)
  static Future<List<Map<String, dynamic>>> getMerchants({
    required String token,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/admin/merchants');

    final res = await _client.get(uri, headers: _headers(token));
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');

    final data = jsonDecode(res.body);
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data['merchants'] != null)
      return List<Map<String, dynamic>>.from(data['merchants']);
    return [];
  }

  /// GET /api/admin/merchants/{id} — Profil complet user + marchand
  static Future<Map<String, dynamic>> getMerchantProfile(
      int id, String token) async {
    final res = await _client.get(
      Uri.parse('$kBaseUrl/api/admin/merchants/$id'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Profil introuvable');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  /// PUT /api/marchand/verify/{userId}
  static Future<void> verifyMarchand(int userId, String token) async {
    final res = await _client.put(
      Uri.parse('$kBaseUrl/api/marchand/verify/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Vérification échouée');
  }

  /// PUT /api/marchand/cancel/{userId}
  static Future<void> cancelMarchand(int userId, String token) async {
    final res = await _client.put(
      Uri.parse('$kBaseUrl/api/marchand/cancel/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Annulation échouée');
  }

  /// PUT /api/marchand/reactivate/{userId}
  static Future<void> reactivateMarchand(int userId, String token) async {
    final res = await _client.put(
      Uri.parse('$kBaseUrl/api/marchand/reactivate/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Réactivation échouée');
  }

  /// PUT /api/users/block/{userId}
  static Future<void> blockUser(int userId, String token) async {
    final res = await _client.put(
      Uri.parse('$kBaseUrl/api/users/block/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Block échoué');
  }

  /// PUT /api/users/unblock/{userId}
  static Future<void> unblockUser(int userId, String token) async {
    final res = await _client.put(
      Uri.parse('$kBaseUrl/api/users/unblock/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Unblock échoué');
  }

  /// DELETE /api/users/delete/{userId}
  static Future<void> deleteUser(int userId, String token) async {
    final res = await _client.delete(
      Uri.parse('$kBaseUrl/api/users/delete/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Suppression échouée');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────────────────────
class MerchantManagementPage extends StatefulWidget {
  final String? token;
  const MerchantManagementPage({super.key, this.token});

  @override
  State<MerchantManagementPage> createState() =>
      _MerchantManagementPageState();
}

class _MerchantManagementPageState extends State<MerchantManagementPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Pending', 'Blocked'];
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _merchants = [];
  bool _loading = true;
  String? _error;

  String get _token => widget.token ?? UserSession().token ?? '';

  // ── Computed ───────────────────────────────────────────────────────────────
    // ── Computed ───────────────────────────────────────────────────────────────
  

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────
    Future<void> _loadMerchants() async {
    setState(() { _loading = true; _error = null; _merchants = []; });
    try {
      // ✅ Récupère TOUS les marchands sans filtre backend
      final list = await MerchandApiService.getMerchants(token: _token);
      setState(() { 
        _merchants = list.map(_normalizeMerchant).toList(); 
        _loading = false; 
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; _merchants = []; });
    }
  }

    List<Map<String, dynamic>> get _filtered {
    // 1. Filtre par statut (local)
    var result = _merchants.where((m) {
      if (_selectedFilter == 'All') return true;
      return m['status'] == _selectedFilter;
    }).toList();

    // 2. Filtre par recherche
    final q = _searchController.text.toLowerCase().trim();
    if (q.isNotEmpty) {
      result = result.where((m) {
        final name  = (m['name'] ?? '').toString().toLowerCase();
        final email = (m['email'] ?? '').toString().toLowerCase();
        final shop  = (m['storeName'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || shop.contains(q);
      }).toList();
    }
    return result;
  }

  /// Normalise les données du backend pour l'affichage
  /// Le backend retourne: status = PENDING / VERIFIED / CANCELLED
  /// Le frontend attend:  status = Pending / Active / Blocked
    Map<String, dynamic> _normalizeMerchant(Map<String, dynamic> raw) {
    final backendStatus = (raw['status'] ?? '').toString().toUpperCase();
    String displayStatus;
    switch (backendStatus) {
      case 'VERIFIED':  displayStatus = 'Active'; break;
      case 'PENDING':   displayStatus = 'Pending'; break;
      case 'CANCELLED': displayStatus = 'Blocked'; break;
      default:          displayStatus = 'Pending';
    }

    return {
      ...raw,
      'id': raw['userId'] ?? raw['id'] ?? 0,
      'name': raw['fullName'] ?? raw['name'] ?? 'Unknown',
      'email': raw['email'] ?? raw['contact'] ?? '',
      'status': displayStatus,
      'offers': raw['nbOffer'] ?? raw['totalOffers'] ?? 0,
      'revenue': raw['revenue'] ?? raw['totalRevenue'] ?? 0,
      'photo': raw['profileImage'] ?? raw['photo'] ?? raw['photoUrl'],
      'storeName': raw['shopName'] ?? '-',
      'businessType': raw['typeOfActivity'] ?? '-',
      'address': raw['wilaya'] ?? '-',
    };
  }
  

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _verify(Map<String, dynamic> m) async {
    final id = m['id'] as int? ?? 0;
    try {
      await MerchandApiService.verifyMarchand(id, _token);
      setState(() => m['status'] = 'Active');
      _showSnack('Marchand vérifié ✅');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  Future<void> _cancel(Map<String, dynamic> m) async {
    final id = m['id'] as int? ?? 0;
    try {
      await MerchandApiService.cancelMarchand(id, _token);
      setState(() => m['status'] = 'Blocked');
      _showSnack('Marchand annulé ❌');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  Future<void> _reactivate(Map<String, dynamic> m) async {
    final id = m['id'] as int? ?? 0;
    try {
      await MerchandApiService.reactivateMarchand(id, _token);
      setState(() => m['status'] = 'Active');
      _showSnack('Marchand réactivé 🔄');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  Future<void> _block(Map<String, dynamic> m) async {
    final id = m['id'] as int? ?? 0;
    try {
      await MerchandApiService.blockUser(id, _token);
      setState(() => m['status'] = 'Blocked');
      _showSnack('Marchand bloqué ❌');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  Future<void> _unblock(Map<String, dynamic> m) async {
    final id = m['id'] as int? ?? 0;
    try {
      await MerchandApiService.unblockUser(id, _token);
      setState(() => m['status'] = 'Active');
      _showSnack('Marchand débloqué ✅');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> m) async {
    final id = m['id'] as int? ?? 0;
    final confirm = await _confirmDialog(
        'Supprimer ce marchand ?', 'Cette action est irréversible.');
    if (!confirm) return;
    try {
      await MerchandApiService.deleteUser(id, _token);
      setState(() => _merchants.remove(m));
      _showSnack('Marchand supprimé ✅');
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _openMerchantDetail(Map<String, dynamic> merchant) async {
    final userId = merchant['id'] as int? ?? 0;
    
    // Charge le profil complet depuis le backend
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: kPrimary)),
    );

    try {
      final fullProfile = await MerchandApiService.getMerchantProfile(userId, _token);
      if (!mounted) return;
      Navigator.pop(context); // Ferme le loader

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MerchantDetailPage(
            merchant: _toDetailMap(fullProfile),
            onStatusChanged: (newStatus) {
              setState(() => merchant['status'] = newStatus);
            },
            onDeleted: () {
              setState(() => _merchants.remove(merchant));
            },
            token: _token,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Erreur chargement profil: $e', isError: true);
    }
  }

  Map<String, dynamic> _toDetailMap(Map<String, dynamic> raw) {
    final fn = raw['firstName']?.toString() ?? '';
    final ln = raw['surname']?.toString() ?? raw['lastName']?.toString() ?? '';
    final nm = '$fn $ln'.trim();
    
    // Détermine le statut d'affichage
    final backendStatus = (raw['marchandStatus'] ?? raw['status'] ?? '').toString().toUpperCase();
    String displayStatus;
    switch (backendStatus) {
      case 'VERIFIED':  displayStatus = 'Active'; break;
      case 'PENDING':   displayStatus = 'Pending'; break;
      case 'CANCELLED': displayStatus = 'Blocked'; break;
      default:          displayStatus = raw['accountState']?.toString() ?? 'Active';
    }

    return {
      'name': nm.isNotEmpty ? nm : (raw['fullName'] ?? raw['name'] ?? 'Unknown'),
      'email': raw['contact'] ?? raw['email'] ?? '',
      'status': displayStatus,
      'offers': raw['nbOffer'] ?? raw['totalOffers'] ?? 0,
      'revenue': raw['revenue'] ?? raw['totalRevenue'] ?? 0,
      'orders': raw['nbOrder'] ?? raw['totalOrders'] ?? 0,
      'favorites': raw['nbFavoris'] ?? raw['totalFavoris'] ?? 0,
      'firstName': fn,
      'lastName': ln,
      'id': raw['id'] ?? raw['userId'] ?? 0,
      'userId': '#${raw['id'] ?? raw['userId'] ?? '000000'}',
      'phone': raw['phoneNumber'] ?? raw['contact'] ?? '-',
      'inscriptionDate': _fmtDate(raw['createdAt'] ?? raw['dateTime']),
      'lastConnexion': _fmtDate(raw['lastConnection'] ?? raw['lastLogin']),
      'storeName': raw['shopName'] ?? raw['businessName'] ?? '-',
      'businessType': raw['typeOfActivity'] ?? raw['businessType'] ?? '-',
      'address': raw['wilaya'] ?? raw['address'] ?? '-',
      'tradeRegisterUrl': raw['tradeRegister'] ?? raw['tradeRegisterUrl'] ?? '',
      'photo': raw['profileImage'] ?? raw['photo'] ?? raw['photoUrl'],
    };
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '-';
    try {
      final d = DateTime.tryParse(raw.toString());
      if (d != null) return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) {}
    return raw.toString();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFE42F27) : kPrimary,
    ));
  }

  Future<bool> _confirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmer',
                      style: TextStyle(color: Color(0xFFE42F27)))),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Header ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: kPrimary),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Merchant Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w400,
                      color: kPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: kPrimary),
                    onPressed: _loadMerchants,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Search Bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFB9D4A1).withOpacity(0.40),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: kTextGrey),
                    hintText: 'Search merchants by name or email...',
                    hintStyle: TextStyle(color: kTextGrey, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Filter Buttons ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final isSelected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedFilter = f);
                          _loadMerchants();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kPrimary
                                : const Color(0xFFD7D8D7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? kPrimary
                                  : const Color(0xFFD7D8D7),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? kWhite
                                  : const Color(0xFF2D2E2D),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Result count ──
              if (!_loading && _error == null)
                Text(
                  '${_filtered.length} merchant${_filtered.length != 1 ? 's' : ''} found',
                  style: const TextStyle(fontSize: 12, color: kTextGrey),
                ),
              const SizedBox(height: 8),

              // ── Body ──
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: kTextGrey, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kTextGrey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMerchants,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              child: const Text('Réessayer',
                  style: TextStyle(color: kWhite)),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return const Center(
          child: Text('No merchants found.',
              style: TextStyle(color: kTextGrey)));
    }
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadMerchants,
      child: ListView.separated(
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildMerchantCard(_filtered[index]),
      ),
    );
  }

  // ── Card ───────────────────────────────────────────────────────────────────
  Widget _buildMerchantCard(Map<String, dynamic> merchant) {
    final status    = merchant['status'] as String;
    final isActive  = status == 'Active';
    final isBlocked = status == 'Blocked';
    final isPending = status == 'Pending';

    final offers  = merchant['offers'] ?? 0;
    final revenue = merchant['revenue'] ?? 0;

    return GestureDetector(
      onTap: () => _openMerchantDetail(merchant),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFD0E2C0),
              backgroundImage: merchant['photo'] != null && merchant['photo'].toString().isNotEmpty
                  ? NetworkImage(merchant['photo'])
                  : null,
              child: merchant['photo'] == null || merchant['photo'].toString().isEmpty
                  ? const Icon(Icons.store_rounded, color: kPrimary, size: 26)
                  : null,
            ),
            const SizedBox(width: 12),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          merchant['name'] ?? '—',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kTextDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _badge('Merchant', const Color(0xFFD0E2C0),
                          const Color(0xFF007665)),
                      const SizedBox(width: 6),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    merchant['email'] ?? '',
                    style: const TextStyle(fontSize: 11, color: kTextGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Offers : $offers     Revenue : $revenue DA',
                    style: const TextStyle(fontSize: 11, color: kTextGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ── Action Buttons ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isPending) ...[
                  _actionButton(
                    label: 'Verify',
                    color: kPrimary,
                    textColor: kWhite,
                    onTap: () => _verify(merchant),
                  ),
                  const SizedBox(height: 6),
                  _actionButton(
                    label: 'Cancel',
                    color: const Color(0xFFE42F27),
                    textColor: kWhite,
                    onTap: () => _cancel(merchant),
                  ),
                ],
                if (isActive)
                  _actionButton(
                    label: 'Block',
                    color: const Color(0xFFE42F27),
                    textColor: kWhite,
                    onTap: () => _block(merchant),
                  ),
                if (isBlocked) ...[
                  _actionButton(
                    label: 'Unblock',
                    color: kPrimary,
                    textColor: kWhite,
                    onTap: () => _unblock(merchant),
                  ),
                  const SizedBox(height: 6),
                  _actionButton(
                    label: 'Reactivate',
                    color: const Color(0xFF4CAF50),
                    textColor: kWhite,
                    onTap: () => _reactivate(merchant),
                  ),
                ],
                const SizedBox(height: 6),
                _actionButton(
                  label: 'Delete',
                  color: const Color(0xFFC3C4C3),
                  textColor: const Color(0xFF5E5E5E),
                  onTap: () => _delete(merchant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────
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
    Color bg, textColor;
    switch (status) {
      case 'Active':
        bg = const Color(0xFFD0E2C0);
        textColor = const Color(0xFF007665);
        break;
      case 'Blocked':
        bg = const Color(0xFFFFBEBE);
        textColor = const Color(0xFFFF3B3B);
        break;
      default: // Pending
        bg = const Color(0xFFFFF9C4);
        textColor = const Color(0xFFF57F17);
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

  Widget _actionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor)),
      ),
    );
  }
}