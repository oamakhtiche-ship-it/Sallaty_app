
import 'package:flutter/material.dart';
import 'offer_details.dart';
import 'create_offer.dart';
import 'dart:io';
import 'offer_store.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Offers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.lightGreen),
      home: const MyOffersPage(),
    );
  }
}

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
  });

  // ✅ CORRIGÉ
  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id:    json['id'].toString(), // ← Spring Boot renvoie souvent un Long
      title: json['title'] ?? '',
      price: '${json['price']} DA',
      available: json['available'] ?? 'Yes',
      location: json['location'] ?? '',
      status: json['status'] ?? 'active',
      // 'active', 'soldout', 'expired'
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? '0',
      availableUntil: json['availableUntil'] ?? '',
      type: json['type'] ?? '',
    );
  }
}


class MyOffersPage extends StatefulWidget {
  const MyOffersPage({super.key});

  @override
  State<MyOffersPage> createState() => _MyOffersPageState();
}

class _MyOffersPageState extends State<MyOffersPage> {
  @override
  void initState() {
    super.initState();
    if (OfferStore.offers.isEmpty) {
      OfferStore.fetchOffers().then((_) {
        if (mounted) setState(() {});
      });
    }
  }
  final Color primaryColor = const Color(0xFF72A843);

  List<Offer> get _offers => OfferStore.offers;

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return const Color(0xFF72A843);
      case 'soldout': return const Color(0xFFD7D8D7);
      case 'expired': return const Color(0xFFD7D8D7);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'soldout': return 'Sold out';
      case 'expired': return 'Expired';
      default: return status;
    }
  }

  // ── Écran vide ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 70),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/myoffers.png',
              width: 209,
              height: 198,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'No offers yet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2E2D),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You have not posted any offers yet.\nStart reducing food waste by\nsharing your surplus food!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2E2D),
                ),
              ),
            ),
            const SizedBox(height: 45),
            GestureDetector(
              onTap: () async {
                final newOffer = await Navigator.push<Offer>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateOfferPage()),
                );
                if (newOffer != null) {
                  setState(() {});
                }
              },
              child: Container(
                width: 201,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF72A843).withValues(alpha:0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Create Your first offer',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Écran liste ───────────────────────────────────────────────────
  Widget _buildListState() {
    return Stack(
      children: [
        Positioned.fill(
          bottom: 90,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
            itemCount: _offers.length,
            itemBuilder: (context, index) {
              return _buildOfferCard(_offers[index]);
            },
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 201,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF72A843).withValues(alpha:0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final newOffer = await Navigator.push<Offer>(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateOfferPage()),
                  );
                  if (newOffer != null) {
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  'Create New offer',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My offers',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),
      // ── Condition centrale ──────────────────────────────────────
      body: _offers.isEmpty ? _buildEmptyState() : _buildListState(),
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
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  ? (offer.imageUrl.startsWith('http')
                  ? Image.network(offer.imageUrl, width: 119, height: 170, fit: BoxFit.cover)
                  : Image.file(File(offer.imageUrl), width: 119, height: 170, fit: BoxFit.cover))
                  : Container(
                width: 119,
                height: 170,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey, size: 36),
              ),
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
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Price: ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF5A5B59),
                          ),
                        ),
                        Text(
                          offer.price,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Available: ${offer.available}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF717270),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF5A5B59)),
                        const SizedBox(width: 2),
                        Text(
                          offer.location,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF717270),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(offer.status).withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(offer.status),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: offer.status == 'active'
                                  ? primaryColor
                                  : const Color(0xFF5A5B59),
                            ),
                          ),
                        ),
                      ],
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
                                setState(() => _offers.remove(offer));
                              },
                              onUpdate: (updatedOffer) {
                                setState(() {
                                  final index = _offers.indexOf(offer);
                                  if (index != -1) _offers[index] = updatedOffer;
                                });
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
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
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
}

