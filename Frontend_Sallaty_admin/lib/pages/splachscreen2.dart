import 'package:flutter/material.dart';
import 'splashscreen3.dart';
import 'login.dart';

class SplashScreen2 extends StatelessWidget {
  const SplashScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF9B9D9A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Login1(),
                        ),
                      );
                    },
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: Color(0xFF9B9D9A),
                        fontSize: 25,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Image.asset(
                  "assets/image2.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 60),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                "Explore endless variety: fresh bread, restaurant meals, "
                    "  pastries, and more. Quality food shouldn't go to waste.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF000000),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 40),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen3()),
                );
              },
              child: Container(
                width: 219,
                height: 52,
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
                child: const Center(
                  child: Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 70),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                indicator(false),
                const SizedBox(width: 8),
                indicator(true),
                const SizedBox(width: 8),
                indicator(false),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static Widget indicator(bool isActive) {
    return Container(
      width: isActive ? 50 : 30,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8CBF26) : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}