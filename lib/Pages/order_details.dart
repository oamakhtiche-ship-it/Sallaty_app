import 'dart:io';
import 'package:flutter/material.dart';
import 'order_item.dart';
import 'carddetails.dart';

// ─── Couleurs ─────────────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF72A843);
const _kBgPage    = Color(0xFFFAFFF7);
const _kGreenBg   = Color(0xFFD0E2C0);
const _kGreenText = Color(0xFF5F8C38);
const _kGreyBg    = Color(0xFFE8E8E8);
const _kGreyText  = Color(0xFF5A5B59);

// ─── Page détail ordre ────────────────────────────────────────────────────────
class OrderDetailsPage extends StatefulWidget {
  final OrderItem order;
  final VoidCallback? onCancelReservation;
  final VoidCallback? onPayNow;

  const OrderDetailsPage({
    super.key,
    required this.order,
    this.onCancelReservation,
    this.onPayNow,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late OrderItem _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  // ── Badge statut ─────────────────────────────────────────────────
  Widget _statusBadge() {
    final (label, bg, fg) = switch (_order.status) {
      OrderStatus.pending   => ('Pending',   _kGreenBg, _kGreenText),
      OrderStatus.confirmed => ('Confirmed', _kGreenBg, _kGreenText),
      OrderStatus.picked    => ('Picked Up', _kGreenBg, _kGreenText),
      OrderStatus.cancelled => ('Cancelled', _kGreenBg, _kGreenText),
    };

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: fg,
        ),
      ),
    );
  }

  // ── Bouton action ─────────────────────────────────────────────────
  Widget _actionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // ── Boutons selon statut ──────────────────────────────────────────
  List<Widget> _buildButtons() {
    switch (_order.status) {

      case OrderStatus.pending:
        return [
          _statusBadge(),
          const SizedBox(height: 10),
          _actionButton(
            label: 'Cancel Reservation',
            color: _kGreyBg,
            textColor: _kGreyText,
            onTap: _showCancelDialog,
          ),
        ];

      case OrderStatus.confirmed:
        return [
          _statusBadge(),
          const SizedBox(height: 20),
          _actionButton(
            label: 'Pay Now',
            color: _kGreenBg,
            textColor: _kGreenText,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => PaymentSheet(
                  totalAmount: _order.price,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _actionButton(
            label: 'Cancel Reservation',
            color: _kGreyBg,
            textColor: _kGreyText,
            onTap: _showCancelDialog,
          ),
        ];

      case OrderStatus.picked:
        return [_statusBadge()];

      case OrderStatus.cancelled:
        return [_statusBadge()];
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onCancelReservation?.call();
              Navigator.pop(context, OrderStatus.cancelled);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Color(0xFFFF3B3B)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: AppBar(
        backgroundColor: _kBgPage,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My orders',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: _kPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: SizedBox(
            width: 310,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Image ──────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _order.imagePath != null && _order.imagePath!.isNotEmpty
                      ? (_order.imagePath!.startsWith('http')
                      ? Image.network(
                    _order.imagePath!,
                    width: 310,
                    height: 192,
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                    File(_order.imagePath!),
                    width: 310,
                    height: 192,
                    fit: BoxFit.cover,
                  ))
                      : Container(
                    width: 310,
                    height: 192,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(Icons.image,
                        color: Colors.grey, size: 60),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Titre + Prix ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _order.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      _order.price,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Merchant Name ───────────────────────────────────
                Text(
                  _order.merchantName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF717270),
                  ),
                ),

                const SizedBox(height: 30),

                // ── Pickup Location ─────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFF5A5B59), size: 22),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup Location',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _order.pickupLocation,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5A5B59),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Pickup Time ─────────────────────────────────────
                if (_order.pickupTime != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Color(0xFF5A5B59), size: 20),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup Time',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _order.pickupTime!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF5A5B59),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 40),

                // ── Boutons selon statut ────────────────────────────
                ..._buildButtons(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Payment Sheet ────────────────────────────────────────────────────────────
class PaymentSheet extends StatelessWidget {
  final String totalAmount;
  const PaymentSheet({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FFF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── X button ──────────────────────────────────────────────
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close,
                  color: Color(0xFF1A1A1A), size: 22),
            ),
          ),

          const SizedBox(height: 4),

          // ── Titre ─────────────────────────────────────────────────
          const Text(
            'Payment',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Color(0xFF72A843),
            ),
          ),

          const SizedBox(height: 4),

          // ── Sous-titre ────────────────────────────────────────────
          const Text(
            'Select a payment method',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 24),

          // ── Credit/Debit Card ─────────────────────────────────────
          _paymentOption(
            context,
            icon: Icons.credit_card,
            title: 'Credit/Debit Card',
            subtitle: 'Pay securely with your card',
            onTap: () {
              Navigator.pop(context); // ferme le bottom sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardDetailsPage(
                    totalAmount: totalAmount,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // ── Cash on Delivery ──────────────────────────────────────
          _paymentOption(
            context,
            icon: Icons.money,
            title: 'Cash on Delivery',
            subtitle: 'Pay when you receive',
            onTap: () {
              Navigator.pop(context);
              // TODO: logique cash on delivery
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _paymentOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF72A843),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ── Icône ──────────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),

            const SizedBox(width: 12),

            // ── Textes ─────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF444543),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}