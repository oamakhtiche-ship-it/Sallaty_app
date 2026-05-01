import 'package:flutter/material.dart';
import 'payment_models.dart';
import 'payment_service.dart';
import 'order_item.dart';
import 'order_details.dart';

const _kGreen = Color(0xFF72A843);

class ConfirmPaymentPage extends StatefulWidget {
  final String ordreId;
  final OrderItem order;
  final PaymentRequestDto cardRequest;
  final String totalAmount;

  const ConfirmPaymentPage({
    super.key,
    required this.ordreId,
    required this.order,
    required this.cardRequest,
    required this.totalAmount,
  });

  @override
  State<ConfirmPaymentPage> createState() => _ConfirmPaymentPageState();
}

class _ConfirmPaymentPageState extends State<ConfirmPaymentPage> {
  bool _loading = false;
  String? _error;

  Future<void> _confirmPayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await PaymentService.instance.pay(widget.cardRequest);

    if (!mounted) return;

    if (result.isSuccess) {
      // Payment OK → go back to OrderDetailsPage, clear card/confirm screens
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsPage(order: widget.order),
        ),
        (route) => route.isFirst,
      );
    } else {
      setState(() {
        _loading = false;
        _error = result.errorMessage ?? 'Payment failed. Please try again.';
      });
    }
  }

  String _maskCard(String raw) {
    final clean = raw.replaceAll(' ', '');
    if (clean.length < 4) return raw;
    return '**** **** **** ${clean.substring(clean.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _loading
            ? const SizedBox()
            : IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Color(0xFF1A1A1A)),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Confirm Payment',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Review your payment details',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),

          // ── Payment Method row ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card_outlined,
                      color: _kGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'via credit / debit card.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Order Summary card ────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 14),
                _summaryRow('Sub Total', widget.totalAmount),
                const SizedBox(height: 10),
                _summaryRow('Delivery Fee', '0'),
                const SizedBox(height: 10),
                _summaryRow('App Tax', '0'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                _summaryRow(
                  'Total Amount',
                  widget.totalAmount,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Secure Payment note ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF6E5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _kGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: _kGreen, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Payment',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kGreen,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your payment information is encrypted and secure. We never store your card details.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Error message ─────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── Confirm & Pay button ──────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _confirmPayment,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.lock_outline,
                      color: Colors.white, size: 18),
              label: Text(
                _loading
                    ? 'Processing...'
                    : 'Confirm & Pay ${widget.totalAmount} DZD',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                disabledBackgroundColor: _kGreen.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isTotal ? 14 : 13,
            fontWeight:
                isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF666666),
          ),
        ),
        Text(
          '$amount DZD',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isTotal ? 15 : 13,
            fontWeight:
                isTotal ? FontWeight.w700 : FontWeight.w400,
            color: isTotal ? _kGreen : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}