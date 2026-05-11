import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'usersession.dart';

const _kBaseUrl = 'https://headstand-rosy-chlorine.ngrok-free.dev';

class AppColors {
  static const primary       = Color(0xFF72A843);
  static const primaryDark   = Color(0xFF5F8F36);
  static const primaryLight  = Color(0xFFA0CA09);
  static const background    = Color(0xFFFAFFF7);
  static const textPrimary   = Color(0xFF333333);
  static const textSecondary = Color(0xFF555555);
  static const border        = Color(0xFFDDDDDD);
  static const divider       = Color(0xFFF0F0F0);
}

class _AdminApi {
  static Future<Map<String, dynamic>> createAdmin({
  required String token,
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  required String role,
  String? permissions,
}) async {
  // ✅ FIX: envoyer comme QUERY PARAMS (comme Postman)
  final uri = Uri.parse('$_kBaseUrl/api/admin/admins/create').replace(
    queryParameters: {
      'firstName': firstName,
      'lastName':  lastName,
      'email':     email,
      'password':  password,
      'role':      role,
      if (permissions != null && permissions.isNotEmpty)
        'permissions': permissions,
    },
  );

  final res = await http.post(
    uri,
    headers: {
      'Authorization':              'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      // ✅ PAS de Content-Type ici — body est vide
    },
    // ✅ body vide — les params sont dans l'URL
  );

  if (res.statusCode == 200 || res.statusCode == 201) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  try {
    final err = jsonDecode(res.body);
    throw Exception(err['message'] ?? 'Erreur ${res.statusCode}');
  } catch (_) {
    throw Exception('Erreur serveur ${res.statusCode}');
  }
}
}

class CreateAdminPage extends StatefulWidget {
  final String? token;
  const CreateAdminPage({super.key, this.token});

  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  String _selectedRole = 'normal';
  bool   _loading      = false;
  bool   _obscurePass  = true;

  final Map<String, bool> _permissions = {
    'Users':    false,
    'Orders':   false,
    'Payments': false,
    'Stats':    false,
    'Settings': false,
    'Content':  false,
  };

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String get _token => widget.token ?? UserSession().token ?? '';

  String _initials() {
    final f = _firstNameCtrl.text.trim();
    final l = _lastNameCtrl.text.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    if (l.isEmpty) return f[0].toUpperCase();
    if (f.isEmpty) return l[0].toUpperCase();
    return '${f[0]}${l[0]}'.toUpperCase();
  }

  String? _buildPermissions() {
    if (_selectedRole == 'super') return null;
    final active = _permissions.entries
        .where((e) => e.value)
        .map((e) => e.key.toUpperCase())
        .join(',');
    return active.isEmpty ? null : active;
  }

  Future<void> _onCreate() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName  = _lastNameCtrl.text.trim();
    final email     = _emailCtrl.text.trim();
    final password  = _passwordCtrl.text.trim();

    if ([firstName, lastName, email, password].any((s) => s.isEmpty)) {
      _snack('Please fill in all fields.', Colors.redAccent);
      return;
    }

    setState(() => _loading = true);
    try {
      // ✅ "SUPER_ADMIN" ou "NORMAL_ADMIN" envoyé comme valeur de "role"
      final roleStr = _selectedRole == 'super' ? 'SUPER_ADMIN' : 'NORMAL_ADMIN';
      final permStr = _buildPermissions();

      final result = await _AdminApi.createAdmin(
        token:       _token,
        firstName:   firstName,
        lastName:    lastName,
        email:       email,
        password:    password,
        role:        roleStr,
        permissions: permStr,
      );

      final adminCard = {
        'initials':    _initials(),
        'name':        '${result['firstName'] ?? firstName} ${result['lastName'] ?? lastName}',
        'email':       result['email']   ?? email,
        'role':        _selectedRole == 'super' ? 'Super Admin' : 'Normal Admin',
        'isSuper':     _selectedRole == 'super',
        'id':          result['id'],
        'permissions': _selectedRole == 'super' ? null : Map<String, bool>.from(_permissions),
      };

      if (mounted) Navigator.pop(context, adminCard);

    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Admin',
            style: TextStyle(
                fontSize: 24,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar preview ──
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFD0E2C0),
                child: Text(_initials(),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Personal Information'),
            const SizedBox(height: 12),
            _field('First Name', _firstNameCtrl),
            const SizedBox(height: 12),
            _field('Last Name',  _lastNameCtrl),
            const SizedBox(height: 12),
            _field('Email',      _emailCtrl,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _passwordField(),

            const SizedBox(height: 24),
            _sectionLabel('Role'),
            const SizedBox(height: 12),
            _roleCard('super',  'Super Admin',   'Full access to all features'),
            const SizedBox(height: 10),
            _roleCard('normal', 'Normal Admin',  'Custom permissions'),

            if (_selectedRole == 'normal') ...[
              const SizedBox(height: 24),
              _sectionLabel('Permissions'),
              const SizedBox(height: 12),
              _permissionsList(),
            ],

            const SizedBox(height: 28),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _createButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.primary));

  Widget _field(String label, TextEditingController ctrl,
      {bool obscure = false,
       TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller:   ctrl,
          obscureText:  obscure,
          keyboardType: keyboardType,
          enabled:      !_loading,
          onChanged:    (_) => setState(() {}), // refresh initials
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled:      true,
            fillColor:   Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller:  _passwordCtrl,
          obscureText: _obscurePass,
          enabled:     !_loading,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled:    true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePass ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey),
              onPressed: () =>
                  setState(() => _obscurePass = !_obscurePass),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleCard(String value, String title, String subtitle) {
    final sel = _selectedRole == value;
    return GestureDetector(
      onTap: _loading ? null : () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? AppColors.primary : AppColors.border,
              width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          Radio<String>(
            value:      value,
            groupValue: _selectedRole,
            activeColor: AppColors.primary,
            onChanged: _loading
                ? null
                : (v) => setState(() => _selectedRole = v!),
          ),
          const SizedBox(width: 4),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _permissionsList() {
    final keys = _permissions.keys.toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: keys.map((key) {
          final isLast = key == keys.last;
          return Column(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(key,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  Checkbox(
                    value:       _permissions[key],
                    activeColor: AppColors.primary,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _permissions[key] = v!),
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(height: 1, color: AppColors.divider),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _createButton() {
    return Container(
      width: double.infinity,
      height: 56,
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
              offset: Offset(0, 4)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _onCreate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor:     Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon:  const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Create Admin',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   16,
                color:      Colors.white)),
      ),
    );
  }
}