import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'usersession.dart';
import 'apiservice.dart';
import 'payment_models.dart';

/// All network calls related to payments live here.
/// UI files never touch http directly.
class PaymentService {
  // Singleton
  static final PaymentService instance = PaymentService._();
  PaymentService._();

  // ── POST /api/payments/pay ──────────────────────────────────────
  Future<PaymentResult> pay(PaymentRequestDto request) async {
    final token = UserSession().token ?? '';

    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/payments/pay'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('[PaymentService] status: ${res.statusCode}');
      debugPrint('[PaymentService] body:   ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return PaymentResult.success(PaymentDto.fromJson(body));
      }

      // Try to extract a meaningful error message from the backend
      String errorMsg = 'Payment failed. Please try again.';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err.containsKey('message')) {
          errorMsg = err['message'] as String;
        }
      } catch (_) {}
      return PaymentResult.failure(errorMsg);
    } catch (e) {
      debugPrint('[PaymentService] error: $e');
      return PaymentResult.failure('Network error. Check your connection.');
    }
  }

  // ── GET /api/payments/ordre/{ordreId} ───────────────────────────
  Future<PaymentDto?> getPaymentByOrdre(int ordreId) async {
    final token = UserSession().token ?? '';
    try {
      final res = await http
          .get(
            Uri.parse(
                '${ApiConfig.baseUrl}/api/payments/ordre/$ordreId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return PaymentDto.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[PaymentService] getPaymentByOrdre error: $e');
    }
    return null;
  }
}