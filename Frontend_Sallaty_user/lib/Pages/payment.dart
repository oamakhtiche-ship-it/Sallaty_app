import 'package:flutter/material.dart';
import 'carddetails.dart';
import 'order_item.dart';
import 'order_details.dart';
import 'payment_service.dart';
import 'payment_models.dart';

// ── Payment Bottom Sheet ──────────────────────────────────────────
class PaymentSheet extends StatefulWidget {
  final String totalAmount;
  final String ordreId;
  final OrderItem order; // ✅ required to navigate back after payment

  const PaymentSheet({
    super.key,
    required this.totalAmount,
    required this.ordreId,
    required this.order,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  bool _cashLoading = false;

  // ── CASH ──────────────────────────────────────────────────────
  Future<void> _onCashTap() async {
    setState(() => _cashLoading = true);
    try {
      final result = await PaymentService.instance.pay(
        PaymentRequestDto(
          ordreId: int.tryParse(widget.ordreId) ?? 0,
          method: PaymentMethod.CASH,
        ),
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        setState(() => _cashLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  result.errorMessage ?? 'Payment failed.')),
        );
        return;
      }

      Navigator.pop(context); // close sheet
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsPage(order: widget.order),
        ),
      );
    } catch (e) {
      setState(() => _cashLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FFF4),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── X button ─────────────────────────────────────
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close,
                  color: Color(0xFF1A1A1A), size: 22),
            ),
          ),
          const SizedBox(height: 4),
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

          // ── Credit/Debit Card ─────────────────────────────
          _paymentOption(
            context,
            icon: Icons.credit_card,
            title: 'Credit/Debit Card',
            subtitle: 'Pay securely with your card',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardDetailsPage(
                    totalAmount: widget.totalAmount,
                    ordreId: widget.ordreId,
                    order: widget.order, // ✅ pass order through
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // ── Cash on Delivery ──────────────────────────────
          _paymentOption(
            context,
            icon: Icons.money,
            title: 'Cash on Delivery',
            subtitle: 'Pay when you receive',
            loading: _cashLoading,
            onTap: _cashLoading ? null : _onCashTap,
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
    VoidCallback? onTap,
    bool loading = false,
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
              color: const Color(0xFF72A843), width: 1),
        ),
        child: Row(
          children: [
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
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A))),
                Text(subtitle,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF444543))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}