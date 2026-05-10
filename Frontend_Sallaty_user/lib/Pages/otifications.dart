import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usersession.dart';
import 'apiservice.dart';

// ─────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'BROADCAST',
      isRead: json['read'] ?? json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

// ─────────────────────────────────────────────
//  SERVICE
// ─────────────────────────────────────────────
class NotificationApiService {
  static String get _base => ApiConfig.baseUrl;

  static Map<String, String> get _headers {
    final token = UserSession().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Returns { "today": [...], "thisWeek": [...], "older": [...] }
  static Future<Map<String, List<NotificationModel>>> fetchAll() async {
    final res = await http
        .get(Uri.parse('$_base/api/notifications/my'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'today': _parseList(body['today']),
        'thisWeek': _parseList(body['thisWeek']),
        'older': _parseList(body['older']),
      };
    }
    throw Exception('Failed to load notifications');
  }

  static List<NotificationModel> _parseList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  static Future<int> fetchUnreadCount() async {
    final res = await http
        .get(Uri.parse('$_base/api/notifications/unread-count'),
            headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['count'] ?? 0;
    }
    return 0;
  }

  static Future<void> markAsRead(int id) async {
    await http.put(Uri.parse('$_base/api/notifications/read/$id'),
        headers: _headers);
  }

  static Future<void> markAllAsRead() async {
    await http.put(Uri.parse('$_base/api/notifications/read-all'),
        headers: _headers);
  }

  static Future<void> delete(int id) async {
    await http.delete(Uri.parse('$_base/api/notifications/$id'),
        headers: _headers);
  }

  static Future<void> deleteAll() async {
    await http.delete(Uri.parse('$_base/api/notifications/all'),
        headers: _headers);
  }
}

// ─────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  Map<String, List<NotificationModel>> _groups = {
    'today': [],
    'thisWeek': [],
    'older': [],
  };
  bool _loading = true;
  String? _error;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await NotificationApiService.fetchAll();
      if (mounted) {
        setState(() { _groups = data; _loading = false; });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  int get _totalUnread {
    int count = 0;
    for (final list in _groups.values) {
      count += list.where((n) => !n.isRead).length;
    }
    return count;
  }

  bool get _isEmpty =>
      _groups['today']!.isEmpty &&
      _groups['thisWeek']!.isEmpty &&
      _groups['older']!.isEmpty;

  Future<void> _markAsRead(NotificationModel n) async {
    if (n.isRead) return;
    _updateLocally(n.id, read: true);
    try {
      await NotificationApiService.markAsRead(n.id);
    } catch (_) {
      _updateLocally(n.id, read: false); // rollback
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final key in _groups.keys) {
        _groups[key] = _groups[key]!
            .map((n) => n.copyWith(isRead: true))
            .toList();
      }
    });
    try {
      await NotificationApiService.markAllAsRead();
    } catch (_) {
      _load(); // rollback
    }
  }

  Future<void> _delete(NotificationModel n) async {
    _removeLocally(n.id);
    try {
      await NotificationApiService.delete(n.id);
    } catch (_) {
      _load(); // rollback
    }
  }

  Future<void> _deleteAll() async {
    final confirm = await _showConfirmDialog();
    if (!confirm) return;
    setState(() {
      _groups = {'today': [], 'thisWeek': [], 'older': []};
    });
    try {
      await NotificationApiService.deleteAll();
    } catch (_) {
      _load();
    }
  }

  void _updateLocally(int id, {required bool read}) {
    setState(() {
      for (final key in _groups.keys) {
        _groups[key] = _groups[key]!.map((n) {
          return n.id == id ? n.copyWith(isRead: read) : n;
        }).toList();
      }
    });
  }

  void _removeLocally(int id) {
    setState(() {
      for (final key in _groups.keys) {
        _groups[key] = _groups[key]!.where((n) => n.id != id).toList();
      }
    });
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Clear All Notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: const Text(
                'Are you sure you want to delete all notifications?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('Delete All',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Icon per notification type ──────────────────────────────
  static _NotifStyle _styleForType(String type) {
    switch (type) {
      case 'ORDER_CONFIRMED':
      case 'ORDER_COMPLETED':
        return _NotifStyle(
            icon: Icons.check_circle_outline,
            color: const Color(0xFF72A843),
            bg: const Color(0xFFEDF7E4));
      case 'ORDER_CANCELLED':
      case 'ORDER_REJECTED':
        return _NotifStyle(
            icon: Icons.cancel_outlined,
            color: Colors.red,
            bg: const Color(0xFFFFEDED));
      case 'PAYMENT_SUCCESS':
      case 'PAYMENT_RECEIVED':
        return _NotifStyle(
            icon: Icons.payments_outlined,
            color: const Color(0xFF1A8E6E),
            bg: const Color(0xFFE3F7F3));
      case 'PAYMENT_FAILED':
        return _NotifStyle(
            icon: Icons.money_off,
            color: Colors.orange,
            bg: const Color(0xFFFFF4E5));
      case 'WARNING':
        return _NotifStyle(
            icon: Icons.warning_amber_outlined,
            color: Colors.orange,
            bg: const Color(0xFFFFF4E5));
      case 'MARCHAND_VERIFIED':
        return _NotifStyle(
            icon: Icons.verified_outlined,
            color: const Color(0xFF72A843),
            bg: const Color(0xFFEDF7E4));
      case 'NEW_OFFER_AVAILABLE':
      case 'NEW_DISCOUNT':
        return _NotifStyle(
            icon: Icons.local_offer_outlined,
            color: const Color(0xFF8B5E3C),
            bg: const Color(0xFFFFF3E6));
      case 'EXPIRING_SOON':
        return _NotifStyle(
            icon: Icons.timer_outlined,
            color: Colors.deepOrange,
            bg: const Color(0xFFFFF0EC));
      case 'WELCOME':
        return _NotifStyle(
            icon: Icons.waving_hand_outlined,
            color: const Color(0xFF72A843),
            bg: const Color(0xFFEDF7E4));
      case 'NEW_FAVORITE':
        return _NotifStyle(
            icon: Icons.favorite_outline,
            color: Colors.pink,
            bg: const Color(0xFFFFEEF2));
      case 'NEW_SUBSCRIBER':
        return _NotifStyle(
            icon: Icons.person_add_outlined,
            color: const Color(0xFF1A6E8E),
            bg: const Color(0xFFE3F2FA));
      case 'BROADCAST':
      default:
        return _NotifStyle(
            icon: Icons.campaign_outlined,
            color: const Color(0xFF72A843),
            bg: const Color(0xFFEDF7E4));
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A1A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            if (_totalUnread > 0)
              Text('$_totalUnread unread',
                  style: const TextStyle(
                      color: Color(0xFF72A843),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          if (!_loading && !_isEmpty) ...[
            if (_totalUnread > 0)
              TextButton(
                onPressed: _markAllAsRead,
                child: const Text('Read all',
                    style: TextStyle(
                        color: Color(0xFF72A843),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.redAccent, size: 22),
              tooltip: 'Clear all',
              onPressed: _deleteAll,
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _isEmpty
                  ? _buildEmpty()
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: RefreshIndicator(
                        color: const Color(0xFF72A843),
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          children: [
                            _buildGroup('Today', _groups['today']!),
                            _buildGroup('This Week', _groups['thisWeek']!),
                            _buildGroup('Older', _groups['older']!),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildGroup(String label, List<NotificationModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF888888),
                      letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                  child: Divider(color: Colors.grey.shade200, thickness: 1)),
            ],
          ),
        ),
        ...items.map((n) => _buildCard(n)),
      ],
    );
  }

  Widget _buildCard(NotificationModel n) {
    final style = _styleForType(n.type);
    return Dismissible(
      key: Key('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _delete(n),
      child: GestureDetector(
        onTap: () => _markAsRead(n),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : const Color(0xFFF0FAE8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.isRead
                  ? Colors.grey.shade100
                  : const Color(0xFF72A843).withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: n.isRead ? 0.03 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ───────────────────────────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              const SizedBox(width: 12),
              // ── Content ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n.title,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: const Color(0xFF1A1A1A))),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF72A843),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(n.message,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(_timeAgo(n.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Skeleton loading ──────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (_, i) => _SkeletonCard(delay: i * 80),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Could not load notifications',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF72A843),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF72A843).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_outlined,
                size: 38, color: Color(0xFF72A843)),
          ),
          const SizedBox(height: 16),
          const Text('No notifications yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text("You're all caught up!",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPER CLASSES
// ─────────────────────────────────────────────
class _NotifStyle {
  final IconData icon;
  final Color color;
  final Color bg;
  const _NotifStyle(
      {required this.icon, required this.color, required this.bg});
}

class _SkeletonCard extends StatefulWidget {
  final int delay;
  const _SkeletonCard({required this.delay});
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + (_anim.value * 0.3);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200
                            .withValues(alpha: opacity * 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  BADGE WIDGET (use on bell icon in HomePage)
// ─────────────────────────────────────────────
class NotificationBadge extends StatefulWidget {
  final VoidCallback onTap;
  const NotificationBadge({super.key, required this.onTap});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _fetchCount();
  }

  Future<void> _fetchCount() async {
    try {
      final count = await NotificationApiService.fetchUnreadCount();
      if (mounted) setState(() => _count = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Color(0xFF8DC63F), size: 26),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsPage()),
            );
            // Refresh count when returning from NotificationsPage
            _fetchCount();
          },
        ),
        if (_count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints:
                    const BoxConstraints(minWidth: 17, minHeight: 17),
                child: Text(
                  _count > 99 ? '99+' : '$_count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}