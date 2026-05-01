import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<_TeamMember> _team = [
    _TeamMember('Malak Bouagal',                   'UI/UX Design', 'BM', Color(0xFFFA897B), Color(0xFFFFEBE8)),
    _TeamMember('Chaima Damir',                    'UI/UX Design', 'DC', Color(0xFFCB1B5F), Color(0xFFFFE0EE)),
    _TeamMember('Makhtiche Alaa',                  'Front End',    'MA', Color(0xFFFFDD94), Color(0xFFFFF3D0)),
    _TeamMember('Bitam Nourhane',                  'Front End',    'BN', Color(0xFFA6DCEF), Color(0xFFD6F0FB)),
    _TeamMember('Benrahal\nNour Elyakine',         'Back End',     'BN', Color(0xFF72A843), Color(0xFFE6F5C0)),
    _TeamMember('Meriem Malak\nFatma Zohra Abada', 'Back End',     'AF', Color(0xFFFFC9D7), Color(0xFFFFEBF1)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF0),
      body: Stack(
          children: [
            // ── Wave header background ──────────────────────────
            ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40, right: -40,
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha:0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20, left: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha:0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Back + Title ────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'About Us',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Scrollable body ─────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Who We Are ────────────────────────
                          const Text(
                            'Who We Are ?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF72A843),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'We are a passionate team building solutions that help reduce food waste and connect communities with local merchants.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF555555),
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Team Grid ─────────────────────────
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _team.length,
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              final delay = index * 0.1;
                              final anim = CurvedAnimation(
                                parent: _controller,
                                curve: Interval(delay, delay + 0.5,
                                    curve: Curves.easeOut),
                              );
                              return FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.25),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: _TeamCard(member: _team[index]),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 28),

                          // ── App Info ──────────────────────────
                          _buildSectionTitle('App Info'),
                          const SizedBox(height: 12),
                          _buildInfoCard([
                            _InfoRow(label: 'Version',  value: '1.0.0'),
                            _InfoRow(label: 'Platform', value: 'Android / iOS'),
                            _InfoRow(label: 'Released', value: '2025'),
                            _InfoRow(label: 'Language', value: 'EN / FR / AR'),
                          ]),

                          const SizedBox(height: 24),

                          // ── Contact ───────────────────────────
                          _buildSectionTitle('Contact'),
                          const SizedBox(height: 12),
                          _buildContactCard(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D5016),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF72A843).withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rows[i].label,
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(rows[i].value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D5016),
                        )),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF72A843).withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactRow(
              Icons.phone_rounded, '+213 83 456 789', const Color(0xFF72A843)),
          const Divider(height: 20, color: Color(0xFFEEEEEE)),
          _buildContactRow(
              Icons.email_rounded, 'sallatyapplication@gmail.com', const Color(0xFFA0CA09)),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
        ),
      ],
    );
  }
}

// ── Wave Clipper ──────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.cubicTo(
      size.width * 0.15, size.height + 20,
      size.width * 0.35, size.height - 80,
      size.width * 0.5,  size.height - 40,
    );
    path.cubicTo(
      size.width * 0.65, size.height,
      size.width * 0.85, size.height - 60,
      size.width,        size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

// ── Models ────────────────────────────────────────────────────────
class _TeamMember {
  final String name;
  final String role;
  final String initials;
  final Color  avatarColor;
  final Color  bgColor;
  const _TeamMember(
      this.name, this.role, this.initials, this.avatarColor, this.bgColor);
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
}

// ── Team Card ─────────────────────────────────────────────────────
class _TeamCard extends StatelessWidget {
  final _TeamMember member;
  const _TeamCard({required this.member});

  String get _roleIcon {
    switch (member.role) {
      case 'UI/UX Design': return '🎨';
      case 'Front End':    return '📱';
      case 'Back End':     return '⚙️';
      default:             return '💼';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: member.avatarColor.withValues(alpha:0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: member.avatarColor.withValues(alpha:0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  member.avatarColor,
                  member.avatarColor.withValues(alpha:0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: member.bgColor,
              child: Text(
                member.initials,
                style: TextStyle(
                  color: member.avatarColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            member.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF2D5016),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: member.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_roleIcon, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: member.avatarColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
