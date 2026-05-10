// lib/offer_store.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'my_offers.dart';
import 'usersession.dart';

class OfferStore {
  // ── Toutes les offres (homepage) ─────────────────────────────────
  static List<Offer> offers = [];

  // ── Offres du marchand connecté (MyOffersPage) ───────────────────
  static List<Offer> myOffers = [];

  static const String _baseUrl = 'https://headstand-rosy-chlorine.ngrok-free.dev';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${UserSession().token ?? ''}',
  };

  // ─────────────────────────────────────────────────────────────────
  //  Toutes les offres — GET /api/offres/available
  // ─────────────────────────────────────────────────────────────────
  static Future<void> fetchOffers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/offres/available'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        offers = data.map((e) => Offer.fromJson(e)).toList();
      } else if (response.statusCode == 401) {
        debugPrint('[OfferStore] Token expiré ou invalide');
      } else {
        debugPrint('[OfferStore] fetchOffers error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OfferStore] fetchOffers exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Offres du marchand connecté — GET /api/offres/marchand/{id}
  // ─────────────────────────────────────────────────────────────────
  static Future<void> fetchMyOffers() async {
    try {
      final userId = UserSession().id;
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('$_baseUrl/api/offres/marchand/$userId'),
        headers: _headers,
      );

      debugPrint('[OfferStore] fetchMyOffers status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        myOffers = data.map((e) => Offer.fromJson(e)).toList();
        debugPrint('[OfferStore] myOffers count: ${myOffers.length}');
      } else {
        debugPrint('[OfferStore] fetchMyOffers error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OfferStore] fetchMyOffers exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Offres d'un marchand spécifique
  // ─────────────────────────────────────────────────────────────────
  static Future<List<Offer>> fetchOffersByMerchantId(int merchantId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/offres/merchant/$merchantId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Offer.fromJson(e)).toList();
      } else {
        debugPrint('[OfferStore] fetchByMerchant error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[OfferStore] fetchByMerchant exception: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Crée une offre — POST /api/offres/create (multipart)
  // ─────────────────────────────────────────────────────────────────
  static Future<Offer?> createOffer(
    Map<String, dynamic> data, {
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/offres/create'),
      );
      request.headers['Authorization'] = 'Bearer ${UserSession().token ?? ''}';

      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: imageFilename ?? 'offer_image.jpg',
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          if (jsonData is Map<String, dynamic>) {
            final newOffer = Offer.fromJson(jsonData);
            myOffers.insert(0, newOffer);
            return newOffer;
          }
        } catch (_) {}
        return Offer(
          id: '', title: '', price: '0 DA', available: 'Yes',
          location: '', status: 'active', imageUrl: '',
          description: '', quantity: '0', availableUntil: '', type: '',
        );
      } else {
        debugPrint('[OfferStore] createOffer error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[OfferStore] createOffer exception: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Supprime une offre — DELETE /api/offres/delete/{offerId}
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> deleteOffer(String offerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/offres/delete/$offerId'),
        headers: _headers,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        myOffers.removeWhere((o) => o.id == offerId);
        offers.removeWhere((o) => o.id == offerId);
        return true;
      } else {
        debugPrint('[OfferStore] deleteOffer error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[OfferStore] deleteOffer exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Modifie une offre — PUT /api/offres/update/{offerId}
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> updateOffer(
    String offerId,
    Map<String, dynamic> offerData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/offres/update/$offerId'),
        headers: _headers,
        body: json.encode(offerData),
      );
      if (response.statusCode == 200) {
        await fetchMyOffers();
        return true;
      } else {
        debugPrint('[OfferStore] updateOffer error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[OfferStore] updateOffer exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Modifie une offre avec image
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> updateOfferWithImage(
    String offerId,
    Map<String, dynamic> offerData,
    Uint8List imageBytes,
    String imageFilename,
  ) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/api/offres/update/$offerId'),
      );
      request.headers['Authorization'] = 'Bearer ${UserSession().token ?? ''}';
      offerData.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFilename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await fetchMyOffers();
        return true;
      } else {
        debugPrint('[OfferStore] updateOfferWithImage error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[OfferStore] updateOfferWithImage exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Archive une offre — PUT /api/offres/archive/{offreId}
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> archiveOffer(String offerId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/offres/archive/$offerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        myOffers.removeWhere((o) => o.id == offerId);
        offers.removeWhere((o) => o.id == offerId);
        return true;
      } else {
        debugPrint('[OfferStore] archiveOffer error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[OfferStore] archiveOffer exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Réactive une offre — PUT /api/offres/update/{offreId}
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> reactivateOffer(String offerId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/offres/update/$offerId'),
        headers: {
          'Authorization': 'Bearer ${UserSession().token ?? ''}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'status=ACTIVE',
      );

      if (response.statusCode == 200) {
        final index = myOffers.indexWhere((o) => o.id == offerId);
        if (index != -1) {
          final old = myOffers[index];
          myOffers[index] = Offer(
            id:             old.id,
            title:          old.title,
            price:          old.price,
            available:      old.available,
            location:       old.location,
            status:         'active',
            imageUrl:       old.imageUrl,
            description:    old.description,
            quantity:       old.quantity,
            availableUntil: old.availableUntil,
            type:           old.type,
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[OfferStore] reactivateOffer error: $e');
      return false;
    }
  }
}