
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'usersession.dart';

/// ─────────────────────────────────────────────
///  CONFIGURATION
/// ─────────────────────────────────────────────
class ApiConfig {
  static const String baseUrl = 'https://ethanol-hemstitch-strongbox.ngrok-free.dev';

  // ── Register — form-urlencoded (@RequestParam) ──
  static const String registerStep1  = '/api/auth/register/step1';
  static const String registerStep2  = '/api/auth/register/step2';
  static const String registerStep3  = '/api/auth/register/step3';
  static const String resendOtp      = '/api/auth/resend-otp';

  // ── Auth — form-urlencoded (@RequestParam) ──
  static const String login          = '/api/auth/login';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword  = '/api/auth/reset-password';

  // ── User — Bearer token ──
  static const String getProfile     = '/api/users/me';
  static const String updateProfile  = '/api/users/update';

  // ── Password change depuis le profil (connecté) ──
  // POST /api/auth/change-password/request  → envoie OTP à l'email/phone du user
  //   Body (form-urlencoded): — (le backend lit le user depuis le JWT)
  //   200: { "success": true, "message": "OTP envoyé" }
  static const String changePasswordRequest = '/api/auth/change-password/request';

  // POST /api/auth/change-password/confirm  → vérifie OTP + applique le nouveau mdp
  //   Body (form-urlencoded): otpCode + newPassword + confirm
  //   200: { "success": true, "message": "Mot de passe changé !" }
  static const String changePasswordConfirm = '/api/auth/change-password/confirm';

  // ── Offer likes ──
  // POST   /api/offres/{offerId}/like   → ajoute un j'adore
  // DELETE /api/offres/{offerId}/like   → retire le j'adore
  // GET    /api/offres/{offerId}/likes  → { "likesCount": 12, "isLikedByMe": true }
  static String offerLike(String offerId)  => '/api/offres/$offerId/like';
  static String offerLikes(String offerId) => '/api/offres/$offerId/likes';
}

/// ─────────────────────────────────────────────
///  RESPONSE WRAPPER
/// ─────────────────────────────────────────────
class ApiResponse<T> {
  final bool    success;
  final T?      data;
  final String? errorMessage;

  ApiResponse.ok(this.data)           : success = true,  errorMessage = null;
  ApiResponse.fail(this.errorMessage) : success = false, data = null;
}

/// ─────────────────────────────────────────────
///  API SERVICE
/// ─────────────────────────────────────────────
class ApiService {
  ApiService._();

  // ── form-urlencoded — register + login + forgot + reset ──
  static Map<String, String> _formHeaders() {
    return {'ngrok-skip-browser-warning': 'true'};
  }

  // ── form-urlencoded + Bearer token ──
  static Map<String, String> _formHeadersAuth() {
    return {
      'ngrok-skip-browser-warning': 'true',
      'Authorization': 'Bearer ${UserSession().token}',
    };
  }

  // ── JSON avec Bearer token — getProfile ──
  static Map<String, String> _jsonHeaders({bool withAuth = false}) {
    final h = <String, String>{
      'Content-Type'              : 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (withAuth && UserSession().token.isNotEmpty) {
      h['Authorization'] = 'Bearer ${UserSession().token}';
    }
    return h;
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try   { return jsonDecode(res.body) as Map<String, dynamic>; }
    catch (_) { return {'message': res.body}; }
  }

  // ──────────────────────────────────────────────────────────────
  //  1. REGISTER STEP 1  →  POST /api/auth/register/step1
  //
  //  Body (form-urlencoded): contact + password + password2
  //  200: { "success": true, "userId": 42, "message": "OTP sent" }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<int>> registerStep1({
    required String email,
    required String password,
    required String password2,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerStep1}'),
        headers: _formHeaders(),
        body: <String, String>{
          'contact'  : email,
          'password' : password,
          'password2': password2,
        },
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final int userId = (body['userId'] as num).toInt();
        return ApiResponse.ok(userId);
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Registration failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  2. REGISTER STEP 2  →  POST /api/auth/register/step2
  //
  //  Body (form-urlencoded): userId + otpCode
  //  200: { "success": true, "message": "Email verified" }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> registerStep2({
    required int    userId,
    required String otpCode,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerStep2}'),
        headers: _formHeaders(),
        body: <String, String>{
          'userId' : userId.toString(),
          'otpCode': otpCode,
        },
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200) {
        return ApiResponse.ok(body['message']?.toString() ?? 'Verified');
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Invalid OTP');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  3. REGISTER STEP 3  →  POST /api/auth/register/step3
  //
  //  Body (form-urlencoded): userId + name + surname
  //  200: { "success": true, "accessToken": "eyJ...", "userId": 42, ... }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> registerStep3({
    required int    userId,
    required String name,
    required String surname,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerStep3}'),
        headers: _formHeaders(),
        body: <String, String>{
          'userId' : userId.toString(),
          'name'   : name,
          'surname': surname,
        },
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200) {
        await UserSession().hydrateFromJson(body);
        return ApiResponse.ok(body['message']?.toString() ?? 'Done');
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  4. RESEND OTP  →  POST /api/auth/resend-otp
  //
  //  Body (form-urlencoded): userId
  //  200: { "success": true, "message": "OTP renvoyé !" }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> resendOtp({
    required int userId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resendOtp}'),
        headers: _formHeaders(),
        body: <String, String>{
          'userId': userId.toString(),
        },
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200) {
        return ApiResponse.ok(body['message']?.toString() ?? 'OTP resent');
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Failed to resend');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  5. LOGIN  →  POST /api/auth/login
  //
  //  Body (form-urlencoded): contact + password
  //  200: { "accessToken": "eyJ...", "user": {...} }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: _formHeaders(),
        body: <String, String>{
          'contact' : email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200) {
        await UserSession().hydrateFromJson(body);
        return ApiResponse.ok(body);
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Login failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  6. FORGOT PASSWORD  →  POST /api/auth/forgot-password
  //
  //  Body (form-urlencoded): contact
  //  200: { "success": true, "message": "OTP envoyé à ..." }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> forgotPassword({
    required String contact,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.forgotPassword}'),
        headers: _formHeaders(),
        body: <String, String>{
          'contact': contact,
        },
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200) {
        return ApiResponse.ok(body['message']?.toString() ?? 'OTP sent');
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Not found');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  7. RESET PASSWORD  →  POST /api/auth/reset-password
  //
  //  Body (form-urlencoded): contact + otpCode + newPassword + confirm
  //  200: { "success": true, "message": "Password réinitialisé !" }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> resetPassword({
    required String contact,
    required String otpCode,
    required String newPassword,
    required String confirm,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resetPassword}'),
        headers: _formHeaders(),
        body: <String, String>{
          'contact'    : contact,
          'otpCode'    : otpCode,
          'newPassword': newPassword,
          'confirm'    : confirm,
        },
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200) {
        return ApiResponse.ok(body['message']?.toString() ?? 'Password reset successfully');
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Reset failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  8. REFRESH PROFILE  →  GET /api/users/me
  //
  //  Header: Authorization: Bearer <token>
  //  200: { "success": true, "userId": 42, "firstName": "...", ... }
  //  401: token expiré → logout automatique
  // ──────────────────────────────────────────────────────────────
  static Future<bool> refreshProfile() async {
    if (!UserSession().isLoggedIn) return false;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfile}'),
        headers: _jsonHeaders(withAuth: true),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        await UserSession().hydrateFromJson(_decode(res));
        return true;
      }
      if (res.statusCode == 401) await UserSession().logout();
      return false;
    } catch (_) { return false; }
  }

  // ──────────────────────────────────────────────────────────────
  //  9. UPDATE PROFILE  →  PUT /api/users/update
  //
  //  Body (form-urlencoded) + Bearer token
  //  Fields optionnels: firstName + surname + contact
  //  200: { "success": true, "message": "Profil mis à jour !" }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> updateProfile({
    String? firstName,
    String? surname,
    String? contact,
  }) async {
    try {
      final headers = {
        ..._formHeaders(),
        'Authorization': 'Bearer ${UserSession().token}',
      };
      final body = <String, String>{};
      if (firstName != null && firstName.isNotEmpty) body['firstName'] = firstName;
      if (surname   != null && surname.isNotEmpty)   body['surname']   = surname;
      if (contact   != null && contact.isNotEmpty)   body['contact']   = contact;

      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfile}'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));

      final resBody = _decode(res);
      if (res.statusCode == 200) {
        return ApiResponse.ok(resBody['message']?.toString() ?? 'Profile updated');
      }
      return ApiResponse.fail(resBody['message']?.toString() ?? 'Update failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  10. CHANGE PASSWORD — ÉTAPE 1 : Demander l'OTP
  //      POST /api/auth/change-password/request
  //
  //  Utilisé depuis EditProfilePage quand l'utilisateur veut
  //  changer son mot de passe alors qu'il EST connecté.
  //  Le backend identifie l'utilisateur via le JWT et envoie
  //  un OTP à son email / téléphone enregistré.
  //
  //  Header: Authorization: Bearer <token>
  //  200: { "success": true, "message": "OTP envoyé à alice@..." }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> changePasswordRequest() async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePasswordRequest}'),
        headers: _formHeadersAuth(),
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200) {
        return ApiResponse.ok(body['message']?.toString() ?? 'OTP sent');
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Request failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  11. CHANGE PASSWORD — ÉTAPE 2 : Confirmer avec OTP
  //      POST /api/auth/change-password/confirm
  //
  //  Body (form-urlencoded): otpCode + newPassword + confirm
  //  Header: Authorization: Bearer <token>
  //  200: { "success": true, "message": "Mot de passe changé !" }
  //
  //  ⚠️  Après succès : mettre à jour UserSession().password
  //      et appeler UserSession().saveToPrefs()
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> changePasswordConfirm({
    required String otpCode,
    required String newPassword,
    required String confirm,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePasswordConfirm}'),
        headers: _formHeadersAuth(),
        body: <String, String>{
          'otpCode'    : otpCode,
          'newPassword': newPassword,
          'confirm'    : confirm,
        },
      ).timeout(const Duration(seconds: 15));

      final body = _decode(res);
      if (res.statusCode == 200) {
        return ApiResponse.ok(body['message']?.toString() ?? 'Password changed');
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  12. OFFER LIKES — charger le compteur + état utilisateur
  //      GET /api/offres/{offerId}/likes
  //
  //  Header: Authorization: Bearer <token>
  //  200: { "likesCount": 12, "isLikedByMe": true }
  // ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getOfferLikes(String offerId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.offerLikes(offerId)}'),
        headers: _jsonHeaders(withAuth: true),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) return _decode(res);
      return null;
    } catch (_) { return null; }
  }

  // ──────────────────────────────────────────────────────────────
  //  13. OFFER LIKES — ajouter un j'adore
  //      POST /api/offres/{offerId}/like
  //
  //  Header: Authorization: Bearer <token>
  //  200: { "success": true, "likesCount": 13 }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<int>> likeOffer(String offerId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.offerLike(offerId)}'),
        headers: _formHeadersAuth(),
      ).timeout(const Duration(seconds: 10));

      final body = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final count = (body['likesCount'] as num?)?.toInt() ?? 0;
        return ApiResponse.ok(count);
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Like failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ──────────────────────────────────────────────────────────────
  //  14. OFFER LIKES — retirer un j'adore
  //      DELETE /api/offres/{offerId}/like
  //
  //  Header: Authorization: Bearer <token>
  //  200: { "success": true, "likesCount": 11 }
  // ──────────────────────────────────────────────────────────────
  static Future<ApiResponse<int>> unlikeOffer(String offerId) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.offerLike(offerId)}'),
        headers: _formHeadersAuth(),
      ).timeout(const Duration(seconds: 10));

      final body = _decode(res);
      if (res.statusCode == 200) {
        final count = (body['likesCount'] as num?)?.toInt() ?? 0;
        return ApiResponse.ok(count);
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Unlike failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }
}
