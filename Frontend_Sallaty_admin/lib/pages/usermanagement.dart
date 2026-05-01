import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'marchantprofile.dart';
import 'clientprofile.dart';

const kBaseUrl     = 'http://localhost:8080';
const kPrimary     = Color(0xFF72A843);
const kPrimaryDark = Color(0xFF02531E);
const kWhite       = Color(0xFFFFFFFF);
const kTextDark    = Color(0xFF2D2E2D);
const kTextGrey    = Color(0xFF717270);
const kBorderGrey  = Color(0xFFC3C4C3);

class UserApiService {
  static final _httpClient = http.Client();

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      };

  static Future<List<Map<String, dynamic>>> getUsers({
    String? filter,
    required String token,
  }) async {
    final queryParams = <String, String>{};
    if (filter != null && filter != 'All') {
      queryParams['filter'] = filter.toLowerCase();
    }

    final uri = Uri.parse('$kBaseUrl/api/admin/users')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final res = await _httpClient.get(uri, headers: _headers(token));
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');

    final data = jsonDecode(res.body);
    List<Map<String, dynamic>> users = [];
    if (data is List) {
      users = List<Map<String, dynamic>>.from(data);
    } else if (data is Map) {
      if (data['users'] != null) {
        users = List<Map<String, dynamic>>.from(data['users']);
      } else if (data['content'] != null) {
        users = List<Map<String, dynamic>>.from(data['content']);
      } else if (data['data'] != null) {
        users = List<Map<String, dynamic>>.from(data['data']);
      }
    }

    // Client-side safety filter
    if (filter != null && filter != 'All') {
      final filterLower = filter.toLowerCase();
      users = users.where((u) {
        final state = (u['status']?.toString() ??
                       u['accountState']?.toString() ??
                       u['account_state']?.toString() ??
                       'active')
            .toLowerCase();
        return state == filterLower;
      }).toList();
    }

    return users;
  }

  static Future<Map<String, dynamic>> getUserProfile(int id, String token) async {
    final res = await _httpClient.get(
      Uri.parse('$kBaseUrl/api/admin/users/$id'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Profil introuvable');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<void> blockUser(int userId, String token) async {
    final res = await _httpClient.put(
      Uri.parse('$kBaseUrl/api/users/block/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Block echoue');
  }

  static Future<void> unblockUser(int userId, String token) async {
    final res = await _httpClient.put(
      Uri.parse('$kBaseUrl/api/users/unblock/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Unblock echoue');
  }

  static Future<void> deleteUser(int userId, String token) async {
    final res = await _httpClient.delete(
      Uri.parse('$kBaseUrl/api/users/delete/$userId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Suppression echouee');
  }
}

class UserManagementPage extends StatefulWidget {
  final String token;
  const UserManagementPage({super.key, required this.token});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Blocked'];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  String _displayName(Map<String, dynamic> u) {
    final first = u['firstName']?.toString().trim() ?? u['first_name']?.toString().trim() ?? '';
    final last  = u['surname']?.toString().trim()   ?? u['lastName']?.toString().trim()  ?? '';
    final full  = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    final fallback = u['name']?.toString().trim() ?? u['fullName']?.toString().trim() ?? '';
    return fallback.isNotEmpty ? fallback : 'Unknown';
  }

  String _displayEmail(Map<String, dynamic> u) {
    return u['contact']?.toString() ?? u['email']?.toString() ?? u['mail']?.toString() ?? '';
  }

  String? _displayPhoto(Map<String, dynamic> u) {
    return u['profileImage']?.toString() ?? u['photo']?.toString() ?? u['photoUrl']?.toString();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      final name  = _displayName(u).toLowerCase();
      final email = _displayEmail(u).toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await UserApiService.getUsers(filter: _selectedFilter, token: widget.token);
      if (!mounted) return;
      setState(() { _users = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _block(Map<String, dynamic> u) async {
    final id = u['id'] as int? ?? u['userId'] as int? ?? 0;
    try {
      await UserApiService.blockUser(id, widget.token);
      if (!mounted) return;
      setState(() {
        u['status'] = 'Blocked';
        u['accountState'] = 'Blocked';
        if (_selectedFilter == 'Active') _users.remove(u);
      });
    } catch (e) { _showSnack('Erreur : $e', isError: true); }
  }

  Future<void> _unblock(Map<String, dynamic> u) async {
    final id = u['id'] as int? ?? u['userId'] as int? ?? 0;
    try {
      await UserApiService.unblockUser(id, widget.token);
      if (!mounted) return;
      setState(() {
        u['status'] = 'Active';
        u['accountState'] = 'Active';
        if (_selectedFilter == 'Blocked') _users.remove(u);
      });
    } catch (e) { _showSnack('Erreur : $e', isError: true); }
  }

  Future<void> _delete(Map<String, dynamic> u) async {
    final id = u['id'] as int? ?? u['userId'] as int? ?? 0;
    final confirm = await _confirmDialog('Supprimer cet utilisateur ?', 'Cette action est irreversible.');
    if (!confirm) return;
    try {
      await UserApiService.deleteUser(id, widget.token);
      if (!mounted) return;
      setState(() => _users.remove(u));
      _showSnack('Utilisateur supprime');
    } catch (e) { _showSnack('Erreur : $e', isError: true); }
  }

  Future<void> _openMerchantDetail(Map<String, dynamic> user) async {
    final userId = user['id'] as int? ?? user['userId'] as int? ?? 0;
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: kPrimary)));
    try {
      final full = await UserApiService.getUserProfile(userId, widget.token);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => MerchantDetailPage(
        merchant: _toMerchantDetailMap(full), token: widget.token,
        onStatusChanged: (s) => setState(() => user['status'] = s),
        onDeleted: () => setState(() => _users.remove(user)),
      )));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Erreur chargement profil: $e', isError: true);
    }
  }

  Future<void> _openClientDetail(Map<String, dynamic> user) async {
    final userId = user['id'] as int? ?? user['userId'] as int? ?? 0;
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: kPrimary)));
    try {
      final full = await UserApiService.getUserProfile(userId, widget.token);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailPage(
        client: _toClientDetailMap(full), token: widget.token, orders: const [],
        onStatusChanged: (s) => setState(() => user['status'] = s),
        onDeleted: () => setState(() => _users.remove(user)),
      )));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Erreur chargement profil: $e', isError: true);
    }
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '-';
    try {
      final d = DateTime.tryParse(v.toString());
      if (d != null) return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) {}
    return v.toString();
  }

  Map<String, dynamic> _toClientDetailMap(Map<String, dynamic> u) {
    final fn = u['firstName']?.toString() ?? u['first_name']?.toString() ?? '';
    final ln = u['surname']?.toString()   ?? u['lastName']?.toString()   ?? '';
    final ct = u['contact']?.toString()   ?? u['email']?.toString()      ?? '';
    final nm = '$fn $ln'.trim();
    return {
      'name': nm.isNotEmpty ? nm : (u['name'] ?? 'Unknown'),
      'email': ct, 'status': u['status'] ?? u['accountState'] ?? 'Active',
      'firstName': fn, 'lastName': ln,
      'id': u['id'] ?? u['userId'] ?? 0,
      'userId': '#${u['id'] ?? u['userId'] ?? '000000'}',
      'phone': ct,
      'inscriptionDate': _fmtDate(u['inscriptionDate'] ?? u['createdAt']),
      'lastConnexion': _fmtDate(u['lastConnexion'] ?? u['lastLogin']),
      'orders': u['nbOrder'] ?? u['orders'] ?? u['totalOrders'] ?? 0,
      'favorites': u['nbFavoris'] ?? u['favorites'] ?? u['totalFavoris'] ?? 0,
      'photo': u['profileImage'] ?? u['photo'] ?? u['photoUrl'],
    };
  }

  Map<String, dynamic> _toMerchantDetailMap(Map<String, dynamic> u) {
    final fn = u['firstName']?.toString() ?? u['first_name']?.toString() ?? '';
    final ln = u['surname']?.toString()   ?? u['lastName']?.toString()   ?? '';
    final ct = u['contact']?.toString()   ?? u['email']?.toString()      ?? '';
    final nm = '$fn $ln'.trim();
    return {
      'name': nm.isNotEmpty ? nm : (u['name'] ?? 'Unknown'),
      'email': ct, 'status': u['status'] ?? u['accountState'] ?? 'Active',
      'offers': u['nbOffer'] ?? u['offers'] ?? u['totalOffers'] ?? 0,
      'revenue': u['revenue'] ?? u['totalRevenue'] ?? 0,
      'orders': u['nbOrder'] ?? u['orders'] ?? u['totalOrders'] ?? 0,
      'favorites': u['nbFavoris'] ?? u['favorites'] ?? u['totalFavoris'] ?? 0,
      'firstName': fn, 'lastName': ln,
      'id': u['id'] ?? u['userId'] ?? 0,
      'userId': '#${u['id'] ?? u['userId'] ?? '000000'}',
      'phone': ct,
      'inscriptionDate': _fmtDate(u['inscriptionDate'] ?? u['createdAt']),
      'lastConnexion': _fmtDate(u['lastConnexion'] ?? u['lastLogin']),
      'storeName': u['storeName'] ?? u['shopName'] ?? '-',
      'businessType': u['businessType'] ?? u['typeOfActivity'] ?? '-',
      'address': u['address'] ?? u['wilaya'] ?? '-',
      'tradeRegisterUrl': u['tradeRegisterUrl'] ?? u['tradeRegister'] ?? '',
      'photo': u['profileImage'] ?? u['photo'] ?? u['photoUrl'],
    };
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFE42F27) : kPrimary,
    ));
  }

  Future<bool> _confirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title), content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              TextButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmer', style: TextStyle(color: Color(0xFFE42F27)))),
            ],
          ),
        ) ?? false;
  }

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
              // Header
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: kPrimary),
                ),
                const SizedBox(width: 10),
                const Text('User Management',
                    style: TextStyle(fontFamily: 'poppins', fontSize: 22,
                        fontWeight: FontWeight.w500, color: kPrimary)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh_rounded, color: kPrimary), onPressed: _loadUsers),
              ]),
              const SizedBox(height: 20),
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFB9D4A1).withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    icon: const Icon(Icons.search, color: kTextGrey),
                    hintText: 'Search users by name or email...',
                    hintStyle: const TextStyle(color: kTextGrey, fontSize: 13),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () { _searchController.clear(); setState(() {}); },
                            child: const Icon(Icons.close, color: kTextGrey, size: 18))
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Filter Buttons
              Row(
                children: _filters.map((f) {
                  final sel = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedFilter == f) return;
                        setState(() { _selectedFilter = f; _searchController.clear(); });
                        _loadUsers();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary : const Color(0xFFD7D8D7),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Text(f, style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? kWhite : const Color(0xFF2D2E2D))),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              if (!_loading && _error == null)
                Text(
                  '${_filtered.length} user${_filtered.length != 1 ? 's' : ''} found'
                  '${_selectedFilter != 'All' ? ' · $_selectedFilter' : ''}',
                  style: const TextStyle(fontSize: 12, color: kTextGrey),
                ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: kTextGrey, size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: kTextGrey)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadUsers,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Reessayer', style: TextStyle(color: kWhite))),
      ]));
    }
    if (_filtered.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline_rounded, color: kTextGrey.withValues(alpha: 0.5), size: 52),
        const SizedBox(height: 12),
        Text(_selectedFilter == 'All' ? 'No users found.' : 'No $_selectedFilter users found.',
            style: const TextStyle(color: kTextGrey, fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildUserCard(_filtered[i]),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final rawStatus  = user['status']?.toString() ?? user['accountState']?.toString() ?? 'Active';
    final isActive   = rawStatus.toLowerCase() == 'active';
    final role       = (user['role']?.toString() ?? user['accountType']?.toString() ?? '').toUpperCase();
    final isMerchant = role == 'MERCHANT' || role == 'MARCHANT' || role == 'MARCHAND' ||
                       role == 'SELLER'   || role == 'VENDOR';
    final displayName  = _displayName(user);
    final displayEmail = _displayEmail(user);
    final photoUrl     = _displayPhoto(user);

    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 3))]),
      child: Row(children: [
        CircleAvatar(radius: 24, backgroundColor: const Color(0xFFD0E2C0),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(isMerchant ? Icons.store_rounded : Icons.person_rounded,
                  color: kPrimary, size: 26)
              : null),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(displayName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
                overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            _badge(isMerchant ? 'Merchant' : 'Client',
                isMerchant ? const Color(0xFFD0E2C0) : const Color(0xFFD6EEFF),
                isMerchant ? const Color(0xFF007665) : const Color(0xFF2979FF)),
          ]),
          const SizedBox(height: 3),
          Text(displayEmail, style: const TextStyle(fontSize: 11, color: kTextGrey),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          _badge(isActive ? 'Active' : 'Blocked',
              isActive ? const Color(0xFFD0E2C0) : const Color(0xFFFFBEBE),
              isActive ? const Color(0xFF007665) : const Color(0xFFFF3B3B)),
        ])),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _actionButton(
              label: isActive ? 'Block' : 'Unblock',
              color: isActive ? const Color(0xFFE42F27) : kPrimary,
              textColor: kWhite,
              onTap: () => isActive ? _block(user) : _unblock(user)),
          const SizedBox(height: 6),
          _actionButton(label: 'Delete', color: const Color(0xFFC3C4C3),
              textColor: const Color(0xFF5E5E5E), onTap: () => _delete(user)),
        ]),
      ]),
    );

    return GestureDetector(
      onTap: () => isMerchant ? _openMerchantDetail(user) : _openClientDetail(user),
      child: card,
    );
  }

  Widget _badge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _actionButton({required String label, required Color color,
      required Color textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
      ),
    );
  }
}