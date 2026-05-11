import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'createadmin.dart';

const _kBaseUrl = 'https://headstand-rosy-chlorine.ngrok-free.dev';

// ─── API ──────────────────────────────────────────────────────────────────────

class _AdminApi {
  /// GET /api/admin/admins
  static Future<List<Map<String, dynamic>>> getAdmins(String token) async {
    final res = await http.get(
      Uri.parse('$_kBaseUrl/api/admin/admins'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    }
    throw Exception('Failed to load admins: ${res.statusCode}');
  }

  /// DELETE /api/admin/admins/{id}
  static Future<void> deleteAdmin(String token, int id) async {
    final res = await http.delete(
      Uri.parse('$_kBaseUrl/api/admin/admins/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Delete failed: ${res.statusCode}');
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Maps a raw backend admin object to the UI card map
Map<String, dynamic> _mapAdmin(Map<String, dynamic> raw) {
  final first = raw['firstName']?.toString() ?? '';
  final last  = raw['lastName']?.toString()  ?? '';
  final initials = (first.isNotEmpty && last.isNotEmpty)
      ? '${first[0]}${last[0]}'.toUpperCase()
      : (first.isNotEmpty ? first[0].toUpperCase() : '?');

  final role    = raw['role']?.toString() ?? 'ADMIN';
  final isSuper = role.toUpperCase().contains('SUPER');

  return {
    'id':       raw['id'],
    'initials': initials,
    'name':     '$first $last'.trim(),
    'email':    raw['email']?.toString() ?? '',
    'role':     isSuper ? 'Super Admin' : 'Admin',
    'isSuper':  isSuper,
  };
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class AdminManagementPage extends StatefulWidget {
  final String token;
  const AdminManagementPage({super.key, required this.token});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  List<Map<String, dynamic>> _admins = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await _AdminApi.getAdmins(widget.token);
      setState(() {
        _admins  = raw.map(_mapAdmin).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deleteAdmin(int id) async {
    try {
      await _AdminApi.deleteAdmin(widget.token, id);
      setState(() => _admins.removeWhere((a) => a['id'] == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin supprimé ✅'),
            backgroundColor: Color(0xFF72A843),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(Map<String, dynamic> admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet admin ?'),
        content: Text('${admin['name']} (${admin['email']}) sera supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final id = admin['id'];
              if (id != null) _deleteAdmin(id as int);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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
              const SizedBox(height: 30),

              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF72A843),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Admin Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF72A843),
                    ),
                  ),
                  const Spacer(),
                  // Refresh
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF72A843)),
                    onPressed: _loadAdmins,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Create Admin Button ──────────────────────────────────
              GestureDetector(
                onTap: () async {
                  final newAdmin = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreateAdminPage(token: widget.token),
                    ),
                  );
                  if (newAdmin != null) {
                    setState(() => _admins.add(newAdmin));
                  }
                },
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
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x6672A843),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Create Admin',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontFamily: 'inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF72A843)))
                    : _error != null
                        ? _ErrorView(
                            message: _error!, onRetry: _loadAdmins)
                        : _admins.isEmpty
                            ? _EmptyState()
                            : ListView.separated(
                                itemCount: _admins.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) {
                                  final a = _admins[i];
                                  return AdminCard(
                                    initials: a['initials'],
                                    name:     a['name'],
                                    email:    a['email'],
                                    role:     a['role'],
                                    isSuper:  a['isSuper'] ?? false,
                                    onDelete: () => _showDeleteDialog(a),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 72,
            color: const Color(0xFF72A843).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No admins yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF72A843),
              fontFamily: 'poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Create Admin" to add your first admin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontFamily: 'poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF72A843)),
          ),
        ],
      ),
    );
  }
}

// ─── Admin Card ───────────────────────────────────────────────────────────────

class AdminCard extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String role;
  final bool isSuper;
  final VoidCallback? onDelete;

  const AdminCard({
    super.key,
    required this.initials,
    required this.name,
    required this.email,
    required this.role,
    this.isSuper  = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF72A843),
            child: Text(
              initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(email,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0E6A5).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuper ? Icons.verified : Icons.person,
                        size: 14,
                        color: const Color(0xFF72A843),
                      ),
                      const SizedBox(width: 4),
                      Text(role,
                          style: const TextStyle(
                              color: Color(0xFF72A843), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Delete button — hidden for Super Admin to prevent accidental removal
          if (onDelete != null && !isSuper)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              tooltip: 'Supprimer',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
