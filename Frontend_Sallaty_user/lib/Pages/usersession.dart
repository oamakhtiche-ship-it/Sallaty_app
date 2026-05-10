import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // ── Raw fields ─────────────────────────────────────────────────
  String? id;
  String? token;
  String? name;
  String? lastName;
  String? surname;
  String? email;
  String? phone;
  String? photoUrl;
  String? wilaya;
  String? businessName;
  String? businessType;
  bool    isMerchant = false;

  // ── Computed getters ───────────────────────────────────────────
  String get fullName {
    final parts = [name, surname ?? lastName]
        .where((p) => p != null && p.isNotEmpty);
    return parts.join(' ');
  }

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (email != null && email!.isNotEmpty) return email!;
    return 'User';
  }

  bool get hasPhoto   => photoUrl != null && photoUrl!.isNotEmpty;
  bool get isLoggedIn => token    != null && token!.isNotEmpty;
  int  get intId      => int.tryParse(id ?? '') ?? 0;

  // ── Normalise photo URL (relative → absolute) ──────────────────
  static String _normaliseUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final s = raw.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    // Relative path — prepend base URL
    const base = 'https://headstand-rosy-chlorine.ngrok-free.dev';
    return '$base${s.startsWith('/') ? s : '/$s'}';
  }

  // ── Hydrate from API JSON response ─────────────────────────────
  Future<void> hydrateFromJson(Map<String, dynamic> json) async {
    print('=== hydrateFromJson called ===');

    token = json['token']?.toString()
         ?? json['accessToken']?.toString();

    final dynamic userRaw = json['user'];
    final Map<String, dynamic> user =
        userRaw is Map<String, dynamic> ? userRaw : json;

    final rawId = user['id'] ?? json['id'] ?? json['userId'];
    id = rawId?.toString();

    name    = _clean(user['name']        ?? user['firstName']);
    surname = _clean(user['surname']     ?? user['lastName']);
    lastName = surname;

    email = _clean(
      user['email']   ??
      user['contact'] ??
      json['email']   ??
      json['contact'],
    );

    phone = _clean(
      user['phone']       ??
      user['phoneNumber'] ??
      json['phone'],
    );

    // ✅ Always normalise photo URL on load
    final rawPhoto =
        user['profileImage'] ??
        user['photoUrl']     ??
        json['profileImage'] ??
        json['photoUrl'];
    photoUrl = _normaliseUrl(rawPhoto?.toString());

    wilaya = _clean(user['wilaya'] ?? json['wilaya']);

    businessName = _clean(
      user['businessName'] ??
      user['shopName']     ??
      json['businessName'] ??
      json['shopName'],
    );

    businessType = _clean(
      user['businessType'] ??
      user['category']     ??
      json['businessType'] ??
      json['category'],
    );

    // Supports bool and String "true"/"false"
    final rawMerchant = user['isMerchant'] ?? json['isMerchant'];
    isMerchant = rawMerchant == true || rawMerchant?.toString() == 'true';

    print('=== AFTER hydrate: token=$token  name=$name  email=$email  '
        'id=$id  isMerchant=$isMerchant  photoUrl=$photoUrl');
    await save();
  }

  // ── Persist to SharedPreferences ───────────────────────────────
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id',            id           ?? '');
    await prefs.setString('user_token',         token        ?? '');
    await prefs.setString('user_name',          name         ?? '');
    await prefs.setString('user_last_name',     lastName     ?? '');
    await prefs.setString('user_surname',       surname      ?? '');
    await prefs.setString('user_email',         email        ?? '');
    await prefs.setString('user_phone',         phone        ?? '');
    await prefs.setString('user_photo_url',     photoUrl     ?? '');
    await prefs.setString('user_wilaya',        wilaya       ?? '');
    await prefs.setString('user_business_name', businessName ?? '');
    await prefs.setString('user_business_type', businessType ?? '');
    await prefs.setBool(  'user_is_merchant',   isMerchant);
    print('=== SAVED: token=$token  name=$name  id=$id  isMerchant=$isMerchant');
  }

  // Aliases kept for backward compatibility
  Future<void> saveToPrefs()   => save();
  Future<void> loadFromPrefs() => load();

  // ── Load from SharedPreferences ────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    id           = _orNull(prefs.getString('user_id'));
    token        = _orNull(prefs.getString('user_token'));
    name         = _orNull(prefs.getString('user_name'));
    lastName     = _orNull(prefs.getString('user_last_name'));
    surname      = _orNull(prefs.getString('user_surname'));
    email        = _orNull(prefs.getString('user_email'));
    phone        = _orNull(prefs.getString('user_phone'));
    wilaya       = _orNull(prefs.getString('user_wilaya'));
    businessName = _orNull(prefs.getString('user_business_name'));
    businessType = _orNull(prefs.getString('user_business_type'));
    isMerchant   = prefs.getBool('user_is_merchant') ?? false;

    // ✅ Always normalise photo URL on load too
    final rawPhoto = prefs.getString('user_photo_url') ?? '';
    photoUrl = _normaliseUrl(rawPhoto.isEmpty ? null : rawPhoto);

    print('=== LOADED: token=$token  name=$name  id=$id  '
        'isMerchant=$isMerchant  photoUrl=$photoUrl');
  }

  // ── Clear session (logout) ─────────────────────────────────────
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    id = token = name = lastName = surname = email =
        phone = photoUrl = wilaya = businessName = businessType = null;
    isMerchant = false;
  }

  // ── Partial update helpers ─────────────────────────────────────
  Future<void> updatePhotoUrl(String url) async {
    photoUrl = _normaliseUrl(url);
    await save();
  }

  Future<void> updateFromProfile(Map<String, dynamic> data) async {
    if (data['firstName']    != null) name         = data['firstName']    as String;
    if (data['name']         != null) name         = data['name']         as String;
    if (data['lastName']     != null) lastName     = data['lastName']     as String;
    if (data['surname']      != null) surname      = data['surname']      as String;
    if (data['email']        != null) email        = data['email']        as String;
    if (data['contact']      != null) email        = data['contact']      as String;
    if (data['phone']        != null) phone        = data['phone']        as String;
    if (data['wilaya']       != null) wilaya       = data['wilaya']       as String;
    if (data['businessName'] != null) businessName = data['businessName'] as String;
    if (data['businessType'] != null) businessType = data['businessType'] as String;

    if (data['photoUrl']     != null) {
      photoUrl = _normaliseUrl(data['photoUrl'] as String);
    }
    if (data['profileImage'] != null) {
      photoUrl = _normaliseUrl(data['profileImage'] as String);
    }

    if (data['isMerchant'] != null) {
      final raw = data['isMerchant'];
      isMerchant = raw == true || raw.toString() == 'true';
    }
    await save();
  }

  // ── Private helpers ────────────────────────────────────────────
  static String? _clean(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static String? _orNull(String? s) =>
      (s == null || s.isEmpty) ? null : s;
}