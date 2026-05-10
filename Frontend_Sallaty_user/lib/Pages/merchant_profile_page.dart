import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usersession.dart';
import 'my_offers.dart';
import 'viewoffer.dart';
import 'apiservice.dart';
import 'network_image_widget.dart';
import 'chat.dart';
import 'conversation.dart';

const String _kBaseUrl = 'https://headstand-rosy-chlorine.ngrok-free.dev';

// ─────────────────────────────────────────────────────────────────────────────
//  MerchantProfilePage
// ─────────────────────────────────────────────────────────────────────────────
class MerchantProfilePage extends StatefulWidget {
  final int         merchantId;   // ← c'est le marchandId (table marchands)
  final String      merchantName;
  final String      shopName;
  final String      avatarUrl;
  final String      wilaya;
  final String      category;
  final bool        isVerified;
  final bool        isMerchant;
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
    this.isMerchant = true,
    this.onContact,
  });

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool        _isLoading      = true;
  bool        _isFollowLoading = false;  // ← protection double-tap
  List<Offer> _offers         = [];
  int         _likesCount     = 0;
  int         _followersCount = 0;
  bool        _isLiked        = false;
  bool        _isFollowing    = false;
  String      _bio            = '';
  String      _realAvatarUrl  = '';
  String      _realShopName   = '';
  String      _realName       = '';
  String      _realWilaya     = '';
  String      _realCategory   = '';
  bool        _realVerified   = false;

  final Map<String, Map<String, dynamic>> _offerLikes = {};

  // ── Helpers ────────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type'              : 'application/json',
    'Authorization'             : 'Bearer ${UserSession().token ?? ''}',
    'ngrok-skip-browser-warning': 'true',
  };

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _realAvatarUrl = widget.avatarUrl;
    _realShopName  = widget.shopName;
    _realName      = widget.merchantName;
    _realWilaya    = widget.wilaya;
    _realCategory  = widget.category;
    _realVerified  = widget.isVerified;
    _loadAll();
  }

  // ── Load everything ────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([
      _loadMerchantInfo(),
      if (widget.isMerchant) _loadOffers(),
    ]);
    if (mounted) setState(() => _isLoading = false);
    if (widget.isMerchant && _offers.isNotEmpty) _loadOfferLikes();
  }

  // ── GET /api/profile/public/{userId} — pour récupérer la photo ───────────
  Future<void> _loadUserPhoto() async {
    try {
      final res = await http.get(
        Uri.parse('$_kBaseUrl/api/profile/public/${widget.merchantId}'),
        headers: _headers,
      );
      debugPrint('[MerchantProfile] profile public status: ${res.statusCode} body: ${res.body}');
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        // Cherche la photo dans tous les champs possibles
        String photo = d['photoUrl']?.toString()
            ?? d['profileImage']?.toString()
            ?? d['photo']?.toString()
            ?? d['profilePhoto']?.toString()
            ?? d['avatarUrl']?.toString()
            ?? '';
        if (photo.isNotEmpty && !photo.startsWith('http')) {
          photo = '$_kBaseUrl/$photo';
        }
        if (photo.isNotEmpty) _realAvatarUrl = photo;
        
        // Récupérer aussi le nom si pas encore rempli
        if (_realName.isEmpty || _realName == widget.merchantName) {
          final firstName = d['firstName']?.toString() ?? '';
          final surname   = d['surname']?.toString()   ?? '';
          if ('$firstName $surname'.trim().isNotEmpty) {
            _realName = '$firstName $surname'.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('[MerchantProfile] _loadUserPhoto error: $e');
    }
  }

  // ── GET /api/marchand/get/{marchandId} ─────────────────────────────────────
  // ✅ Bonne route selon la doc API
  Future<void> _loadMerchantInfo() async {
    try {
      // 1) Infos du marchand
      final res = await http.get(
        Uri.parse('$_kBaseUrl/api/marchand/get/${widget.merchantId}'),
        headers: _headers,
      );
      debugPrint('[MerchantProfile] marchand status: ${res.statusCode}');
      debugPrint('[MerchantProfile] marchand body: ${res.body}');

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        // ✅ /api/marchand/get/{id} retourne directement (pas imbriqué)
        // Champs réels : businessName, businessType, fullName, wilaya, statusMarchand, nbFollowers

        _realShopName = d['businessName']?.toString() ?? widget.shopName;
        _realCategory = d['businessType']?.toString() ?? widget.category;
        _realWilaya   = d['wilaya']?.toString()        ?? widget.wilaya;
        _realVerified = d['statusMarchand']?.toString() == 'VERIFIED';
        _bio          = d['bio']?.toString() ?? d['description']?.toString() ?? '';
        _realName     = d['fullName']?.toString() ?? widget.merchantName;

        // nbFollowers depuis le backend directement
        final nbFollowers = (d['nbFollowers'] as num?)?.toInt() ?? 0;
        if (nbFollowers > 0) _followersCount = nbFollowers;

        // ⚠️ Pas de photo dans /api/marchand/get/{id}
        // On la récupère via /api/profile/public/{userId}
        // Le userId est le même que le marchandId pour ce backend
        // (on le charge juste après dans _loadUserPhoto)
      }

      // ✅ Charger la photo via /api/profile/public/{userId}
      await _loadUserPhoto();

      // 2) ✅ Nombre de followers : GET /api/subscribe/{marchandId}/count
      final resCount = await http.get(
        Uri.parse('$_kBaseUrl/api/subscribe/${widget.merchantId}/count'),
        headers: _headers,
      );
      debugPrint('[MerchantProfile] subscribe count status: ${resCount.statusCode} body: ${resCount.body}');
      if (resCount.statusCode == 200) {
        final c = jsonDecode(resCount.body);
        if (c is int) {
          _followersCount = c;
        } else if (c is Map) {
          _followersCount = ((c['count'] ?? c['subscribersCount'] ?? c['followersCount'] ?? c['nbFollowers']) as num?)?.toInt() ?? _followersCount;
        }
      }

      // 3) ✅ Est-ce que je suis ce marchand : GET /api/subscribe/{marchandId}/check
      final resCheck = await http.get(
        Uri.parse('$_kBaseUrl/api/subscribe/${widget.merchantId}/check'),
        headers: _headers,
      );
      debugPrint('[MerchantProfile] subscribe check status: ${resCheck.statusCode} body: ${resCheck.body}');
      if (resCheck.statusCode == 200) {
        final c = jsonDecode(resCheck.body);
        if (c is bool) {
          _isFollowing = c;
        } else if (c is Map) {
          _isFollowing = c['subscribed'] == true
              || c['isSubscribed'] == true
              || c['following'] == true
              || c['isFollowing'] == true;
        }
      }

      // 4) ✅ Favoris total du marchand : GET /api/marchand/total-favoris/{marchandId}
      if (_likesCount == 0) {
        final resFav = await http.get(
          Uri.parse('$_kBaseUrl/api/marchand/total-favoris/${widget.merchantId}'),
          headers: _headers,
        );
        if (resFav.statusCode == 200) {
          final f = jsonDecode(resFav.body);
          if (f is int) {
            _likesCount = f;
          } else if (f is Map) {
            _likesCount = ((f['totalFavoris'] ?? f['count'] ?? f['total']) as num?)?.toInt() ?? 0;
          }
        }
      }

    } catch (e) {
      debugPrint('[MerchantProfile] _loadMerchantInfo error: $e');
    }
  }

  // ── GET /api/offres/marchand/{marchandId} ──────────────────────────────────
  Future<void> _loadOffers() async {
    try {
      final res = await http.get(
        Uri.parse('$_kBaseUrl/api/offres/marchand/${widget.merchantId}'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _offers = data.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
        for (final o in _offers) {
          _offerLikes[o.id] = {'count': 0, 'isLiked': false, 'isLoading': false};
        }
      }
    } catch (e) {
      debugPrint('[MerchantProfile] _loadOffers error: $e');
    }
  }

  // ── Likes des offres ───────────────────────────────────────────────────────
  Future<void> _loadOfferLikes() async {
    await Future.wait(_offers.map((o) async {
      final data = await ApiService.getOfferLikes(o.id);
      if (data != null && mounted) {
        setState(() {
          _offerLikes[o.id] = {
            'count'    : (data['likesCount'] as num?)?.toInt() ?? 0,
            'isLiked'  : data['isLikedByMe'] == true,
            'isLoading': false,
          };
        });
      }
    }));
  }

  // ── POST/DELETE /api/subscribe/{marchandId} ────────────────────────────────
  // ✅ Bonne route selon la doc API
  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return; // ← bloque les double-taps
    _isFollowLoading = true;

    final wasFollowing = _isFollowing;
    // Optimistic update
    setState(() {
      _isFollowing = !wasFollowing;
      _followersCount += wasFollowing ? -1 : 1;
    });

    try {
      final url = Uri.parse('$_kBaseUrl/api/subscribe/${widget.merchantId}');
      final http.Response res;
      if (wasFollowing) {
        res = await http.delete(url, headers: _headers);
      } else {
        res = await http.post(url, headers: _headers);
      }
      debugPrint('[Follow] status: ${res.statusCode} body: ${res.body}');

      if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 204) {
        // Rollback si le serveur refuse
        if (mounted) setState(() {
          _isFollowing = wasFollowing;
          _followersCount += wasFollowing ? 1 : -1;
        });
      } else {
        // ✅ Recharger le vrai nombre de followers depuis le backend
        final resCount = await http.get(
          Uri.parse('$_kBaseUrl/api/subscribe/${widget.merchantId}/count'),
          headers: _headers,
        );
        if (resCount.statusCode == 200 && mounted) {
          final c = jsonDecode(resCount.body);
          setState(() {
            if (c is int) {
              _followersCount = c;
            } else if (c is Map) {
              _followersCount = ((c['count'] ?? c['subscribersCount'] ?? c['followersCount']) as num?)?.toInt() ?? _followersCount;
            }
          });
        }
      }
    } catch (e) {
      // Rollback si erreur réseau
      if (mounted) setState(() {
        _isFollowing = wasFollowing;
        _followersCount += wasFollowing ? 1 : -1;
      });
      debugPrint('[MerchantProfile] follow error: $e');
    } finally {
      _isFollowLoading = false;
    }
  }

  // ── Toggle like offre ──────────────────────────────────────────────────────
  Future<void> _toggleOfferLike(String offerId) async {
    final state = _offerLikes[offerId];
    if (state == null || state['isLoading'] == true) return;
    setState(() {
      _offerLikes[offerId]!['isLoading'] = true;
      _offerLikes[offerId]!['isLiked']   = !state['isLiked'];
      _offerLikes[offerId]!['count']     =
          state['isLiked'] ? state['count'] - 1 : state['count'] + 1;
    });
    final ApiResponse<int> result = state['isLiked']
        ? await ApiService.unlikeOffer(offerId)
        : await ApiService.likeOffer(offerId);
    if (!mounted) return;
    setState(() {
      _offerLikes[offerId]!['isLoading'] = false;
      if (result.success && result.data != null) {
        _offerLikes[offerId]!['count'] = result.data;
      } else {
        _offerLikes[offerId]!['isLiked'] = state['isLiked'];
        _offerLikes[offerId]!['count']   = state['count'];
      }
    });
  }

  // ── Start chat with this merchant ──────────────────────────────────────────
  Future<void> _startChat(BuildContext context) async {
    final myId = int.tryParse(UserSession().id ?? '') ?? 0;
    final myToken = UserSession().token ?? '';
    if (myId == 0 || myToken.isEmpty) return;

    final nav = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF72A843))),
    );

    try {
      final api = ChatApiService(myToken);
      final conv = await api.getOrCreateConversation(
        myUserId: myId,
        merchantId: widget.merchantId,
        merchantName: _realShopName.isNotEmpty ? '$_realShopName — $_realName' : _realName,
        merchantAvatar: _realAvatarUrl,
      );
      if (!mounted) return;
      nav.pop();
      nav.push(MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: conv.conversationId,
          receiverId: widget.merchantId,
          receiverName: _realShopName.isNotEmpty ? '$_realShopName — $_realName' : _realName,
          receiverAvatar: _realAvatarUrl,
          myUserId: myId,
          myToken: myToken,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      nav.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer la conversation'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────
  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':   return const Color(0xFF72A843);
      case 'expired':  return Colors.red;
      case 'reserved': return Colors.orange;
      case 'soldout':  return Colors.grey;
      default:         return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':   return 'Active';
      case 'expired':  return 'Expired';
      case 'reserved': return 'Reserved';
      case 'soldout':  return 'Sold out';
      default:         return status;
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF72A843)))
          : CustomScrollView(
              slivers: [
                // ── SliverAppBar avec avatar ──────────────────────────
                SliverAppBar(
                  backgroundColor: const Color(0xFFF8FFF4),
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 120,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFF72A843).withOpacity(0.15),
                            child: _realAvatarUrl.isNotEmpty
                                ? ClipOval(
                                    child: AppNetworkImage(
                                      url: _realAvatarUrl,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    _realShopName.isNotEmpty
                                        ? _realShopName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF72A843)),
                                  ),
                          ),
                          const Spacer(),
                          // Boutons cloche + Follow
                          Row(
                            children: [
                              // Cloche notification
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF72A843).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.notifications_outlined,
                                    color: Color(0xFF72A843), size: 22),
                              ),
                              const SizedBox(width: 10),
                              // ✅ Bouton Follow avec protection double-tap
                              GestureDetector(
                                onTap: _isFollowLoading ? null : _toggleFollow,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isFollowing
                                        ? Colors.white
                                        : const Color(0xFF72A843),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: const Color(0xFF72A843), width: 1.5),
                                  ),
                                  child: _isFollowLoading
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _isFollowing
                                                ? const Color(0xFF72A843)
                                                : Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!_isFollowing)
                                              const Icon(Icons.add,
                                                  color: Colors.white, size: 16),
                                            if (!_isFollowing) const SizedBox(width: 4),
                                            Text(
                                              _isFollowing ? 'Following' : 'Follow',
                                              style: TextStyle(
                                                color: _isFollowing
                                                    ? const Color(0xFF72A843)
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Infos marchand ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom boutique + badges
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _realShopName.isNotEmpty ? _realShopName : 'Shop',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            if (_realVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFF72A843), width: 1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.verified,
                                        size: 12, color: Color(0xFF72A843)),
                                    SizedBox(width: 3),
                                    Text('Verified',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF72A843),
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (_realCategory.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC9D7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _realCategory,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFCB1B5F),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Nom gérant
                        if (_realName.isNotEmpty)
                          Text(
                            'Chez $_realName',
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF555555),
                                fontWeight: FontWeight.w500),
                          ),
                        const SizedBox(height: 2),

                        // Wilaya
                        if (_realWilaya.isNotEmpty)
                          Text(
                            _realWilaya,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        const SizedBox(height: 8),

                        // Bio
                        if (_bio.isNotEmpty)
                          Text(
                            _bio,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF555555),
                                height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 16),

                        // ── Stats : Followers / Publications / Likes ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStat(_formatCount(_followersCount), 'Followers'),
                              _buildDividerV(),
                              _buildStat('${_offers.length}', 'Publications'),
                              _buildDividerV(),
                              _buildStat(_formatCount(_likesCount), 'Likes'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Bouton Contact ────────────────────────────
                        if (widget.onContact != null ||
                            (UserSession().id != null &&
                                UserSession().id != widget.merchantId.toString()))
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: widget.onContact ?? () => _startChat(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF72A843),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.chat_bubble_outline,
                                  color: Colors.white, size: 18),
                              label: const Text('Message',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // ── Bouton Offers centré ──────────────────────
                        if (widget.isMerchant)
                          Center(
                            child: Container(
                              width: 180,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF72A843),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  'Offers (${_offers.length})',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Liste des offres ──────────────────────────────────
                if (widget.isMerchant && _offers.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No offers yet',
                                style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (widget.isMerchant && _offers.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildOfferCard(_offers[index]),
                        ),
                        childCount: _offers.length,
                      ),
                    ),
                  ),

                // ── Client (pas marchand) ─────────────────────────────
                if (!widget.isMerchant)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.person_outline,
                                size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('This user is a client',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // ── Stat column ────────────────────────────────────────────────────────────
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDividerV() {
    return Container(height: 30, width: 1, color: const Color(0xFFD0E6A5));
  }

  // ── Offer card ─────────────────────────────────────────────────────────────
  Widget _buildOfferCard(Offer offer) {
    final likeState    = _offerLikes[offer.id];
    final likeCount    = likeState?['count']    as int?  ?? 0;
    final isOfferLiked = likeState?['isLiked']  as bool? ?? false;
    final isLoading    = likeState?['isLoading'] as bool? ?? false;

    final statusColor = _statusColor(offer.status);
    final statusLabel = _statusLabel(offer.status);

    final totalQty = int.tryParse(offer.quantity) ?? 0;
    final availQty = int.tryParse(offer.available) ?? totalQty;
    final stockRatio = totalQty > 0 ? (availQty / totalQty).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge statut
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor),
              ),
            ),
          ),

          // Contenu : image + infos
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: offer.imageUrl.isEmpty
                      ? Container(
                          width: 90, height: 90,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.fastfood,
                              color: Colors.grey, size: 36))
                      : AppNetworkImage(
                          url: offer.imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey, height: 1.3),
                      ),
                      const SizedBox(height: 8),

                      // Date d'expiration
                      if (offer.availableUntil.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Ends in: ${offer.availableUntil.length > 10 ? offer.availableUntil.substring(0, 10) : offer.availableUntil}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.access_time,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              offer.availableUntil.length > 16
                                  ? offer.availableUntil.substring(11, 16)
                                  : '',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // Barre de stock
                      if (totalQty > 0) ...[
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: stockRatio > 0.3
                                    ? const Color(0xFF72A843)
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: stockRatio,
                                  minHeight: 5,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    stockRatio > 0.3
                                        ? const Color(0xFF72A843)
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$availQty left',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer : prix + like + Purchase
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Text(
                  offer.price.isNotEmpty ? offer.price : '—',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(width: 4),
                const Text('DA',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),

                // Bouton like (cœur)
                GestureDetector(
                  onTap: isLoading ? null : () => _toggleOfferLike(offer.id),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isOfferLiked
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOfferLiked
                            ? Colors.red.withOpacity(0.4)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.red)))
                        : Icon(
                            isOfferLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isOfferLiked ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                Text('$likeCount',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),

                const Spacer(),

                // ✅ Bouton Purchase — désactivé si pas active
                GestureDetector(
                  onTap: offer.status.toLowerCase() == 'active'
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewOfferPage(
                                offerId:        offer.id,
                                title:          offer.title,
                                description:    offer.description,
                                location:       offer.location,
                                price:          offer.price,
                                imageUrl:       offer.imageUrl,
                                availableUntil: offer.availableUntil,
                                status:         offer.status,
                                quantity:       offer.quantity,
                              ),
                            ),
                          )
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: offer.status.toLowerCase() == 'active'
                          ? const Color(0xFF72A843)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      'Purchase',
                      style: TextStyle(
                        color: offer.status.toLowerCase() == 'active'
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}