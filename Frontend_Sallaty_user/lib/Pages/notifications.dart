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

  bool _generalNotification = true;
  bool _sound               = false;
  bool _vibrate             = true;
  bool _appUpdates          = false;
  bool _billReminder        = true;
  bool _promotion           = true;
  bool _discountAvailable   = false;
  bool _paymentRequest      = false;
  bool _newServiceAvailable = false;
  bool _newTipsAvailable    = true;

  static const String _prefsKey = 'notification_prefs';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // ── Charge depuis backend puis fallback local ─────────────────
  Future<void> _loadPrefs() async {
    // 1. Essaie de charger depuis le backend
    final userId = UserSession().id;
    if (userId != null) {
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/settings/$userId'),
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Authorization': 'Bearer ${UserSession().token ?? ''}',
          },
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          _applyData(data);
          setState(() => _isLoading = false);
          return;
        }
      } catch (_) {}
    }

    // 2. Fallback — charge depuis SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _applyData(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  void _applyData(Map<String, dynamic> data) {
    setState(() {
      _generalNotification  = data['generalNotification']  ?? true;
      _sound                = data['sound']                ?? false;
      _vibrate              = data['vibrate']              ?? true;
      _appUpdates           = data['appUpdates']           ?? false;
      _billReminder         = data['billReminder']         ?? true;
      _promotion            = data['promotion']            ?? true;
      _discountAvailable    = data['discountAvailable']    ?? false;
      _paymentRequest       = data['paymentRequest']       ?? false;
      _newServiceAvailable  = data['newServiceAvailable']  ?? false;
      _newTipsAvailable     = data['newTipsAvailable']     ?? true;
    });
  }

  // ── Sauvegarde local + backend ────────────────────────────────
  Future<void> _savePrefs() async {
    final data = {
      'generalNotification': _generalNotification,
      'sound':               _sound,
      'vibrate':             _vibrate,
      'appUpdates':          _appUpdates,
      'billReminder':        _billReminder,
      'promotion':           _promotion,
      'discountAvailable':   _discountAvailable,
      'paymentRequest':      _paymentRequest,
      'newServiceAvailable': _newServiceAvailable,
      'newTipsAvailable':    _newTipsAvailable,
    };

    // 1. Local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(data));

    // 2. Backend — PUT /api/settings/{userId}
    final userId = UserSession().id;
    if (userId != null) {
      try {
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/settings/$userId'),
          headers: {
            'Content-Type'              : 'application/json',
            'ngrok-skip-browser-warning': 'true',
            'Authorization': 'Bearer ${UserSession().token ?? ''}',
          },
          body: jsonEncode(data),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[NotificationsPage] sync error: $e');
      }
    }
  }

  void _toggle(bool newVal, void Function(bool) setter) {
    setState(() => setter(newVal));
    _savePrefs();
  }

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
          _buildSection(
            title: 'Common',
            items: [
              _buildToggleItem('General Notification', _generalNotification,
                  (val) => _toggle(val, (v) => _generalNotification = v)),
              _buildToggleItem('Sound', _sound,
                  (val) => _toggle(val, (v) => _sound = v)),
              _buildToggleItem('Vibrate', _vibrate,
                  (val) => _toggle(val, (v) => _vibrate = v)),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: 'System & services update',
            items: [
              _buildToggleItem('App updates', _appUpdates,
                  (val) => _toggle(val, (v) => _appUpdates = v)),
              _buildToggleItem('Bill Reminder', _billReminder,
                  (val) => _toggle(val, (v) => _billReminder = v)),
              _buildToggleItem('Promotion', _promotion,
                  (val) => _toggle(val, (v) => _promotion = v)),
              _buildToggleItem('Discount Available', _discountAvailable,
                  (val) => _toggle(val, (v) => _discountAvailable = v)),
              _buildToggleItem('Payment Request', _paymentRequest,
                  (val) => _toggle(val, (v) => _paymentRequest = v)),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: 'Others',
            items: [
              _buildToggleItem('New Service Available', _newServiceAvailable,
                  (val) => _toggle(val, (v) => _newServiceAvailable = v)),
              _buildToggleItem('New Tips Available', _newTipsAvailable,
                  (val) => _toggle(val, (v) => _newTipsAvailable = v)),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF72A843).withOpacity(0.08),
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

  Widget _buildSection({required String title, required List<Widget> items}) {
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
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF72A843),
            activeTrackColor: const Color(0xFF72A843).withOpacity(0.4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
