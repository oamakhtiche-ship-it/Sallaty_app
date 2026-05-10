import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'offer_details.dart';
import 'create_offer.dart';
import 'offer_store.dart';
import 'apiservice.dart';
import 'usersession.dart';
import 'network_image_widget.dart';

// ── Modèle Offer ──────────────────────────────────────────────────────
class Offer {
  final String id;
  final String title;
  final String price;
  final String available;
  final String location;
  final String status;
  final String imageUrl;
  final String description;
  final String quantity;
  final String availableUntil;
  final String type;

  // ✅ Champ optionnel pour la nouvelle image (Android + Web)
  final XFile? newImageFile;

  Offer({
    required this.id,
    required this.title,
    required this.price,
    required this.available,
    required this.location,
    required this.status,
    required this.imageUrl,
    required this.description,
    required this.quantity,
    required this.availableUntil,
    required this.type,
    this.newImageFile, // optionnel
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    // Cherche toutes les clés possibles renvoyées par le backend
    final rawImage = json['imageUrl']?.toString()
                  ?? json['imagePath']?.toString()
                  ?? json['photo']?.toString()
                  ?? json['image']?.toString()
                  ?? json['photoUrl']?.toString()
                  ?? '';

    // ApiService.buildImageUrl gère : vide, relatif (/uploads/...), absolu
    final imageUrl = ApiService.buildImageUrl(rawImage);

    return Offer(
      id:             json['id']?.toString() ?? '',
      title:          json['title']?.toString() ?? '',
      price:          '${json['price'] ?? 0} DA',
      available:      json['available']?.toString() ?? 'Yes',
      location:       json['wilaya']?.toString()
                   ?? json['location']?.toString() ?? '',
      status:         (json['status']?.toString() ?? 'active').toLowerCase(),
      imageUrl:       imageUrl,
      description:    json['description']?.toString() ?? '',
      quantity:       json['quantity']?.toString() ?? '0',
      availableUntil: json['expireAt']?.toString()
                   ?? json['availableUntil']?.toString() ?? '',
      type:           json['foodtype']?.toString()
                   ?? json['type']?.toString() ?? '',
    );
  }

  // ✅ Copie avec un nouveau imageUrl (après upload réussi)
  Offer copyWith({String? imageUrl}) {
    return Offer(
      id:             id,
      title:          title,
      price:          price,
      available:      available,
      location:       location,
      status:         status,
      imageUrl:       imageUrl ?? this.imageUrl,
      description:    description,
      quantity:       quantity,
      availableUntil: availableUntil,
      type:           type,
      newImageFile:   null, // on vide après upload
    );
  }
}

class MyOffersPage extends StatefulWidget {
  const MyOffersPage({super.key});

  @override
  State<MyOffersPage> createState() => _MyOffersPageState();
}

class _MyOffersPageState extends State<MyOffersPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    await OfferStore.fetchMyOffers();
    if (mounted) setState(() => _isLoading = false);
  }

  final Color primaryColor = const Color(0xFF72A843);

  List<Offer> get _offers => OfferStore.myOffers;

  Color _statusColor(String status) {
    switch (status) {
      case 'active':   return const Color(0xFF72A843);
      case 'soldout':  return const Color(0xFFD7D8D7);
      case 'reserved': return const Color(0xFF1574FF);
      case 'expired':  return const Color(0xFFD7D8D7);
      default:         return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':   return 'Active';
      case 'reserved': return 'Sold out';
      case 'expired':  return 'Expired';
      case 'archived': return 'Archived';
      default:         return status;
    }
  }

  // ── Upload photo de l'offre après édition ────────────────────────
  // ✅ Appelé depuis onUpdate si newImageFile != null
  Future<String?> _uploadOfferPhoto(String offerId, XFile image) async {
    try {
      final token = UserSession().token ?? '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/offres/photo/$offerId');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        req.files.add(http.MultipartFile.fromBytes(
          'file', bytes,
          filename: image.name,
        ));
      } else {
        req.files.add(await http.MultipartFile.fromPath(
          'file', image.path,
        ));
      }

      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Le backend retourne éventuellement la nouvelle URL
        // Sinon on recharge les offres
        return null; // signal : recharger
      }
      return null;
    } catch (e) {
      debugPrint('Photo upload error: $e');
      return null;
    }
  }

  // ── Empty state ───────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      
      child: Padding(
        
        padding: const EdgeInsets.only(top: 70),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          
          children: [
            Image.asset(
              'assets/images/myoffers.png',
              width: 209, height: 198, fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'No offers yet',
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 24,
                fontWeight: FontWeight.w600, color: Color(0xFF2D2E2D),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You have not posted any offers yet.\nStart reducing food waste by\nsharing your surplus food!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter', fontSize: 16,
                  fontWeight: FontWeight.w600, color: Color(0xFF2D2E2D),
                ),
              ),
            ),
            const SizedBox(height: 45),
            _createButton(),
          ],
        ),
      ),
    );
  }

  // ── List state ────────────────────────────────────────────────────
  Widget _buildListState() {
    return Stack(
      children: [
        Positioned.fill(
          bottom: 90,
          child: RefreshIndicator(
            onRefresh: _loadOffers,
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 8, bottom: 16),
              itemCount: _offers.length,
              itemBuilder: (_, i) => _buildOfferCard(_offers[i]),
            ),
          ),
        ),
        Positioned(
          bottom: 16, left: 0, right: 0,
          child: Center(child: _createButton(withIcon: true)),
        ),
      ],
    );
  }

  Widget _createButton({bool withIcon = false}) {
    return Container(
      width: 201, height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF72A843).withOpacity(0.4),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: withIcon
          ? ElevatedButton.icon(
              onPressed: _goToCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text(
                'Create New offer',
                style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 15,
                  fontWeight: FontWeight.w600, color: Colors.white,
                ),
              ),
            )
          : GestureDetector(
              onTap: _goToCreate,
              child: const Center(
                child: Text(
                  'Create Your first offer',
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 16,
                    fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateOfferPage()),
    );
    if (result == true) _loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0, centerTitle: true,
        title: Text(
          'My offers',
          style: TextStyle(
            fontFamily: 'Poppins', fontSize: 24,
            fontWeight: FontWeight.w500, color: primaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: _loadOffers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _offers.isEmpty
              ? _buildEmptyState()
              : _buildListState(),
    );
  }

  Widget _buildOfferCard(Offer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: offer.imageUrl.isNotEmpty
                  ? AppNetworkImage(url: offer.imageUrl, width: 119, height: 170, fit: BoxFit.cover)
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins', fontSize: 15,
                        fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Text('Price: ',
                          style: TextStyle(
                              fontFamily: 'Inter', fontSize: 13,
                              color: Color(0xFF5A5B59))),
                      Text(offer.price,
                          style: TextStyle(
                              fontFamily: 'Inter', fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor)),
                    ]),
                    Text('Available: ${offer.available}',
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 13,
                            color: Color(0xFF717270))),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Color(0xFF5A5B59)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(offer.location,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Poppins', fontSize: 13,
                                color: Color(0xFF717270))),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(offer.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(offer.status),
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: offer.status == 'active'
                                ? primaryColor
                                : const Color(0xFF5A5B59),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OfferDetailsPage(
                              offer: offer,
                              onDelete: () {
                                setState(() {
                                  OfferStore.myOffers
                                      .removeWhere((o) => o.id == offer.id);
                                });
                              },
                              // ✅ onUpdate : upload photo si newImageFile présent
                              onUpdate: (updatedOffer) async {
                                // 1. Mettre à jour la liste immédiatement (UI réactif)
                                setState(() {
                                  final index = OfferStore.myOffers
                                      .indexWhere((o) => o.id == updatedOffer.id);
                                  if (index != -1) {
                                    OfferStore.myOffers[index] = updatedOffer;
                                  }
                                });

                                // 2. Upload la photo si une nouvelle a été choisie
                                if (updatedOffer.newImageFile != null) {
                                  await _uploadOfferPhoto(
                                    updatedOffer.id,
                                    updatedOffer.newImageFile!,
                                  );
                                  // 3. Recharger depuis le backend pour avoir la vraie URL
                                  await _loadOffers();
                                }
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 27,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0E2C0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'View details',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 11,
                            fontWeight: FontWeight.w500, color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 119, height: 170, color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey, size: 36));
}