
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usersession.dart';
import 'my_offers.dart';   // pour le modèle Offer
import 'viewoffer.dart';   // pour naviguer vers une offre
import 'apiservice.dart';  // pour likeOffer / unlikeOffer / getOfferLikes

// ── URL de base ──────────────────────────────────────────────────────────────
const String _kBaseUrl = 'https://ethanol-hemstitch-strongbox.ngrok-free.dev'; // ← même base que ApiConfig

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
  final bool   isMerchant;     // ← nouveau : true = marchand, false = client simple

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
    this.isMerchant = true,    // par défaut on assume que c'est un marchand
    this.onContact,
  });

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  bool        _isLoading  = true;
  List<Offer> _offers     = [];
  int         _likesCount = 0;   // likes du profil marchand (j'adore la boutique)
  bool        _isLiked    = false;

  // Map offerId → { 'count': int, 'isLiked': bool, 'isLoading': bool }
  // Chaque offre a son propre état de like
  final Map<String, Map<String, dynamic>> _offerLikes = {};

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  // ── Charge les offres ET le nombre de likes du marchand ──────────
  //
  //  APIs utilisées :
  //  GET /api/offres/merchant/{merchantId}  → liste des offres
  //  GET /api/merchants/{merchantId}        → { "likesCount": 5, "isLikedByMe": true }
  // ─────────────────────────────────────────────────────────────────
  Future<void> _loadMerchantData() async {
    try {
      final token = UserSession().token;
      final headers = {
        'Content-Type'              : 'application/json',
        'Authorization'             : 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };

      // 1. Offres du marchand (uniquement si isMerchant)
      // GET /api/offres/merchant/{merchantId}
      if (widget.isMerchant) {
        final offersRes = await http.get(
          Uri.parse('$_kBaseUrl/api/offres/merchant/${widget.merchantId}'),
          headers: headers,
        );
        if (offersRes.statusCode == 200) {
          final List data = jsonDecode(offersRes.body);
          _offers = data.map((e) => Offer.fromJson(e)).toList();

          // Initialiser l'état des likes pour chaque offre
          for (final offer in _offers) {
            _offerLikes[offer.id] = {
              'count'    : 0,
              'isLiked'  : false,
              'isLoading': false,
            };
          }
        }
      }

      // 2. Infos du marchand (likes globaux de la boutique)
      // GET /api/merchants/{merchantId}
      final merchantRes = await http.get(
        Uri.parse('$_kBaseUrl/api/merchants/${widget.merchantId}'),
        headers: headers,
      );

      if (merchantRes.statusCode == 200) {
        final data = jsonDecode(merchantRes.body);
        _likesCount = (data['likesCount'] as num?)?.toInt() ?? 0;
        _isLiked    = data['isLikedByMe'] == true;
      }

      if (mounted) setState(() => _isLoading = false);

      // 3. Charger les likes de chaque offre en parallèle (après le premier rendu)
      //    GET /api/offres/{offerId}/likes → { "likesCount": 3, "isLikedByMe": false }
      if (widget.isMerchant && _offers.isNotEmpty) {
        _loadOfferLikes();
      }
    } catch (e) {
      debugPrint('[MerchantProfilePage] load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Charge les likes de chaque offre en parallèle ──────────────
  Future<void> _loadOfferLikes() async {
    await Future.wait(
      _offers.map((offer) async {
        final data = await ApiService.getOfferLikes(offer.id);
        if (data != null && mounted) {
          setState(() {
            _offerLikes[offer.id] = {
              'count'    : (data['likesCount'] as num?)?.toInt() ?? 0,
              'isLiked'  : data['isLikedByMe'] == true,
              'isLoading': false,
            };
          });
        }
      }),
    );
  }

  // ── Toggle like sur la boutique ────────────────────────────────
  //
  //  POST   /api/merchants/{merchantId}/like   → ajoute un like
  //  DELETE /api/merchants/{merchantId}/like   → retire le like
  // ─────────────────────────────────────────────────────────────────
  Future<void> _toggleMerchantLike() async {
    final token = UserSession().token;
    final url = Uri.parse('$_kBaseUrl/api/merchants/${widget.merchantId}/like');
    try {
      if (_isLiked) {
        await http.delete(url,
            headers: {
              'Authorization'             : 'Bearer $token',
              'ngrok-skip-browser-warning': 'true',
            });
        setState(() { _isLiked = false; _likesCount--; });
      } else {
        await http.post(url,
            headers: {
              'Authorization'             : 'Bearer $token',
              'ngrok-skip-browser-warning': 'true',
            });
        setState(() { _isLiked = true; _likesCount++; });
      }
    } catch (e) {
      debugPrint('[MerchantProfilePage] merchant like error: $e');
    }
  }

  // ── Toggle j'adore sur une offre spécifique ─────────────────────
  //
  //  POST   /api/offres/{offerId}/like   → ajoute le j'adore
  //  DELETE /api/offres/{offerId}/like   → retire le j'adore
  //  La réponse contient le nouveau compteur : { "likesCount": 5 }
  // ─────────────────────────────────────────────────────────────────
  Future<void> _toggleOfferLike(String offerId) async {
    final state = _offerLikes[offerId];
    if (state == null || state['isLoading'] == true) return;

    // Optimistic UI — mise à jour immédiate
    setState(() {
      _offerLikes[offerId]!['isLoading'] = true;
      _offerLikes[offerId]!['isLiked']   = !state['isLiked'];
      _offerLikes[offerId]!['count']     =
      state['isLiked'] ? state['count'] - 1 : state['count'] + 1;
    });

    // Appel API
    final ApiResponse<int> result = state['isLiked']
        ? await ApiService.unlikeOffer(offerId)  // isLiked = true → on était aimé → unlike
        : await ApiService.likeOffer(offerId);   // isLiked = false → on n'aimait pas → like

    if (!mounted) return;

    setState(() {
      _offerLikes[offerId]!['isLoading'] = false;
      if (result.success && result.data != null) {
        // Utiliser le compteur retourné par le backend (source de vérité)
        _offerLikes[offerId]!['count'] = result.data;
      } else {
        // Rollback en cas d'erreur
        _offerLikes[offerId]!['isLiked'] = state['isLiked'];
        _offerLikes[offerId]!['count']   = state['count'];
      }
    });
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
          // ── Header marchand ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMerchantHeader(),
            ),
          ),

          // ── Section offres (marchands uniquement) ────────────
          if (widget.isMerchant) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_outlined,
                        color: Color(0xFF72A843), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      // Compteur dynamique — augmente à chaque nouvelle offre ajoutée
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

            // ── Grille des offres ─────────────────────────────
            _offers.isEmpty
                ? SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'No offers yet',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
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
                  crossAxisCount  : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing : 12,
                  childAspectRatio: 0.65, // légèrement plus haut pour loger les likes
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildOfferCard(_offers[index]),
                  childCount: _offers.length,
                ),
              ),
            ),
          ],

          // ── Message pour les clients (pas marchands) ─────────
          if (!widget.isMerchant)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.person_outline,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'This user is a client',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No offers to display.',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── Header avec avatar, likes, badge merchant, bouton contacter ──
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
                backgroundColor: const Color(0xFF72A843).withOpacity(0.15),
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
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),

                    // ── Badge Merchant / Client ───────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.isMerchant
                            ? const Color(0xFF72A843).withOpacity(0.12)
                            : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isMerchant
                                ? Icons.store_outlined
                                : Icons.person_outline,
                            size: 12,
                            color: widget.isMerchant
                                ? const Color(0xFF72A843)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isMerchant ? 'Merchant' : 'Client',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isMerchant
                                  ? const Color(0xFF72A843)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Wilaya + catégorie
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${widget.wilaya} • ${widget.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Likes de la boutique (bouton cœur + compteur) ────
              Column(
                children: [
                  GestureDetector(
                    onTap: _toggleMerchantLike,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(_isLiked),
                        color: _isLiked ? Colors.red : Colors.grey,
                        size: 26,
                      ),
                    ),
                  ),
                  Text(
                    '$_likesCount',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const Text('likes',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),

          // ── Stats bar (publications) — marchands uniquement ──────
          if (widget.isMerchant) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStat('${_offers.length}', 'Publications'),
                  Container(
                    height: 30,
                    width: 1,
                    color: const Color(0xFFD0E6A5),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  _buildStat('$_likesCount', 'Likes'),
                ],
              ),
            ),
          ],

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

  // ── Stat item dans la barre de stats ────────────────────────────
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // ── Card d'une offre avec son compteur de j'adore ───────────────
  Widget _buildOfferCard(Offer offer) {
    final isNetwork    = offer.imageUrl.startsWith('http');
    final likeState    = _offerLikes[offer.id];
    final likeCount    = likeState?['count']     as int?  ?? 0;
    final isOfferLiked = likeState?['isLiked']   as bool? ?? false;
    final isLoading    = likeState?['isLoading']  as bool? ?? false;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewOfferPage(
            offerId:       offer.id, 
            title         : offer.title,
            description   : offer.description,
            location      : offer.location,
            price         : offer.price,
            imageUrl      : offer.imageUrl.isNotEmpty
                ? offer.imageUrl
                : 'https://via.placeholder.com/150',
            availableUntil: offer.availableUntil,
            status        : offer.status,
            quantity      : offer.quantity,
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
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
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

            // Infos + likes
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
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

                  // Prix
                  Text(
                    offer.price,
                    style: const TextStyle(
                      color: Color(0xFF72A843),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Badge statut
                  Container(
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

                  const SizedBox(height: 6),

                  // ── J'adore (compteur + bouton toggle) ──────────
                  //
                  //  Appelle ApiService.likeOffer / unlikeOffer
                  //  Le compteur se met à jour optimistiquement
                  //  puis est confirmé par la réponse du backend.
                  // ──────────────────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => _toggleOfferLike(offer.id),
                        child: isLoading
                            ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.red,
                          ),
                        )
                            : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isOfferLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey(isOfferLiked),
                            color: isOfferLiked
                                ? Colors.red
                                : Colors.grey,
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
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