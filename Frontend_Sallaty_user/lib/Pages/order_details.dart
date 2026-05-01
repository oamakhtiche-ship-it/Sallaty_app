import 'package:flutter/material.dart';
import 'order_item.dart';
import 'orderstore.dart';
import 'payment_sheet.dart';

const _kPrimary500 = Color(0xFF72A843);
const _kBackground = Color(0xFFF8FBF6);
const _kNeutral100 = Color(0xFFD7D8D7);
const _kNeutral900 = Color(0xFF2D2E2D);

class OrderDetailsPage extends StatefulWidget {
  final OrderItem order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late OrderItem _order;
  bool _confirmingPickup = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  // ── Confirm Pickup → status = picked ─────────────────────────
  Future<void> _confirmPickup() async {
    setState(() => _confirmingPickup = true);
    try {
      final store = OrderStore.instance;
      final idx = store.clientOrders.indexWhere(
        (o) => o.ordreId == _order.ordreId,
      );
      if (idx != -1) {
        // void method — no await
        store.updateClientOrderStatus(idx, OrderStatus.picked);
        if (!mounted) return;
        setState(() => _order = _order.copyWith(status: OrderStatus.picked));
        Navigator.pop(context, OrderStatus.picked);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm pickup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _confirmingPickup = false);
    }
  }

  // ── Open Payment Sheet ────────────────────────────────────────
  void _openPayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PaymentSheet(
          totalAmount: _order.price,
          ordreId: _order.ordreId,
          order: _order,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPicked = _order.status == OrderStatus.picked;
    final isConfirmed = _order.status == OrderStatus.confirmed;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: _kNeutral900, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kNeutral900,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status badge ──────────────────────────────────
            _statusBadge(_order.status),
            const SizedBox(height: 20),

            // ── Order image ───────────────────────────────────
            if (_order.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _order.imagePath!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: _kNeutral100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.image_not_supported,
                        size: 36, color: Color(0xFFAAAAAA)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Info card ─────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Order Information'),
                  const SizedBox(height: 12),
                  _infoRow('Order ID', '#${_order.ordreId}'),
                  _infoRow('Title', _order.title),
                  _infoRow('Merchant', _order.merchantName),
                  _infoRow('Pickup', _order.pickupLocation),
                  if (_order.pickupTime != null)
                    _infoRow('Time', _order.pickupTime!),
                  _infoRow(
                    'Price',
                    '${_order.price} DZD',
                    valueColor: _kPrimary500,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Buttons ───────────────────────────────────────
            if (!isPicked && isConfirmed) ...[
              // PAY NOW
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _openPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // CONFIRM PICKUP
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _confirmingPickup ? null : _confirmPickup,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kPrimary500, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _confirmingPickup
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: _kPrimary500,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Pickup',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary500,
                          ),
                        ),
                ),
              ),
            ],

            // ── Picked success banner ─────────────────────────
            if (isPicked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kPrimary500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kPrimary500.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: _kPrimary500, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Order Picked Up',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary500,
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

  // ── Helpers ───────────────────────────────────────────────────

  Widget _statusBadge(OrderStatus status) {
    final label = _statusLabel(status);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kNeutral100),
        ),
        child: child,
      );

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _kNeutral900,
        ),
      );

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? _kNeutral900,
                ),
              ),
            ),
          ],
        ),
      );

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.picked:
        return 'Picked Up';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.picked:
        return _kPrimary500;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}