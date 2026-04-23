import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'viewoffer.dart';
import'my_offers.dart';

class AllOffersPage extends StatelessWidget {
  final String      title;
  final List<Offer> offers;

  const AllOffersPage({
    super.key,
    required this.title,
    required this.offers,
  });

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
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF72A843),
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8F5E3)),
        ),
      ),
      body: offers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aucune offre disponible',
              style: GoogleFonts.poppins(
                  color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:    2,
          crossAxisSpacing:  12,
          mainAxisSpacing:   12,
          childAspectRatio:  0.70,
        ),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return _OfferGridCard(offer: offer);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFER GRID CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OfferGridCard extends StatelessWidget {
  final Offer offer;
  const _OfferGridCard({required this.offer});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':   return const Color(0xFF72A843);
      case 'soldout':  return Colors.red;
      case 'expired':  return Colors.orange;
      default:         return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':   return 'Disponible';
      case 'soldout':  return 'Épuisé';
      case 'expired':  return 'Expiré';
      default:         return status;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + status badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: isNetwork
                      ? Image.network(offer.imageUrl,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover)
                      : Image.file(File(offer.imageUrl),
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(offer.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(offer.status),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          offer.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Price
                  Text(
                    '${offer.price} DA',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF72A843),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
