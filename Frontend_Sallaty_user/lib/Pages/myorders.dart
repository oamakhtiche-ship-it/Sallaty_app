import 'package:flutter/material.dart';
import 'orderstore.dart';
import 'order_item.dart';
import 'order_details.dart';
import 'network_image_widget.dart';

const _kPrimary500    = Color(0xFF72A843);
const _kBackground    = Color(0xFFF8FBF6);
const _kNeutral100    = Color(0xFFD7D8D7);
const _kNeutral900    = Color(0xFF2D2E2D);
const _kPendingBg     = Color(0xFFFFF9C4);
const _kPendingText   = Color(0xFFF57F17);
const _kConfirmedBg   = Color(0xFFD0E2C0);
const _kConfirmedText = Color(0xFF3B6D11);
const _kCancelledBg   = Color(0x80FFBEBE);
const _kCancelledText = Color(0xFFFF3B3B);
const _kPickedBg      = Color(0xFFD7D8D7);
const _kPickedText    = Color(0xFF5A5B59);

class MyOrdersPage extends StatefulWidget {
  final VoidCallback? onBrowse;
  const MyOrdersPage({super.key, this.onBrowse});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  OrderStatus? _activeFilter;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await OrderStore.instance.fetchClientOrders();
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load orders');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OrderItem> get _orders => OrderStore.instance.clientOrders;

  List<OrderItem> get _filtered => _activeFilter == null
      ? _orders
      : _orders.where((o) => o.status == _activeFilter).toList();

  void _updateOrderStatus(int globalIndex, OrderStatus newStatus) {
    setState(() {
      OrderStore.instance.updateClientOrderStatus(globalIndex, newStatus);
    });
  }

  int _globalIndex(OrderItem item) =>
      OrderStore.instance.clientOrders.indexOf(item);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: CircularProgressIndicator(color: _kPrimary500),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrders,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary500),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            // ── Titre ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    const Text(
                      'My orders',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          color: _kPrimary500),
                      onPressed: _loadOrders,
                    ),
                  ],
                ),
              ),
            ),

            // ── Filtres ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'All',
                        isActive: _activeFilter == null,
                        onTap: () =>
                            setState(() => _activeFilter = null),
                      ),
                      _FilterTab(
                        label: 'Pending',
                        isActive:
                            _activeFilter == OrderStatus.pending,
                        onTap: () => setState(
                            () => _activeFilter = OrderStatus.pending),
                      ),
                      _FilterTab(
                        label: 'Confirmed',
                        isActive:
                            _activeFilter == OrderStatus.confirmed,
                        onTap: () => setState(() =>
                            _activeFilter = OrderStatus.confirmed),
                      ),
                      _FilterTab(
                        label: 'Picked',
                        isActive:
                            _activeFilter == OrderStatus.picked,
                        onTap: () => setState(
                            () => _activeFilter = OrderStatus.picked),
                      ),
                      _FilterTab(
                        label: 'Cancelled',
                        isActive:
                            _activeFilter == OrderStatus.cancelled,
                        onTap: () => setState(() =>
                            _activeFilter = OrderStatus.cancelled),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Liste ou état vide ───────────────────────────────
            _filtered.isEmpty
                ? SliverFillRemaining(
              child: _EmptyState(onBrowse: () => widget.onBrowse?.call()),
             )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = _filtered[index];
                        final globalIdx = _globalIndex(order);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                              16, 0, 16, 10),
                          child: _OrderCard(
                            order: order,
                            onStatusChanged: (newStatus) {
                              _updateOrderStatus(
                                  globalIdx, newStatus);
                            },
                          ),
                        );
                      },
                      childCount: _filtered.length,
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Tab ───────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? _kPrimary500 : _kNeutral100,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isActive ? Colors.white : _kNeutral900,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final ValueChanged<OrderStatus>? onStatusChanged;

  const _OrderCard({required this.order, this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // ✅ No extra callbacks — OrderDetailsPage handles everything internally
        final result = await Navigator.push<OrderStatus>(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(order: order),
          ),
        );
        if (result != null) {
          onStatusChanged?.call(result);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Image ──────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: order.imagePath != null
                  ? AppNetworkImage(url: order.imagePath!, width: 64, height: 64, fit: BoxFit.cover)
                  : _placeholder(),
            ),

            const SizedBox(width: 10),

            // ── Infos ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        order.price,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.merchantName,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pickup: ${order.pickupLocation}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF777777)),
                  ),
                  if (order.pickupTime != null)
                    Text(
                      'Until: ${order.pickupTime}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF777777)),
                    ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _StatusBadge(status: order.status),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        color: const Color(0xFFE0E0E0),
        child: const Icon(Icons.image,
            color: Color(0xFFAAAAAA), size: 28),
      );
}

// ─── Status Badge ─────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      OrderStatus.pending   => ('Pending',   _kPendingBg,   _kPendingText),
      OrderStatus.confirmed => ('Confirmed', _kConfirmedBg, _kConfirmedText),
      OrderStatus.cancelled => ('Cancelled', _kCancelledBg, _kCancelledText),
      OrderStatus.picked    => ('Picked',    _kPickedBg,    _kPickedText),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: fg)),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyState({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 100, color: Color(0xFFB0BEC5)),
            const SizedBox(height: 20),
            const Text(
              'No orders yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kNeutral900),
            ),
            const SizedBox(height: 8),
            const Text(
              "You don't have any orders yet.\nBrowse available offers and help\nreduce food waste today!",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBrowse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary500,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Browse Offers',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}