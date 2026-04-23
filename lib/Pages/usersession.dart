
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  // ── Singleton ──────────────────────────────────────────────
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // ── Clés SharedPreferences ──────────────────────────────────
  static const _kToken        = 'jwt_token';
  static const _kId           = 'user_id';
  static const _kEmail        = 'user_email';
  static const _kName         = 'user_name';
  static const _kSurname      = 'user_surname';
  static const _kPhone        = 'user_phone';
  static const _kWilaya       = 'user_wilaya';
  static const _kMerchant     = 'user_is_merchant';
  static const _kPhotoUrl     = 'user_photo_url';
  static const _kBusinessName = 'user_business_name'; // ← nouveau
  static const _kBusinessType = 'user_business_type'; // ← nouveau

  // ── Données en mémoire ──────────────────────────────────────
  String name         = '';
  String surname      = '';
  String email        = '';
  String password     = ''; // jamais persisté sur le disque (sécurité)
  String phone        = '';
  String wilaya       = '';
  bool   isMerchant   = false;
  File?  profileImage;        // image locale (avant upload)
  String? displayName;        // Google Sign-In
  String? photoUrl;           // URL photo (Google ou backend)
  int    id           = 0;
  String token        = '';   // JWT — source de vérité pour "est connecté ?"

  // ── Champs Merchant ─────────────────────────────────────────
  /// Nom de la boutique (shopName dans RegisterMerchantPage)
  String businessName = '';
  /// Type d'activité (selectedType dans RegisterMerchantPage)
  String businessType = '';

  // ── Helper ──────────────────────────────────────────────────
  String get fullName {
    final parts = [surname, name].where((s) => s.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : 'No Name';
  }

  /// Retourne true si l'utilisateur a un token valide en mémoire.
  bool get isLoggedIn => token.isNotEmpty;

  // ────────────────────────────────────────────────────────────
  //  CHARGER depuis le disque (à appeler au démarrage de l'app)
  // ────────────────────────────────────────────────────────────
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    token        = prefs.getString(_kToken)        ?? '';
    id           = prefs.getInt(_kId)              ?? 0;
    email        = prefs.getString(_kEmail)        ?? '';
    name         = prefs.getString(_kName)         ?? '';
    surname      = prefs.getString(_kSurname)      ?? '';
    phone        = prefs.getString(_kPhone)        ?? '';
    wilaya       = prefs.getString(_kWilaya)       ?? '';
    isMerchant   = prefs.getBool(_kMerchant)       ?? false;
    photoUrl     = prefs.getString(_kPhotoUrl);
    businessName = prefs.getString(_kBusinessName) ?? ''; // ← nouveau
    businessType = prefs.getString(_kBusinessType) ?? ''; // ← nouveau
  }

  // ────────────────────────────────────────────────────────────
  //  SAUVEGARDER sur le disque
  // ────────────────────────────────────────────────────────────
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kToken,        token);
    await prefs.setInt   (_kId,           id);
    await prefs.setString(_kEmail,        email);
    await prefs.setString(_kName,         name);
    await prefs.setString(_kSurname,      surname);
    await prefs.setString(_kPhone,        phone);
    await prefs.setString(_kWilaya,       wilaya);
    await prefs.setBool  (_kMerchant,     isMerchant);
    await prefs.setString(_kBusinessName, businessName); // ← nouveau
    await prefs.setString(_kBusinessType, businessType); // ← nouveau
    if (photoUrl != null) await prefs.setString(_kPhotoUrl, photoUrl!);
    // NOTE: password n'est jamais écrit sur le disque intentionnellement
  }

  // ────────────────────────────────────────────────────────────
  //  HYDRATER depuis la réponse du backend
  //
  //  Réponse Spring Boot attendue :
  //  {
  //    "token":        "eyJhbGc...",
  //    "id":           42,
  //    "email":        "alice@example.com",
  //    "name":         "Alice",
  //    "surname":      "Dupont",
  //    "phone":        "0555000000",
  //    "wilaya":       "Alger",
  //    "isMerchant":   true,
  //    "photoUrl":     "https://...",     ← optionnel
  //    "businessName": "Chez Alice",      ← optionnel (merchant seulement)
  //    "businessType": "Restaurant"       ← optionnel (merchant seulement)
  //  }
  // ────────────────────────────────────────────────────────────
  Future<void> hydrateFromJson(Map<String, dynamic> json) async {
    if (json['token']        != null) token        = json['token'].toString();
    if (json['id']           != null) id           = (json['id'] as num).toInt();
    if (json['email']        != null) email        = json['email'].toString();
    if (json['name']         != null) name         = json['name'].toString();
    if (json['surname']      != null) surname      = json['surname'].toString();
    if (json['phone']        != null) phone        = json['phone'].toString();
    if (json['wilaya']       != null) wilaya       = json['wilaya'].toString();
    if (json['isMerchant']   != null) isMerchant   = json['isMerchant'] as bool;
    if (json['photoUrl']     != null) photoUrl     = json['photoUrl'].toString();
    if (json['businessName'] != null) businessName = json['businessName'].toString(); // ← nouveau
    if (json['businessType'] != null) businessType = json['businessType'].toString(); // ← nouveau

    // Persister immédiatement après hydratation
    await saveToPrefs();
  }

  // ────────────────────────────────────────────────────────────
  //  LOGOUT  —  efface tout en mémoire ET sur le disque
  // ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    name         = '';
    surname      = '';
    email        = '';
    password     = '';
    phone        = '';
    wilaya       = '';
    isMerchant   = false;
    profileImage = null;
    displayName  = null;
    photoUrl     = null;
    id           = 0;
    token        = '';
    businessName = ''; // ← nouveau
    businessType = ''; // ← nouveau
  }

  // Alias pour la compatibilité avec l'ancien code
  Future<void> clear() => logout();
}