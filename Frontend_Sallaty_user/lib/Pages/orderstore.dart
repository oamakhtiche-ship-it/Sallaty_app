import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usersession.dart';
import 'apiservice.dart';
import 'order_item.dart';

// ── ReservationRecord ─────────────────────────────────────────────
class ReservationRecord {
  final String offerId;
  final String offerTitle;
  final String clientName;
  final String clientId;
  final String profilePhoto;
  final String timeAgo;
  final String price;
  String status;

  ReservationRecord({
    required this.offerId,
    required this.offerTitle,
    required this.clientName,
    required this.clientId,
    required this.profilePhoto,
    required this.timeAgo,
    required this.price,
    required this.status,
  });
}

// ── OrderStore ────────────────────────────────────────────────────
class OrderStore {
  OrderStore._();
  static final OrderStore instance = OrderStore._();

  final List<OrderItem> _clientOrders = [];
  List<OrderItem> get clientOrders => List.unmodifiable(_clientOrders);

  final Map<String, List<ReservationRecord>> _reservations = {};
  Map<String, List<ReservationRecord>> get reservationsByOffer =>
      Map.unmodifiable(_reservations);

  List<ReservationRecord> getReservations(String offreId) =>
      _reservations[offreId] ?? [];

  // ════════════════════════════════════════════════════════════
  //  CLIENT — GET /api/ordres/client
  // ════════════════════════════════════════════════════════════
  Future<void> fetchClientOrders() async {
    try {
      final token = UserSession().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/ordres/client'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('[OrderStore] fetchClientOrders: ${res.statusCode}');
      debugPrint('[OrderStore] body: ${res.body}');

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _clientOrders.clear();
        for (final e in data) {
          String photoUrl = '';
          if (e['photo'] != null && e['photo'].toString().isNotEmpty) {
            final p = e['photo'].toString();
            photoUrl = p.startsWith('http')
                ? p
                : '${ApiConfig.baseUrl}/$p';
          }
          _clientOrders.add(OrderItem(
            ordreId:        e['ordreId']?.toString()      ?? '',
            title:          e['title']?.toString()        ?? '',
            merchantName:   e['merchantName']?.toString() ?? '',
            pickupLocation: e['wilaya']?.toString()       ?? '',
            pickupTime:     e['expireAt']?.toString(),
            price:          e['totalPrice'] != null
                ? '${e['totalPrice']} DA' : '',
            imagePath:      photoUrl.isNotEmpty ? photoUrl : null,
            status:         _parseStatus(
                e['status']?.toString() ?? 'pending'),
          ));
        }
      }
    } catch (e) {
      debugPrint('[OrderStore] fetchClientOrders error: $e');
    }
  }

  void updateClientOrderStatus(int index, OrderStatus newStatus) {
    if (index >= 0 && index < _clientOrders.length) {
      _clientOrders[index] =
          _clientOrders[index].copyWith(status: newStatus);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  MERCHANT — GET /api/ordres/reservations/{offreId}
  // ════════════════════════════════════════════════════════════
  Future<void> fetchMerchantReservations(String offreId) async {
    try {
      final token = UserSession().token ?? '';
      final res = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/ordres/reservations/$offreId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('[OrderStore] fetchReservations: ${res.statusCode}');
      debugPrint('[OrderStore] body: ${res.body}');

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        _reservations[offreId] = data.map((e) {
          final firstName = e['firstName']?.toString() ?? '';
          final surname   = e['surname']?.toString()   ?? '';
          final name      = '$firstName $surname'.trim();

          // ✅ URL complète pour la photo de profil
          String photoUrl = '';
          if (e['profilePhoto'] != null &&
              e['profilePhoto'].toString().isNotEmpty) {
            final p = e['profilePhoto'].toString();
            photoUrl = p.startsWith('http')
                ? p
                : '${ApiConfig.baseUrl}/$p';
          }

          return ReservationRecord(
            offerId:      e['ordreId']?.toString()    ?? '',
            offerTitle:   e['offerTitle']?.toString() ?? '',
            clientName:   name.isNotEmpty ? name : 'Client',
            clientId:     e['clientId']?.toString()   ?? '',
            profilePhoto: photoUrl,
            timeAgo:      e['createdAt']?.toString()  ?? '',
            price:        e['totalPrice'] != null
                ? '${e['totalPrice']} DA' : '',
            status: (e['status']?.toString() ?? 'pending').toLowerCase(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[OrderStore] fetchReservations error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  MERCHANT — PUT confirm / reject
  // ════════════════════════════════════════════════════════════
  Future<bool> updateReservationStatus({
    required String reservationId,
    required String newStatus,
  }) async {
    try {
      final token    = UserSession().token ?? '';
      final endpoint = newStatus == 'confirmed' ? 'confirm' : 'reject';
      final res = await http.put(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/ordres/$endpoint/$reservationId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      debugPrint('[OrderStore] updateReservation: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[OrderStore] updateReservation error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  CLIENT — PUT /api/ordres/cancel/{ordreId}
  // ════════════════════════════════════════════════════════════
  Future<bool> cancelClientOrder(String ordreId) async {
    try {
      final token = UserSession().token ?? '';
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/ordres/cancel/$ordreId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      debugPrint('[OrderStore] cancelOrder: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[OrderStore] cancelOrder error: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  CLIENT — PUT /api/ordres/complete/{ordreId}
  // ════════════════════════════════════════════════════════════
  Future<bool> confirmPickup(String ordreId) async {
    try {
      final token = UserSession().token ?? '';
      final res = await http.put(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/ordres/complete/$ordreId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      debugPrint('[OrderStore] confirmPickup: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[OrderStore] confirmPickup error: $e');
      return false;
    }
  }

  // ── Helper ────────────────────────────────────────────────────
  OrderStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':  return OrderStatus.confirmed;
      case 'cancelled':
      case 'canceled':   return OrderStatus.cancelled;
      case 'picked':
      case 'completed':  return OrderStatus.picked;
      default:           return OrderStatus.pending;
    }
  }
}