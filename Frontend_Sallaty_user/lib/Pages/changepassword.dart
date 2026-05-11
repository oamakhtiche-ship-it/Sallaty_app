

import 'package:flutter/material.dart';
import 'apiservice.dart';
import 'usersession.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {

  final _oldCtrl     = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showOld     = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _isSaving    = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Validation locale ─────────────────────────────────────────
  String? _validate() {
    if (_oldCtrl.text.trim().isEmpty)   return 'Please enter your current password';
    if (_newCtrl.text.length < 6)       return 'New password must be at least 6 characters';
    if (_newCtrl.text != _confirmCtrl.text) return 'Passwords do not match';
    if (_oldCtrl.text == _newCtrl.text) return 'New password must be different from the current one';
    return null;
  }

  // ── Save → PUT /api/profile/password ─────────────────────────
Future<void> _save() async {
    final error = _validate();
    if (error != null) { _showSnack(error, isError: true); return; }

    
    print('=== TOKEN: ${UserSession().token}');
    print('=== ID: ${UserSession().id}');

    setState(() => _isSaving = true);

    final result = await ApiService.updatePassword(
      oldPassword: _oldCtrl.text.trim(),
      newPassword: _newCtrl.text.trim(),
      confirm:     _confirmCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      _showSnack('Password updated successfully ✅');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } else {
      _showSnack(result.errorMessage ?? 'Failed to update password', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF72A843),
    ));
  }
═
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Change Password',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Info banner ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF72A843).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF72A843).withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lock_outline, color: Color(0xFF72A843), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter your current password and choose a new one. '
                      'Your new password must be at least 6 characters.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Current Password ──────────────────────────────
            _buildPasswordField(
              label: 'Current Password',
              controller: _oldCtrl,
              show: _showOld,
              onToggle: () => setState(() => _showOld = !_showOld),
            ),
            const SizedBox(height: 16),

            // ── New Password ──────────────────────────────────
            _buildPasswordField(
              label: 'New Password',
              controller: _newCtrl,
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 16),

            // ── Confirm Password ──────────────────────────────
            _buildPasswordField(
              label: 'Confirm New Password',
              controller: _confirmCtrl,
              show: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
            ),

            // ── Indicateur de force (dynamique) ──────────────
            const SizedBox(height: 8),
            _buildStrengthIndicator(),

            const SizedBox(height: 36),

            // ── Save button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF72A843),
                  disabledBackgroundColor:
                      const Color(0xFF72A843).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Update Password',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Password field avec show/hide ─────────────────────────────
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(38, 208, 230, 165),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            obscureText: !show,
            onChanged: (_) => setState(() {}),   
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey, size: 20,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Indicateur de force du mot de passe (dynamique) ──────────
  Widget _buildStrengthIndicator() {
    final pw = _newCtrl.text;
    if (pw.isEmpty) return const SizedBox.shrink();

    final hasLength   = pw.length >= 8;
    final hasUpper    = pw.contains(RegExp(r'[A-Z]'));
    final hasDigit    = pw.contains(RegExp(r'[0-9]'));
    final hasSpecial  = pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    final score       = [hasLength, hasUpper, hasDigit, hasSpecial]
                          .where((b) => b).length;

    final label = score <= 1 ? 'Weak' : score == 2 ? 'Fair' : score == 3 ? 'Good' : 'Strong';
    final color = score <= 1 ? Colors.redAccent
                : score == 2 ? Colors.orange
                : score == 3 ? Colors.amber
                : const Color(0xFF72A843);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < score ? color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}