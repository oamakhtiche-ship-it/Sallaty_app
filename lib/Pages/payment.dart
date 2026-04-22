import 'package:flutter/material.dart';
import 'carddetails.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestPaymentPage(),
    );
  }
}

class TestPaymentPage extends StatelessWidget {
  const TestPaymentPage({super.key});

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaymentSheet(),
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
        title: const Text(
          'Test Payment',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Color(0xFF72A843),
          ),
        ),
      ),
      body: Center(
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
                color: const Color(0xFF72A843).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _showPaymentSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Pay Now',
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
    );
  }
}

// ── Payment Bottom Sheet ──────────────────────────────────────────────
class PaymentSheet extends StatelessWidget {
  const PaymentSheet({super.key});

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
              child: const Icon(Icons.close, color: Color(0xFF1A1A1A), size: 22),
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
            subtitle: 'pay securly with your card',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CardDetailsPage(
                    totalAmount: '3560 DZD', // ← remplace par ta variable
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
              // logique cash on delivery
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