import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'my_offers.dart';

class EditOfferPage extends StatefulWidget {
  // Données de l'offre existante passées en paramètre
  final String initialId;           // ← ADDED: required id field
  final String initialName;
  final String initialDescription;
  final String initialPrice;
  final String initialAddress;
  final String initialType;
  final String initialExpirationDate;
  final String initialStatus;
  final int initialQuantity;
  final String? initialImageUrl; // URL image existante depuis le serveur

  const EditOfferPage({
    super.key,
    required this.initialId,        // ← ADDED: required in constructor
    this.initialName = '',
    this.initialDescription = '',
    this.initialPrice = '',
    this.initialAddress = '',
    this.initialType = '',
    this.initialExpirationDate = '',
    this.initialStatus = '',
    this.initialQuantity = 1,
    this.initialImageUrl,
  });

  @override
  State<EditOfferPage> createState() => _EditOfferPageState();
}

class _EditOfferPageState extends State<EditOfferPage> {
  File? _newSelectedImage;   // nouvelle image choisie
  final ImagePicker _picker = ImagePicker();
  final Color primaryColor = const Color(0xFF72A843);

  late final TextEditingController _offerNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _addressController;
  late final TextEditingController _expirationController;
  late int _quantity;
  String? _selectedType;
  String? _selectedStatus;

  bool _showError = false;

  final List<String> _types = ['Bakery', 'Fish Shop', 'Cafe', 'Fast Food', 'Grocery','Butcher','Fruits & Vegetables','Restaurant','Home Cooking'];
  final List<String> _statuses = ['Active', 'Expired', 'Sold out'];

  @override
  void initState() {
    super.initState();
    _offerNameController    = TextEditingController(text: widget.initialName);
    _descriptionController  = TextEditingController(text: widget.initialDescription);
    _priceController        = TextEditingController(text: widget.initialPrice);
    _addressController      = TextEditingController(text: widget.initialAddress);
    _expirationController   = TextEditingController(text: widget.initialExpirationDate);
    _quantity               = widget.initialQuantity;
    _selectedType           = widget.initialType.isNotEmpty ? widget.initialType : null;

    // Convertit la valeur API vers la valeur de la liste
    if (widget.initialStatus.toLowerCase() == 'active') {
      _selectedStatus = 'Active';
    } else if (widget.initialStatus.toLowerCase() == 'soldout') {
      _selectedStatus = 'Sold out';
    } else if (widget.initialStatus.toLowerCase() == 'expired') {
      _selectedStatus = 'Expired';
    } else {
      _selectedStatus = null;
    }
  }

  @override
  void dispose() {
    _offerNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _expirationController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    return _offerNameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _selectedType != null &&
        _expirationController.text.trim().isNotEmpty &&
        _selectedStatus != null;
  }

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
          'Edit Offer',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),

      // ── Bouton Save fixé en bas ────────────────────────────
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
            onPressed: () {
              final isValid = _validateForm();
              setState(() => _showError = !isValid);
              if (isValid) {
                final updatedOffer = Offer(
                  id: widget.initialId,             // ← ADDED: pass the id
                  title: _offerNameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  price: _priceController.text.trim(),
                  location: _addressController.text.trim(),
                  availableUntil: _expirationController.text.trim(),
                  status: _selectedStatus == 'Active'
                      ? 'active'
                      : _selectedStatus == 'Sold out'
                      ? 'soldout'
                      : 'expired',
                  quantity: _quantity.toString(),
                  available: _quantity.toString(),
                  imageUrl: widget.initialImageUrl ?? '',
                  type: _selectedType ?? '',
                );
                Navigator.pop(context, updatedOffer);   // ← retourne l'offre mise à jour
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Update Offer',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Offer Name ──────────────────────────────────
            _buildLabel('Offer Name'),
            _buildTextField(
              controller: _offerNameController,
              hint: 'Enter Offer Name',
              hasError: _showError && _offerNameController.text.trim().isEmpty,
            ),
            const SizedBox(height: 16),

            // ── Change Photo ─────────────────────────────────
            _buildLabel('Change photo'),
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
                          title: const Text('Galerie'),
                          onTap: () async {
                            Navigator.pop(context);
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setState(() => _newSelectedImage = File(image.path));
                            }
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.camera_alt, color: primaryColor),
                          title: const Text('Caméra'),
                          onTap: () async {
                            Navigator.pop(context);
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.camera,
                            );
                            if (image != null) {
                              setState(() => _newSelectedImage = File(image.path));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _newSelectedImage != null
                // Nouvelle image sélectionnée
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _newSelectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
                    : widget.initialImageUrl != null
                // Image existante depuis le serveur
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.initialImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
                  ),
                )
                // Aucune image
                    : _buildPhotoPlaceholder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Quantity + Price ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Quantity ────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Quantity'),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                          child: Container(
                            width: 32, height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.remove, color: Colors.white, size: 18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _quantity.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _quantity++),
                          child: Container(
                            width: 32, height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.add, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Price ────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Price'),
                    SizedBox(
                      width: 150,
                      height: 40,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (_showError) {setState(() {});}
                          else {setState(() {});}
                        },
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF717270),
                          ),
                          suffixStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _showError && _priceController.text.trim().isEmpty
                                  ? const Color(0xFFFF3B3B)
                                  : const Color(0xFF395422),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _showError && _priceController.text.trim().isEmpty
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

            // ── Address ─────────────────────────────────────
            _buildLabel('Address'),
            _buildTextField(
              controller: _addressController,
              hint: 'Enter Your Full Address',
              hasError: _showError && _addressController.text.trim().isEmpty,
            ),
            const SizedBox(height: 16),

            // ── Type ────────────────────────────────────────
            _buildLabel('Type'),
            _buildDropdown(
              hint: 'Select Type',
              value: _selectedType,
              items: _types,
              hasError: _showError && _selectedType == null,
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 16),

            // ── Expiration Date ──────────────────────────────
            _buildLabel('Expiration Date'),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_expirationController.text) ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _expirationController.text =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  });
                }
              },
              child: AbsorbPointer(
                child: _buildTextField(
                  controller: _expirationController,
                  hint: 'YYYY-MM-DD',
                  hasError: _showError && _expirationController.text.trim().isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Status ──────────────────────────────────────
            _buildLabel('Status'),
            _buildDropdown(
              hint: 'Choose Status',
              value: _selectedStatus,
              items: _statuses,
              hasError: _showError && _selectedStatus == null,
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),

            const SizedBox(height: 12),

            // ── Message d'erreur global ──────────────────────
            if (_showError)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: const Text(
                  'All fields are required . Please enter all of them .',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
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
    );
  }

  // ── Placeholder photo ────────────────────────────────────
  Widget _buildPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 36),
        const SizedBox(height: 8),
        const Text(
          'Tap to change photo',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool hasError = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) {
        if (_showError) setState(() {});
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: Color(0xFF717270),
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF3B3B) : const Color(0xFF395422),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF3B3B) : const Color(0xFF72A843),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          color: hasError ? const Color(0xFFFF3B3B) : const Color(0xFF395422),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFFAAAAAA),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475367)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            onChanged(val);
            if (_showError) setState(() {});
          },
        ),
      ),
    );
  }
}
