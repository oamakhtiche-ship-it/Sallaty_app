import 'dart:io';
import 'package:flutter/material.dart';
import 'usersession.dart';
import 'apiservice.dart';
import 'editprofile.dart';

class ManageProfilePage extends StatefulWidget {
  const ManageProfilePage({super.key});

  @override
  State<ManageProfilePage> createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends State<ManageProfilePage> {

  bool    _isLoading    = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Chargement depuis le backend ──────────────────────────────
  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    final success = await ApiService.refreshProfile();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!success) _errorMessage = 'Connexion impossible. Données locales affichées.';
    });
  }

  // ── Aller sur EditProfile et rafraîchir au retour ─────────────
  Future<void> _navigateToEdit() async {
    final nav = Navigator.of(context);
    await nav.push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
    if (mounted) await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.account_circle_outlined, size: 24, color: Colors.black),
            SizedBox(width: 8),
            Text('Manage Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF72A843)),
            onPressed: _isLoading ? null : _loadProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF72A843)),
    );
  }

  Widget _buildContent() {
    final session = UserSession();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Bannière offline ──────────────────────────────────
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                  ),
                ],
              ),
            ),

          // ── Avatar ────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFD0E6A5),
                  backgroundImage: session.hasPhoto
                      ? (session.photoUrl!.startsWith('http')
                          ? NetworkImage(session.photoUrl!) as ImageProvider
                          : FileImage(File(session.photoUrl!)) as ImageProvider)
                      : null,
                  child: !session.hasPhoto
                      ? Text(
                          (session.name?.isNotEmpty ?? false)
                              ? session.name![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF72A843)),
                        )
                      : null,
                ),
                if (session.isMerchant)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF72A843),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.store, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(session.displayName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(session.email ?? '',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),

          const SizedBox(height: 24),

          // ── Champs ────────────────────────────────────────────
          _buildReadOnlyField(label: 'Surname',       value: session.surname  ?? ''),
          _buildReadOnlyField(label: 'Name',          value: session.name     ?? ''),
          _buildReadOnlyField(label: 'Email address', value: session.email    ?? ''),
          _buildReadOnlyField(label: 'Password',      value: '••••••••'),

          const Text('Phone number',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color.fromARGB(38, 208, 230, 165),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('+213',
                    style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(width: 12),
                Text(
                  (session.phone?.isNotEmpty ?? false) ? session.phone! : '—',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildReadOnlyField(
              label: 'Status',
              value: session.isMerchant ? 'Merchant & Client' : 'Client'),
          _buildReadOnlyField(label: 'Wilaya', value: session.wilaya ?? ''),

          // ── Section commerçant ────────────────────────────────
          if (session.isMerchant) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Divider(color: Color(0xFFD0E6A5), thickness: 1.5),
            ),
            Row(
              children: const [
                Icon(Icons.store_outlined, size: 18, color: Color(0xFF72A843)),
                SizedBox(width: 6),
                Text('Business Information',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600, color: Color(0xFF72A843))),
              ],
            ),
            const SizedBox(height: 14),
            _buildReadOnlyField(label: 'Business Name', value: session.businessName ?? ''),
            _buildReadOnlyField(label: 'Business Type', value: session.businessType ?? ''),
          ],

          const SizedBox(height: 24),

          // ✅ Bouton Edit Profile — rafraîchit les données au retour
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _navigateToEdit,
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: const Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF72A843),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (session.id != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text('Account ID: ${session.id}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ],
          const SizedBox(height: 20),
        ],
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