import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usersession.dart';
import 'apiservice.dart';

class FavoriStore extends ChangeNotifier {
  FavoriStore._();
  static final FavoriStore _instance = FavoriStore._();
  factory FavoriStore() => _instance;

  final Set<String> _favoriIds = {};
  String? _loadedForUserId;

  Set<String> get favoriIds => Set.unmodifiable(_favoriIds);

  bool isFavori(String offreId) {
    final id = offreId.trim().replaceAll('.0', '');
    return _favoriIds.any((e) => e.trim() == id);
  }

  // ══════════════════════════════════════════════
  //  GET /api/favoris/my
  // ══════════════════════════════════════════════
  Future<void> loadMyFavoris() async {
    final currentUserId = UserSession().id;

    if (currentUserId == null || currentUserId.isEmpty) {
      _favoriIds.clear();
      _loadedForUserId = null;
      notifyListeners();
      return;
    }

    if (_loadedForUserId != null && _loadedForUserId != currentUserId) {
      _favoriIds.clear();
    }

    try {
      final token = UserSession().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/favoris/my'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('[FavoriStore] status: ${res.statusCode}');
      debugPrint('[FavoriStore] RAW: ${res.body}');

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _favoriIds.clear();

        for (final e in data) {
          // ✅ Essaie tous les noms de champs possibles
          final raw = e['offreId'] ??
              e['offre_id'] ??
              e['OffreId'] ??
              e['offerId'] ??
              e['id'] ??
              '';

          final offreId = raw
              .toString()
              .trim()
              .replaceAll('.0', '');

          debugPrint('[FavoriStore] item: $e → offreId: "$offreId"');

          if (offreId.isNotEmpty && offreId != '0') {
            _favoriIds.add(offreId);
          }
        }

        debugPrint('[FavoriStore] favoris chargés: $_favoriIds');
        _loadedForUserId = currentUserId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[FavoriStore] loadMyFavoris error: $e');
    }
  }

  // ══════════════════════════════════════════════
  //  POST /api/favoris/toggle/{offreId}
  // ══════════════════════════════════════════════
  Future<void> toggleFavori(String offreId) async {
  final token = UserSession().token;
  if (token == null) return;

  final cleanId = offreId.trim().replaceAll('.0', '');
  final wasAdded = _favoriIds.any((e) => e.trim() == cleanId);

  // ✅ Update optimiste immédiat
  if (wasAdded) {
    _favoriIds.removeWhere((e) => e.trim() == cleanId);
  } else {
    _favoriIds.add(cleanId);
  }
  notifyListeners();

  try {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/favoris/toggle/$cleanId'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    debugPrint('[FavoriStore] toggle status: ${res.statusCode}');
    debugPrint('[FavoriStore] toggle body: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      // ✅ Synchronise avec ce que le backend dit réellement
      final isFavoriNow = data['isFavori'] as bool? ?? !wasAdded;

      debugPrint('[FavoriStore] backend isFavori: $isFavoriNow');

      // ✅ Force l'état selon le backend — source de vérité
      if (isFavoriNow) {
        _favoriIds.add(cleanId);
      } else {
        _favoriIds.removeWhere((e) => e.trim() == cleanId);
      }
      notifyListeners();
    } else {
      // ✅ Rollback si erreur
      if (wasAdded) {
        _favoriIds.add(cleanId);
      } else {
        _favoriIds.removeWhere((e) => e.trim() == cleanId);
      }
      notifyListeners();
    }
  } catch (e) {
    debugPrint('[FavoriStore] toggle error: $e');
    // ✅ Rollback si exception
    if (wasAdded) {
      _favoriIds.add(cleanId);
    } else {
      _favoriIds.removeWhere((e) => e.trim() == cleanId);
    }
    notifyListeners();
  }
}

  // ✅ Appelé au logout
  void clear() {
    _favoriIds.clear();
    _loadedForUserId = null;
    notifyListeners();
  }
}