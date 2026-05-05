import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'apiservice.dart';
import 'usersession.dart';
import 'favori_button.dart';
import 'network_image_widget.dart';

class ViewOfferPage extends StatefulWidget {
  final String offerId;
  final String title;
  final String description;
  final String location;
  final String price;
  final String imageUrl;
  final String availableUntil;
  final String status;
  final String quantity;

  const ViewOfferPage({
    super.key,
    required this.offerId,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.availableUntil = '',
    this.status         = 'active',
    this.quantity       = '',
  });

  @override
  State<ViewOfferPage> createState() => _ViewOfferPageState();
}

class _ViewOfferPageState extends State<ViewOfferPage> {

  Color _statusColor() {
    switch (widget.status.toLowerCase()) {
      case 'active':  return const Color(0xFF72A843);
      case 'soldout': return Colors.red;
      case 'expired': return Colors.orange;
      default:        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (widget.status.toLowerCase()) {
      case 'active':  return '✓  Available';
      case 'soldout': return '✕  Sold Out';
      case 'expired': return '⚠  Expired';
      default:        return widget.status;
    }
  }

  bool get _canReserve => widget.status.toLowerCase() == 'active';

  DateTime? get _expirationDate {
    if (widget.availableUntil.isEmpty) return null;
    try { return DateTime.parse(widget.availableUntil); } catch (_) { return null; }
  }

  int get _maxStock {
    final q = int.tryParse(widget.quantity.trim());
    return (q != null && q > 0) ? q : 99;
  }

  void _showReservationSheet() {
    if (!_canReserve) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.status.toLowerCase() == 'soldout'
            ? 'This offer is sold out'
            : 'This offer has expired'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReservationSheet(
        offreId:        widget.offerId,
        offerTitle:     widget.title,
        location:       widget.location,
        price:          widget.price,
        imageUrl:       widget.imageUrl,
        maxStock:       _maxStock,
        expirationDate: _expirationDate,
        onConfirmed: () => Navigator.pop(pageContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expirationDisplay = widget.availableUntil.isNotEmpty
        ? widget.availableUntil
        : 'Not specified';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF4),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF72A843),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: FavoriButton(offerId: widget.offerId),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.imageUrl.isNotEmpty
                      ? AppNetworkImage(
                          url: widget.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(
                          color: const Color(0xFFD0E6A5),
                          child: const Icon(Icons.fastfood,
                              size: 80, color: Colors.white),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF72A843), Color(0xFFA0CA09)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4))],
                      ),
                      child: Text('${widget.price} DA',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: _statusColor().withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(_statusLabel(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: GoogleFonts.poppins(
                          fontSize: 24, fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A))),
                  const SizedBox(height: 10),
                  _InfoChip(
                      icon: Icons.location_on,
                      label: widget.location,
                      color: const Color(0xFF72A843)),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFE8F5E3), width: 1.5),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Offer Details',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: const Color(0xFF72A843))),
                        const SizedBox(height: 14),
                        _DetailRow(icon: Icons.payments_outlined,
                            label: 'Price',
                            value: '${widget.price} DA ',
                            valueColor: const Color(0xFF72A843), bold: true),
                        const _RowDivider(),
                        _DetailRow(icon: Icons.info_outline,
                            label: 'Status',
                            value: _statusLabel(),
                            valueColor: _statusColor(), bold: true),
                        const _RowDivider(),
                        if (widget.quantity.isNotEmpty) ...[
                          _DetailRow(icon: Icons.inventory_2_outlined,
                              label: 'Available Quantity',
                              value: widget.quantity,
                              valueColor: const Color(0xFF1A1A1A)),
                          const _RowDivider(),
                        ],
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Expiration Date',
                          value: expirationDisplay,
                          valueColor: widget.status.toLowerCase() == 'expired'
                              ? Colors.red
                              : const Color(0xFF1A1A1A),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: const Color(0xFFE8F5E3)),
                  const SizedBox(height: 20),

                  Text('Description',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: const Color(0xFF72A843))),
                  const SizedBox(height: 8),
                  Text(
                    widget.description.isNotEmpty
                        ? widget.description
                        : 'No description available.',
                    style: const TextStyle(
                        fontSize: 14, height: 1.7,
                        color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 24),

                  Row(children: [
                    Expanded(child: _StatCard(
                        icon: Icons.access_time, title: 'Available',
                        value: widget.status.toLowerCase() == 'active'
                            ? 'Today' : 'Unavailable',
                        color: const Color(0xFF72A843))),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(
                        icon: Icons.verified_user, title: 'Quality',
                        value: 'Guaranteed',
                        color: const Color(0xFFB87333))),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(
                        icon: Icons.savings, title: 'Savings',
                        value: 'Up to 70%',
                        color: const Color(0xFF1A6E8E))),
                  ]),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _showReservationSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _canReserve
                                ? [const Color(0xFF72A843),
                                   const Color(0xFFA0CA09)]
                                : [Colors.grey.shade400,
                                   Colors.grey.shade500],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _canReserve
                              ? [BoxShadow(
                                  color: const Color(0xFF72A843)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  _canReserve
                                      ? Icons.shopping_bag_outlined
                                      : Icons.block,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                _canReserve
                                    ? 'Reserve This Offer'
                                    : widget.status.toLowerCase() == 'soldout'
                                        ? 'Offer Sold Out'
                                        : 'Offer Expired',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RESERVATION BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _ReservationSheet extends StatefulWidget {
  final String       offreId;
  final String       offerTitle;
  final String       location;
  final String       price;
  final String       imageUrl;
  final int          maxStock;
  final DateTime?    expirationDate;
  final VoidCallback onConfirmed;

  const _ReservationSheet({
    required this.offreId,
    required this.offerTitle,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.maxStock,
    required this.expirationDate,
    required this.onConfirmed,
  });

  @override
  State<_ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<_ReservationSheet> {
  int    _quantity   = 1;
  String _pickupDate = '';
  String _pickupTime = '';
  bool   _isLoading  = false;
  final TextEditingController _noteCtrl = TextEditingController();

  final List<String> _timeSlots = [
    '09:00','10:00','11:00','12:00',
    '14:00','15:00','16:00','17:00','18:00',
  ];

  List<DateTime> get _availableDates {
    final today = DateTime.now();
    if (widget.expirationDate == null) {
      return List.generate(7, (i) => today.add(Duration(days: i)));
    }
    final lastDay = widget.expirationDate!.subtract(const Duration(days: 1));
    if (lastDay.isBefore(today)) return [today];
    final diff = lastDay.difference(today).inDays;
    return List.generate(diff + 1, (i) => today.add(Duration(days: i)));
  }

  String _formatDateLabel(DateTime dt) {
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
  }

  String _formatDateForDisplay(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateForApi(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
      '-${dt.day.toString().padLeft(2, '0')}';

  double get _totalPrice {
    final raw = widget.price.replaceAll(RegExp(r'[^0-9.]'), '');
    return (double.tryParse(raw) ?? 0) * _quantity;
  }

  Future<void> _confirm() async {
    if (_pickupDate.isEmpty) { _err('Please choose a pickup date'); return; }
    if (_pickupTime.isEmpty) { _err('Please choose a pickup time'); return; }

    final token = UserSession().token ?? '';
    if (token.isEmpty) { _err('Please log in to reserve'); return; }

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ordres/create'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {
          'offreId':  widget.offreId,
          'quantity': _quantity.toString(),
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
        _showSuccess();
      } else {
        try {
          final body = jsonDecode(res.body);
          _err(body['message']?.toString() ?? 'Reservation failed');
        } catch (_) {
          _err('Reservation failed (${res.statusCode})');
        }
      }
    } catch (e) {
      _err('Connection error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                      color: Color(0xFFEAF6E1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle,
                      color: Color(0xFF72A843), size: 48)),
              const SizedBox(height: 20),
              Text('Reservation Confirmed!',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('"${widget.offerTitle}"\nhas been reserved.',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F8EC),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _ConfirmRow(icon: Icons.shopping_bag_outlined,
                      label: 'Quantity',
                      value: '$_quantity item${_quantity > 1 ? 's' : ''}'),
                  const SizedBox(height: 6),
                  _ConfirmRow(icon: Icons.payments_outlined,
                      label: 'Total',
                      value: '${_totalPrice.toStringAsFixed(0)} DA'),
                  const SizedBox(height: 6),
                  _ConfirmRow(icon: Icons.calendar_today_outlined,
                      label: 'Pickup',
                      value: '$_pickupDate at $_pickupTime'),
                  const SizedBox(height: 6),
                  _ConfirmRow(icon: Icons.location_on_outlined,
                      label: 'Location', value: widget.location),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    widget.onConfirmed();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF72A843),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Great!',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dates = _availableDates;
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.shopping_bag_outlined,
                  color: Color(0xFF72A843), size: 22),
              const SizedBox(width: 8),
              Text('Reserve', style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A))),
            ]),
            const SizedBox(height: 4),
            Text(widget.offerTitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),

            _SectionLabel(label: 'Quantity'),
            const SizedBox(height: 6),
            Text('Available stock: ${widget.maxStock} item${widget.maxStock > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(children: [
              _QtyButton(icon: Icons.remove, onTap: () {
                if (_quantity > 1) setState(() => _quantity--);
              }),
              const SizedBox(width: 16),
              Text('$_quantity', style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A))),
              const SizedBox(width: 16),
              _QtyButton(icon: Icons.add, onTap: () {
                if (_quantity < widget.maxStock) {
                  setState(() => _quantity++);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Maximum available: ${widget.maxStock}'),
                    backgroundColor: Colors.orange.shade700,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                }
              }),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF6E1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${_totalPrice.toStringAsFixed(0)} DA',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF72A843),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ]),
            const SizedBox(height: 20),

            _SectionLabel(label: 'Pickup Date'),
            if (widget.expirationDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Available until ${_formatDateForDisplay(widget.expirationDate!.subtract(const Duration(days: 1)))}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 10),
            dates.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Flexible(child: Text(
                          'No pickup dates available',
                          style: TextStyle(fontSize: 12, color: Colors.red))),
                    ]),
                  )
                : SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final date    = dates[i];
                        final parts   = _formatDateLabel(date).split(' ');
                        final isSel   = _pickupDate == _formatDateForApi(date);
                        final isToday = i == 0;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _pickupDate = _formatDateForApi(date)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 64,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF72A843)
                                  : const Color(0xFFF5F5F0),
                              borderRadius: BorderRadius.circular(14),
                              border: isSel
                                  ? null
                                  : Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(parts[0], style: TextStyle(
                                    fontSize: 11,
                                    color: isSel ? Colors.white70 : Colors.grey)),
                                Text(parts[1], style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSel
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A))),
                                if (isToday)
                                  Text('Today', style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isSel
                                          ? Colors.white70
                                          : const Color(0xFF72A843))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),

            _SectionLabel(label: 'Pickup Time'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _timeSlots.map((slot) {
                final isSel = _pickupTime == slot;
                return GestureDetector(
                  onTap: () => setState(() => _pickupTime = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFF72A843)
                          : const Color(0xFFF5F5F0),
                      borderRadius: BorderRadius.circular(10),
                      border: isSel
                          ? null
                          : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(slot, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: isSel
                            ? Colors.white
                            : const Color(0xFF555555))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _SectionLabel(label: 'Note (optional)'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _noteCtrl, maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'E.g. Nut allergy, special requests...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF72A843), Color(0xFFA0CA09)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Confirm Reservation',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small Widgets ────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    valueColor;
  final bool     bold;
  const _DetailRow({required this.icon, required this.label,
      required this.value, required this.valueColor, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: const Color(0xFF72A843)),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      const Spacer(),
      Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: valueColor)),
    ]),
  );
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: const Color(0xFFF0F0F0));
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A)));
}

class _QtyButton extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: const Color(0xFFEAF6E1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF72A843), size: 20)),
  );
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _ConfirmRow({required this.icon, required this.label,
      required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: const Color(0xFF72A843)),
    const SizedBox(width: 8),
    Text('$label: ',
        style: const TextStyle(fontSize: 12, color: Colors.grey)),
    Expanded(child: Text(value,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A)),
        overflow: TextOverflow.ellipsis)),
  ]);
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip({required this.icon, required this.label,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(
          fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   value;
  final Color    color;
  const _StatCard({required this.icon, required this.title,
      required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(title, style: TextStyle(
          fontSize: 10, color: color.withValues(alpha: 0.7)),
          textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center),
    ]),
  );
}