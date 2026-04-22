/*import 'dart:io';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // Personal info
  String name = '';
  String surname = '';
  String email = '';
  String password = '';
  String phone = '';
  String wilaya = '';

  // Account type
  bool isMerchant = false;

  // Profile image
  File? profileImage;

  // Google Sign-In
  String? displayName;
  String? photoUrl;

  // for chat
  int id = 0;
  String token = '';

  // Computed helpers
  String get fullName {
    final parts = [surname, name].where((s) => s.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : 'No Name';
  }

  void clear() {
    name = '';
    surname = '';
    email = '';
    password = '';
    phone = '';
    wilaya = '';
    isMerchant = false;
    profileImage = null;
    displayName = null;
    photoUrl = null;
    id = 0;
    token = '';
  }
}*/

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────
///  UserSession  —  Singleton + persistance locale (SharedPrefs)
///
///  FLUX :
///   1. Au démarrage de l'app → appeler UserSession().loadFromPrefs()
///      → si un token existe, l'utilisateur est déjà connecté
///   2. Après login/register réussi → appeler UserSession().saveToPrefs()
///      → toutes les données sont écrites sur le disque
///   3. Au logout → appeler UserSession().logout()
///      → efface tout en mémoire ET sur le disque
///
///  CÔTÉ SPRING BOOT :
///   Le token JWT est stocké ici et envoyé dans chaque requête via
///   le header :  Authorization: Bearer <token>
/// ─────────────────────────────────────────────────────────────

class UserSession {
  // ── Singleton ──────────────────────────────────────────────
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // ── Clés SharedPreferences ──────────────────────────────────
  // Ces clés sont les identifiants utilisés pour écrire/lire sur le disque.
  // Ne pas les changer sans migrer les données existantes.
  static const _kToken    = 'jwt_token';
  static const _kId       = 'user_id';
  static const _kEmail    = 'user_email';
  static const _kName     = 'user_name';
  static const _kSurname  = 'user_surname';
  static const _kPhone    = 'user_phone';
  static const _kWilaya   = 'user_wilaya';
  static const _kMerchant = 'user_is_merchant';
  static const _kPhotoUrl = 'user_photo_url';

  // ── Données en mémoire ──────────────────────────────────────
  String name      = '';
  String surname   = '';
  String email     = '';
  String password  = ''; // jamais persisté sur le disque (sécurité)
  String phone     = '';
  String wilaya    = '';
  bool   isMerchant = false;
  File?  profileImage;   // image locale (avant upload)
  String? displayName;   // Google Sign-In
  String? photoUrl;      // URL photo (Google ou backend)
  int    id    = 0;
  String token = '';     // JWT — source de vérité pour "est connecté ?"

  // ── Helper ──────────────────────────────────────────────────
  String get fullName {
    final parts = [surname, name].where((s) => s.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : 'No Name';
  }

  /// Retourne true si l'utilisateur a un token valide en mémoire.
  /// NE vérifie PAS l'expiration côté serveur — c'est le backend
  /// qui rejettera les requêtes avec un 401 si le token est expiré.
  bool get isLoggedIn => token.isNotEmpty;

  // ────────────────────────────────────────────────────────────
  //  CHARGER depuis le disque (à appeler au démarrage de l'app)
  //
  //  Usage dans main.dart :
  //    void main() async {
  //      WidgetsFlutterBinding.ensureInitialized();
  //      await UserSession().loadFromPrefs();   // ← ICI
  //      runApp(const MyApp());
  //    }
  //
  //  Puis dans votre widget racine :
  //    home: UserSession().isLoggedIn ? HomePage() : SignUp1()
  // ────────────────────────────────────────────────────────────
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    token      = prefs.getString(_kToken)   ?? '';
    id         = prefs.getInt(_kId)         ?? 0;
    email      = prefs.getString(_kEmail)   ?? '';
    name       = prefs.getString(_kName)    ?? '';
    surname    = prefs.getString(_kSurname) ?? '';
    phone      = prefs.getString(_kPhone)   ?? '';
    wilaya     = prefs.getString(_kWilaya)  ?? '';
    isMerchant = prefs.getBool(_kMerchant)  ?? false;
    photoUrl   = prefs.getString(_kPhotoUrl);

    // TODO: si votre backend expose GET /api/user/me, vous pouvez
    //       re-valider/rafraîchir le profil ici :
    //       if (isLoggedIn) await _refreshProfileFromBackend();
  }

  // ────────────────────────────────────────────────────────────
  //  SAUVEGARDER sur le disque
  //
  //  À appeler après chaque modification importante :
  //    - login réussi
  //    - register + update profile réussis
  //    - mise à jour du profil
  // ────────────────────────────────────────────────────────────
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kToken,   token);
    await prefs.setInt   (_kId,      id);
    await prefs.setString(_kEmail,   email);
    await prefs.setString(_kName,    name);
    await prefs.setString(_kSurname, surname);
    await prefs.setString(_kPhone,   phone);
    await prefs.setString(_kWilaya,  wilaya);
    await prefs.setBool  (_kMerchant, isMerchant);
    if (photoUrl != null) await prefs.setString(_kPhotoUrl, photoUrl!);
    // NOTE: password n'est jamais écrit sur le disque intentionnellement
  }

  // ────────────────────────────────────────────────────────────
  //  HYDRATER depuis la réponse du backend
  //
  //  À appeler après login ou register avec la Map JSON renvoyée
  //  par Spring Boot, puis enchaîner saveToPrefs().
  //
  //  Exemple d'utilisation dans ApiService :
  //    final body = jsonDecode(res.body);
  //    await UserSession().hydrateFromJson(body);
  //    await UserSession().saveToPrefs();
  //
  //  Exemple de réponse Spring Boot attendue :
  //  {
  //    "token":      "eyJhbGc...",
  //    "id":         42,
  //    "email":      "alice@example.com",
  //    "name":       "Alice",
  //    "surname":    "Dupont",
  //    "phone":      "0555000000",
  //    "wilaya":     "Alger",
  //    "isMerchant": false,
  //    "photoUrl":   "https://..."   ← optionnel
  //  }
  // ────────────────────────────────────────────────────────────
  Future<void> hydrateFromJson(Map<String, dynamic> json) async {
    if (json['token']      != null) token      = json['token'].toString();
    if (json['id']         != null) id         = (json['id'] as num).toInt();
    if (json['email']      != null) email      = json['email'].toString();
    if (json['name']       != null) name       = json['name'].toString();
    if (json['surname']    != null) surname    = json['surname'].toString();
    if (json['phone']      != null) phone      = json['phone'].toString();
    if (json['wilaya']     != null) wilaya     = json['wilaya'].toString();
    if (json['isMerchant'] != null) isMerchant = json['isMerchant'] as bool;
    if (json['photoUrl']   != null) photoUrl   = json['photoUrl'].toString();

    // Persister immédiatement après hydratation
    await saveToPrefs();
  }

  // ────────────────────────────────────────────────────────────
  //  LOGOUT  —  efface tout en mémoire ET sur le disque
  //
  //  À appeler sur le bouton "Se déconnecter".
  //  Naviguer ensuite vers SignUp1 ou Login1 avec pushAndRemoveUntil.
  //
  //  TODO: si votre backend a un endpoint POST /api/auth/logout
  //        (pour invalider le token côté serveur), appelez-le AVANT
  //        d'appeler cette méthode.
  // ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // supprime toutes les clés persistées

    // Réinitialiser la mémoire
    name       = '';
    surname    = '';
    email      = '';
    password   = '';
    phone      = '';
    wilaya     = '';
    isMerchant = false;
    profileImage = null;
    displayName  = null;
    photoUrl     = null;
    id    = 0;
    token = '';
  }

  // Alias pour la compatibilité avec l'ancien code
  Future<void> clear() => logout();
}