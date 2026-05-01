import 'package:flutter/material.dart';
import 'usermanagement.dart';
import 'merchantmanag.dart';
import 'offermanag.dart';
import 'reservation.dart';
import 'usersession.dart'; // ← add this

class ControlCenterBody extends StatelessWidget {
  const ControlCenterBody({super.key});

  // Read token once from UserSession
  String get _token => UserSession().token ?? '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Control Center',
            style: TextStyle(
                fontSize: 32, fontFamily: 'inter',
                fontWeight: FontWeight.w600, color: Color(0xFF0A0A0A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'What would you like to manage?',
            style: TextStyle(fontSize: 14, fontFamily: 'inter',
                color: Color(0xFF4C702D)),
          ),
          const SizedBox(height: 25),
          _ControlTile(
            label: 'Users',
            icon: Icons.group,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => UserManagementPage(token: _token), // ← fix
            )),
          ),
          const SizedBox(height: 14),
          _ControlTile(
            label: 'Merchants',
            icon: Icons.storefront,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MerchantManagementPage(token: _token), // ← fix
            )),
          ),
          const SizedBox(height: 14),
          _ControlTile(
            label: 'Offers',
            icon: Icons.local_offer_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const OfferManagementPage(),
            )),
          ),
          const SizedBox(height: 14),
          _ControlTile(
            label: 'Orders',
            icon: Icons.shopping_cart_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ReservationManagementPage(),
            )),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ControlTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDCE9C8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: const Color(0xFF72A843)),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 20, fontFamily: 'poppins',
                  fontWeight: FontWeight.w600, color: Color(0xFF4C702D)),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}