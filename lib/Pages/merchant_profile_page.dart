// lib/merchant_profile_page.dart
//
// ─── NOUVEAU FICHIER ────────────────────────────────────────────────────────────
// • Page profil marchand affichée quand on tape sur une card dans la recherche
// • Affiche : avatar, nom boutique, wilaya, catégorie, likes réels, offres réelles
// • Bouton "Contacter" pour ouvrir le chat
// • Toutes les offres du marchand sont listées (depuis l'API)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usersession.dart';
import 'my_offers.dart';   // pour le modèle Offer
import 'viewoffer.dart';   // pour naviguer vers une offre

// ── URL de base ──────────────────────────────────────────────────────────────
const String _kBaseUrl = 'https://ton-api.ngrok-free.dev'; // ← à changer

// ─────────────────────────────────────────────────────────────────────────────
//  MerchantProfilePage
// ─────────────────────────────────────────────────────────────────────────────
class MerchantProfilePage extends StatefulWidget {
  final int    merchantId;
  final String merchantName;   // nom complet
  final String shopName;
  final String avatarUrl;
  final String wilaya;
  final String category;
  final bool   isVerified;

  // Callback pour contacter le marchand (ouvre le chat)
  final VoidCallback? onContact;

  const MerchantProfilePage({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.shopName,
    required this.avatarUrl,
    required this.wilaya,
    required this.category,
    required this.isVerified,
    this.onContact,
  });

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  bool _isLoading = true;
  List<Offer> _offers = [];
  int  _likesCount    = 0;
  bool _isLiked       = false; // si l'utilisateur courant a liké ce marchand

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  // ── Charge les offres ET le nombre de likes du marchand ──────────
  Future<void> _loadMerchantData() async {
    try {
      final token = UserSession().token;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 1. Offres du marchand
      // GET /api/offres/merchant/{merchantId}
      final offersRes = await http.get(
        Uri.parse('$_kBaseUrl/api/offres/merchant/${widget.merchantId}'),
        headers: headers,
      );

      // 2. Infos du marchand (likes, etc.)
      // GET /api/merchants/{merchantId}
      final merchantRes = await http.get(
        Uri.parse('$_kBaseUrl/api/merchants/${widget.merchantId}'),
        headers: headers,
      );

      if (mounted) {
        setState(() {
          if (offersRes.statusCode == 200) {
            final List data = jsonDecode(offersRes.body);
            _offers = data.map((e) => Offer.fromJson(e)).toList();
          }
          if (merchantRes.statusCode == 200) {
            final data = jsonDecode(merchantRes.body);
            _likesCount = (data['likesCount'] as num?)?.toInt() ?? 0;
            _isLiked    = data['isLikedByMe'] == true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MerchantProfilePage] load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Toggle like ──────────────────────────────────────────────────
  // POST /api/merchants/{merchantId}/like   → ajoute un like
  // DELETE /api/merchants/{merchantId}/like → retire le like
  Future<void> _toggleLike() async {
    final token = UserSession().token;
    final url = Uri.parse('$_kBaseUrl/api/merchants/${widget.merchantId}/like');
    try {
      if (_isLiked) {
        await http.delete(url,
            headers: {'Authorization': 'Bearer $token'});
        setState(() { _isLiked = false; _likesCount--; });
      } else {
        await http.post(url,
            headers: {'Authorization': 'Bearer $token'});
        setState(() { _isLiked = true; _likesCount++; });
      }
    } catch (e) {
      debugPrint('[MerchantProfilePage] like error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FFF4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.shopName,
          style: const TextStyle(
            color: Color(0xFF72A843),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF72A843)),
      )
          : CustomScrollView(
        slivers: [
          // ── Header marchand ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMerchantHeader(),
            ),
          ),

          // ── Titre section offres ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined,
                      color: Color(0xFF72A843), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Offers (${_offers.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Liste des offres ─────────────────────────────
          _offers.isEmpty
              ? SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'No offers yet',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          )
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 0.70,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                    _buildOfferCard(_offers[index]),
                childCount: _offers.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── Header avec avatar, likes, catégorie, bouton contacter ──────
  Widget _buildMerchantHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 36,
                backgroundColor:
                const Color(0xFF72A843).withOpacity(0.15),
                backgroundImage: widget.avatarUrl.isNotEmpty
                    ? NetworkImage(widget.avatarUrl)
                    : null,
                child: widget.avatarUrl.isEmpty
                    ? Text(
                  widget.shopName.isNotEmpty
                      ? widget.shopName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF72A843),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 14),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom boutique + badge vérifié
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.shopName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (widget.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 16, color: Color(0xFF72A843)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Nom du gérant
                    Text(
                      widget.merchantName,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    // Wilaya + catégorie
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.wilaya} • ${widget.category}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Likes (bouton cœur avec compteur)
              Column(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(_isLiked),
                        color: _isLiked
                            ? Colors.red
                            : Colors.grey,
                        size: 26,
                      ),
                    ),
                  ),
                  Text(
                    '$_likesCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Text(
                    'likes',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bouton Contacter
          if (widget.onContact != null)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: widget.onContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF72A843),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Colors.white, size: 16),
                label: const Text(
                  'Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Card d'une offre du marchand ─────────────────────────────────
  Widget _buildOfferCard(Offer offer) {
    final isNetwork = offer.imageUrl.startsWith('http');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewOfferPage(
            title:          offer.title,
            description:    offer.description,
            location:       offer.location,
            price:          offer.price,
            imageUrl:       offer.imageUrl.isNotEmpty
                ? offer.imageUrl
                : 'https://via.placeholder.com/150',
            availableUntil: offer.availableUntil,
            status:         offer.status,
            quantity:       offer.quantity,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              child: isNetwork
                  ? Image.network(offer.imageUrl,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover)
                  : Image.file(File(offer.imageUrl),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover),
            ),
            // Infos
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    offer.price,
                    style: const TextStyle(
                      color: Color(0xFF72A843),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  // Badge statut
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: offer.status == 'active'
                          ? const Color(0xFF72A843).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      offer.status == 'active'
                          ? 'Available'
                          : offer.status == 'soldout'
                          ? 'Sold out'
                          : 'Expired',
                      style: TextStyle(
                        fontSize: 9,
                        color: offer.status == 'active'
                            ? const Color(0xFF72A843)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}