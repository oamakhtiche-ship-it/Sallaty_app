import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import 'usersession.dart';
import 'home.dart';
import 'apiservice.dart';

class SignUp3 extends StatefulWidget {
  final int userId;
  const SignUp3({super.key, required this.userId});

  @override
  State<SignUp3> createState() => _SignUp3State();
}

class _SignUp3State extends State<SignUp3> {
  final TextEditingController nameController    = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool   showSuccess  = false;
  bool   _isLoading   = false;
  File?  _profileImage;  // pour l'affichage uniquement
  XFile? _pickedXFile;   // pour l'upload (Android ✅ iOS ✅ Web ✅)

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedXFile  = image;
        _profileImage = File(image.path); // affichage local uniquement
      });
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Step A : POST /api/auth/register/step3
  //  Step B : POST /api/users/uploadImage/{userId}  (si photo choisie)
  //  Step C : navigate to HomePage
  // ──────────────────────────────────────────────────────────────
  Future<void> _onSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    // ── Step A : register name / surname ───────────────────────
    final result = await ApiService.registerStep3(
      userId : widget.userId,
      name   : nameController.text.trim(),
      surname: surnameController.text.trim(),
    );

    if (!mounted) { setState(() => _isLoading = false); return; }

    if (!result.success) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Registration failed')),
      );
      return;
    }

    // ── Step B : upload photo (Android ✅  iOS ✅  Web ✅) ──────
    if (_pickedXFile != null) {
      final bytes    = await _pickedXFile!.readAsBytes();
      final filename = _pickedXFile!.name;

      // filePath fourni sur mobile, webBytes sur Web
      final photoResult = await ApiService.uploadProfilePhotoStatic(
        widget.userId,
        filename,
        filePath: _pickedXFile!.path,
        webBytes: bytes,
      );

      if (!mounted) return;

      if (photoResult.success && photoResult.data != null && photoResult.data!.isNotEmpty) {
        // ✅ Save the returned imagePath so the profile page shows the photo
        await UserSession().updatePhotoUrl(photoResult.data!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Photo upload failed: ${photoResult.errorMessage}. '
              'You can add it later in your profile.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    // ── Step C : update local session & show success ───────────
    UserSession().name    = nameController.text.trim();
    UserSession().surname = surnameController.text.trim();

    setState(() { _isLoading = false; showSuccess = true; });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      body: Stack(
        children: [
          SafeArea(
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

                      // ── Progress bar — step 3/3 complète ─────
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
                                width: 180,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6BA539),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Photo de profil (optionnelle) ─────────
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? const Icon(Icons.person,
                                      size: 70, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF72A843),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          "Add a profile picture",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ── Name ──────────────────────────────────
                      const Text("Name:", style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter your name";
                          }
                          if (value.length < 3) {
                            return "Name must be at least 3 characters";
                          }
                          if (RegExp(r'\d').hasMatch(value)) {
                            return "Name cannot contain numbers";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Surname ───────────────────────────────
                      const Text("Surname:", style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: surnameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter your surname";
                          }
                          if (value.length < 3) {
                            return "Surname must be at least 3 characters";
                          }
                          if (RegExp(r'\d').hasMatch(value)) {
                            return "Surname cannot contain numbers";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 50),

                      // ── Bouton Sign Up ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 61,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.bottomRight,
                              end: Alignment.topLeft,
                              colors: [
                                Color(0xFF72A843),
                                Color(0xFFA0CA09),
                              ],
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
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                        fontSize: 24, color: Colors.white),
                                  ),
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

          if (showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withAlpha(51)),
          ),
          Center(
            child: Container(
              width: 264,
              height: 370,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF4C702D), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    backgroundColor: Color(0xFF4C702D),
                    radius: 40,
                    child: Icon(Icons.how_to_reg,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Welcome, ${nameController.text.trim()}!",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA0CA09),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your account has been created.\nPlease wait a moment",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16, color: Color(0xFF7C7C7C)),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF72A843)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



