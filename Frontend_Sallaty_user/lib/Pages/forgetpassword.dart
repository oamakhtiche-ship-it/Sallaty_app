import 'package:flutter/material.dart';
import 'mobile.dart';   // ViaMobileNumberPage
import 'email.dart';    // EmailPage
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ForgotPasswordPage(),
  ));
}
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // null = rien sélectionné, 'mobile' ou 'email'
  String? _selected;

  final Color primaryColor = const Color(0xFF72A843);
  final Color activeColor  = const Color(0xFFB9D4A1);  // couleur sélectionnée
  final Color inactiveColor = const Color(0xFFD0E2C0).withValues(alpha:0.20);
  final Color activeTextColor   = const Color(0xFF263816);
  final Color inactiveTextColor = const Color(0xFF1E1E1E).withValues(alpha:0.5);
  final Color defaultTextColor  = const Color(0xFF263816);
  void _onOptionTap(String option) {
    setState(() => _selected = option);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      if (option == 'mobile') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ViaMobileNumberPage()),
        ).then((_) {
          if (!mounted) return;
          setState(() => _selected = null);
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmailPage()),
        ).then((_) {
          if (!mounted) return;
          setState(() => _selected = null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Forgot Password?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(17.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Texte descriptif
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Choose one of the following contact \nmethods to receive a one-time password \n(OTP) to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Image
              Center(
                child: Image.asset(
                  'assets/images/forgotpassword.png',
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 280,
                      height: 280,
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          error.toString(),  // affiche le vrai message d'erreur
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Box Via Mobile Number
              _buildContactOption(
                title: 'Via Mobile Number',
                option: 'mobile',
              ),

              const SizedBox(height: 30),

              // Box Via Email
              _buildContactOption(
                title: 'Via Email',
                option: 'email',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required String title,
    required String option,
  }) {

    final bool isSelected = _selected == option;
    final Color boxColor = isSelected ? activeColor : inactiveColor;
    final Color textColor = _selected == null
        ? defaultTextColor
        : isSelected
        ? activeTextColor
        : inactiveTextColor;

    return GestureDetector(
      onTap: () => _onOptionTap(option),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 250,
          height: 65,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}