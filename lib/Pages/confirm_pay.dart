import 'package:flutter/material.dart';

class ConfirmPaymentPage extends StatefulWidget {
  final String paymentMethod;
  final double subTotal;
  final double deliveryFee;
  final double appTax;

  const ConfirmPaymentPage({
    super.key,
    required this.paymentMethod,
    required this.subTotal,
    required this.deliveryFee,
    required this.appTax,
  });

  @override
  State<ConfirmPaymentPage> createState() => _ConfirmPaymentPageState();
}

class _ConfirmPaymentPageState extends State<ConfirmPaymentPage> {
  final Color primaryColor = const Color(0xFF72A843);

  double get totalAmount => widget.subTotal + widget.deliveryFee + widget.appTax;

  // ── Payment Success ───────────────────────────────────────────────
  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF72A843),
                size: 70,
              ),
              const SizedBox(height: 16),
              const Text(
                'payment successful!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF72A843),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your order has been placed successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF717270),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigator.pushAndRemoveUntil vers HomePage
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back To Home',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Payment Failed ────────────────────────────────────────────────
  void _showPaymentFailed() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFFF3B3B),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'payment failed',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF3B3B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'we could not process your payment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF717270),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: retour vers PaymentSheet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Change payment method',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirm Payment',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Subtitle ──────────────────────────────────────────
            const Text(
              'Review your payment details',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1A1A1A),
              ),
            ),

            const SizedBox(height: 16),

            // ── Payment Method ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Icon(Icons.credit_card,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        widget.paymentMethod,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF717270),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Order Summary ──────────────────────────────────────
            const Text(
              'Order Summary',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),

            const SizedBox(height: 16),

            _summaryRow(
              label: 'Sub Total',
              value: '${widget.subTotal.toStringAsFixed(0)} DZD',
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 24),

            _summaryRow(
              label: 'Delivery Fee',
              value: '${widget.deliveryFee.toStringAsFixed(0)} DZD',
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 24),

            _summaryRow(
              label: 'App Tax',
              value: '${widget.appTax.toStringAsFixed(0)} DZD',
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 24),

            _summaryRow(
              label: 'Total Amount',
              value: '${totalAmount.toStringAsFixed(0)} DZD',
              labelColor: primaryColor,
              valueColor: primaryColor,
              isBold: true,
            ),

            const SizedBox(height: 24),

            // ── Secure Payment Banner ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEEFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: Color(0xFF1A73E8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Payment',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your payment information is encrypted and secure. We never store your card details.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF444543),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),


            // ── Confirm & Pay Button ───────────────────────────────
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // ── Simule succès ou échec ──────────────────────
                  bool paymentSuccess = true; // ← remplace par ta logique API

                  if (paymentSuccess) {
                    _showPaymentSuccess();
                  } else {
                    _showPaymentFailed();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.lock_outline,
                    color: Colors.white, size: 18),
                label: Text(
                  'Confirm & Pay ${totalAmount.toStringAsFixed(0)} DZD',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Summary Row ───────────────────────────────────────────────────
  Widget _summaryRow({
    required String label,
    required String value,
    Color labelColor = const Color(0xFF1A1A1A),
    Color valueColor = const Color(0xFF1A1A1A),
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: labelColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}