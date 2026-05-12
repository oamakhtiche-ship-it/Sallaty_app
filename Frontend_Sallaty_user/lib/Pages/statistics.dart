import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'apiservice.dart';
import 'usersession.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  bool get _isMerchant => UserSession().isMerchant;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final endpoint = _isMerchant
          ? '/api/statistics/marchand'
          : '/api/statistics/client';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserSession().token ?? ''}',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  
  // DEBUG - affiche les URLs des images dans la console
  if (_isMerchant) {
    final topItems = decoded['topSellingItems'] as List? ?? [];
    final followers = decoded['newFollowers'] as List? ?? [];
    for (var item in topItems) {
      print('📸 topItem photoUrl: ${item['photoUrl']}');
    }
    for (var f in followers) {
      print('👤 follower photoUrl: ${f['photoUrl']}');
    }
  } else {
    final orders = decoded['recentOrders'] as List? ?? [];
    for (var o in orders) {
      print('🛒 order photoUrl: ${o['photoUrl']}');
    }
  }

  setState(() {
    _data = decoded;
    _loading = false;
  });
}
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Statistics',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
            onPressed: _load,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _error != null
              ? _buildError()
              : _isMerchant
                  ? _buildMerchantView()
                  : _buildClientView(),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ERROR
  // ════════════════════════════════════════════════════════════
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  MERCHANT VIEW
  // ════════════════════════════════════════════════════════════
  Widget _buildMerchantView() {
    final int totalRevenue   = (_data['totalRevenue']   as num? ?? 0).toInt();
    final int totalLikes     = (_data['totalLikes']     as num? ?? 0).toInt();
    final int totalFollowers = (_data['totalFollowers'] as num? ?? 0).toInt();
    final int totalOffers    = (_data['totalOffers']    as num? ?? 0).toInt();
    final int totalOrders    = (_data['totalOrders']    as num? ?? 0).toInt();
    final int revenueToday   = (_data['revenueToday']   as num? ?? 0).toInt();
    final int revenueWeek    = (_data['revenueWeek']    as num? ?? 0).toInt();
    final int revenueMonth   = (_data['revenueMonth']   as num? ?? 0).toInt();
    final List chart         = (_data['revenueChart']   as List?) ?? List.filled(30, 0);
    final List topItems      = (_data['topSellingItems'] as List?) ?? [];
    final List newFollowers  = (_data['newFollowers']   as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Dashboard'),
          const SizedBox(height: 8),

          Row(children: [
            _statCard('$totalRevenue DA', 'Total Revenue',
                Icons.attach_money, Colors.green),
            const SizedBox(width: 8),
            _statCard('$totalLikes', 'Total Likes',
                Icons.favorite, Colors.pink),
            const SizedBox(width: 8),
            _statCard('$totalFollowers', 'Followers',
                Icons.person, Colors.green),
          ]),
          const SizedBox(height: 8),

          Row(children: [
            _statCard('$totalOffers', 'Total Offers',
                Icons.label, Colors.green),
            const SizedBox(width: 8),
            _statCard('$totalOrders', 'Total Orders',
                Icons.receipt_long, Colors.green),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 20),

          _sectionTitle('New Followers'),
          const SizedBox(height: 8),
          newFollowers.isEmpty
              ? _emptyBox('No followers yet')
              : Column(
                  children: newFollowers
                      .map<Widget>((f) => _followerTile(f as Map))
                      .toList()),
          const SizedBox(height: 20),

          _revenueCard(revenueToday, revenueWeek, revenueMonth, chart),
          const SizedBox(height: 20),

          if (topItems.isNotEmpty) ...[
            _sectionTitle('Top Selling Items'),
            const SizedBox(height: 8),
            ...topItems.map<Widget>((item) => _topItemTile(item as Map)),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CLIENT VIEW
  // ════════════════════════════════════════════════════════════
  Widget _buildClientView() {
    final int totalOrders = (_data['totalOrders'] as num? ?? 0).toInt();
    final int confirmed   = (_data['confirmed']   as num? ?? 0).toInt();
    final int pending     = (_data['pending']     as num? ?? 0).toInt();
    final int cancelled   = (_data['cancelled']   as num? ?? 0).toInt();
    final int totalSpent  = (_data['totalSpent']  as num? ?? 0).toInt();
    final List chart      = (_data['spendChart']  as List?) ?? List.filled(30, 0);
    final List orders     = (_data['recentOrders'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('My Orders'),
          const SizedBox(height: 8),

          Row(children: [
            _statCard('$totalOrders', 'Total',
                Icons.receipt_long, Colors.green),
            const SizedBox(width: 8),
            _statCard('$confirmed', 'Confirmed',
                Icons.check_circle, Colors.green),
            const SizedBox(width: 8),
            _statCard('$pending', 'Pending',
                Icons.hourglass_empty, Colors.orange),
          ]),
          const SizedBox(height: 8),

          Row(children: [
            _statCard('$cancelled', 'Cancelled',
                Icons.cancel, Colors.red),
            const SizedBox(width: 8),
            _statCard('$totalSpent DA', 'Total Spent',
                Icons.wallet, Colors.green),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Spending this month',
                    style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 16),
                _chartSection(
                    chart.map((e) => (e as num).toDouble()).toList()),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Recent Orders'),
          const SizedBox(height: 8),
          orders.isEmpty
              ? _emptyBox('No orders yet')
              : Column(
                  children: orders
                      .map<Widget>((o) => _orderTile(o as Map))
                      .toList()),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ════════════════════════════════════════════════════════════

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _emptyBox(String msg) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black38)));

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text(label,
                style: const TextStyle(
                    color: Colors.black45, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _revenueCard(int today, int week, int month, List chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue',
              style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _revChip('$today DA', 'Today'),
              _revChip('$week DA', 'This week'),
              _revChip('$month DA', 'This month'),
            ],
          ),
          const SizedBox(height: 16),
          _chartSection(
              chart.map((e) => (e as num).toDouble()).toList()),
        ],
      ),
    );
  }

  Widget _revChip(String value, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ]));

     Widget _followerTile(Map f) {
  final fullUrl = _buildImageUrl(f['photoUrl']?.toString());
  final isValid = fullUrl.isNotEmpty &&
      Uri.tryParse(fullUrl)?.hasAuthority == true;

  return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          backgroundImage: isValid
              ? NetworkImage(fullUrl, headers: {'ngrok-skip-browser-warning': 'true'})
              : null,
          child: !isValid
              ? const Icon(Icons.person, color: Color(0xFF4CAF50))
              : null),
      title: Text(f['name']?.toString() ?? 'Client',
          style: const TextStyle(fontWeight: FontWeight.w500)));
}
  Widget _topItemTile(Map item) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _photoBox(item['photoUrl']?.toString(), Icons.image),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
            item['title']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item['count']} sold',
                style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ));

  Widget _orderTile(Map o) {
    final status = (o['status'] ?? '').toString().toUpperCase();
    final statusColor = status == 'CONFIRMED' || status == 'COMPLETED'
        ? Colors.green
        : status == 'CANCELLED'
            ? Colors.red
            : Colors.orange;

    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          _photoBox(o['photoUrl']?.toString(), Icons.shopping_bag),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(o['title']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('${o['price']} DA',
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 12)),
              ])),
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold))),
        ]));
  }

 // Helper pour construire l'URL complète
String _buildImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  
  // S'assure qu'il y a exactement un "/" entre baseUrl et le path
  final base = ApiConfig.baseUrl.endsWith('/')
      ? ApiConfig.baseUrl
      : '${ApiConfig.baseUrl}/';
  final path = url.startsWith('/') ? url.substring(1) : url;
  
  return '$base$path';
}

Widget _photoBox(String? url, IconData fallback) {
  final fullUrl = _buildImageUrl(url);
  final isValid = fullUrl.isNotEmpty &&
      Uri.tryParse(fullUrl)?.hasAuthority == true;

  if (isValid) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          headers: const {'ngrok-skip-browser-warning': 'true'},  
          errorBuilder: (context, error, stackTrace) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(fallback, color: const Color(0xFF4CAF50)),
          ),
        ));
  }
  return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(fallback, color: const Color(0xFF4CAF50)));
}

  // ════════════════════════════════════════════════════════════
  //  CHART
  // ════════════════════════════════════════════════════════════
  Widget _chartSection(List<double> data) {
    final maxVal =
        data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    final hasData = maxVal > 0;
    final monthName = DateFormat('MMMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(monthName,
            style: const TextStyle(color: Colors.black45, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: hasData
              ? CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _ChartPainter(data, maxVal))
              : const Center(
                  child: Text('No data yet',
                      style: TextStyle(color: Colors.black38))),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['1', '5', '10', '15', '20', '25', '30']
              .map((d) => Text(d,
                  style: const TextStyle(
                      color: Colors.black38, fontSize: 10)))
              .toList(),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CHART PAINTER
// ════════════════════════════════════════════════════════════
class _ChartPainter extends CustomPainter {
  final List<double> data;
  final double maxVal;
  const _ChartPainter(this.data, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxVal == 0) return;

    final linePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4CAF50).withOpacity(0.3),
          const Color(0xFF4CAF50).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final step = size.width / (data.length - 1);
    final path     = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath
      ..lineTo((data.length - 1) * step, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.data != data;
}