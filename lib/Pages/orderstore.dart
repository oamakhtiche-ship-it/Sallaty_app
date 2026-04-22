/*// lib/order_store.dart
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
} */


// lib/orderstore.dart
//
// ─── CORRECTIONS ───────────────────────────────────────────────────────────────
// • Ajout du champ `price` dans ReservationRecord  ← CORRIGE le bug "price isn't defined"
// • Ajout des champs `offerImageUrl` et `quantity` pour les stats et l'UI
// • fetchClientOrders() + fetchMerchantReservations() connectés à l'API
// • updateReservationStatus() envoie le nouveau statut au backend
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'order_item.dart';
import 'usersession.dart';

// ── URL de base — remplace par ton URL ngrok / production ────────────────────
const String _kBaseUrl = 'https://ton-api.ngrok-free.dev'; // ← à changer

// ─────────────────────────────────────────────────────────────────────────────
//  ReservationRecord — représente une réservation reçue par un marchand
// ─────────────────────────────────────────────────────────────────────────────
class ReservationRecord {
  final String offerId;       // id de l'offre côté backend
  final String offerTitle;    // titre de l'offre
  final String clientName;    // nom du client
  final String timeAgo;       // ex : "2h ago"
  String status;              // 'pending' | 'confirmed' | 'canceled'

  // ── CHAMP MANQUANT — causait l'erreur "price isn't defined" ─────────────
  final String price;         // prix de l'offre (ex : "500 DA")
  final String offerImageUrl; // image de l'offre (optionnel, pour l'historique)
  final int    quantity;      // quantité réservée

  ReservationRecord({
    required this.offerId,
    required this.offerTitle,
    required this.clientName,
    required this.timeAgo,
    this.status = 'pending',
    this.price = '',           // ← valeur par défaut pour ne pas casser l'existant
    this.offerImageUrl = '',
    this.quantity = 1,
  });

  // ── Construit un ReservationRecord depuis la réponse JSON du backend ────
  // Adapte les clés JSON selon ce que ton backend Spring Boot renvoie
  factory ReservationRecord.fromJson(Map<String, dynamic> json) {
    return ReservationRecord(
      offerId:       json['offerId']?.toString()    ?? '',
      offerTitle:    json['offerTitle']             ?? '',
      clientName:    json['clientName']             ?? '',
      timeAgo:       json['timeAgo']                ?? '',
      status:        json['status']                 ?? 'pending',
      price:         json['price']?.toString()      ?? '',  // ← clé backend
      offerImageUrl: json['offerImageUrl']          ?? '',
      quantity:      (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OrderStore — singleton global
// ─────────────────────────────────────────────────────────────────────────────
class OrderStore {
  OrderStore._();
  static final OrderStore instance = OrderStore._();

  // ── Données en mémoire ───────────────────────────────────────────────────
  final List<OrderItem> clientOrders = [];

  // offerId → liste de réservations (vue marchand)
  final Map<String, List<ReservationRecord>> reservationsByOffer = {};

  // ── Helper header ────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${UserSession().token}',
  };

  // ─────────────────────────────────────────────────────────────────────────
  //  CLIENT : récupère ses commandes depuis le backend
  //  GET /api/orders/my
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> fetchClientOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$_kBaseUrl/api/orders/my'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        clientOrders
          ..clear()
          ..addAll(data.map((e) => OrderItem(
            title:          e['title']           ?? '',
            merchantName:   e['merchantName']     ?? '',
            pickupLocation: e['pickupLocation']   ?? '',
            pickupTime:     e['pickupTime'],
            price:          e['price']?.toString() ?? '',
            status:         _parseStatus(e['status']),
            imagePath:      e['imageUrl'],
          )));
      } else {
        debugPrint('[OrderStore] fetchClientOrders error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OrderStore] fetchClientOrders exception: $e');
      // garde les données locales si le réseau échoue
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CLIENT : ajoute une commande (localement + envoie au backend)
  //  POST /api/orders
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> addClientOrder(OrderItem order) async {
    clientOrders.insert(0, order); // affichage optimiste immédiat

    try {
      await http.post(
        Uri.parse('$_kBaseUrl/api/orders'),
        headers: _headers,
        body: jsonEncode({
          'title':           order.title,
          'merchantName':    order.merchantName,
          'pickupLocation':  order.pickupLocation,
          'pickupTime':      order.pickupTime,
          'price':           order.price,
          'status':          order.status.name,
          'imageUrl':        order.imagePath ?? '',
        }),
      );
    } catch (e) {
      debugPrint('[OrderStore] addClientOrder exception: $e');
      // l'order est déjà visible localement — pas de rollback pour l'instant
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MARCHAND : récupère les réservations d'une offre
  //  GET /api/reservations?offerId={offerId}
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> fetchMerchantReservations(String offerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_kBaseUrl/api/reservations?offerId=$offerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        reservationsByOffer[offerId] = data
            .map((e) => ReservationRecord.fromJson(e))
            .toList();
      } else {
        debugPrint('[OrderStore] fetchReservations error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OrderStore] fetchReservations exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MARCHAND : confirme ou rejette une réservation
  //  PATCH /api/reservations/{reservationId}/status
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> updateReservationStatus({
    required String reservationId,
    required String newStatus, // 'confirmed' ou 'canceled'
  }) async {
    try {
      await http.patch(
        Uri.parse('$_kBaseUrl/api/reservations/$reservationId/status'),
        headers: _headers,
        body: jsonEncode({'status': newStatus}),
      );
    } catch (e) {
      debugPrint('[OrderStore] updateReservationStatus exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MARCHAND : récupère TOUTES ses réservations (pour statistiques)
  //  GET /api/reservations/merchant/all
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> fetchAllMerchantReservations() async {
    try {
      final response = await http.get(
        Uri.parse('$_kBaseUrl/api/reservations/merchant/all'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        reservationsByOffer.clear();
        for (final e in data) {
          final record = ReservationRecord.fromJson(e);
          reservationsByOffer
              .putIfAbsent(record.offerId, () => [])
              .add(record);
        }
      } else {
        debugPrint('[OrderStore] fetchAllMerchantReservations error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OrderStore] fetchAllMerchantReservations exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Mise à jour locale du statut d'une commande client (UI only)
  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  //  Ajoute une réservation localement (utilisé depuis ViewOfferPage)
  // ─────────────────────────────────────────────────────────────────────────
  void addReservation(ReservationRecord record) {
    reservationsByOffer
        .putIfAbsent(record.offerId, () => [])
        .insert(0, record);
  }

  // Retourne les réservations d'une offre (vue locale)
  List<ReservationRecord> getReservations(String offerId) {
    return reservationsByOffer[offerId] ?? [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Parse le statut depuis une chaîne JSON
  // ─────────────────────────────────────────────────────────────────────────
  OrderStatus _parseStatus(String? s) {
    switch (s) {
      case 'confirmed': return OrderStatus.confirmed;
      case 'cancelled': return OrderStatus.cancelled;
      case 'picked':    return OrderStatus.picked;
      default:          return OrderStatus.pending;
    }
  }
}