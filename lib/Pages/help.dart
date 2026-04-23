
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  static const String _base = 'http://10.0.2.2:8080';

  static const _categoryMeta = {
    'ORDERS_DELIVERY':         {'label': 'Orders & Delivery',       'icon': '🚚', 'bg': Color(0xFFFFF3E0)},
    'ACCOUNT_PROFILE':         {'label': 'Account & Profile',       'icon': '👤', 'bg': Color(0xFFE3F2FD)},
    'PAYMENTS':                {'label': 'Payments',                'icon': '💳', 'bg': Color(0xFFEDE7F6)},
    'MERCHANT_SELLING':        {'label': 'Merchant / Selling',      'icon': '🧑‍💼', 'bg': Color(0xFFE8F5E9)},
    'GENERAL_TROUBLESHOOTING': {'label': 'General Troubleshooting', 'icon': '🔧', 'bg': Color(0xFFFCE4EC)},
  };

  Map<String, List<Map<String, dynamic>>> _faqData = {};
  bool    _isLoading         = true;
  String? _error;
  String? _expandedCategory;
  int?    _expandedQuestion;

  @override
  void initState() {
    super.initState();
    _fetchFaq();
  }

  Future<void> _fetchFaq() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final resp = await http
          .get(Uri.parse('$_base/api/static/help'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body) as Map<String, dynamic>;
        final parsed = <String, List<Map<String, dynamic>>>{};
        raw.forEach((category, items) {
          if (items is List) {
            parsed[category] = items
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        });
        setState(() { _faqData = parsed; _isLoading = false; });
      } else {
        setState(() { _error = 'Server error (${resp.statusCode})'; _isLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Unable to load. Check your connection.'; _isLoading = false; });
    }
  }

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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF72A843)))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Chat Button ────────────────────────────────────────
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
                Text('Chat with Support 24/7',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Bandeau erreur ─────────────────────────────────────
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_outlined, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.orange.shade800))),
                  GestureDetector(
                    onTap: _fetchFaq,
                    child: Text('Retry',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── FAQ Categories ─────────────────────────────────────
          ..._categoryMeta.entries.map((catEntry) {
            final catKey = catEntry.key;
            final meta   = catEntry.value;
            final items  = _faqData[catKey] ?? [];
            final isOpen = _expandedCategory == catKey;

            return GestureDetector(
              onTap: () => setState(() {
                _expandedCategory = isOpen ? null : catKey;
                _expandedQuestion = null;
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECF3DF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: meta['bg'] as Color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(meta['icon'] as String, style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(meta['label'] as String,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ),
                          if (items.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF72A843).withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${items.length}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF72A843), fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(width: 8),
                          Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                        ],
                      ),
                    ),
                    if (isOpen) ...[
                      const Divider(height: 1, indent: 14, endIndent: 14),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('No questions available yet.',
                              style: TextStyle(fontSize: 13, color: Colors.black45)),
                        )
                      else
                        ...items.map((faq) {
                          final qId       = faq['id'] as int?;
                          final question  = faq['question']?.toString() ?? '';
                          final answer    = faq['answer']?.toString() ?? '';
                          final qExpanded = _expandedQuestion == qId;

                          return GestureDetector(
                            onTap: () => setState(() {
                              _expandedQuestion = qExpanded ? null : qId;
                            }),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(question,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                                        ),
                                        Icon(qExpanded ? Icons.remove : Icons.add,
                                            size: 18, color: const Color(0xFF72A843)),
                                      ],
                                    ),
                                  ),
                                  if (qExpanded) ...[
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(answer,
                                          style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.6)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // ── Still need help ────────────────────────────────────
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
                const Text('Still need help?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Divider(height: 20),

                // Phone
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.phone, color: Colors.redAccent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone support', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('+213 63 456 789',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF72A843))),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Email
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.email_outlined, color: Color(0xFF72A843), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email us', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          'sallatyapplication@gmail.com',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF72A843)),
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
    );
  }
}
