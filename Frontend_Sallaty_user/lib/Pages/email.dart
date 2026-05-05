
import 'package:flutter/material.dart';
import 'verificationcode.dart';
import 'apiservice.dart';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final TextEditingController _emailController = TextEditingController();
  bool    _hasError     = false;
  String? _errorMessage;
  bool    _isLoading    = false;

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  Future<void> _onSendPressed() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() { _hasError = true; _errorMessage = 'Please enter your email address'; });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() { _hasError = true; _errorMessage = 'Invalid email address'; });
      return;
    }

    setState(() { _hasError = false; _errorMessage = null; _isLoading = true; });

    // ── BACKEND CALL via ApiService ───────────────────────────
    final result = await ApiService.forgotPassword(contact: email);
    // ─────────────────────────────────────────────────────────

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationCodePage(contact: email),
        ),
      );
    } else {
      setState(() {
        _hasError     = true;
        _errorMessage = result.errorMessage ?? 'Email not found';
      });
    }
  }

  @override
  void dispose() { _emailController.dispose(); super.dispose(); }

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

              const Text('Enter your email to receive a\npassword reset code:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 18,
                      color: Color(0xFF1A1A1A), height: 1.5)),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Email address:',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 16,
                        fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
              ),

              const SizedBox(height: 8),

              Container(
                height: 57,
                decoration: BoxDecoration(
                  color: _hasError ? const Color(0xFFFFEDED) : const Color(0xFFF8FBF6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _hasError
                          ? Colors.red
                          : const Color(0xFF7C7C7C).withValues(alpha: 0.5),
                      width: 2),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_hasError)
                      {setState(() { _hasError = false; _errorMessage = null; });}
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.black),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 16, horizontal: 21),
                  ),
                ),
              ),

              if (_hasError && _errorMessage != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.red)),
                ),
              ],

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
                  onPressed: _isLoading ? null : _onSendPressed,
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