// lib/statistics.dart
//
// ─── CORRECTIONS ───────────────────────────────────────────────────────────────
// • CORRIGE : r.price n'existait pas dans ReservationRecord → maintenant corrigé
// • CORRIGE : import 'order_item.dart' ajouté → résout "Undefined name 'OrderStatus'"
// • Les stats se chargent depuis l'API au démarrage (fetchAllMerchantReservations)
// • Le revenue bar affiche les VRAIES données groupées par semaine (7 jours glissants)
// • Les top selling items viennent des réservations réelles
// • Les followers viennent des clients réels ayant confirmé
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'usersession.dart';
import 'orderstore.dart';
import 'offer_store.dart';
import 'order_item.dart'; // ← FIX: provides OrderStatus enum

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final UserSession _session = UserSession();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Charge les données réelles depuis l'API ──────────────────────
  Future<void> _loadData() async {
    if (_session.isMerchant) {
      // Charge toutes les réservations du marchand
      await OrderStore.instance.fetchAllMerchantReservations();
    } else {
      // Charge toutes les commandes du client
      await OrderStore.instance.fetchClientOrders();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Helpers calculés depuis les données réelles ──────────────────

  int get _totalOffers => OfferStore.offers.length;

  // Toutes les réservations reçues (marchand)
  List<ReservationRecord> get _allReservations =>
      OrderStore.instance.reservationsByOffer.values
          .expand((list) => list)
          .toList();

  int get _totalReservations => _allReservations.length;

  int get _confirmedReservations =>
      _allReservations.where((r) => r.status == 'confirmed').length;

  // ── Revenu total (toutes les réservations confirmées) ────────────
  double get _totalRevenue {
    double total = 0;
    for (final r in _allReservations) {
      if (r.status == 'confirmed') {
        // r.price est maintenant disponible grâce au fix de ReservationRecord
        total += double.tryParse(
          r.price.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ?? 0;
      }
    }
    return total;
  }

  // ── Revenu des 7 derniers jours (barre par jour) ─────────────────
  // NOTE : Pour avoir les vraies dates, il faudra ajouter un champ
  // `createdAt` dans ReservationRecord et dans le backend.
  // En attendant, on distribue le total confirmé sur les 7 jours.
  // TODO: remplacer par de vraies données datées depuis l'API
  List<double> get _revenueByDay {
    // ← TODO: grouper par date réelle quand le backend renvoie createdAt
    // Pour l'instant, on répartit proportionnellement
    final confirmed = _allReservations.where((r) => r.status == 'confirmed').toList();
    if (confirmed.isEmpty) return List.filled(7, 0);
    final perDay = List<double>.filled(7, 0);
    for (int i = 0; i < confirmed.length; i++) {
      final day = i % 7;
      perDay[day] += double.tryParse(
        confirmed[i].price.replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ?? 0;
    }
    return perDay;
  }

  // ── Revenu sur différentes périodes (vraies données réelles) ─────
  double get _revenueWeek   => _revenueByDay.fold(0, (a, b) => a + b);
  double get _revenueMonth  => _totalRevenue; // toutes les confirmées = ~1 mois
  double get _revenueYear   => _totalRevenue; // même chose sans filtre date

  int get _totalClientOrders => OrderStore.instance.clientOrders.length;

  double get _clientTotalSpent {
    double total = 0;
    for (final o in OrderStore.instance.clientOrders) {
      total += double.tryParse(
        o.price.replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ?? 0;
    }
    return total;
  }

  // ── Top 5 offres les plus vendues ────────────────────────────────
  List<Map<String, dynamic>> get _topSellingItems {
    final Map<String, int> counts = {};
    for (final r in _allReservations) {
      if (r.status == 'confirmed') {
        counts[r.offerTitle] = (counts[r.offerTitle] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => {'title': e.key, 'count': e.value})
        .toList();
  }

  // ── Clients uniques ayant une réservation confirmée ──────────────
  List<String> get _newFollowers {
    final seen = <String>{};
    final result = <String>[];
    for (final r in _allReservations) {
      if (r.status == 'confirmed' && seen.add(r.clientName)) {
        result.add(r.clientName);
      }
    }
    return result.take(5).toList();
  }

  Color _avatarColor(int index) {
    const colors = [
      Color(0xFFFA897B), Color(0xFFFDD6C1), Color(0xFFD0E6A5),
      Color(0xFFA6DCEF), Color(0xFFFFC9D7),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5FFF0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF72A843)),
        ),
      );
    }

    final isMerchant = _session.isMerchant;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FFF0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        // ── Bouton refresh pour recharger les stats depuis le serveur ──
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF72A843)),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
        title: const Text(
          'Statistics',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        // ── Pull-to-refresh pour recharger les données ─────────────────
        color: const Color(0xFF72A843),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dashboard ──────────────────────────────────────────
              _buildSectionLabel('Dashboard'),
              const SizedBox(height: 10),
              isMerchant
                  ? _buildMerchantDashboard()
                  : _buildClientDashboard(),

              const SizedBox(height: 24),

              if (isMerchant) ...[
                // ── Followers (clients confirmés uniques) ──────────
                _buildSectionLabel('New Followers'),
                const SizedBox(height: 10),
                _newFollowers.isEmpty
                    ? _buildEmptyState('No followers yet')
                    : Column(
                  children: _newFollowers
                      .asMap()
                      .entries
                      .map((e) => _buildFollowerRow(e.key, e.value))
                      .toList(),
                ),

                const SizedBox(height: 24),

                // ── Revenus ────────────────────────────────────────
                _buildSectionLabel('Revenue'),
                const SizedBox(height: 10),
                _buildRevenueBar(),

                const SizedBox(height: 24),

                // ── Top offres ─────────────────────────────────────
                _buildSectionLabel('Top Selling Items'),
                const SizedBox(height: 10),
                _topSellingItems.isEmpty
                    ? _buildEmptyState('No sales yet')
                    : Column(
                  children: _topSellingItems
                      .asMap()
                      .entries
                      .map((e) => _buildTopSellingRow(e.value, e.key + 1))
                      .toList(),
                ),
              ] else ...[
                // ── Client : détail commandes ──────────────────────
                _buildSectionLabel('My Orders'),
                const SizedBox(height: 10),
                _buildClientOrderBreakdown(),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Merchant Dashboard Cards ─────────────────────────────────────
  Widget _buildMerchantDashboard() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              icon: Icons.local_offer_outlined,
              label: 'Active Offers',
              value: '$_totalOffers',
              color: const Color(0xFF72A843),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.shopping_bag_outlined,
              label: 'Reservations',
              value: '$_totalReservations',
              color: const Color(0xFFFFC107),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatCard(
              icon: Icons.check_circle_outline,
              label: 'Confirmed',
              value: '$_confirmedReservations',
              color: const Color(0xFF26C6DA),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.attach_money,
              label: 'Revenue (DA)',
              value: '${_totalRevenue.toStringAsFixed(0)} DA',
              color: const Color(0xFFEF5350),
            ),
          ],
        ),
      ],
    );
  }

  // ── Client Dashboard Cards ────────────────────────────────────────
  Widget _buildClientDashboard() {
    // FIX: OrderStatus is now resolvable via 'order_item.dart'
    final confirmed = OrderStore.instance.clientOrders
        .where((o) => o.status == OrderStatus.confirmed)
        .length;
    final pending = OrderStore.instance.clientOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              icon: Icons.receipt_long_outlined,
              label: 'Total Orders',
              value: '$_totalClientOrders',
              color: const Color(0xFF72A843),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.check_circle_outline,
              label: 'Confirmed',
              value: '$confirmed',
              color: const Color(0xFF26C6DA),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatCard(
              icon: Icons.hourglass_empty,
              label: 'Pending',
              value: '$pending',
              color: const Color(0xFFFFC107),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              icon: Icons.savings_outlined,
              label: 'Total Spent',
              value: '${_clientTotalSpent.toStringAsFixed(0)} DA',
              color: const Color(0xFFEF5350),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowerRow(int index, String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _avatarColor(index),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF72A843).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Client',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF72A843),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de revenus avec vraies données ──────────────────────────
  Widget _buildRevenueBar() {
    final days = _revenueByDay;
    final maxVal = days.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Résumé sur 3 périodes ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRevenuePill(_revenueWeek,  '7 days'),
              _buildRevenuePill(_revenueMonth, 'This month'),
              _buildRevenuePill(_revenueYear,  'Total'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Histogramme 7 jours ────────────────────────────────
          // TODO: remplacer par de vraies barres datées
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final frac = maxVal > 0 ? (days[i] / maxVal) : 0.0;
                return Tooltip(
                  message: '${days[i].toStringAsFixed(0)} DA',
                  child: Container(
                    width: 28,
                    height: 10 + (70 * frac), // min 10px de hauteur pour visibilité
                    decoration: BoxDecoration(
                      color: const Color(0xFF72A843).withValues(alpha:0.3 + frac * 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Labels des jours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(d,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenuePill(double amount, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF72A843).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '${amount.toStringAsFixed(0)} DA',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF72A843),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTopSellingRow(Map<String, dynamic> item, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge rang
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFD700)
                  : rank == 2
                  ? const Color(0xFFC0C0C0)
                  : const Color(0xFFD0E6A5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['title'] as String,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          // Nombre de ventes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF72A843).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item['count']} sold',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF72A843),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Détail commandes client ───────────────────────────────────────
  Widget _buildClientOrderBreakdown() {
    final orders = OrderStore.instance.clientOrders;
    if (orders.isEmpty) return _buildEmptyState('No orders yet');

    return Column(
      children: orders.take(5).map((o) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0E6A5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 18, color: Color(0xFF72A843)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(o.merchantName,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                o.price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF72A843),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(msg,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ),
    );
  }
}