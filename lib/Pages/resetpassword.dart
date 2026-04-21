import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reset Password',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.lightGreen),
      home: const ResetPasswordPage(),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _passwordError;
  String? _confirmPasswordError;

  // ── Validation ────────────────────────────────────────────────────
  bool _validate() {
    String? passwordErr;
    String? confirmErr;

    if (_passwordController.text.isEmpty) {
      passwordErr = 'Password is required';
    } else if (_passwordController.text.length < 6) {
      passwordErr = 'Password must be at least 6 characters';
    }

    if (_confirmPasswordController.text.isEmpty) {
      confirmErr = 'Please confirm your password';
    } else if (_passwordController.text != _confirmPasswordController.text) {
      confirmErr = 'Passwords do not match';
    }

    setState(() {
      _passwordError = passwordErr;
      _confirmPasswordError = confirmErr;
    });

    return passwordErr == null && confirmErr == null;
  }

  // ── Appel API ─────────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    // ┌─────────────────────────────────────────────────────────────┐
    // │  Pour connecter ton API, remplace ce bloc par :            │
    // │                                                             │
    // │  final response = await http.post(                         │
    // │    Uri.parse('https://TON_API/reset-password'),            │
    // │    body: {                                                  │
    // │      'password': _passwordController.text,                 │
    // │    },                                                       │
    // │  );                                                         │
    // │  final bool success = response.statusCode == 200;          │
    // └─────────────────────────────────────────────────────────────┘
    await Future.delayed(const Duration(milliseconds: 800));
    final bool success = true; // ← remplace par la réponse API

    setState(() => _isLoading = false);

    if (success && mounted) {
      // ── Navigation vers la page d'accueil ────────────────────────
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false, // supprime tout l'historique de navigation
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF72A843);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),

              // ── Titre ─────────────────────────────────────────────
              Text(
                'Reset password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 17),

              // ── Image ─────────────────────────────────────────────
              Center(
                child: Image.asset(
                  'assets/reset_password.png',
                  width: 219,
                  height: 251,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 219,
                      height: 251,
                      color: Colors.grey[200],
                      child: const Center(child: Text('Image non trouvée')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // ── Sous-titre ────────────────────────────────────────
              Text(
                'Create new password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1E1E1E).withValues(alpha:0.63),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 40),

              // ── Label Password ────────────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Champ Password ────────────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _passwordError != null
                        ? Colors.red
                        : const Color(0xFF7C7C7C).withValues(alpha:0.5),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 21,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF1A1A1A),
                        size: 22.23,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                  ),
                ),
              ),

              // ── Erreur Password ───────────────────────────────────
              if (_passwordError != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _passwordError!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Label Confirm Password ────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Confirm Password:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Champ Confirm Password ────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _confirmPasswordError != null
                        ? Colors.red
                        : const Color(0xFF7C7C7C).withValues(alpha:0.5),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  onChanged: (_) {
                    if (_confirmPasswordError != null) {
                      setState(() => _confirmPasswordError = null);
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 21,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF1A1A1A),
                        size: 22.23,
                      ),
                      onPressed: () {
                        setState(() =>
                        _showConfirmPassword = !_showConfirmPassword);
                      },
                    ),
                  ),
                ),
              ),

              // ── Erreur Confirm Password ───────────────────────────
              if (_confirmPasswordError != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _confirmPasswordError!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 100),

              // ── Bouton Continue ───────────────────────────────────
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
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8FBF6),
                      height: 1.0,
                    ),
                  ),
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