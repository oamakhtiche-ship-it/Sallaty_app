import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'usersession.dart';
import 'apiservice.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;

  // ── COMMON ────────────────────────────────────────────────────
  bool _generalNotification = true;
  bool _sound               = true;
  bool _vibrate             = true;

  // ── ORDERS ────────────────────────────────────────────────────
  bool _orderConfirmed = true;
  bool _orderCancelled = true;
  bool _orderCompleted = true;
  bool _paymentSuccess = true;

  // ── PROMOTIONS ────────────────────────────────────────────────
  bool _newDiscount    = true;
  bool _expiringOffer  = true;
  bool _newOfferNearby = true;

  // ── OTHERS ────────────────────────────────────────────────────
  bool _broadcastMessage = true;
  bool _marchandVerified = true;

  static const String _prefsKey = 'notification_prefs';

  // ── Base URL & auth headers ───────────────────────────────────
  // ✅ No userId in URL — controller resolves it from JWT
  static String get _settingsUrl => '${ApiConfig.baseUrl}/api/settings';

  Map<String, String> get _headers => {
    'Content-Type':               'application/json',
    'ngrok-skip-browser-warning': 'true',
    'Authorization': 'Bearer ${UserSession().token ?? ''}',
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // ════════════════════════════════════════════════════════════════
  //  LOAD  →  GET /api/settings   (no userId in URL)
  // ════════════════════════════════════════════════════════════════
  Future<void> _loadPrefs() async {
    try {
      final res = await http
          .get(Uri.parse(_settingsUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        _applyData(jsonDecode(res.body) as Map<String, dynamic>);
        setState(() => _isLoading = false);
        return;
      }
    } catch (_) {}

    // Fallback — SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_prefsKey);
    if (raw != null) {
      try { _applyData(jsonDecode(raw) as Map<String, dynamic>); } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  // ── Apply backend field names exactly ────────────────────────
  void _applyData(Map<String, dynamic> data) {
    setState(() {
      _generalNotification = data['generalNotification'] ?? true;
      _sound               = data['sound']               ?? true;
      _vibrate             = data['vibrate']             ?? true;
      _orderConfirmed      = data['orderConfirmed']      ?? true;
      _orderCancelled      = data['orderCancelled']      ?? true;
      _orderCompleted      = data['orderCompleted']      ?? true;
      _paymentSuccess      = data['paymentSuccess']      ?? true;
      _newDiscount         = data['newDiscount']         ?? true;
      _expiringOffer       = data['expiringOffer']       ?? true;
      _newOfferNearby      = data['newOfferNearby']      ?? true;
      _broadcastMessage    = data['broadcastMessage']    ?? true;
      _marchandVerified    = data['marchandVerified']    ?? true;
    });
  }

  // ════════════════════════════════════════════════════════════════
  //  TOGGLE  →  PUT /api/settings/toggle/{type}
  //  Uses the atomic toggle endpoint — no full object needed
  // ════════════════════════════════════════════════════════════════
  Future<void> _toggle(
    String type,
    bool newVal,
    void Function(bool) setter,
  ) async {
    // 1. Optimistic UI update
    setState(() => setter(newVal));

    // 2. Persist locally
    _saveLocal();

    // 3. ✅ Correct endpoint: PUT /api/settings/toggle/{type}
    try {
      final res = await http
          .put(
            Uri.parse('$_settingsUrl/toggle/$type'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        // Sync returned state from backend (source of truth)
        _applyData(jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        // Revert on failure
        setState(() => setter(!newVal));
        _showSnack('Failed to save (${res.statusCode})');
      }
    } catch (e) {
      // Revert on network error
      setState(() => setter(!newVal));
      _showSnack('Network error — change not saved');
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  SAVE ALL  →  PUT /api/settings   (full object, no userId)
  //  Used only if you want to bulk-save (e.g. on page exit)
  // ════════════════════════════════════════════════════════════════
  Future<void> _saveAll() async {
    final data = _toMap();
    _saveLocal();

    try {
      await http
          .put(
            Uri.parse(_settingsUrl),        // ✅ no /{userId}
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[NotificationsPage] saveAll error: $e');
    }
  }

  // ── Local cache ───────────────────────────────────────────────
  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_toMap()));
  }

  Map<String, dynamic> _toMap() => {
    'generalNotification': _generalNotification,
    'sound':               _sound,
    'vibrate':             _vibrate,
    'orderConfirmed':      _orderConfirmed,
    'orderCancelled':      _orderCancelled,
    'orderCompleted':      _orderCompleted,
    'paymentSuccess':      _paymentSuccess,
    'newDiscount':         _newDiscount,
    'expiringOffer':       _expiringOffer,
    'newOfferNearby':      _newOfferNearby,
    'broadcastMessage':    _broadcastMessage,
    'marchandVerified':    _marchandVerified,
  };

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5FFF0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF72A843)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FFF0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [

          // ── COMMON ────────────────────────────────────────────
          _buildSection(title: 'Common', items: [
            _buildToggleItem(
              'General Notification', _generalNotification,
              (v) => _toggle('generalNotification', v, (x) => _generalNotification = x),
            ),
            _buildToggleItem(
              'Sound', _sound,
              (v) => _toggle('sound', v, (x) => _sound = x),
            ),
            _buildToggleItem(
              'Vibrate', _vibrate,
              (v) => _toggle('vibrate', v, (x) => _vibrate = x),
            ),
          ]),
          const SizedBox(height: 24),

          // ── ORDERS ────────────────────────────────────────────
          _buildSection(title: 'Orders', items: [
            _buildToggleItem(
              'Order Confirmed', _orderConfirmed,
              (v) => _toggle('orderConfirmed', v, (x) => _orderConfirmed = x),
            ),
            _buildToggleItem(
              'Order Cancelled', _orderCancelled,
              (v) => _toggle('orderCancelled', v, (x) => _orderCancelled = x),
            ),
            _buildToggleItem(
              'Order Completed', _orderCompleted,
              (v) => _toggle('orderCompleted', v, (x) => _orderCompleted = x),
            ),
            _buildToggleItem(
              'Payment Success', _paymentSuccess,
              (v) => _toggle('paymentSuccess', v, (x) => _paymentSuccess = x),
            ),
          ]),
          const SizedBox(height: 24),

          // ── PROMOTIONS ────────────────────────────────────────
          _buildSection(title: 'Promotions', items: [
            _buildToggleItem(
              'New Discount', _newDiscount,
              (v) => _toggle('newDiscount', v, (x) => _newDiscount = x),
            ),
            _buildToggleItem(
              'Expiring Offer', _expiringOffer,
              (v) => _toggle('expiringOffer', v, (x) => _expiringOffer = x),
            ),
            _buildToggleItem(
              'New Offer Nearby', _newOfferNearby,
              (v) => _toggle('newOfferNearby', v, (x) => _newOfferNearby = x),
            ),
          ]),
          const SizedBox(height: 24),

          // ── OTHERS ────────────────────────────────────────────
          _buildSection(title: 'Others', items: [
            _buildToggleItem(
              'Broadcast Message', _broadcastMessage,
              (v) => _toggle('broadcastMessage', v, (x) => _broadcastMessage = x),
            ),
            _buildToggleItem(
              'Merchant Verified', _marchandVerified,
              (v) => _toggle('marchandVerified', v, (x) => _marchandVerified = x),
            ),
          ]),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF72A843).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: Color(0xFF72A843)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preferences are automatically saved',
                    style: TextStyle(fontSize: 12, color: Color(0xFF72A843)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildToggleItem(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, color: Colors.black87)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF72A843),
            activeTrackColor:
                const Color(0xFF72A843).withValues(alpha: 0.4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}