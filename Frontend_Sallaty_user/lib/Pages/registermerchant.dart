import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'usersession.dart';
import 'apiservice.dart';

class RegisterMerchantPage extends StatefulWidget {
  final VoidCallback? onSuccess;
  const RegisterMerchantPage({super.key, this.onSuccess});

  @override
  State<RegisterMerchantPage> createState() => _RegisterMerchantPageState();
}

class _RegisterMerchantPageState extends State<RegisterMerchantPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedType;
  String? _selectedWilaya;

  // ✅ Stocke le XFile pour accéder à .path (Android) ou .readAsBytes() (Web)
  XFile? _pickedTradeRegister;
  Uint8List? _tradeRegisterPreviewBytes; // uniquement pour l'aperçu
  String? _tradeRegisterName;

  bool _isLoading = false;

  final List<String> _activityTypes = [
    'Restaurant',
    'Café',
    'Bakery',
    'FastFood',
    'Grocery',
    'Butcher',
    'Fish Shop',
    'Fruits & Vegetables',
    'HomeCooking',
  ];

  final List<String> _wilayas = [
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
    final full = '${s.name ?? ''} ${s.surname ?? ''}'.trim();
    if (full.isNotEmpty) _fullNameController.text = full;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Pick trade register image ────────────────────────────────────
  // ✅ Fonctionne sur Android ET Web
  Future<void> _pickTradeRegister() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    // Lire les bytes pour l'aperçu (fonctionne partout)
    final bytes = await image.readAsBytes();
    setState(() {
      _pickedTradeRegister = image;
      _tradeRegisterPreviewBytes = bytes;
      _tradeRegisterName = image.name;
    });
  }

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      _showError('Please select a type of activity');
      return;
    }
    if (_selectedWilaya == null) {
      _showError('Please select a city');
      return;
    }
    if (_pickedTradeRegister == null) {
      _showError('Please upload your trade register');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/marchand/register');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer ${UserSession().token ?? ''}',
        })
        ..fields['fullName'] = _fullNameController.text.trim()
        ..fields['shopName'] = _shopNameController.text.trim()
        ..fields['typeOfActivity'] = _selectedType!
        ..fields['wilaya'] = _selectedWilaya!
        ..fields['phoneNumber'] = _phoneController.text.trim();

      // ✅ BRANCHING PLATFORM : File sur Android/iOS, bytes sur Web
      if (kIsWeb) {
        final bytes = await _pickedTradeRegister!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'tradeRegister',
          bytes,
          filename: _tradeRegisterName ?? 'trade_register.jpg',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'tradeRegister',
          _pickedTradeRegister!.path,
        ));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.statusCode == 200) {
        final session = UserSession();
        session.businessName = _shopNameController.text.trim();
        session.businessType = _selectedType!;
        session.isMerchant = true;
        if (_phoneController.text.trim().isNotEmpty) {
          session.phone = _phoneController.text.trim();
        }
        await session.saveToPrefs();

        _showSuccess('Request sent! Awaiting verification.');
        await Future.delayed(const Duration(milliseconds: 800));
        widget.onSuccess?.call();
      } else {
        String errorMsg = 'Registration failed';
        try {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          errorMsg = body['message']?.toString() ?? errorMsg;
        } catch (_) {}
        _showError(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Connection error. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF72A843),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Register as a marchant',
          style: TextStyle(
              color: Color(0xFF72A843),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Header ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.store, color: Colors.white, size: 30),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Register as a Merchant',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Fill in the details below to get started',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Full Name ────────────────────────────────────
              _buildLabel('Full Name', Icons.person_outline),
              const SizedBox(height: 6),
              _buildTextFormField(
                controller: _fullNameController,
                hint: 'Enter your full name',
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Full name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Shop Name ────────────────────────────────────
              _buildLabel('Shop Name', Icons.storefront_outlined),
              const SizedBox(height: 6),
              _buildTextFormField(
                controller: _shopNameController,
                hint: 'Enter your shop name',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Type of Activity ─────────────────────────────
              _buildLabel('Type of Activity', Icons.category_outlined),
              const SizedBox(height: 6),
              _buildDropdownField(
                hint: 'Select type',
                value: _selectedType,
                items: _activityTypes,
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              const SizedBox(height: 16),

              // ── City ─────────────────────────────────────────
              _buildLabel('City', Icons.location_city_outlined),
              const SizedBox(height: 6),
              _buildDropdownField(
                hint: 'Select wilaya',
                value: _selectedWilaya,
                items: _wilayas,
                onChanged: (val) => setState(() => _selectedWilaya = val),
              ),
              const SizedBox(height: 16),

              // ── Phone ────────────────────────────────────────
              _buildLabel('Phone Number', Icons.phone_outlined),
              const SizedBox(height: 6),
              _buildTextFormField(
                controller: _phoneController,
                hint: '06 69608447',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Phone number is required';
                  if (v.length < 9) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Trade Register Upload ─────────────────────────
              _buildLabel('Trade Register', Icons.upload_file_outlined),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickTradeRegister,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _pickedTradeRegister != null
                        ? Colors.white
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _pickedTradeRegister != null
                          ? const Color(0xFF72A843)
                          : Colors.grey.shade300,
                      width: _pickedTradeRegister != null ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ✅ Aperçu : utilise _tradeRegisterPreviewBytes (Uint8List)
                      // qui fonctionne sur Android ET Web
                      _tradeRegisterPreviewBytes != null
                          ? Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  _tradeRegisterPreviewBytes!,
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('File selected',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF72A843),
                                      fontWeight: FontWeight.w500)),
                            ])
                          : const Text('Upload Trade Register Here',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFFAAAAAA))),
                      _tradeRegisterPreviewBytes != null
                          ? GestureDetector(
                              onTap: () => setState(() {
                                _pickedTradeRegister = null;
                                _tradeRegisterPreviewBytes = null;
                                _tradeRegisterName = null;
                              }),
                              child: const Icon(Icons.close,
                                  color: Colors.grey, size: 18),
                            )
                          : const Icon(Icons.download_outlined,
                              color: Color(0xFF475367)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── Register Button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF72A843),
                    disabledBackgroundColor:
                        const Color(0xFF72A843).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Register',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF72A843)),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF72A843), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value != null
              ? const Color(0xFF72A843)
              : Colors.grey.shade300,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint,
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          value: value,
          icon: Icon(Icons.keyboard_arrow_down,
              color: value != null
                  ? const Color(0xFF72A843)
                  : Colors.grey),
          items: items
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
