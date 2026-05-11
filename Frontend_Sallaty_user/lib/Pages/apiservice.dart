import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;
import 'usersession.dart';

class ApiConfig {
  static const String baseUrl = 'https://headstand-rosy-chlorine.ngrok-free.dev';

  static const String registerStep1  = '/api/auth/register/step1';
  static const String registerStep2  = '/api/auth/register/step2';
  static const String registerStep3  = '/api/auth/register/step3';
  static const String resendOtp      = '/api/auth/resend-otp';
  static const String login          = '/api/auth/login';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword  = '/api/auth/reset-password';
  static const String getProfile     = '/api/users/me';

  static const String updateProfile         = '/api/profile/update';
  static const String changePasswordRequest = '/api/auth/change-password/request';
  static const String changePasswordConfirm = '/api/auth/change-password/confirm';

  static String offerLike(String offerId)  => '/api/offres/$offerId/like';
  static String offerLikes(String offerId) => '/api/offres/$offerId/likes';
}

class ApiResponse<T> {
  final bool    success;
  final T?      data;
  final String? errorMessage;

  ApiResponse.ok(this.data)           : success = true,  errorMessage = null;
  ApiResponse.fail(this.errorMessage) : success = false, data = null;
}

class ApiService {
  ApiService._();

  static Map<String, String> _formHeaders() => {};

  static Map<String, String> _formHeadersAuth() => {
    'Authorization': 'Bearer ${UserSession().token ?? ''}',
  };

  static Map<String, String> _jsonHeaders({bool withAuth = false}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    final t = UserSession().token;
    if (withAuth && t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try   { return jsonDecode(res.body) as Map<String, dynamic>; }
    catch (_) { return {'message': res.body}; }
  }


  static Future<void> _attachFile(
    http.MultipartRequest request,
    String fieldName,
    String? filePath,      
    String filename,
    Uint8List? webBytes,   
  ) async {
    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, webBytes!, filename: filename),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, filePath!,
            filename: filename),
      );
    }
  }

  // ── 1. REGISTER STEP 1 ────────────────────────────────────────
  static Future<ApiResponse<int>> registerStep1({
    required String email,
    required String password,
    required String password2,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerStep1}'),
        headers: _formHeaders(),
        body: {'contact': email, 'password': password, 'password2': password2},
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.ok((body['userId'] as num).toInt());
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Registration failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 2. REGISTER STEP 2 ────────────────────────────────────────
  static Future<ApiResponse<String>> registerStep2({
    required int    userId,
    required String otpCode,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerStep2}'),
        headers: _formHeaders(),
        body: {'userId': userId.toString(), 'otpCode': otpCode},
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'Verified');
      return ApiResponse.fail(body['message']?.toString() ?? 'Invalid OTP');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 3. REGISTER STEP 3 ────────────────────────────────────────
  static Future<ApiResponse<String>> registerStep3({
    required int    userId,
    required String name,
    required String surname,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerStep3}'),
        headers: _formHeaders(),
        body: {'userId': userId.toString(), 'name': name, 'surname': surname},
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

  // ── 4. RESEND OTP ─────────────────────────────────────────────
  static Future<ApiResponse<String>> resendOtp({required int userId}) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resendOtp}'),
        headers: _formHeaders(),
        body: {'userId': userId.toString()},
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'OTP resent');
      return ApiResponse.fail(body['message']?.toString() ?? 'Failed to resend');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 5. LOGIN ──────────────────────────────────────────────────
  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: _formHeaders(),
        body: {'contact': email, 'password': password},
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

  // ── 6. FORGOT PASSWORD ────────────────────────────────────────
  static Future<ApiResponse<String>> forgotPassword({required String contact}) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.forgotPassword}'),
        headers: _formHeaders(),
        body: {'contact': contact},
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'OTP sent');
      return ApiResponse.fail(body['message']?.toString() ?? 'Not found');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 7. RESET PASSWORD ─────────────────────────────────────────
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
        body: {
          'contact': contact, 'otpCode': otpCode,
          'newPassword': newPassword, 'confirm': confirm,
        },
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'Password reset');
      return ApiResponse.fail(body['message']?.toString() ?? 'Reset failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 8. REFRESH PROFILE ────────────────────────────────────────
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
      if (res.statusCode == 401) await UserSession().clear();
      return false;
    } catch (e) { return false; }
  }

  // ── 9. UPDATE PROFILE FULL ────────────────────────────────────
  static Future<ApiResponse<String>> updateProfileFull({
    String? name,
    String? surname,
    String? wilaya,
    String? businessName,
    String? businessType,
    String? phoneNumber,
  }) async {
    try {
      final body = <String, String>{};
      if (name         != null && name.isNotEmpty)         body['name']         = name;
      if (surname      != null && surname.isNotEmpty)      body['surname']      = surname;
      if (wilaya       != null && wilaya.isNotEmpty)       body['wilaya']       = wilaya;
      if (businessName != null && businessName.isNotEmpty) body['businessName'] = businessName;
      if (businessType != null && businessType.isNotEmpty) body['businessType'] = businessType;
      if (phoneNumber  != null && phoneNumber.isNotEmpty)  body['phoneNumber']  = phoneNumber;

      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfile}'),
        headers: _formHeadersAuth(),
        body: body,
      ).timeout(const Duration(seconds: 15));
      final resBody = _decode(res);
      if (res.statusCode == 200) {
        await UserSession().updateFromProfile({
          if (name         != null) 'name'        : name,
          if (surname      != null) 'surname'     : surname,
          if (wilaya       != null) 'wilaya'      : wilaya,
          if (businessName != null) 'businessName': businessName,
          if (businessType != null) 'businessType': businessType,
          if (phoneNumber  != null) 'phone'       : phoneNumber,
        });
        return ApiResponse.ok(resBody['message']?.toString() ?? 'Profile updated');
      }
      return ApiResponse.fail(resBody['message']?.toString() ?? 'Update failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 10. CHANGE PASSWORD REQUEST ───────────────────────────────
  static Future<ApiResponse<String>> changePasswordRequest() async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePasswordRequest}'),
        headers: _formHeadersAuth(),
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'OTP sent');
      return ApiResponse.fail(body['message']?.toString() ?? 'Request failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 11. CHANGE PASSWORD CONFIRM ───────────────────────────────
  static Future<ApiResponse<String>> changePasswordConfirm({
    required String otpCode,
    required String newPassword,
    required String confirm,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePasswordConfirm}'),
        headers: _formHeadersAuth(),
        body: {'otpCode': otpCode, 'newPassword': newPassword, 'confirm': confirm},
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'Password changed');
      return ApiResponse.fail(body['message']?.toString() ?? 'Failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 12. OFFER LIKES — charger ─────────────────────────────────
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

  // ── 13. OFFER LIKES — ajouter ─────────────────────────────────
  static Future<ApiResponse<int>> likeOffer(String offerId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.offerLike(offerId)}'),
        headers: _formHeadersAuth(),
      ).timeout(const Duration(seconds: 10));
      final body = _decode(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.ok((body['likesCount'] as num?)?.toInt() ?? 0);
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Like failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 14. OFFER LIKES — retirer ─────────────────────────────────
  static Future<ApiResponse<int>> unlikeOffer(String offerId) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.offerLike(offerId)}'),
        headers: _formHeadersAuth(),
      ).timeout(const Duration(seconds: 10));
      final body = _decode(res);
      if (res.statusCode == 200) {
        return ApiResponse.ok((body['likesCount'] as num?)?.toInt() ?? 0);
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Unlike failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 15. UPDATE PASSWORD ───────────────────────────────────────
  static Future<ApiResponse<String>> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirm,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/password'),
        headers: _formHeadersAuth(),
        body: {'oldPassword': oldPassword, 'newPassword': newPassword, 'confirm': confirm},
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'Password updated');
      return ApiResponse.fail(body['message']?.toString() ?? 'Failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 16. UPDATE PROFILE PHOTO — Android/iOS (File) ────────────
  static Future<ApiResponse<String>> updateProfilePhoto(File photo) async {
    try {
      final userId = UserSession().id;
      if (userId == null) return ApiResponse.fail('User not logged in');
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/uploadImage/$userId');
      final filename = photo.path.split('/').last;
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_formHeadersAuth())
        ..files.add(await http.MultipartFile.fromPath(
            'file', photo.path, filename: filename));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res  = await http.Response.fromStream(streamed);
      final body = _decode(res);
      if (res.statusCode == 200) {
        final imagePath = body['imagePath']?.toString() ?? '';
        await UserSession().updatePhotoUrl(imagePath);
        return ApiResponse.ok(imagePath);
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Upload failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 16b. UPDATE PROFILE PHOTO — Web (Uint8List) ───────────────
  static Future<ApiResponse<String>> updateProfilePhotoWeb(
      Uint8List bytes, String filename) async {
    try {
      final userId = UserSession().id;
      if (userId == null) return ApiResponse.fail('User not logged in');
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/uploadImage/$userId');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_formHeadersAuth())
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res  = await http.Response.fromStream(streamed);
      final body = _decode(res);
      if (res.statusCode == 200) {
        final imagePath = body['imagePath']?.toString() ?? '';
        await UserSession().updatePhotoUrl(imagePath);
        return ApiResponse.ok(imagePath);
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Upload failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── buildImageUrl ─────────────────────────────────────────────
  static String buildImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return '';
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }
    final clean = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    return '${ApiConfig.baseUrl}$clean';
  }

  // ── 16c. UPLOAD PHOTO STATIC (signup — pas de token requis) ───
  //  filename   : positional — toujours requis
  //  filePath   : named optionnel — Android/iOS uniquement
  //  webBytes   : named optionnel — Web uniquement
  // ─────────────────────────────────────────────────────────────
  static Future<ApiResponse<String>> uploadProfilePhotoStatic(
    int userId,
    String filename, {
    String?    filePath,
    Uint8List? webBytes,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/uploadImage/$userId');
      final request = http.MultipartRequest('POST', uri);
      await _attachFile(request, 'file', filePath, filename, webBytes);
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res  = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResponse.ok(body['imagePath']?.toString() ?? '');
      }
      return ApiResponse.fail(body['message']?.toString() ?? 'Upload failed');
    } on SocketException {
      return ApiResponse.fail('No internet connection');
    } catch (e) {
      return ApiResponse.fail('Error: $e');
    }
  }

  // ── 17. SEND OTP (alias forgotPassword) ───────────────────────
  static Future<ApiResponse<String>> sendOtp(String contact) async {
    return forgotPassword(contact: contact);
  }

  // ── 18. UPDATE CONTACT ────────────────────────────────────────
  static Future<ApiResponse<String>> updateContact({
    required String newContact,
    required String otpCode,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/contact'),
        headers: _formHeadersAuth(),
        body: {'newContact': newContact, 'otpCode': otpCode},
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'Contact updated');
      return ApiResponse.fail(body['message']?.toString() ?? 'Failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 19. SEND CONTACT OTP ──────────────────────────────────────
  static Future<ApiResponse<String>> sendContactOtp(String newContact) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/contact/send-otp'),
        headers: _formHeadersAuth(),
        body: {'newContact': newContact},
      ).timeout(const Duration(seconds: 15));
      final body = _decode(res);
      if (res.statusCode == 200) return ApiResponse.ok(body['message']?.toString() ?? 'OTP sent');
      return ApiResponse.fail(body['message']?.toString() ?? 'Failed');
    } on SocketException { return ApiResponse.fail('No internet connection'); }
    catch (e)            { return ApiResponse.fail('Error: $e'); }
  }

  // ── 20. GET MERCHANT STATUS ───────────────────────────────────
  static Future<String?> getMerchantStatus() async {
    try {
      final userId = UserSession().intId;
      if (userId == 0) return null;
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/marchand/get/$userId'),
        headers: _jsonHeaders(withAuth: true),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _decode(res)['statusMarchand']?.toString();
      }
      return null;
    } catch (_) { return null; }
  }

  // ── 21. GET MERCHANT STATISTICS ───────────────────────────────
  Future<Map<String, dynamic>> getMerchantStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/statistics/marchand'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserSession().token ?? ''}',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to load merchant statistics: ${response.statusCode}');
    } catch (e) { rethrow; }
  }

  // ── 22. GET CLIENT ORDERS ─────────────────────────────────────
  Future<List<dynamic>> getClientOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/statistics/client'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserSession().token ?? ''}',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      throw Exception('Failed to load client orders: ${response.statusCode}');
    } catch (e) { rethrow; }
  }
}
