// lib/Pages/create_offer.dart
// ✅ Android + Web compatible
// ✅ kIsWeb : utilise Uint8List sur Web, File sur Android/iOS

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'usersession.dart';
import 'apiservice.dart';

const List<String> _kFoodTypes = [
  'GROCERY',
  'FRUITS_VEGETABLES',
  'RESTAURANT',
  'BAKERY',
  'FISH',
  'CAFE',
  'FAST_FOOD',
  'HOME_COOKING',
  'OTHER',
];

const List<String> _kStatuses = ['ACTIVE', 'INACTIVE'];

const List<String> _kWilayas = [
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
  '28 - M\'Sila',
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
];

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  int _quantity = 1;
  String? _selectedFoodType;
  String? _selectedWilaya;
  String? _selectedStatus;

  // ✅ Stocke le XFile pour avoir accès à .path (Android) et .readAsBytes() (Web)
  XFile? _pickedImage;
  Uint8List? _imagePreviewBytes; // uniquement pour l'aperçu
  String? _imageFilename;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ───────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    // Lire les bytes uniquement pour l'aperçu
    final bytes = await image.readAsBytes();
    setState(() {
      _pickedImage = image;
      _imagePreviewBytes = bytes;
      _imageFilename = image.name;
    });
  }

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFoodType == null) {
      _snack('Please select a category', error: true);
      return;
    }
    if (_selectedWilaya == null) {
      _snack('Please select an address', error: true);
      return;
    }
    if (_selectedStatus == null) {
      _snack('Please choose a status', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = UserSession().token ?? '';

      // ── Étape 1 : créer l'offre (sans image) ──────────────────────
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/offres/create');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = _titleCtrl.text.trim()
        ..fields['description'] = _descCtrl.text.trim()
        ..fields['price'] = _priceCtrl.text.trim()
        ..fields['quantity'] = _quantity.toString()
        ..fields['wilaya'] = _selectedWilaya!
        ..fields['foodtype'] = _selectedFoodType!
        ..fields['status'] = _selectedStatus!;

      if (_dateCtrl.text.isNotEmpty) {
        request.fields['expireAt'] = '${_dateCtrl.text}T23:59:00';
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        // ── Étape 2 : upload photo séparément ─────────────────────
        if (_pickedImage != null) {
          try {
            String? offerId;
            try {
              final body = jsonDecode(res.body);
              if (body is Map) offerId = body['id']?.toString();
            } catch (_) {}

            if (offerId != null) {
              final photoUri = Uri.parse('${ApiConfig.baseUrl}/api/offres/photo/$offerId');
              final photoReq = http.MultipartRequest('POST', photoUri)
                ..headers['Authorization'] = 'Bearer $token';

              // ✅ BRANCHING PLATFORM : File sur Android/iOS, bytes sur Web
              if (kIsWeb) {
                final bytes = await _pickedImage!.readAsBytes();
                photoReq.files.add(http.MultipartFile.fromBytes(
                  'file',
                  bytes,
                  filename: _imageFilename ?? 'offer.jpg',
                ));
              } else {
                photoReq.files.add(await http.MultipartFile.fromPath(
                  'file',
                  _pickedImage!.path,
                ));
              }

              await photoReq.send().timeout(const Duration(seconds: 30));
            }
          } catch (_) {}
        }

        setState(() => _isLoading = false);
        _snack('Offer created ✅', error: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
        String msg = 'Failed to create offer';
        try {
          final body = jsonDecode(res.body);
          if (body is Map) msg = body['message']?.toString() ?? msg;
        } catch (_) {}
        _snack(msg, error: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Error: $e', error: true);
      }
    }
  }

  void _snack(String msg, {required bool error}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : const Color(0xFF72A843),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Offer',
          style: TextStyle(
            color: Color(0xFF72A843),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Offer Name ────────────────────────────────────────
              _label('Offer Name', req: true),
              _textField(
                ctrl: _titleCtrl,
                hint: '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Offer name is required' : null,
              ),
              const SizedBox(height: 14),

              // ── Description ───────────────────────────────────────
              _label('Description', req: true),
              _textField(
                ctrl: _descCtrl,
                hint: '',
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 14),

              // ── Picture ───────────────────────────────────────────
              _label('Picture', req: true),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: _imagePreviewBytes != null
                      ? Row(children: [
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(_imagePreviewBytes!,
                                height: 36, width: 36, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _imageFilename ?? 'Image selected',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF444444)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.check_circle,
                              color: Color(0xFF72A843), size: 20),
                          const SizedBox(width: 12),
                        ])
                      : const Row(children: [
                          SizedBox(width: 14),
                          Expanded(
                            child: Text('Upload Product Picture Here',
                                style: TextStyle(
                                    color: Color(0xFF9E9E9E), fontSize: 13)),
                          ),
                          Icon(Icons.file_download_outlined,
                              color: Color(0xFF9E9E9E), size: 22),
                          SizedBox(width: 14),
                        ]),
                ),
              ),
              const SizedBox(height: 14),

              // ── Category (foodtype) ───────────────────────────────
              _label('Category', req: true),
              _dropdown(
                value: _selectedFoodType,
                hint: 'Choose Category',
                items: _kFoodTypes,
                onChanged: (v) => setState(() => _selectedFoodType = v),
              ),
              const SizedBox(height: 14),

              // ── Quantity + Price ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Quantity', req: true),
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _qtyBtn(
                                icon: Icons.remove,
                                onTap: () {
                                  if (_quantity > 1) setState(() => _quantity--);
                                },
                              ),
                              Text(
                                _quantity.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              _qtyBtn(
                                icon: Icons.add,
                                onTap: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Price', req: true),
                        _textField(
                          ctrl: _priceCtrl,
                          hint: '',
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Address (wilaya) ──────────────────────────────────
              _label('Address', req: true),
              _dropdown(
                value: _selectedWilaya,
                hint: 'Enter Your Full Address',
                items: _kWilayas,
                onChanged: (v) => setState(() => _selectedWilaya = v),
              ),
              const SizedBox(height: 14),

              // ── Expiration Date ───────────────────────────────────
              _label('Expiration Date', req: false),
              _textField(
                ctrl: _dateCtrl,
                hint: 'YYYY-MM-DD',
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 14),

              // ── Status ────────────────────────────────────────────
              _label('Status', req: true),
              _dropdown(
                value: _selectedStatus,
                hint: 'Choose Status',
                items: _kStatuses,
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF72A843),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ───────────────────────────────────────────────
  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF72A843),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _label(String text, {bool req = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            text: text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333)),
            children: req
                ? const [
                    TextSpan(
                        text: '*', style: TextStyle(color: Colors.red))
                  ]
                : [],
          ),
        ),
      );

  Widget _textField({
    required TextEditingController ctrl,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF72A843), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      );

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hint,
                style: const TextStyle(
                    color: Color(0xFF9E9E9E), fontSize: 13)),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Color(0xFF72A843)),
            items: items
                .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(i,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF222222)))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}
