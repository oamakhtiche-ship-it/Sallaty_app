import 'package:flutter/material.dart';

class AboutsallatyPage extends StatefulWidget {
  const AboutsallatyPage({super.key});

  @override
  State<AboutsallatyPage> createState() => _AboutsallatyPageState();
}

class _AboutsallatyPageState extends State<AboutsallatyPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'About Sallaty',
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF72A843),
            fontFamily: 'poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // ─── Text Area ───────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter a new content about Sallaty app here...',
                    hintStyle: TextStyle(
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF878986),
                      fontSize: 16,
                    ),
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Save Changes Button ──────────────────────────────────
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF72A843),
                    Color(0xFFA0CA09),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF72A843).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: handle save
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontFamily: 'poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF8FBF6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}