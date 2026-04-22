import 'package:flutter/material.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  String? _expandedItem;

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Orders & Delivery',
      'icon': '🚚',
      'iconBg': Color(0xFFFFF3E0),
      'content': 'Track your orders, manage deliveries, and resolve any delivery issues here.',
    },
    {
      'title': 'Account & Profile',
      'icon': '👤',
      'iconBg': Color(0xFFE3F2FD),
      'content': 'Manage your account settings, profile information, and security options.',
    },
    {
      'title': 'Payments',
      'icon': '💳',
      'iconBg': Color(0xFFEDE7F6),
      'content': 'View payment methods, transaction history, and resolve payment issues.',
    },
    {
      'title': 'Merchant / Selling',
      'icon': '🧑‍💼',
      'iconBg': Color(0xFFE8F5E9),
      'content': 'Learn how to create offers, manage your store, and grow your sales.',
    },
    {
      'title': 'General Troubleshooting',
      'icon': '🔧',
      'iconBg': Color(0xFFFCE4EC),
      'content': 'Fix common issues with the app, notifications, and account access.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FBF2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ── Chat Button ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFD0E6A5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💬', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Chat with Support 24/7',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── FAQ Items ──────────────────────────────
            ..._items.map((item) {
              final isExpanded = _expandedItem == item['title'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedItem = isExpanded ? null : item['title'] as String;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFFECF3DF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Icon box
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item['iconBg'] as Color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                item['icon'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Title
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Arrow
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      // Expanded content
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          item['content'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // ── Still need help ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 20),

                  // Phone
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.phone,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone support',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '+213 63 456 789',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF72A843),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Email
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF72A843),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email us',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'om_bouagal@esi.dz',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF72A843),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}