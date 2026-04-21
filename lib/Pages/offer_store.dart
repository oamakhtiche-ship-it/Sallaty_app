import 'my_offers.dart';
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
}