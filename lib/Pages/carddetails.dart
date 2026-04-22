import 'package:flutter/material.dart';
import 'confirm_pay.dart';
class CardDetailsPage extends StatefulWidget {
  final String totalAmount;

  const CardDetailsPage({
    super.key,
    required this.totalAmount,
  });

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  final Color primaryColor = const Color(0xFF72A843);

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _saveCard = false;
  bool _showError = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    return _cardNumberController.text.trim().isNotEmpty &&
        _expiryController.text.trim().isNotEmpty &&
        _cvvController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty;
  }

  // ── Formate le numéro de carte : 1234 5678 9012 3456 ──────────────
  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFFF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFFF7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Card Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Subtitle ──────────────────────────────────────────
            const Text(
              'Enter your card information',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1A1A1A),
              ),
            ),

            const SizedBox(height: 16),


            // ── Card Visual ───────────────────────────────────────────
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/bank_card.png',
                  width: 280,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Card Number ───────────────────────────────────────
            _buildLabel('Card Number*'),
            _buildTextField(
              controller: _cardNumberController,
              hint: '1234 5678 9012 3456',
              keyboardType: TextInputType.number,
              hasError: _showError && _cardNumberController.text.trim().isEmpty,
              maxLength: 19,
              onChanged: (val) {
                final formatted = _formatCardNumber(
                    val.replaceAll(' ', ''));
                if (formatted != val) {
                  _cardNumberController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                        offset: formatted.length),
                  );
                }
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // ── Expiry + CVV ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Expiry Date*'),
                      _buildTextField(
                        controller: _expiryController,
                        hint: 'MM/YY',
                        keyboardType: TextInputType.number,
                        hasError: _showError &&
                            _expiryController.text.trim().isEmpty,
                        maxLength: 5,
                        onChanged: (val) {
                          if (val.length == 2 && !val.contains('/')) {
                            _expiryController.text = '$val/';
                            _expiryController.selection =
                                TextSelection.collapsed(offset: 3);
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('CVV*'),
                      _buildTextField(
                        controller: _cvvController,
                        hint: '123',
                        keyboardType: TextInputType.number,
                        hasError: _showError &&
                            _cvvController.text.trim().isEmpty,
                        maxLength: 3,
                        obscureText: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Cardholder Name ───────────────────────────────────
            _buildLabel('Cardholder Name*'),
            _buildTextField(
              controller: _nameController,
              hint: 'Name',
              hasError:
              _showError && _nameController.text.trim().isEmpty,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height:0),

            // ── Save card ─────────────────────────────────────────
            Row(
              children: [
                Checkbox(
                  value: _saveCard,
                  activeColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) =>
                      setState(() => _saveCard = val ?? false),
                ),
                const Text(
                  'Save card for future purchases',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 0),

            // ── Total Amount ──────────────────────────────────────
            Container(
              width: double.infinity,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF717270),
                    ),
                  ),
                  Text(
                    widget.totalAmount,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Confirm & Pay ─────────────────────────────────────
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final isValid = _validateForm();
                  setState(() => _showError = !isValid);
                  if (isValid) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfirmPaymentPage(
                          paymentMethod: 'via credit / debit card.',
                          subTotal: 1345,
                          deliveryFee: 450,
                          appTax: 100,
                          // ← remplace par tes vraies valeurs
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.lock_outline,
                    color: Colors.white, size: 18),
                label: const Text(
                  'Confirm & Pay',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool hasError = false,
    bool obscureText = false,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF717270),
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError
                ? const Color(0xFFFF3B3B)
                : const Color(0xFF395422),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError
                ? const Color(0xFFFF3B3B)
                : const Color(0xFF72A843),
            width: 1.5,
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
