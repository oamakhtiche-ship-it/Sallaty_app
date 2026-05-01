import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup2.dart';
import 'login1.dart';

// ─── Base URL ─────────────────────────────────────────────────────────────────
const _kBase = 'https://ethanol-hemstitch-strongbox.ngrok-free.dev';

class SignUp1 extends StatefulWidget {
  const SignUp1({super.key});

  @override
  State<SignUp1> createState() => _SignUp1State();
}

class _SignUp1State extends State<SignUp1> {
  final _formKey = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── EMAIL / PASSWORD SIGN UP ──────────────────────────────────────────────
  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$_kBase/api/auth/register/step1'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'ngrok-skip-browser-warning': 'true',
        },
        body: {
          'contact':   _emailController.text.trim(),
          'password':  _passwordController.text,
          'password2': _confirmController.text,
        },
      );

      if (!mounted) return;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final success = body['success'] == true;
      final userId = body['userId'] as int?;

      if (success && userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignUp2(userId: userId),
          ),
        );
      } else {
        final msg = body['message']?.toString() ?? 'Registration failed (${res.statusCode})';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // ── Title ─────────────────────────────────────────────────
                  const Center(
                    child: Text(
                      'Create an account',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF72A843),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ── Progress bar (step 1 of 3) ────────────────────────────
                  Center(
                    child: Container(
                      width: 180,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xA0D9D9D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6BA539),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // ── Email ─────────────────────────────────────────────────
                  const Text('Email:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter your email';
                      }
                      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Password ──────────────────────────────────────────────
                  const Text('Password:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.remove_red_eye_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Confirm Password ──────────────────────────────────────
                  const Text('Confirm Password:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.remove_red_eye_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm your password';
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 50),

                  // ── Sign Up Button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 51,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomRight,
                          end: Alignment.topLeft,
                          colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign Up',
                                style: TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Sign In Link ──────────────────────────────────────────
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          const TextSpan(text: 'Already have an account ?  '),
                          TextSpan(
                            text: 'Sign in',
                            style: const TextStyle(
                              color: Color(0xFF6BA539),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const Login1()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}