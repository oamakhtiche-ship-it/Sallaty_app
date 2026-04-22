/*import 'package:flutter/material.dart';
import 'signup2.dart';
import 'login1.dart';
import 'package:flutter/gestures.dart';
import 'usersession.dart';
import 'package:google_sign_in/google_sign_in.dart';



class SignUp1 extends StatefulWidget {
  const SignUp1({super.key});

  @override
  State<SignUp1> createState() => _SignUp1State();
}

class _SignUp1State extends State<SignUp1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;


  // ── Google Sign-In ──
  Future<void> _signUpWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut(); // force le sélecteur de compte
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) return; // annulé par l'utilisateur

      UserSession().email = account.email;
      UserSession().displayName = account.displayName ?? '';
      UserSession().photoUrl = account.photoUrl ?? '';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUp2()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Google : $e')),
        );
      }
    }
  }

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

                  const Center(
                    child: Text(
                      "Create an account",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF72A843),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Center(
                    child: Container(
                      width: 180,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xA0D9D9D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6BA539),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Text("Email Address:", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Enter your email address";
                      if (!value.contains("@")) return "Enter a valid email";
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  const Text("Password:", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.remove_red_eye_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Enter your password";
                      if (value.length < 6) return "Password must be at least 6 characters";
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  const Text("Confirm Password:", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.remove_red_eye_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Enter your password";
                      if (value.length < 6) return "Password must be at least 6 characters";
                      if (value != passwordController.text) return "Passwords do not match";
                      return null;
                    },
                  ),

                  const SizedBox(height: 50),

                  SizedBox(
                    width: double.infinity,
                    height: 61,
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            UserSession().email = emailController.text.trim();
                            UserSession().password = passwordController.text;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUp2()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Sign Up", style: TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("Or Sign Up with"),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ── Bouton Google ──
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _signUpWithGoogle, // ← appel direct
                      icon: Image.network(
                        "https://cdn-icons-png.flaticon.com/512/281/281764.png",
                        height: 22,
                      ),
                      label: const Text("Google", style: TextStyle(fontSize: 24, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAED581),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          const TextSpan(text: "Already have an account ?  "),
                          TextSpan(
                            text: "Sign in",
                            style: const TextStyle(
                              color: Color(0xFF6BA539),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Login1()),
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
}*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;

import 'signup2.dart';
import 'login1.dart';

class SignUp1 extends StatefulWidget {
  const SignUp1({super.key});

  @override
  State<SignUp1> createState() => _SignUp1State();
}

class _SignUp1State extends State<SignUp1> {
  final _formKey = GlobalKey<FormState>();
  final emailController           = TextEditingController();
  final passwordController        = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true; // ← FIX: booléen séparé
  bool _isLoading              = false;

  // ─────────────────────────────────────────────────────────────
  //  POST /api/auth/register/step1
  //  Flutter → Backend : form-urlencoded  (body: Map<String,String>)
  //  Backend → Flutter : JSON             (jsonDecode)
  // ─────────────────────────────────────────────────────────────
  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ── ENVOI form-urlencoded ──────────────────────────────
      final response = await http.post(
        Uri.parse("https://ethanol-hemstitch-strongbox.ngrok-free.dev/api/auth/register/step1"),
        headers: {
          "ngrok-skip-browser-warning": "true",
          // PAS de Content-Type manuel —
          // http.dart l'ajoute automatiquement quand body est Map<String,String>
        },
        body: <String, String>{
          "contact"  : emailController.text.trim(),
          "password" : passwordController.text,
          "password2": confirmPasswordController.text, // ← FIX: password2 inclus
        },
      );

      if (!mounted) return;

      // ── RÉCEPTION JSON ─────────────────────────────────────
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      //  data["success"] → bool
      //  data["userId"]  → int   (nécessaire pour step2)
      //  data["message"] → String

      if (data["success"] == true) {
        final int userId = data["userId"]; // ← FIX: userId passé à SignUp2

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignUp2(userId: userId),
          ),
        );
      } else {
        _showError(data["message"] ?? "Registration failed");
      }
    } catch (e) {
      if (!mounted) return;
      _showError("Connection error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

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

                  const Center(
                    child: Text(
                      "Create an account",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF72A843),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Progress bar — step 1/3
                  Center(
                    child: Container(
                      width: 180,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xA0D9D9D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6BA539),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  // ── Email ────────────────────────────────────
                  const Text("Email Address:", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        {return "Enter your email address";}
                      if (!value.contains("@"))
                       { return "Enter a valid email";}
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Password ─────────────────────────────────
                  const Text("Password:", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
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
                          horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        {return "Enter your password";}
                      if (value.length < 6)
                       { return "Password must be at least 6 characters";}
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Confirm Password ──────────────────────────
                  const Text("Confirm Password:", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword
                            ? Icons.remove_red_eye_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                       { return "Confirm your password";}
                      if (value != passwordController.text)
                       { return "Passwords do not match";}
                      return null;
                    },
                  ),

                  const SizedBox(height: 50),

                  // ── Sign Up Button ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 61,
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
                            : const Text("Sign Up",
                            style: TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ── Divider ───────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("Or Sign Up with"),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ── Google Button ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Image.network(
                        "https://cdn-icons-png.flaticon.com/512/281/281764.png",
                        height: 22,
                      ),
                      label: const Text("Google",
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAED581),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── Sign In link ──────────────────────────────
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          const TextSpan(text: "Already have an account ?  "),
                          TextSpan(
                            text: "Sign in",
                            style: const TextStyle(
                              color: Color(0xFF6BA539),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Login1()),
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