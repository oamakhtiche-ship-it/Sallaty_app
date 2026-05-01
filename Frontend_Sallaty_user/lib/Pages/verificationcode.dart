import 'package:flutter/material.dart';
import 'apiservice.dart';
import 'usersession.dart';
import 'resetpassword.dart';

class VerificationCodePage extends StatefulWidget {
  final String contact;
  final String? mode; // 'changeContact' → update contact flow

  const VerificationCodePage({
    super.key,
    required this.contact,
    this.mode,
  });

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the verification code');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    try {
      if (widget.mode == 'changeContact') {
        final result = await ApiService.updateContact(
          newContact: widget.contact,
          otpCode: code,
        );
        if (!mounted) return;
        if (result.success) {
          final session = UserSession();
          if (widget.contact.contains('@')) {
            session.email = widget.contact;
          } else {
            session.phone = widget.contact;
          }
          await session.save();
          Navigator.pop(context, true);
        } else {
          setState(() => _error = result.errorMessage ?? 'Invalid code');
        }
      } else {
        // ✅ FIXED — navigue directement avec le code, pas de nouvel appel API
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              contact: widget.contact,
              otpCode: code,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Connection error. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _resendCode() async {
  setState(() { _isLoading = true; _error = null; });
  try {
    // ✅ FIX — utilise le bon endpoint selon le mode
    if (widget.mode == 'changeContact') {
      await ApiService.sendContactOtp(widget.contact);
    } else {
      await ApiService.sendOtp(widget.contact);
    }
  } catch (_) {}
  if (mounted) setState(() => _isLoading = false);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Code'),
        backgroundColor: const Color(0xFF72A843),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Enter the code sent to',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(widget.contact,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(
                    color: Colors.grey.shade300, fontSize: 28),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF72A843))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF72A843), width: 2)),
                      errorText: _error,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF72A843),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _resendCode,
                child: const Text('Resend Code',
                    style: TextStyle(color: Color(0xFF72A843))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}