/*import 'package:flutter/material.dart';
import 'signup3.dart';
class SignUp2 extends StatefulWidget {
  const SignUp2({super.key});
  @override
  State<SignUp2> createState() => _SignUp2State();
}
class _SignUp2State extends State<SignUp2> {
  final TextEditingController c1 = TextEditingController();
  final TextEditingController c2 = TextEditingController();
  final TextEditingController c3 = TextEditingController();
  final TextEditingController c4 = TextEditingController();
  final TextEditingController c5 = TextEditingController();
  final TextEditingController c6 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 30),

                /// TITLE
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

                /// PROGRESS BAR
                Center(
                  child: Container(
                    width: 180,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Color(0xA0D9D9D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
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

                SizedBox(
                  width: double.infinity,
                  child: const Text(
                    "Verification Code  ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF72A843),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: const Text(
                    "We have sent you a code",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF717270),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: double.infinity,
                  child: const Text(
                    "code to verify your email address ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF717270),
                    ),
                  ),
                ),
                const SizedBox(height: 20),


                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      height: 60,
                      width: 50,
                      child: TextField(
                        controller: [c1, c2, c3, c4, c5, c6][index],
                        autofocus: index == 0 ? true : false,
                        // Focus sur le 1er champ
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: "",
                          // Masque le compteur de caractères
                          filled: true,
                          fillColor: Colors.grey[300],
                          // Couleur grise de votre image
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 1 && index < 5) {
                            FocusScope
                                .of(context)
                                .nextFocus(); // Passe au champ suivant
                          }
                          if (value.isEmpty && index > 0) {
                            FocusScope
                                .of(context)
                                .previousFocus(); // Retour au champ précédent
                          }
                        },

                      ),
                    );
                  }),
                ),

               const SizedBox(height: 10),

                Center(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 18),
                      children: [
                        TextSpan(text: "Didn’t receive anything?"),
                        TextSpan(
                          text: "Send again",
                          style: TextStyle(
                            color: Color(0xFF6BA539),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 150),

                /// SIGN UP BUTTON
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
                      onPressed: () {

                        String codeUser = c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;

                        if (codeUser.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all the boxes")),
                          );
                          return;
                        }

                        // Ici, tu enverras codeUser au serveur pour validation

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUp3()),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 24, color: Colors.white),

                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),


                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

}*/

import 'package:flutter/material.dart';
import 'signup3.dart';
import 'apiservice.dart';

class SignUp2 extends StatefulWidget {
  final int userId;
  const SignUp2({super.key, required this.userId});

  @override
  State<SignUp2> createState() => _SignUp2State();
}

class _SignUp2State extends State<SignUp2> {
  final TextEditingController c1 = TextEditingController();
  final TextEditingController c2 = TextEditingController();
  final TextEditingController c3 = TextEditingController();
  final TextEditingController c4 = TextEditingController();
  final TextEditingController c5 = TextEditingController();
  final TextEditingController c6 = TextEditingController();

  bool _isLoading       = false;
  bool _isResending     = false;

  // ──────────────────────────────────────────────────────────────
  //  POST /api/auth/register/step2
  //  Flutter → Backend : form-urlencoded
  //  Body:     userId=42&otpCode=123456
  //  200:  { "success": true, "message": "Email verified" }
  // ──────────────────────────────────────────────────────────────
  Future<void> _onVerify() async {
    final code = c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;

    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all the boxes")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.registerStep2(
      userId : widget.userId,
      otpCode: code,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result.success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignUp3(userId: widget.userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Verification failed')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  POST /api/auth/register/resend-otp
  //  Flutter → Backend : form-urlencoded
  //  Body:     userId=42
  //  200:  { "success": true, "message": "OTP resent" }
  // ──────────────────────────────────────────────────────────────
  Future<void> _resendCode() async {
    if (_isResending) return; // évite double tap
    setState(() => _isResending = true);

    final result = await ApiService.resendOtp(userId: widget.userId);

    setState(() => _isResending = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? "Code resent to your email ✓"
              : result.errorMessage ?? "Failed to resend",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
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

              // Progress bar — step 2/3
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
                        width: 120,
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

              const SizedBox(
                width: double.infinity,
                child: Text(
                  "Verification Code",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF72A843),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const SizedBox(
                width: double.infinity,
                child: Text(
                  "We have sent you a code",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Color(0xFF717270)),
                ),
              ),

              const SizedBox(height: 5),

              const SizedBox(
                width: double.infinity,
                child: Text(
                  "to verify your email address",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Color(0xFF717270)),
                ),
              ),

              const SizedBox(height: 30),

              // ── 6 OTP boxes ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    height: 60,
                    width: 50,
                    child: TextField(
                      controller: [c1, c2, c3, c4, c5, c6][index],
                      autofocus: index == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 1 && index < 5)
                          {FocusScope.of(context).nextFocus();}
                        if (value.isEmpty && index > 0)
                          {FocusScope.of(context).previousFocus();}
                      },
                    ),
                  );
                }),
              ),

              // ── Send again — juste sous les boxes ────────────
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: _isResending ? null : _resendCode,
                  child: _isResending
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6BA539),
                    ),
                  )
                      : RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          color: Color(0xFF1A1A1A), fontSize: 18),
                      children: [
                        TextSpan(text: "Didn't receive anything?  "),
                        TextSpan(
                          text: "Send again",
                          style: TextStyle(
                            color: Color(0xFF6BA539),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Spacer pousse le bouton vers le bas ──────────
              const Spacer(),

              // ── Verify button ─────────────────────────────────
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
                    onPressed: _isLoading ? null : _onVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verify",
                        style: TextStyle(
                            fontSize: 24, color: Colors.white)),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
