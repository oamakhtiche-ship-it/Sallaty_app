import 'package:flutter/material.dart';

class PendingVerificationPage extends StatelessWidget {
  const PendingVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Offers',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon ──────────────────────────────
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF72A843).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 60,
                  color: Color(0xFF72A843),
                ),
              ),
              const SizedBox(height: 28),

              // ── Title ─────────────────────────────
              const Text(
                'Verification Pending',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Subtitle ──────────────────────────
              const Text(
                'Your merchant account is currently under review by our admin team. You will be able to create and manage offers once your account is verified.',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Status badge ──────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule,
                        color: Color(0xFFB8860B), size: 16),
                    SizedBox(width: 8),
                    Text('Status: PENDING',
                        style: TextStyle(
                            color: Color(0xFFB8860B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

            ],
          ),
        ),
      ),
    );
  }
}