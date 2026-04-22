/*import 'my_offers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'usersession.dart'; // ← pour récupérer le token JWT
import 'dart:io';

class OfferStore {
  static List<Offer> offers = [];

  // ── URL de base de ton a serveur ──────────────────────────────
  static const String _baseUrl = 'https://ethanol-hemstitch-strongbox.ngrok-free.dev';

  // ── Récupérer toutes les offres ─────────────────────────────
  static Future<void> fetchOffers() async {
    final url = Uri.parse('$_baseUrl/api/offres/all'); // ← adapte l'endpoint

    try {
      final token = UserSession().token; // ton JWT stocké dans la session

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ← JWT envoyé ici
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        offers = data.map((e) => Offer.fromJson(e)).toList();
      } else if (response.statusCode == 401) {
        debugPrint('Token expiré ou invalide');
        // tu peux rediriger vers login ici si besoin
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    }
  }

  // ── Créer une nouvelle offre ────────────────────────────────
  static Future<Offer?> createOffer(Map<String, dynamic> data, {File? image}) async {
    final url = Uri.parse('$_baseUrl/api/offres/create');
    final token = UserSession().token;

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Champs texte
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Image (optionnelle)
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final newOffer = Offer.fromJson(json); // ← id réel retourné par Spring Boot
        offers.insert(0, newOffer);
        return newOffer;
      } else {
        debugPrint('Create error: ${response.statusCode} — ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Create error: $e');
      return null;
    }
  }

  // ── Supprimer une offre ─────────────────────────────────────
  static Future<bool> deleteOffer(String offerId) async {
    final url = Uri.parse('$_baseUrl/api/offres/delete$offerId');

    try {
      final token = UserSession().token;

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        offers.removeWhere((o) => o.id == offerId);
        return true;
      } else {
        debugPrint('Delete error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  // ── Modifier une offre ──────────────────────────────────────
  static Future<bool> updateOffer(String offerId, Map<String, dynamic> offerData) async {
    final url = Uri.parse('$_baseUrl/api/offres/update $offerId');

    try {
      final token = UserSession().token;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(offerData),
      );

      if (response.statusCode == 200) {
        await fetchOffers();
        return true;
      } else {
        debugPrint('Update error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Update error: $e');
      return false;
    }
  }
} */


// lib/offer_store.dart
//
// ─── CORRECTIONS ───────────────────────────────────────────────────────────────
// • BUG CORRIGÉ : URL delete avait un espace → '/api/offres/delete$offerId'
//   au lieu de '/api/offres/delete/$offerId'  (slash manquant + espace en trop)
// • BUG CORRIGÉ : URL update avait un espace → '/api/offres/update $offerId'
//   corrigé en '/api/offres/update/$offerId'
// • Ajout de fetchMerchantOffers() → récupère uniquement les offres du marchand connecté
// • Ajout de fetchOffersByMerchantId() → pour la page profil marchand
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'my_offers.dart';
import 'usersession.dart';

class OfferStore {
  static List<Offer> offers = [];

  // ── URL de base ──────────────────────────────────────────────────
  static const String _baseUrl =
      'https://ton-api.ngrok-free.dev'; // ← à changer

  // ── Headers communs ──────────────────────────────────────────────
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${UserSession().token}',
  };

  // ─────────────────────────────────────────────────────────────────
  //  Récupère TOUTES les offres (page accueil / recherche)
  //  GET /api/offres/all
  // ─────────────────────────────────────────────────────────────────
  static Future<void> fetchOffers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/offres/all'),
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
  //  Récupère uniquement les offres DU MARCHAND CONNECTÉ (page My Offers)
  //  GET /api/offres/my
  // ─────────────────────────────────────────────────────────────────
  static Future<void> fetchMyOffers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/offres/my'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        offers = data.map((e) => Offer.fromJson(e)).toList();
      } else {
        debugPrint('[OfferStore] fetchMyOffers error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OfferStore] fetchMyOffers exception: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Récupère les offres d'un marchand spécifique (page profil marchand)
  //  GET /api/offres/merchant/{merchantId}
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
  //  Crée une nouvelle offre (avec image optionnelle)
  //  POST /api/offres/create  (multipart)
  // ─────────────────────────────────────────────────────────────────
  static Future<Offer?> createOffer(
      Map<String, dynamic> data, {
        File? image,
      }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/offres/create'),
      );
      request.headers['Authorization'] = 'Bearer ${UserSession().token}';

      // Champs texte
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Image (optionnelle)
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final newOffer = Offer.fromJson(jsonData);
        offers.insert(0, newOffer); // ajout en tête de liste
        return newOffer;
      } else {
        debugPrint('[OfferStore] createOffer error: ${response.statusCode} — ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[OfferStore] createOffer exception: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Supprime une offre
  //  DELETE /api/offres/delete/{offerId}
  //  BUG CORRIGÉ : il manquait le slash et il y avait un espace
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> deleteOffer(String offerId) async {
    try {
      final response = await http.delete(
        // ← CORRIGÉ : 'delete/$offerId' au lieu de 'delete$offerId'
        Uri.parse('$_baseUrl/api/offres/delete/$offerId'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
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
  //  Modifie une offre (JSON simple, sans image)
  //  PUT /api/offres/update/{offerId}
  //  BUG CORRIGÉ : 'update $offerId' → 'update/$offerId'
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> updateOffer(
      String offerId,
      Map<String, dynamic> offerData,
      ) async {
    try {
      final response = await http.put(
        // ← CORRIGÉ : 'update/$offerId' au lieu de 'update $offerId'
        Uri.parse('$_baseUrl/api/offres/update/$offerId'),
        headers: _headers,
        body: json.encode(offerData),
      );

      if (response.statusCode == 200) {
        // Rafraîchit la liste locale
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
  //  Modifie une offre AVEC une nouvelle image (multipart)
  //  PUT /api/offres/update/{offerId}  (multipart)
  // ─────────────────────────────────────────────────────────────────
  static Future<bool> updateOfferWithImage(
      String offerId,
      Map<String, dynamic> offerData,
      File image,
      ) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/api/offres/update/$offerId'),
      );
      request.headers['Authorization'] = 'Bearer ${UserSession().token}';
      offerData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
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
}