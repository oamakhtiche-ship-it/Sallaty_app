import 'package:flutter/material.dart';
import 'resetpassword.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verification Code',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.lightGreen),
      home: const VerificationCodePage(),
    );
  }
}

enum VerifyState { idle, success, error }

class VerificationCodePage extends StatefulWidget {
  const VerificationCodePage({super.key});

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final Color primaryColor = const Color(0xFF72A843);
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  VerifyState _state = VerifyState.idle;
  bool _isLoading = false;
  bool _isResending = false;

  String get _enteredCode => _controllers.map((c) => c.text).join();

  // ── Vérification du code ──────────────────────────────────────────
  Future<void> _verifyCode() async {
    final code = _enteredCode;
    if (code.length < 6) return;

    setState(() => _isLoading = true);

    // ════════════════════════════════════════════════════════════════
    // TODO: Remplace par appel API Django :
    //
    // import 'package:http/http.dart' as http;
    // import 'dart:convert';
    //
    // final response = await http.post(
    //   Uri.parse('https://TON_API/verify-otp/'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'otp': code}),
    // );
    // final bool isValid = response.statusCode == 200;
    // ════════════════════════════════════════════════════════════════
    await Future.delayed(const Duration(milliseconds: 800));
    final bool isValid = (code == '123456');

    setState(() {
      _isLoading = false;
      _state = isValid ? VerifyState.success : VerifyState.error;
    });
  }

  // ── Renvoyer le code ──────────────────────────────────────────────
  Future<void> _resendCode() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    // ════════════════════════════════════════════════════════════════
    // TODO: Remplace par appel API Django :
    //
    // import 'package:http/http.dart' as http;
    // import 'dart:convert';
    //
    // final response = await http.post(
    //   Uri.parse('https://TON_API/resend-otp/'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'email': 'EMAIL_OU_PHONE_UTILISATEUR'}),
    // );
    // final bool success = response.statusCode == 200;
    // ════════════════════════════════════════════════════════════════
    await Future.delayed(const Duration(milliseconds: 800));
    final bool success = true;

    setState(() => _isResending = false);

    if (success && mounted) {
      for (final c in _controllers) c.clear();
      setState(() => _state = VerifyState.idle);
      FocusScope.of(context).requestFocus(FocusNode());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Code resent successfully !',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetState() {
    if (_state == VerifyState.error) {
      setState(() => _state = VerifyState.idle);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // ── Titre ─────────────────────────────────────────────
              Text(
                'Verification Code',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),

              // ── Sous-titre dynamique ──────────────────────────────
              Text(
                _state == VerifyState.success
                    ? 'Code verified successfully\nYou can now reset\nyour password.'
                    : _state == VerifyState.error
                    ? 'Wrong code , try again'
                    : 'We have sent you a code\nto verify your email address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: _state == VerifyState.error
                      ? const Color(0xFFFF0000)
                      : const Color(0xFF717270),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // ── 6 champs OTP ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final Color boxColor = _state == VerifyState.error
                      ? const Color(0xFFFF9D9D).withOpacity(0.80)
                      : _state == VerifyState.success
                      ? const Color(0xFFDCEDC8)
                      : const Color(0xFFD7D8D7).withOpacity(0.80);

                  final Color borderColor = _state == VerifyState.error
                      ? const Color(0xFFFF7C7C)
                      : _state == VerifyState.success
                      ? primaryColor
                      : const Color(0xFFC3C4C3);

                  return Padding(
                    padding: EdgeInsets.only(right: index < 5 ? 7.0 : 0.0),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: TextField(
                        controller: _controllers[index],
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        enableInteractiveSelection: false,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 10),
                        ),
                        onChanged: (value) {
                          _resetState();
                          if (value.length == 1 && index < 5) {
                            FocusScope.of(context).nextFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // ── Checkmark vert (succès uniquement) ────────────────
              if (_state == VerifyState.success) ...[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── "Didn't receive anything?" (caché en succès) ──────
              if (_state != VerifyState.success) ...[
                Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1A1A1A),
                        ),
                        children: [
                          const TextSpan(text: "Didn't receive anything? "),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: _isResending ? null : _resendCode,
                              child: Text(
                                'send',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: _isResending
                                      ? Colors.grey
                                      : primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _isResending ? null : _resendCode,
                      child: _isResending
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      )
                          : Text(
                        'again',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 60),

              // ── Bouton Verify / Reset your password ───────────────
              Container(
                width: double.infinity,
                height: 61,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA0CA09), Color(0xFF72A843)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    if (_state == VerifyState.success) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const ResetPasswordPage(),
                        ),
                      );
                    } else {
                      _verifyCode();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _state == VerifyState.success
                        ? 'Reset your password'
                        : 'Verify',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8FBF6),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
