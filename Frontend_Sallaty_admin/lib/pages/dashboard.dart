import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

const kPrimary     = Color(0xFFA0CA09);
const kPrimaryDark = Color(0xFF395422);
const kCardBg      = Color(0xFFD0E2C0);
const kWhite       = Color(0xFFFFFFFF);
const kGrey        = Color(0xFFCCCCCC);
const kTextDark    = Color(0xFF000000);

const _baseUrl = 'http://localhost:8080';

class DashboardPage extends StatefulWidget {
  final String token;
  const DashboardPage({super.key, required this.token});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  bool _isLoading = true;
  bool _hasError  = false;

  int    totalUsers     = 0;
  int    totalMerchants = 0;
  int    totalOffers    = 0;
  int    totalOrders    = 0;
  double totalRevenue   = 0;
  double foodSaved      = 0;

  List<double> merchantRevenues = [];
  List<String> merchantNames    = [];
  List<double> monthlyRevenue   = [];
  double merchantPercent = 0;
  double clientPercent   = 0;

  Map<String, String> get _headers => {
    'Authorization'              : 'Bearer ${widget.token}',
    'Content-Type'               : 'application/json',
    'ngrok-skip-browser-warning' : 'true',
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/admin/dashboard'), headers: _headers),
        http.get(Uri.parse('$_baseUrl/api/admin/charts'),    headers: _headers),
      ]);

      final dashRes   = responses[0];
      final chartsRes = responses[1];

      if (dashRes.statusCode == 200 && chartsRes.statusCode == 200) {

        final dashData = jsonDecode(dashRes.body) as Map<String, dynamic>;
        final stats    = (dashData['stats'] as Map<String, dynamic>?) ?? {};

        final chartsData      = jsonDecode(chartsRes.body) as Map<String, dynamic>;
        final topMerchants    = (chartsData['topMerchants']     as List?) ?? [];
        final revenuePerMonth = (chartsData['revenuePerMonth']  as List?) ?? [];
        final userDist        = (chartsData['userDistribution'] as Map<String, dynamic>?) ?? {};

        if (!mounted) return;
        setState(() {
          totalUsers     = _toInt(stats['totalUsers']);
          totalMerchants = _toInt(stats['totalMerchants']);
          totalOffers    = _toInt(stats['totalOffers']);
          totalOrders    = _toInt(stats['totalOrders']);
          totalRevenue   = _toDouble(stats['totalRevenue']);
          foodSaved      = _toDouble(stats['foodSaved']);

          // ✅ FIX: backend retourne "businessName" pas "name"
          merchantRevenues = topMerchants
              .map<double>((m) => _toDouble((m as Map)['revenue']))
              .toList();
          merchantNames = topMerchants
              .map<String>((m) => ((m as Map)['businessName'] ?? '').toString())
              .toList();

          // ✅ FIX: backend retourne liste d'objets {month, year, revenue}
          monthlyRevenue = revenuePerMonth
              .map<double>((v) => _toDouble((v as Map)['revenue']))
              .toList();

          // ✅ FIX: backend retourne "marchandPercent" et "clientPercent"
          merchantPercent = _toDouble(userDist['marchandPercent']);
          clientPercent   = _toDouble(userDist['clientPercent']);

          _isLoading = false;
          _hasError  = false;
        });

      } else {
        _setError();
      }
    } catch (_) {
      _setError();
    }
  }

  int    _toInt(dynamic v)    => (v as num?)?.toInt()    ?? 0;
  double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  // ✅ FIX: interval ne peut jamais être 0
  double _safeInterval(double maxY) => maxY > 0 ? maxY / 4 : 25.0;

  void _setError() {
    if (!mounted) return;
    setState(() { _isLoading = false; _hasError = true; });
  }

  Future<void> _refresh() async {
    setState(() { _isLoading = true; _hasError = false; });
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Failed to load dashboard',
                style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildStatsGrid(),
            const SizedBox(height: 12),
            _buildWideCard('Total Revenue',
                '${totalRevenue.toStringAsFixed(0)} DA',
                Icons.attach_money_rounded),
            const SizedBox(height: 12),
            _buildWideCard('Food Saved',
                '${foodSaved.toStringAsFixed(0)} KG',
                Icons.eco_outlined),
            const SizedBox(height: 18),
            _buildChartCard('Top Merchants',     _buildBarChart()),
            const SizedBox(height: 16),
            _buildChartCard('Revenue per Month', _buildLineChart()),
            const SizedBox(height: 16),
            _buildChartCard('User Distribution', _buildPieChart()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('DashBoard',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryDark)),
            SizedBox(height: 2),
            Text('Welcome back, Admin',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        Image.asset('assets/logo.png', height: 50, fit: BoxFit.contain),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      _StatItem('Total Users',  totalUsers.toString(),     Icons.people_outline),
      _StatItem('Merchants',    totalMerchants.toString(), Icons.store_outlined),
      _StatItem('Total Offers', totalOffers.toString(),    Icons.local_offer_outlined),
      _StatItem('Total Orders', totalOrders.toString(),    Icons.shopping_cart_outlined),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: items.map(_buildStatCard).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: kCardBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(item.value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryDark)),
            ],
          ),
          Icon(item.icon, color: kPrimary, size: 26),
        ],
      ),
    );
  }

  Widget _buildWideCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
          color: kCardBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryDark)),
          ]),
          Icon(icon, color: kPrimary, size: 28),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: kPrimary)),
        const SizedBox(height: 14),
        chart,
      ]),
    );
  }

  Widget _buildBarChart() {
    if (merchantRevenues.isEmpty) return _noData();

    final maxRaw = merchantRevenues.reduce((a, b) => a > b ? a : b);
    // ✅ FIX: maxY et interval ne peuvent jamais être 0
    final maxY   = maxRaw > 0 ? (maxRaw * 1.3).ceilToDouble() : 100.0;
    final interval = _safeInterval(maxY);

    return SizedBox(
      height: 190,
      child: BarChart(BarChartData(
        maxY: maxY,
        barGroups: List.generate(
          merchantRevenues.length,
          (i) => BarChartGroupData(x: i, barRods: [
            BarChartRodData(
                toY: merchantRevenues[i],
                color: kPrimary,
                width: 28,
                borderRadius: BorderRadius.circular(4)),
          ]),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: interval, // ✅ jamais 0
          getDrawingHorizontalLine: (v) =>
              FlLine(color: kGrey.withOpacity(0.4), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= merchantNames.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(merchantNames[idx],
                      style: const TextStyle(fontSize: 8, color: Colors.grey),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: interval, // ✅ jamais 0
              getTitlesWidget: (v, _) => Text(_formatK(v),
                  style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ),
          ),
          topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      )),
    );
  }

  Widget _buildLineChart() {
    if (monthlyRevenue.isEmpty) return _noData();

    final maxRaw = monthlyRevenue.reduce((a, b) => a > b ? a : b);
    // ✅ FIX: maxY et interval ne peuvent jamais être 0
    final maxY     = maxRaw > 0 ? (maxRaw * 1.3).ceilToDouble() : 100.0;
    final interval = _safeInterval(maxY);

    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];

    return SizedBox(
      height: 190,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              monthlyRevenue.length,
              (i) => FlSpot(i.toDouble(), monthlyRevenue[i]),
            ),
            isCurved: true,
            color: const Color(0xFFA4CF4A),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, f, b, i) => FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFFA4CF4A),
                  strokeWidth: 1,
                  strokeColor: kWhite),
            ),
            belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFA4CF4A).withOpacity(0.08)),
          ),
        ],
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: interval, // ✅ jamais 0
          getDrawingHorizontalLine: (v) =>
              FlLine(color: kGrey.withOpacity(0.3), strokeWidth: 1),
          getDrawingVerticalLine: (v) =>
              FlLine(color: kGrey.withOpacity(0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                return Text(months[idx],
                    style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: interval, // ✅ jamais 0
              getTitlesWidget: (v, _) => Text(_formatK(v),
                  style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ),
          ),
          topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      )),
    );
  }

  Widget _buildPieChart() {
    final mPct = merchantPercent > 0 ? merchantPercent : 0.0;
    final cPct = clientPercent   > 0 ? clientPercent   : 0.0;
    if (mPct == 0 && cPct == 0) return _noData();

    return Row(children: [
      SizedBox(
        height: 150,
        width: 150,
        child: PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 0,
          sections: [
            PieChartSectionData(
                value: mPct,
                color: const Color(0xFFA4CF4A),
                title: '${mPct.toInt()}%',
                radius: 70,
                titleStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kWhite)),
            PieChartSectionData(
                value: cPct,
                color: const Color(0xFFD0E2C0),
                title: '${cPct.toInt()}%',
                radius: 70,
                titleStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ],
        )),
      ),
      const SizedBox(width: 24),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _legendDot(const Color(0xFFA4CF4A), 'Merchant  ${mPct.toInt()}%'),
        const SizedBox(height: 10),
        _legendDot(const Color(0xFFD0E2C0), 'Client  ${cPct.toInt()}%'),
      ]),
    ]);
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: kTextDark)),
    ]);
  }

  Widget _noData() => const SizedBox(
        height: 150,
        child: Center(
            child: Text('No data', style: TextStyle(color: Colors.grey))),
      );

  String _formatK(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toInt().toString();
  }
}

class _StatItem {
  final String   title;
  final String   value;
  final IconData icon;
  const _StatItem(this.title, this.value, this.icon);
}