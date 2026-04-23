import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'offer_store.dart';

const String _kGoogleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final Color primaryColor = const Color(0xFF72A843);

  final _offerNameController    = TextEditingController();
  final _descriptionController  = TextEditingController();
  final _priceController        = TextEditingController();
  final _expirationController   = TextEditingController();
  final _addressController      = TextEditingController();

  int _quantity = 1;
  String? _selectedStatus;
  bool _showError = false;

  // ── Address autocomplete state ──────────────────────────────────────────
  List<Map<String, String>> _addressSuggestions = [];
  Timer? _addressDebounce;
  bool _isLoadingAddress = false;
  bool _addressSelected  = false; // true once user taps a suggestion
  final FocusNode _addressFocusNode = FocusNode();

  final List<String> _statuses = ['Active', 'Sold out', 'Expired'];

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressTyped);
  }

  @override
  void dispose() {
    _offerNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _expirationController.dispose();
    _addressController.removeListener(_onAddressTyped);
    _addressController.dispose();
    _addressFocusNode.dispose();
    _addressDebounce?.cancel();
    super.dispose();
  }

  // ─── Address search ────────────────────────────────────────────────────────

  void _onAddressTyped() {
    final text = _addressController.text;
    if (_addressSelected) {
      // User is editing after selection — reset
      if (text != (_addressSuggestions.isNotEmpty ? _addressSuggestions.first['description'] : null)) {
        _addressSelected = false;
      }
    }
    _addressDebounce?.cancel();
    if (text.trim().length < 3) {
      setState(() => _addressSuggestions = []);
      return;
    }
    _addressDebounce = Timer(const Duration(milliseconds: 450), () {
      _fetchAddressSuggestions(text.trim());
    });
  }

  Future<void> _fetchAddressSuggestions(String input) async {
    setState(() => _isLoadingAddress = true);

    // ── Mock data when no real key is provided ──────────────────────────────
    if (_kGoogleApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      await Future.delayed(const Duration(milliseconds: 300));
      final mocks = [
        'Alger Centre, Alger, Algeria',
        'Oran, Algeria',
        'Constantine, Algeria',
        'Annaba, Algeria',
        'Sétif, Algeria',
        'Blida, Algeria',
        'Batna, Algeria',
        'Béjaïa, Algeria',
        'Tizi Ouzou, Algeria',
        'Mostaganem, Algeria',
      ];
      final filtered = mocks
          .where((m) => m.toLowerCase().contains(input.toLowerCase()))
          .map((m) => {'description': m, 'place_id': 'mock_${m.hashCode}'})
          .toList();
      if (mounted) setState(() { _addressSuggestions = filtered; _isLoadingAddress = false; });
      return;
    }

    // ── Real Google Places Autocomplete ─────────────────────────────────────
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(input)}'
            '&components=country:dz'    // restrict to Algeria; remove or change as needed
            '&types=geocode'
            '&key=$_kGoogleApiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final predictions = (data['predictions'] as List<dynamic>? ?? []);
        final suggestions = predictions.map((p) => {
          'description': (p['description'] as String? ?? ''),
          'place_id'   : (p['place_id']    as String? ?? ''),
        }).toList();
        if (mounted) setState(() { _addressSuggestions = suggestions; _isLoadingAddress = false; });
      } else {
        if (mounted) setState(() { _addressSuggestions = []; _isLoadingAddress = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _addressSuggestions = []; _isLoadingAddress = false; });
    }
  }

  void _selectAddress(String description) {
    _addressController.text = description;
    _addressSelected = true;
    _addressFocusNode.unfocus();
    setState(() => _addressSuggestions = []);
  }

  // ─── Form validation ───────────────────────────────────────────────────────

  bool _validateForm() {
    return _offerNameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedImage != null &&
        _priceController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _expirationController.text.trim().isNotEmpty &&
        _selectedStatus != null;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Offer',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),

      // ── Submit button (fixed bottom) ───────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFA1C582), width: 1),
          ),
          child: ElevatedButton(
            // ✅ REMPLACE tout l'ancien onPressed par celui-ci
            onPressed: () async {
              final isValid = _validateForm();
              setState(() => _showError = !isValid);
              if (!isValid) return;

              final response = await OfferStore.createOffer({
                'title':          _offerNameController.text.trim(),
                'description':    _descriptionController.text.trim(),
                'price':          _priceController.text.trim(),
                'location':       _addressController.text.trim(),
                'availableUntil': _expirationController.text.trim(),
                'status':         _selectedStatus == 'Active' ? 'active'
                    : _selectedStatus == 'Sold out' ? 'soldout' : 'expired',
                'quantity':       _quantity.toString(),
                'type':           '',
              }, image: _selectedImage);

              // Le serveur retourne l'offre avec son id généré
              if (response != null && mounted) {
                Navigator.pop(context, response);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              elevation: 0,
            ),
            child: const Text(
              'Submit',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),

      body: GestureDetector(
        // Dismiss suggestions when tapping elsewhere
        onTap: () {
          _addressFocusNode.unfocus();
          setState(() => _addressSuggestions = []);
        },
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Offer Name ────────────────────────────────────────────────
              _buildLabel('Offer Name*'),
              _buildTextField(
                controller: _offerNameController,
                hint: 'Enter Offer Name',
                hasError: _showError && _offerNameController.text.trim().isEmpty,
              ),
              const SizedBox(height: 16),

              // ── Description ───────────────────────────────────────────────
              _buildLabel('Description*'),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Enter Description',
                maxLines: 4,
                hasError: _showError && _descriptionController.text.trim().isEmpty,
              ),
              const SizedBox(height: 16),

              // ── Picture ───────────────────────────────────────────────────
              _buildLabel('Picture*'),
              GestureDetector(
                onTap: () async {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.photo_library, color: primaryColor),
                            title: const Text('Gallery'),
                            onTap: () async {
                              Navigator.pop(context);
                              final XFile? image =
                              await _picker.pickImage(source: ImageSource.gallery);
                              if (image != null) setState(() => _selectedImage = File(image.path));
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.camera_alt, color: primaryColor),
                            title: const Text('Camera'),
                            onTap: () async {
                              Navigator.pop(context);
                              final XFile? image =
                              await _picker.pickImage(source: ImageSource.camera);
                              if (image != null) setState(() => _selectedImage = File(image.path));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _showError && _selectedImage == null
                          ? const Color(0xFFFF3B3B)
                          : const Color(0xFF395422),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _selectedImage != null
                          ? Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(_selectedImage!,
                              width: 30, height: 30, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                        const Text('Photo selected',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Color(0xFF395422))),
                      ])
                          : const Text('Upload Product Picture Here',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFFAAAAAA))),
                      const Icon(Icons.download_outlined, color: Color(0xFF475367)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Quantity + Price ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Quantity
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Quantity*'),
                      Row(children: [
                        _QtyBtn(
                          icon: Icons.remove,
                          color: primaryColor,
                          onTap: () { if (_quantity > 1) setState(() => _quantity--); },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _quantity.toString().padLeft(2, '0'),
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        _QtyBtn(
                          icon: Icons.add,
                          color: primaryColor,
                          onTap: () => setState(() => _quantity++),
                        ),
                      ]),
                    ],
                  ),

                  const SizedBox(width: 24),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Price*'),
                      SizedBox(
                        width: 150,
                        height: 40,
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) { if (_showError) setState(() {}); },
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: const TextStyle(
                                fontFamily: 'Poppins', fontSize: 13,
                                color: Color(0xFF717270)),
                            suffixText:
                            _priceController.text.isNotEmpty ? 'DA' : null,
                            suffixStyle: const TextStyle(
                                fontFamily: 'Poppins', fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A1A)),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _showError &&
                                    _priceController.text.trim().isEmpty
                                    ? const Color(0xFFFF3B3B)
                                    : const Color(0xFF395422),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _showError &&
                                    _priceController.text.trim().isEmpty
                                    ? const Color(0xFFFF3B3B)
                                    : const Color(0xFF72A843),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Address with Google Maps autocomplete ─────────────────────
              _buildLabel('Address*'),
              // Wrap in a Stack so suggestions float over the rest of the form
              Stack(
                clipBehavior: Clip.none,
                children: [
                  TextField(
                    controller:  _addressController,
                    focusNode:   _addressFocusNode,
                    onChanged:   (_) { if (_showError) setState(() {}); },
                    decoration: InputDecoration(
                      hintText: 'Type your address...',
                      hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF717270)),
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: _showError &&
                              _addressController.text.trim().isEmpty
                              ? const Color(0xFFFF3B3B)
                              : primaryColor,
                          size: 20),
                      suffixIcon: _isLoadingAddress
                          ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: primaryColor),
                        ),
                      )
                          : _addressController.text.isNotEmpty
                          ? GestureDetector(
                        onTap: () {
                          _addressController.clear();
                          _addressSelected = false;
                          setState(() => _addressSuggestions = []);
                        },
                        child: const Icon(Icons.close,
                            color: Colors.grey, size: 18),
                      )
                          : null,
                      filled:      true,
                      fillColor:   Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _showError &&
                              _addressController.text.trim().isEmpty
                              ? const Color(0xFFFF3B3B)
                              : const Color(0xFF395422),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _showError &&
                              _addressController.text.trim().isEmpty
                              ? const Color(0xFFFF3B3B)
                              : const Color(0xFF72A843),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),

                  // ── Suggestions dropdown ────────────────────────────────
                  if (_addressSuggestions.isNotEmpty)
                    Positioned(
                      top: 54,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryColor.withValues(alpha: 0.2)),
                          ),
                          constraints:
                          const BoxConstraints(maxHeight: 220),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _addressSuggestions.length,
                            separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade100),
                            itemBuilder: (context, i) {
                              final suggestion =
                              _addressSuggestions[i]['description']!;
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _selectAddress(suggestion),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: primaryColor
                                              .withValues(alpha:0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: primaryColor),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          suggestion,
                                          style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 13,
                                              color: Color(0xFF1A1A1A)),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Spacer to push content below the dropdown when it's open
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: _addressSuggestions.isNotEmpty
                    ? (_addressSuggestions.length * 50.0).clamp(0, 220)
                    : 0,
              ),
              const SizedBox(height: 16),

              // ── Expiration Date ───────────────────────────────────────────
              _buildLabel('Expiration Date*'),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: primaryColor,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    setState(() {
                      _expirationController.text =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _expirationController,
                    decoration: InputDecoration(
                      hintText: 'YYYY-MM-DD',
                      hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF717270)),
                      prefixIcon: Icon(Icons.calendar_today_outlined,
                          color: _showError &&
                              _expirationController.text.trim().isEmpty
                              ? const Color(0xFFFF3B3B)
                              : primaryColor,
                          size: 18),
                      filled:    true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _showError &&
                              _expirationController.text.trim().isEmpty
                              ? const Color(0xFFFF3B3B)
                              : const Color(0xFF395422),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Status ────────────────────────────────────────────────────
              _buildLabel('Status*'),
              _buildDropdown(
                hint: 'Choose Status',
                value: _selectedStatus,
                items: _statuses,
                hasError: _showError && _selectedStatus == null,
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),

              const SizedBox(height: 12),

              // ── Global error message ──────────────────────────────────────
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'All fields are required. Please fill them all in.',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFFFF3B3B),
                      letterSpacing: -0.24,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Reusable helpers ──────────────────────────────────────────────────────

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1A1A1A)),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool hasError = false,
  }) {
    return TextField(
      controller:   controller,
      maxLines:     maxLines,
      keyboardType: keyboardType,
      onChanged:    (_) { if (_showError) setState(() {}); },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: Color(0xFF717270)),
        filled:    true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFFF3B3B)
                  : const Color(0xFF395422),
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFFF3B3B)
                  : const Color(0xFF72A843),
              width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool hasError = false,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: hasError
                ? const Color(0xFFFF3B3B)
                : const Color(0xFF395422),
            width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFFAAAAAA))),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF475367)),
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(item,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF1A1A1A))),
          ))
              .toList(),
          onChanged: (val) {
            onChanged(val);
            if (_showError) setState(() {});
          },
        ),
      ),
    );
  }
}

// ─── Quantity button helper ───────────────────────────────────────────────────
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 40,
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}
