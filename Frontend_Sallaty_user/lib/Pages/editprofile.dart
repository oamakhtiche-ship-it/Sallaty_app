import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'usersession.dart';
import 'apiservice.dart';
import 'cannotswitchmerchant.dart';
import 'changepassword.dart';
import 'verificationcode.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _businessTypeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _newContactCtrl = TextEditingController();

  String? _selectedWilaya;

  
  XFile? _pickedImage;
  Uint8List? _newPhotoBytes; 

  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  static const List<String> _wilayas = [
    '01 - Adrar',
    '02 - Chlef',
    '03 - Laghouat',
    '04 - Oum El Bouaghi',
    '05 - Batna',
    '06 - Béjaïa',
    '07 - Biskra',
    '08 - Béchar',
    '09 - Blida',
    '10 - Bouira',
    '11 - Tamanrasset',
    '12 - Tébessa',
    '13 - Tlemcen',
    '14 - Tiaret',
    '15 - Tizi Ouzou',
    '16 - Alger',
    '17 - Djelfa',
    '18 - Jijel',
    '19 - Sétif',
    '20 - Saïda',
    '21 - Skikda',
    '22 - Sidi Bel Abbès',
    '23 - Annaba',
    '24 - Guelma',
    '25 - Constantine',
    '26 - Médéa',
    '27 - Mostaganem',
    "28 - M'Sila",
    '29 - Mascara',
    '30 - Ouargla',
    '31 - Oran',
    '32 - El Bayadh',
    '33 - Illizi',
    '34 - Bordj Bou Arréridj',
    '35 - Boumerdès',
    '36 - El Tarf',
    '37 - Tindouf',
    '38 - Tissemsilt',
    '39 - El Oued',
    '40 - Khenchela',
    '41 - Souk Ahras',
    '42 - Tipaza',
    '43 - Mila',
    '44 - Aïn Defla',
    '45 - Naâma',
    '46 - Aïn Témouchent',
    '47 - Ghardaïa',
    '48 - Relizane',
    '49 - Timimoun',
    '50 - Bordj Badji Mokhtar',
    '51 - Ouled Djellal',
    '52 - Béni Abbès',
    '53 - In Salah',
    '54 - In Guezzam',
    '55 - Touggourt',
    '56 - Djanet',
    "57 - El M'Ghair",
    '58 - El Meniaa',
  ];

  @override
  void initState() {
    super.initState();
    final s = UserSession();
    _nameCtrl.text = s.name ?? '';
    _surnameCtrl.text = s.surname ?? '';
    _businessNameCtrl.text = s.businessName ?? '';
    _businessTypeCtrl.text = s.businessType ?? '';
    _phoneCtrl.text = s.phone ?? '';

    final w = s.wilaya ?? '';
    if (w.isNotEmpty) {
      final match = _wilayas.firstWhere(
        (e) => e == w || e.contains(w),
        orElse: () => '',
      );
      _selectedWilaya = match.isNotEmpty ? match : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _businessNameCtrl.dispose();
    _businessTypeCtrl.dispose();
    _phoneCtrl.dispose();
    _newContactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _pickedImage = image;
      _newPhotoBytes = bytes;
      _isUploadingPhoto = true;
    });

    final ApiResponse<String> result;
    if (kIsWeb) {
      result = await ApiService.updateProfilePhotoWeb(bytes, image.name);
    } else {
      result = await ApiService.updateProfilePhoto(File(image.path));
    }

    if (!mounted) return;
    setState(() => _isUploadingPhoto = false);
    _showSnack(
      result.success
          ? 'Profile photo updated ✅'
          : result.errorMessage ?? 'Failed',
      isError: !result.success,
    );
  }

  // ── Save → PUT /api/profile/update ──────────────────────────────
  Future<void> _save() async {
    setState(() => _isSaving = true);

    String? wilayaValue = _selectedWilaya;
    if (wilayaValue != null && wilayaValue.contains(' - ')) {
      wilayaValue = wilayaValue.split(' - ').last;
    }

    final result = await ApiService.updateProfileFull(
      name: _nameCtrl.text.trim(),
      surname: _surnameCtrl.text.trim(),
      wilaya: wilayaValue,
      businessName:
          UserSession().isMerchant ? _businessNameCtrl.text.trim() : null,
      businessType:
          UserSession().isMerchant ? _businessTypeCtrl.text.trim() : null,
      phoneNumber:
          UserSession().isMerchant ? _phoneCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    _showSnack(
      result.success
          ? result.data ?? 'Profile updated ✅'
          : result.errorMessage ?? 'Update failed',
      isError: !result.success,
    );
    if (result.success) Navigator.pop(context);
  }

  // ── BottomSheet : Change Contact ─────────────────────────────────
  void _showChangeContactSheet() {
    _newContactCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        bool isSendingOtp = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Change Contact',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your new email or phone number. We will send a verification code.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(38, 208, 230, 165),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _newContactCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'New email or phone number'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSendingOtp
                          ? null
                          : () async {
                              final newContact =
                                  _newContactCtrl.text.trim();
                              if (newContact.isEmpty) {
                                _showSnack('Please enter a contact',
                                    isError: true);
                                return;
                              }
                              setSheetState(() => isSendingOtp = true);
                              final result =
                                  await ApiService.sendContactOtp(newContact);
                              setSheetState(() => isSendingOtp = false);
                              if (result.success) {
                                Navigator.pop(ctx);
                                final changed =
                                    await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerificationCodePage(
                                      contact: newContact,
                                      mode: 'changeContact',
                                    ),
                                  ),
                                );
                                if (changed == true && mounted) {
                                  setState(() {});
                                }
                              } else {
                                _showSnack(
                                  result.errorMessage ??
                                      'Failed to send code',
                                  isError: true,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF72A843),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSendingOtp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Send Verification Code',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? Colors.redAccent : const Color(0xFF72A843),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = UserSession();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ──────────────────────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFD0E6A5),
                    backgroundImage: _newPhotoBytes != null
                        ? MemoryImage(_newPhotoBytes!) as ImageProvider
                        : (s.photoUrl != null && s.photoUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(s.photoUrl!)
                            : null,
                    child: (_newPhotoBytes == null &&
                            (s.photoUrl == null || s.photoUrl!.isEmpty))
                        ? Text(
                            (s.name?.isNotEmpty == true)
                                ? s.name![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF72A843)))
                        : null,
                  ),
                  if (_isUploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: const Color(0xFF72A843),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Personal Info ──────────────────────────────────────
            _sectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _buildField(label: 'First Name', controller: _nameCtrl),
            _buildField(label: 'Last Name', controller: _surnameCtrl),
            _buildReadOnlyWithAction(
              label: 'Contact',
              value: s.email ?? '',
              icon: Icons.alternate_email,
              actionLabel: 'Change',
              onAction: _showChangeContactSheet,
            ),
            _buildReadOnlyWithAction(
              label: 'Password',
              value: '••••••••',
              icon: Icons.lock_outline,
              actionLabel: 'Change',
              onAction: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage())),
            ),
            const SizedBox(height: 8),
            _sectionLabel('Wilaya'),
            const SizedBox(height: 6),
            _buildWilayaDropdown(),

            // ── Business Info ──────────────────────────────────────
            const SizedBox(height: 8),
            _sectionTitle('Business Information'),
            const SizedBox(height: 12),
            if (s.isMerchant) ...[
              _buildField(
                  label: 'Business Name',
                  controller: _businessNameCtrl),
              _buildField(
                  label: 'Business Type',
                  controller: _businessTypeCtrl),
              _buildField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone),
            ] else ...[
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const CannotSwitchToMerchantPage())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(38, 208, 230, 165),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            const Color(0xFF72A843).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF72A843).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.store_outlined,
                            color: Color(0xFF72A843), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Become a Merchant',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF72A843))),
                            SizedBox(height: 3),
                            Text(
                              'Register your business to access merchant features',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Color(0xFF72A843), size: 14),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── Save ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF72A843),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF72A843))),
      );

  Widget _sectionLabel(String t) => Text(t,
      style:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(38, 208, 230, 165),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration:
                const InputDecoration(border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReadOnlyWithAction({
    required String label,
    required String value,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(38, 208, 230, 165),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '—' : value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF72A843).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF72A843).withOpacity(0.4)),
              ),
              child: Text(actionLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF72A843),
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWilayaDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(38, 208, 230, 165),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select wilaya'),
          value: _selectedWilaya,
          items: _wilayas
              .map((w) =>
                  DropdownMenuItem(value: w, child: Text(w)))
              .toList(),
          onChanged: (val) => setState(() => _selectedWilaya = val),
        ),
      ),
    );
  }
}

