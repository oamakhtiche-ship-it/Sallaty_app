import 'package:shared_preferences/shared_preferences.dart';

/// Singleton — holds the authenticated admin's session data in memory
/// and persists the JWT token to SharedPreferences so the user stays
/// logged in across app restarts.
class UserSession {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const _kToken     = 'admin_token';
  static const _kUserId    = 'admin_user_id';
  static const _kFirstName = 'admin_first_name';
  static const _kSurname   = 'admin_surname';
  static const _kRole      = 'admin_role';

  // ── In-memory state ────────────────────────────────────────────────────────
  String? _token;
  int?    _userId;
  String? _firstName;
  String? _surname;
  String? _role;          // e.g. "ADMIN" | "SUPER_ADMIN"
  String? _profileImage;
  String? _accountType;   // "ADMIN" side of accountType if needed

  // ── Getters ────────────────────────────────────────────────────────────────
  String? get token        => _token;
  int?    get userId       => _userId;
  String? get firstName    => _firstName;
  String? get surname      => _surname;
  String? get role         => _role;
  String? get profileImage => _profileImage;
  String? get accountType  => _accountType;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  String get displayName {
    final parts = [_firstName, _surname]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    return parts.isNotEmpty ? parts : 'Admin';
  }

  // ── Save session (called after successful login) ───────────────────────────
  Future<void> save({
    required String token,
    required int    userId,
    required String firstName,
    required String surname,
    required String role,
    String? profileImage,
    String? accountType,
  }) async {
    _token        = token;
    _userId       = userId;
    _firstName    = firstName;
    _surname      = surname;
    _role         = role;
    _profileImage = profileImage;
    _accountType  = accountType;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken,     token);
    await prefs.setInt   (_kUserId,    userId);
    await prefs.setString(_kFirstName, firstName);
    await prefs.setString(_kSurname,   surname);
    await prefs.setString(_kRole,      role);
  }

  /// Call this in main() before runApp() to restore a previously saved session.
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token     = prefs.getString(_kToken);
    _userId    = prefs.getInt   (_kUserId);
    _firstName = prefs.getString(_kFirstName);
    _surname   = prefs.getString(_kSurname);
    _role      = prefs.getString(_kRole);
  }

  /// Update in-memory profile image (no need to persist — re-fetched on login)
  void updateProfileImage(String? path) => _profileImage = path;

  // ── Clear session (logout) ─────────────────────────────────────────────────
  Future<void> clear() async {
    _token        = null;
    _userId       = null;
    _firstName    = null;
    _surname      = null;
    _role         = null;
    _profileImage = null;
    _accountType  = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kFirstName);
    await prefs.remove(_kSurname);
    await prefs.remove(_kRole);
  }
}