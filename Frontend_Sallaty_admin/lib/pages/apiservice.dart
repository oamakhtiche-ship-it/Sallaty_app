import 'dart:convert';
import 'package:http/http.dart' as http;
import 'usersession.dart';

// ─── Base URL ─────────────────────────────────────────────────────────────────
const _kBaseUrl = 'http://localhost:8080';

// ─── Login Result ─────────────────────────────────────────────────────────────
class LoginResult {
  final bool    success;
  final String? errorMessage;

  const LoginResult._({required this.success, this.errorMessage});

  factory LoginResult.ok()           => const LoginResult._(success: true);
  factory LoginResult.fail(String m) => LoginResult._(success: false, errorMessage: m);
}

// ─── ApiService ───────────────────────────────────────────────────────────────
class ApiService {
  ApiService._(); // static only

  static final _httpClient = http.Client();

  static Map<String, String> get _baseHeaders => {
    'Content-Type'               : 'application/json',
    'ngrok-skip-browser-warning' : 'true',
  };

  static Map<String, String> _authHeaders(String token) => {
    ..._baseHeaders,
    'Authorization': 'Bearer $token',
  };

  // ══════════════════════════════════════════════════════════════════════════
  //  POST /api/auth/login
  // ══════════════════════════════════════════════════════════════════════════
  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginRes = await http.post(
        Uri.parse('$_kBaseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'ngrok-skip-browser-warning': 'true',
        },
        body: {'contact': email, 'password': password},
      );

      if (loginRes.statusCode != 200) {
        try {
          final err = jsonDecode(loginRes.body);
          final msg = err['message'] ?? err['error'] ?? 'Login failed';
          return LoginResult.fail(msg.toString());
        } catch (_) {
          return LoginResult.fail(
              'Server error (${loginRes.statusCode}). Please try again.');
        }
      }

      final loginData = jsonDecode(loginRes.body) as Map<String, dynamic>;

      final token = loginData['token']?.toString() ?? '';
      if (token.isEmpty) {
        return LoginResult.fail('No token received from server.');
      }

      final userId      = (loginData['id'] as num?)?.toInt() ?? 0;
      final firstName   = loginData['name']?.toString() ??
                          loginData['firstName']?.toString() ?? '';
      final surname     = loginData['surname']?.toString() ?? '';
      final profileImage = loginData['photoUrl']?.toString() ?? '';

      // ── Guard: only ADMIN may enter ────────────────────────────────────
      final userRole = loginData['role']?.toString().toUpperCase() ?? '';
      final isAdmin  = email.toLowerCase().contains('admin') ||
                       userRole.contains('ADMIN');

      if (!isAdmin) {
        return LoginResult.fail('Access denied. This app is for admins only.');
      }

      // ── Persist session ────────────────────────────────────────────────
      await UserSession().save(
        token:        token,
        userId:       userId,
        firstName:    firstName,
        surname:      surname,
        role:         'ADMIN',
        profileImage: profileImage,
        accountType:  'ADMIN',
      );

      return LoginResult.ok();
    } catch (e) {
      return LoginResult.fail('Network error. Please check your connection.');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GET /api/admin/users/{id}
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getUserProfile(
      int id, String token) async {
    final res = await _httpClient.get(
      Uri.parse('$_kBaseUrl/api/admin/users/$id'),
      headers: _authHeaders(token),
    );
    if (res.statusCode != 200) throw Exception('Profil introuvable');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GET /api/users/me
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>?> getMe() async {
    final token = UserSession().token;
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_kBaseUrl/api/users/me'),
        headers: _authHeaders(token),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  POST /api/users/logout
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> logout() async {
    final token = UserSession().token;
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$_kBaseUrl/api/users/logout'),
          headers: _authHeaders(token),
        );
      } catch (_) {}
    }
    await UserSession().clear();
  }
  


  
}