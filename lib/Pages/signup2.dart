import 'package:flutter/material.dart';
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

}