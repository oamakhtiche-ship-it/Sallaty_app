
// ═══════════════════════════════════════════════════════════════════
//  mobile.dart  —  Forgot password via Mobile Number
//
//  BACKEND ENDPOINT:
//    POST /api/auth/forgot-password
//    Body (form-urlencoded): contact = "0555000000"
//    200 OK: { "success": true, "message": "OTP envoyé à 0555000000" }
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'verificationcode.dart';
import 'apiservice.dart';

class ViaMobileNumberPage extends StatefulWidget {
  const ViaMobileNumberPage({super.key});

  @override
  State<ViaMobileNumberPage> createState() => _ViaMobileNumberPageState();
}

class _ViaMobileNumberPageState extends State<ViaMobileNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  String? _errorMessage;
  bool    _isLoading = false;

  // ──────────────────────────────────────────────────────────────
  //  POST /api/auth/forgot-password
  //  Body : contact = "0555000000"   ← @RequestParam Spring Boot
  //
  //  200 → { "success": true, "message": "OTP envoyé à ..." }
  //        → VerificationCodePage(contact: phone)
  //  4xx → affiche message d'erreur
  // ──────────────────────────────────────────────────────────────
  Future<void> _validateAndSend() async {
    final phone = _phoneController.text.trim();
    final regex = RegExp(r'^0[567]\d{8}$');

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number.');
      return;
    }
    if (!regex.hasMatch(phone)) {
      setState(() => _errorMessage = 'Invalid phone number');
      return;
    }

    setState(() { _errorMessage = null; _isLoading = true; });

    // ── BACKEND CALL via ApiService ───────────────────────────
    final result = await ApiService.forgotPassword(contact: phone);
    // ─────────────────────────────────────────────────────────

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationCodePage(contact: phone),
        ),
      );
    } else {
      setState(() => _errorMessage =
          result.errorMessage ?? 'Phone number not found');
    }
  }

  @override
  void dispose() { _phoneController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF72A843);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        toolbarHeight: 120,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Forgot Password?',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 26,
                color: primaryColor)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Center(
                child: Image.asset('assets/images/enter_mobile.png',
                    width: 280, height: 280, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                        width: 280, height: 280, color: Colors.grey[200],
                        child: const Center(child: Text('Image not found')))),
              ),

              const SizedBox(height: 20),

              const Text('Enter your phone number to\nreceive a reset code:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A), height: 1.5)),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mobile Number:',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 16,
                        fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
              ),

              const SizedBox(height: 8),

              Container(
                height: 57,
                decoration: BoxDecoration(
                  color: _errorMessage != null
                      ? const Color(0xFFFFEDED)
                      : const Color(0xFFF8FBF6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _errorMessage != null
                          ? Colors.red
                          : const Color(0xFF7C7C7C).withValues(alpha: 0.5),
                      width: 2),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: (_) {
                    if (_errorMessage != null)
                      setState(() => _errorMessage = null);
                  },
                  decoration: const InputDecoration(
                    counterText: '',
                    prefixIcon: Icon(Icons.phone, color: Colors.black),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 16, horizontal: 21),
                  ),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400)),
                  ),
                ),

              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                height: 61,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFA0CA09), Color(0xFF72A843)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndSend,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
