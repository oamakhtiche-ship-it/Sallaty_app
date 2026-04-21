import 'package:flutter/material.dart';
import 'my_offers.dart';
import 'view_reservations.dart';
import 'edit_offer.dart';
import 'dart:io';

class OfferDetailsPage extends StatefulWidget {
  final Offer offer;
  final VoidCallback onDelete;
  final Function(Offer) onUpdate;

  const OfferDetailsPage({
    super.key,
    required this.offer,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<OfferDetailsPage> createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  late Offer _offer;
  final Color primaryColor = const Color(0xFF72A843);

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;
  }

  // ── Couleur par type ──────────────────────────────────────────────
  Map<String, dynamic> _typeStyle(String type) {
    switch (type) {
      case 'Bakery':
        return {'bg': const Color(0xFFFFF0E0), 'text': const Color(0xFFC05A00)};
      case 'Fish Shop':
        return {'bg': const Color(0xFFE6F4FB), 'text': const Color(0xFF0C5A8A)};
      case 'Cafe':
        return {'bg': const Color(0xFFFFF0E0), 'text': const Color(0xFFA04A00)};
      case 'Fast Food':
        return {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFB85C00)};
      case 'Grocery':
        return {'bg': const Color(0xFFEDF7E5), 'text': const Color(0xFF2E6B10)};
      case 'Butcher':
        return {'bg': const Color(0xFFFEECEC), 'text': const Color(0xFFA02020)};
      case 'Fruits & Vegetables':
        return {'bg': const Color(0xFFF0FAE8), 'text': const Color(0xFF3A7A12)};
      case 'Restaurant':
        return {'bg': const Color(0xFFF3EEFF), 'text': const Color(0xFF5A2E9A)};
      case 'Home Cooking':
        return {'bg': const Color(0xFFFFF8E0), 'text': const Color(0xFF8A6000)};
      default:
        return {'bg': const Color(0xFFF0F0F0), 'text': const Color(0xFF666666)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeStyle = _typeStyle(_offer.type);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Offers details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── Image ──────────────────────────────────────────────
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: _offer.imageUrl.isNotEmpty
                    ? (_offer.imageUrl.startsWith('http')
                    ? Image.network(
                  _offer.imageUrl,
                  width: 300,
                  height: 200,
                  fit: BoxFit.cover,
                )
                    : Image.file(
                  File(_offer.imageUrl),
                  width: 300,
                  height: 200,
                  fit: BoxFit.cover,
                ))
                    : Container(
                  width: 300,
                  height: 200,
                  color: const Color(0xFFE5E7EB),
                  child: const Icon(
                    Icons.image,
                    color: Colors.grey,
                    size: 60,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Titre + Badge Type ──────────────────────────────────
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _offer.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeStyle['bg'] as Color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _offer.type,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: typeStyle['text'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _offer.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF717270),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Grid Price / Quantity ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoBox(
                  label: 'Price',
                  value: _offer.price,
                  color: const Color(0xFFD7D8D7),
                  valueColor: const Color(0xFF4A5565),
                ),
                const SizedBox(width: 10),
                _infoBox(
                  label: 'Quantity',
                  value: _offer.quantity,
                  color: const Color(0xFFEFF6FF),
                  valueColor: const Color(0xFF1574FF),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Grid Available / Status ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoBox(
                  label: 'Available',
                  value: _offer.available,
                  color: const Color(0xFFFFBEBE).withValues(alpha: 0.30),
                  valueColor: const Color(0xFFFF5C5C),
                ),
                const SizedBox(width: 10),
                _infoBox(
                  label: 'Status',
                  value: _offer.status == 'active'
                      ? 'Active'
                      : _offer.status == 'soldout'
                      ? 'Sold out'
                      : 'Expired',
                  color: const Color(0xFFD0E2C0),
                  valueColor: const Color(0xFF72A843),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Pickup Location ─────────────────────────────────────
            SizedBox(
              width: 300,
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: Color(0xFF5A5B59), size: 30),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Location',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        _offer.location,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF5A5B59),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Available Until ─────────────────────────────────────
            SizedBox(
              width: 300,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF5A5B59), size: 25),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Until',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        _offer.availableUntil,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF5A5B59),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Edit offer ──────────────────────────────────────────
            Center(
              child: _actionButton(
                label: 'Edit offer',
                icon: Icons.edit_outlined,
                color: const Color(0xFFD0E2C0),
                textColor: const Color(0xFF5F8C38),
                onTap: () async {
                  final updatedOffer = await Navigator.push<Offer>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditOfferPage(
                        initialId: _offer.id,             // ← ADDED
                        initialName: _offer.title,
                        initialDescription: _offer.description,
                        initialPrice: _offer.price,
                        initialAddress: _offer.location,
                        initialExpirationDate: _offer.availableUntil,
                        initialStatus: _offer.status,
                        initialQuantity: int.tryParse(_offer.quantity) ?? 1,
                        initialImageUrl: _offer.imageUrl,
                        initialType: _offer.type,
                      ),
                    ),
                  );
                  if (updatedOffer != null) {
                    setState(() => _offer = updatedOffer);
                    widget.onUpdate(updatedOffer);
                  }
                },
              ),
            ),

            const SizedBox(height: 10),

            // ── View reservations ───────────────────────────────────
            Center(
              child: _actionButton(
                label: 'View reservations',
                icon: Icons.people_outline,
                color: const Color(0xFFD0E2C0),
                textColor: const Color(0xFF5F8C38),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ViewReservationsPage(offerId: _offer.title),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ── Delete offer ────────────────────────────────────────
            Center(
              child: _actionButton(
                label: 'Delete Offer',
                icon: Icons.delete_outline,
                color: const Color(0xFFFFBEBE).withValues(alpha: 0.50),
                textColor: const Color(0xFFFF3B3B),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Offer'),
                      content: const Text(
                          'Are you sure you want to delete this offer?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onDelete();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFFFF3B3B)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Widget boîte info ─────────────────────────────────────────────
  Widget _infoBox({
    required String label,
    required String value,
    required Color color,
    Color valueColor = const Color(0xFF4A5565),
  }) {
    return Container(
      width: 140,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
              color: Color(0xFF4A5565),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget bouton action ──────────────────────────────────────────
  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}