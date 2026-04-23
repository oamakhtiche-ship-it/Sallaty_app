import 'package:flutter/material.dart';
import 'usersession.dart';

class ManageProfilePage extends StatelessWidget {
  const ManageProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = UserSession();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: const [
                  Icon(Icons.account_circle_outlined, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Manage Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFD0E6A5),
                  backgroundImage: session.profileImage != null
                      ? FileImage(session.profileImage!)
                      : null,
                  child: session.profileImage == null
                      ? Text(
                    session.name.isNotEmpty
                        ? session.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF72A843),
                    ),
                  )
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              _buildReadOnlyField(label: 'Surname', value: session.surname),
              _buildReadOnlyField(label: 'Name', value: session.name),
              _buildReadOnlyField(label: 'Email address', value: session.email),
              _buildReadOnlyField(label: 'Password', value: '••••••••'),

              const Text(
                'Phone number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(38, 208, 230, 165),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text(
                      '+213',
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      session.phone.isNotEmpty ? session.phone : '—',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildReadOnlyField(
                label: 'Status',
                value: session.isMerchant ? 'Merchant & Client' : 'Client',
              ),
              _buildReadOnlyField(label: 'Wilaya', value: session.wilaya),

              // ── Merchant-only fields ──────────────────────────────
              if (session.isMerchant) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Divider(color: Color(0xFFD0E6A5), thickness: 1.5),
                ),
                Row(
                  children: const [
                    Icon(Icons.store_outlined, size: 18, color: Color(0xFF72A843)),
                    SizedBox(width: 6),
                    Text(
                      'Business Information',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF72A843),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildReadOnlyField(
                  label: 'Business Name',
                  value: session.businessName,
                ),
                _buildReadOnlyField(
                  label: 'Business Type',
                  value: session.businessType,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color.fromARGB(38, 208, 230, 165),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}