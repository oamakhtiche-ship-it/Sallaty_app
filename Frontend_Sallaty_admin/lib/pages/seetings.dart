import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'appcontent.dart';
import 'admin.dart';

const kBaseUrl = 'https://headstand-rosy-chlorine.ngrok-free.dev';

// ─── API Service ──────────────────────────────────────────────────────────────

class SettingsApiService {
  // GET /api/config
  static Future<Map<String, dynamic>> getConfig(String token) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/api/config'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('getConfig failed: ${res.statusCode}');
  }

  // PUT /api/config/commission/{rate}
  static Future<void> updateCommission(String token, double rate) async {
    final res = await http.put(
      Uri.parse('$kBaseUrl/api/config/commission/$rate'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('updateCommission failed: ${res.statusCode}');
  }

  // PUT /api/config/transport/{cost}
  static Future<void> updateTransport(String token, double cost) async {
    final res = await http.put(
      Uri.parse('$kBaseUrl/api/config/transport/$cost'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('updateTransport failed: ${res.statusCode}');
  }

  // PUT /api/config/mintopup/{amount}
  static Future<void> updateMinTopUp(String token, double amount) async {
    final res = await http.put(
      Uri.parse('$kBaseUrl/api/config/mintopup/$amount'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('updateMinTopUp failed: ${res.statusCode}');
  }

  // PUT /api/config/cancel/{hours}
  static Future<void> updateCancelDeadline(String token, int hours) async {
    final res = await http.put(
      Uri.parse('$kBaseUrl/api/config/cancel/$hours'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('updateCancelDeadline failed: ${res.statusCode}');
  }

  // PUT /api/config/expiry/{hours}
  static Future<void> updateExpiry(String token, int hours) async {
    final res = await http.put(
      Uri.parse('$kBaseUrl/api/config/expiry/$hours'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('updateExpiry failed: ${res.statusCode}');
  }
}

// ─── Settings Body ────────────────────────────────────────────────────────────

class SettingsBody extends StatefulWidget {
  final String token;
  const SettingsBody({super.key, required this.token});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  bool _saving = false;

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF72A843)),
    );
  }

  // ── Financial Settings Dialog ──────────────────────────────────────────────
  void _showFinancialSettings() async {
    // Load current config from backend
    Map<String, dynamic>? config;
    try {
      config = await SettingsApiService.getConfig(widget.token);
    } catch (_) {}

    final commissionCtrl = TextEditingController(
        text: (config?['commissionRate'] ?? 15).toString());
    final transportCtrl = TextEditingController(
        text: (config?['transportCost'] ?? 200).toString());
    final rechargeCtrl = TextEditingController(
        text: (config?['minTopUp'] ?? 500).toString());

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFF8FBF6),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Financial Settings',
                      style: TextStyle(
                          fontSize: 20, fontFamily: 'poppins',
                          fontWeight: FontWeight.w600, color: Color(0xFF4C702D))),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF555555)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Commission',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0A0A0A))),
              const SizedBox(height: 5),
              _NumberField(controller: commissionCtrl, suffix: '%'),
              const SizedBox(height: 14),
              const Text('Transport Cost',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0A0A0A))),
              const SizedBox(height: 5),
              _NumberField(controller: transportCtrl, suffix: 'DA'),
              const SizedBox(height: 14),
              const Text('Minimum Recharge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0A0A0A))),
              const SizedBox(height: 6),
              _NumberField(controller: rechargeCtrl, suffix: 'DA'),
              const SizedBox(height: 20),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : _SaveButton(onTap: () async {
                      final commission = double.tryParse(commissionCtrl.text.trim());
                      final transport  = double.tryParse(transportCtrl.text.trim());
                      final recharge   = double.tryParse(rechargeCtrl.text.trim());

                      if (commission == null || transport == null || recharge == null) {
                        _showError('Valeurs invalides !');
                        return;
                      }

                      setState(() => _saving = true);
                      try {
                        await SettingsApiService.updateCommission(widget.token, commission);
                        await SettingsApiService.updateTransport(widget.token, transport);
                        await SettingsApiService.updateMinTopUp(widget.token, recharge);
                        Navigator.pop(ctx);
                        _showSuccess('Paramètres financiers sauvegardés ✅');
                      } catch (e) {
                        _showError(e.toString());
                      } finally {
                        setState(() => _saving = false);
                      }
                    }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cancellation Policy Dialog ─────────────────────────────────────────────
  void _showCancellationPolicy() async {
    Map<String, dynamic>? config;
    try {
      config = await SettingsApiService.getConfig(widget.token);
    } catch (_) {}

    final hoursCtrl = TextEditingController(
        text: (config?['cancelDeadlineHours'] ?? 1).toString());

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cancellation Policy',
                      style: TextStyle(
                          fontSize: 20, fontFamily: 'poppins',
                          fontWeight: FontWeight.w600, color: Color(0xFF4C702D))),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF555555)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Client can cancel until:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0A0A0A))),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(width: 80, child: _NumberField(controller: hoursCtrl, suffix: '')),
                  const SizedBox(width: 10),
                  const Text('hour before pickup',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0A0A0A))),
                ],
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Clients won't be able to cancel their orders after this time period.",
                  style: TextStyle(fontSize: 16, color: Color(0xFF0A0A0A)),
                ),
              ),
              const SizedBox(height: 20),
              _SaveButton(onTap: () async {
                final hours = int.tryParse(hoursCtrl.text.trim());
                if (hours == null) { _showError('Valeur invalide !'); return; }
                setState(() => _saving = true);
                try {
                  await SettingsApiService.updateCancelDeadline(widget.token, hours);
                  Navigator.pop(ctx);
                  _showSuccess('Politique d\'annulation mise à jour ✅');
                } catch (e) {
                  _showError(e.toString());
                } finally {
                  setState(() => _saving = false);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Notification Settings Dialog ───────────────────────────────────────────
  void _showNotificationSettings() async {
    Map<String, dynamic>? config;
    try {
      config = await SettingsApiService.getConfig(widget.token);
    } catch (_) {}

    String selected = (config?['hoursBeforeExpiry'] ?? 24).toString();
    // Normalise to one of our 3 options
    if (!['6', '12', '24'].contains(selected)) selected = '24';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Notification Settings',
                        style: TextStyle(
                            fontSize: 20, fontFamily: 'poppins',
                            fontWeight: FontWeight.w600, color: Color(0xFF4C702D))),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, size: 20, color: Color(0xFF555555)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Send alert before expiration',
                    style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                const SizedBox(height: 12),
                _RadioOption(
                  label: '24 hours', value: '24', groupValue: selected,
                  onChanged: (v) => setDialogState(() => selected = v!),
                ),
                const SizedBox(height: 8),
                _RadioOption(
                  label: '12 hours', value: '12', groupValue: selected,
                  onChanged: (v) => setDialogState(() => selected = v!),
                ),
                const SizedBox(height: 8),
                _RadioOption(
                  label: '6 hours', value: '6', groupValue: selected,
                  onChanged: (v) => setDialogState(() => selected = v!),
                ),
                const SizedBox(height: 20),
                _SaveButton(onTap: () async {
                  final hours = int.parse(selected);
                  setState(() => _saving = true);
                  try {
                    await SettingsApiService.updateExpiry(widget.token, hours);
                    Navigator.pop(ctx);
                    _showSuccess('Notifications mises à jour ✅');
                  } catch (e) {
                    _showError(e.toString());
                  } finally {
                    setState(() => _saving = false);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          const Text('Settings',
              style: TextStyle(
                  fontSize: 32, fontFamily: 'inter',
                  fontWeight: FontWeight.w600, color: Color(0xFF0A0A0A))),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.attach_money_rounded,
            label: 'Financial Settings',
            onTap: _showFinancialSettings,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications Settings',
            onTap: _showNotificationSettings,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.schedule_rounded,
            label: 'Cancellation Policy',
            onTap: _showCancellationPolicy,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'App Content',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppContentScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.manage_accounts_outlined,
            label: 'Admin Management',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminManagementPage(token: widget.token)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDCE9C8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF72A843)),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: 20, fontFamily: 'poppins',
                    fontWeight: FontWeight.w600, color: Color(0xFF4C702D))),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF4C702D)),
          ],
        ),
      ),
    );
  }
}

// ─── Number Field ─────────────────────────────────────────────────────────────
class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  const _NumberField({required this.controller, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          if (suffix.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFE8E8E8),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              alignment: Alignment.center,
              child: Text(suffix,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF555555))),
            ),
        ],
      ),
    );
  }
}

// ─── Radio Option ─────────────────────────────────────────────────────────────
class _RadioOption extends StatelessWidget {
  final String label, value, groupValue;
  final ValueChanged<String?> onChanged;
  const _RadioOption({required this.label, required this.value,
      required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF72A843) : const Color(0xFFAAAAAA),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF72A843)),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? const Color(0xFF72A843) : const Color(0xFF555555),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              )),
        ],
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFDCE9C8),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Text('Save Changes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF72A843))),
      ),
    );
  }
}
