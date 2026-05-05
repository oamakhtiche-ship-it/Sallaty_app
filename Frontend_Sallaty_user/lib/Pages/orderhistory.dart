// lib/orderhistory.dart
import 'package:flutter/material.dart';
import 'orderstore.dart';
import 'order_item.dart';
import 'network_image_widget.dart';
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Orders the client has placed (bought)
  List<OrderItem> get _boughtOrders => OrderStore.instance.clientOrders;

  /// Orders that came from the merchant's reservations (sold)
  List<ReservationRecord> get _soldReservations =>
      OrderStore.instance.reservationsByOffer.values
          .expand((list) => list)
          .toList();

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return const Color(0xFF72A843);
      case OrderStatus.pending:
        return const Color(0xFFFFC107);
      case OrderStatus.cancelled:
        return const Color(0xFFFF5252);
      case OrderStatus.picked:
        return const Color(0xFF5A5B59);
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.picked:
        return 'Picked';
    }
  }

  Color _resStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF72A843);
      case 'canceled':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFFFFC107);
    }
  }

  String _resStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'canceled':
        return 'Canceled';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: const [
                  Icon(Icons.shopping_cart_outlined, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'Order History',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
         const SizedBox(height: 9),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    child: TabBar(
      controller: _tabController,
      indicator: BoxDecoration(
        color: const Color(0xFF72A843),
        borderRadius: BorderRadius.circular(30),
      ),
      indicatorSize: TabBarIndicatorSize.tab, 
      labelPadding: EdgeInsets.zero,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.black54,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Sold'),
        Tab(text: 'Bought'),
      ],
    ),
  ),
),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSoldList(),
                  _buildBoughtList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sold tab (merchant reservations) ─────────────────────────────
  Widget _buildSoldList() {
    final sold = _soldReservations;
    if (sold.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sold.length,
      itemBuilder: (context, index) => _buildSoldCard(sold[index]),
    );
  }

  Widget _buildSoldCard(ReservationRecord r) {
    final color = _resStatusColor(r.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFD0E2C0),
            child: Text(
              r.clientName.isNotEmpty ? r.clientName[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF72A843)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.clientName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Offer: ${r.offerTitle}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                Text(r.timeAgo,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _resStatusLabel(r.status),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bought tab (client orders) ────────────────────────────────────
  Widget _buildBoughtList() {
    final bought = _boughtOrders;
    if (bought.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: bought.length,
      itemBuilder: (context, index) => _buildBoughtCard(bought[index]),
    );
  }

  Widget _buildBoughtCard(OrderItem order) {
    final color = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: order.imagePath != null
                ? AppNetworkImage(url: order.imagePath!, width: 75, height: 75, fit: BoxFit.cover)
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('From: ${order.merchantName}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                Text('Pickup: ${order.pickupLocation}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                if (order.pickupTime != null)
                  Text('Time: ${order.pickupTime}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(order.price,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No orders yet',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 75,
    height: 75,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.image, color: Colors.grey),
  );
}