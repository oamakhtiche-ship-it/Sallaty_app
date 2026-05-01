import 'package:flutter/material.dart';
import 'confirm_pay.dart';
import 'order_item.dart';
import 'payment_models.dart';

const _kGreen = Color(0xFF72A843);
const _kBg = Color(0xFFF5F5F5);

class CardDetailsPage extends StatefulWidget {
  final String totalAmount;
  final String ordreId;
  final OrderItem order;

  const CardDetailsPage({
    super.key,
    required this.totalAmount,
    required this.ordreId,
    required this.order,
  });

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _saveCard = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;

    final request = PaymentRequestDto(
      ordreId: int.tryParse(widget.ordreId) ?? 0,
      method: PaymentMethod.CARD,
      cardNumber: _cardNumberCtrl.text.trim(),
      expiryDate: _expiryCtrl.text.trim(),
      cvv: _cvvCtrl.text.trim(),
      cardholderName: _nameCtrl.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmPaymentPage(
          ordreId: widget.ordreId,
          order: widget.order,
          cardRequest: request,
          totalAmount: widget.totalAmount,
        ),
      ),
    );
  }

  // live masked card number for the card visual
  String get _maskedDisplay {
    final clean = _cardNumberCtrl.text.replaceAll(' ', '');
    if (clean.isEmpty) return '•••• •••• •••• ••••';
    final padded = clean.padRight(16, '•');
    return '${padded.substring(0, 4)} ${padded.substring(4, 8)} ${padded.substring(8, 12)} ${padded.substring(12, 16)}';
  }

  String get _expiryDisplay {
    final v = _expiryCtrl.text;
    return v.isEmpty ? 'MM/YY' : v;
  }

  String get _nameDisplay {
    final v = _nameCtrl.text;
    return v.isEmpty ? 'CARDHOLDER NAME' : v.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Card Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kGreen,
          ),
        ),
        centerTitle: true,
        // ── Confirm & Pay button in app bar ─────────────────
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _proceed,
              icon: const Icon(Icons.lock_outline, size: 16,
                  color: Colors.white),
              label: const Text(
                'Confirm & Pay',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 0),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── instruction text ──────────────────────────────
            const Text(
              'Enter your card information',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 16),

            // ── Card visual ───────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge(
                  [_cardNumberCtrl, _expiryCtrl, _nameCtrl]),
              builder: (_, __) => _CardVisual(
                cardNumber: _maskedDisplay,
                expiry: _expiryDisplay,
                name: _nameDisplay,
              ),
            ),
            const SizedBox(height: 24),

            // ── Card Number ───────────────────────────────────
            _buildField(
              label: 'Card Number',
              required: true,
              child: _inputField(
                controller: _cardNumberCtrl,
                hint: '1234 5678 9012 3456',
                keyboardType: TextInputType.number,
                maxLength: 19,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.replaceAll(' ', '').length < 16) {
                    return 'Enter a valid 16-digit number';
                  }
                  return null;
                },
                onChanged: (v) {
                  final clean = v.replaceAll(' ', '');
                  final formatted = clean
                      .replaceAllMapped(
                        RegExp(r'.{1,4}'),
                        (m) => '${m.group(0)} ',
                      )
                      .trim();
                  if (formatted != v) {
                    _cardNumberCtrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                          offset: formatted.length),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Expiry + CVV ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Expiry Date',
                    required: true,
                    child: _inputField(
                      controller: _expiryCtrl,
                      hint: 'MM/YY',
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) {
                          return 'MM/YY';
                        }
                        return null;
                      },
                      onChanged: (v) {
                        if (v.length == 2 && !v.contains('/')) {
                          _expiryCtrl.text = '$v/';
                          _expiryCtrl.selection = TextSelection.collapsed(
                              offset: _expiryCtrl.text.length);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: 'CVV',
                    required: true,
                    child: _inputField(
                      controller: _cvvCtrl,
                      hint: '123',
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 3) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Cardholder Name ───────────────────────────────
            _buildField(
              label: 'Cardholder Name',
              required: true,
              child: _inputField(
                controller: _nameCtrl,
                hint: 'Name',
                keyboardType: TextInputType.name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 14),

            // ── Save card checkbox ────────────────────────────
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _saveCard,
                    onChanged: (v) =>
                        setState(() => _saveCard = v ?? false),
                    activeColor: _kGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Color(0xFFBBBBBB)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Save card for future purchases',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Total Amount bar ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF555555),
                    ),
                  ),
                  Text(
                    '${widget.totalAmount} DZD',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
            children: required
                ? const [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFFAAAAAA),
        ),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ── Card Visual Widget ────────────────────────────────────────────
class _CardVisual extends StatelessWidget {
  final String cardNumber;
  final String expiry;
  final String name;

  const _CardVisual({
    required this.cardNumber,
    required this.expiry,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A6B), Color(0xFF2563C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A6B).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // background circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // chip + VISA row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // chip
                    Container(
                      width: 36,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: const Color(0xFFE8C96E),
                      ),
                      child: CustomPaint(painter: _ChipPainter()),
                    ),
                    // VISA text
                    const Text(
                      'VISA',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // card number
                Text(
                  cardNumber,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 14),
                // name + valid thru
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARDHOLDER NAME',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: Colors.white54,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'VALID THRU',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: Colors.white54,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          expiry,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A520)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // vertical line
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    // horizontal line
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}