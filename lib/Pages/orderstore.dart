// lib/order_store.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'order_item.dart';
import 'usersession.dart';

class ReservationRecord {
  final String offerId;
  final String offerTitle;
  final String clientName;
  final String timeAgo;
  String status;

  ReservationRecord({
    required this.offerId,
    required this.offerTitle,
    required this.clientName,
    required this.timeAgo,
    this.status = 'pending',
  });
}

class OrderStore {
  OrderStore._();
  static final OrderStore instance = OrderStore._();

  static const String _baseUrl = 'https://ton-api.com'; // ← remplace par ton URL

  final List<OrderItem> clientOrders = [];
  final Map<String, List<ReservationRecord>> reservationsByOffer = {};

  // ── POST : envoie la réservation à l'API ──────────────────────────────────
  Future<void> addClientOrder(OrderItem order) async {
    clientOrders.insert(0, order); // affichage local immédiat

    try {
      await http.post(
        Uri.parse('$_baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserSession().token}',
        },
        body: jsonEncode({
          'title':           order.title,
          'merchant_name':   order.merchantName,
          'pickup_location': order.pickupLocation,
          'pickup_time':     order.pickupTime,
          'price':           order.price,
          'status':          order.status.name,
          'image_path':      order.imagePath ?? '',
        }),
      );
    } catch (_) {
      // silently fail — l'order est déjà affiché localement
    }
  }

  // ── GET : charge les orders depuis l'API ──────────────────────────────────
  Future<void> fetchClientOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/orders'),
        headers: {
          'Authorization': 'Bearer ${UserSession().token}',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        clientOrders.clear();
        clientOrders.addAll(data.map((e) => OrderItem(
          title:          e['title'] ?? '',
          merchantName:   e['merchant_name'] ?? '',
          pickupLocation: e['pickup_location'] ?? '',
          pickupTime:     e['pickup_time'],
          price:          e['price'] ?? '',
          status:         _parseStatus(e['status']),
          imagePath:      e['image_path'],
        )));
      }
    } catch (_) {
      // garde les données locales si l'API échoue
    }
  }

  OrderStatus _parseStatus(String? s) {
    switch (s) {
      case 'confirmed': return OrderStatus.confirmed;
      case 'cancelled': return OrderStatus.cancelled;
      case 'picked':    return OrderStatus.picked;
      default:          return OrderStatus.pending;
    }
  }

  void updateClientOrderStatus(int index, OrderStatus newStatus) {
    if (index < 0 || index >= clientOrders.length) return;
    final old = clientOrders[index];
    clientOrders[index] = OrderItem(
      title:          old.title,
      merchantName:   old.merchantName,
      pickupLocation: old.pickupLocation,
      pickupTime:     old.pickupTime,
      price:          old.price,
      status:         newStatus,
      imagePath:      old.imagePath,
    );
  }

  void addReservation(ReservationRecord record) {
    reservationsByOffer
        .putIfAbsent(record.offerId, () => [])
        .insert(0, record);
  }

  List<ReservationRecord> getReservations(String offerId) {
    return reservationsByOffer[offerId] ?? [];
  }
}