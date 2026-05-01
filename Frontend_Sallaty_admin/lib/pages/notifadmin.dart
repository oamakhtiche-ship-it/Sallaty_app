import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── Colors ───────────────────────────────────────────────────────────────────
const kPrimary     = Color(0xFF72A843);
const kPrimaryDark = Color(0xFF395422);
const kCardBg      = Color(0xFFE8F5C8);
const kWhite       = Color(0xFFFFFFFF);
const _kBaseUrl    = 'http://localhost:8080';

// ─── API ──────────────────────────────────────────────────────────────────────

class _NotifApi {
  /// POST /api/notifications/broadcast
  /// recipients: ALL | CLIENTS | MERCHANTS
  static Future<void> broadcast({
    required String token,
    required String title,
    required String message,
    required String recipients, // 'ALL' | 'CLIENTS' | 'MERCHANTS'
  }) async {
    final res = await http.post(
      Uri.parse('$_kBaseUrl/api/notifications/broadcast'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type':  'application/x-www-form-urlencoded',
      },
      body: {
        'title':      title,
        'message':    message,
        'recipients': recipients,
      },
    );
    if (res.statusCode != 200) {
      _throwError(res, 'broadcast');
    }
  }

  /// POST /api/notifications/support/{userId}
  static Future<void> support({
    required String token,
    required int    userId,
    required String title,
    required String message,
  }) async {
    final res = await http.post(
      Uri.parse('$_kBaseUrl/api/notifications/support/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type':  'application/x-www-form-urlencoded',
      },
      body: {'title': title, 'message': message},
    );
    if (res.statusCode != 200) {
      _throwError(res, 'support');
    }
  }

  /// PUT /api/users/block/{userId}
  static Future<void> blockUser({
    required String token,
    required int    userId,
  }) async {
    final res = await http.put(
      Uri.parse('$_kBaseUrl/api/users/block/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      _throwError(res, 'block');
    }
  }

  /// GET /api/admin/users?filter=  — search users for autocomplete
  static Future<List<Map<String, dynamic>>> searchUsers({
    required String token,
    required String query,
  }) async {
    final uri = Uri.parse(
        '$_kBaseUrl/api/admin/users?filter=${Uri.encodeComponent(query)}');
    final res = await http.get(uri,
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      // Sometimes wrapped: { users: [...] }
      if (data is Map && data['users'] is List) {
        return List<Map<String, dynamic>>.from(data['users']);
      }
    }
    return [];
  }

  static void _throwError(http.Response res, String ctx) {
    try {
      final err = jsonDecode(res.body);
      throw Exception(err['message'] ?? 'Erreur $ctx ${res.statusCode}');
    } catch (_) {
      throw Exception('Erreur $ctx ${res.statusCode}');
    }
  }
}

// ─── Selected user model ──────────────────────────────────────────────────────

class _SelectedUser {
  final int    id;
  final String name;
  final String role;
  const _SelectedUser({required this.id, required this.name, required this.role});
}

// ─────────────────────────────────────────
//  NOTIFICATIONS PAGE
// ─────────────────────────────────────────

class NotificationsPage extends StatefulWidget {
  final String token;
  const NotificationsPage({super.key, required this.token});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // ── Broadcast state ──
  final _broadcastTitleCtrl   = TextEditingController();
  final _broadcastMessageCtrl = TextEditingController();
  String _selectedRecipient   = 'All users';
  bool   _broadcastLoading    = false;

  // ── Support state ──
  final _supportTitleCtrl   = TextEditingController();
  final _supportMessageCtrl = TextEditingController();
  final _supportSearchCtrl  = TextEditingController();
  _SelectedUser? _selectedSupportUser;
  List<Map<String, dynamic>> _supportResults = [];
  bool _supportLoading = false;

  // ── Warning state ──
  final _warnTitleCtrl   = TextEditingController();
  final _warnMessageCtrl = TextEditingController();
  final _warnSearchCtrl  = TextEditingController();
  _SelectedUser? _selectedWarnUser;
  List<Map<String, dynamic>> _warnResults = [];
  bool _warnLoading = false;

  @override
  void dispose() {
    _broadcastTitleCtrl.dispose();
    _broadcastMessageCtrl.dispose();
    _supportTitleCtrl.dispose();
    _supportMessageCtrl.dispose();
    _supportSearchCtrl.dispose();
    _warnTitleCtrl.dispose();
    _warnMessageCtrl.dispose();
    _warnSearchCtrl.dispose();
    super.dispose();
  }

  // ── Recipient string → backend enum ──
  String _recipientEnum(String label) {
    switch (label) {
      case 'Clients':   return 'CLIENTS';
      case 'Merchants': return 'MERCHANTS';
      default:          return 'ALL';
    }
  }

  // ── User search ──
  Future<void> _searchUsers(String q, bool isSupport) async {
    if (q.trim().isEmpty) {
      setState(() {
        if (isSupport) _supportResults = [];
        else            _warnResults    = [];
      });
      return;
    }
    try {
      final results = await _NotifApi.searchUsers(
          token: widget.token, query: q.trim());
      if (!mounted) return;
      setState(() {
        if (isSupport) _supportResults = results;
        else            _warnResults    = results;
      });
    } catch (_) {}
  }

  _SelectedUser _mapUser(Map<String, dynamic> u) {
    final id   = u['id'] as int? ?? 0;
    final name = '${u['firstName'] ?? u['name'] ?? ''} ${u['lastName'] ?? u['surname'] ?? ''}'.trim();
    final role = u['role']?.toString() ?? u['accountType']?.toString() ?? 'User';
    return _SelectedUser(id: id, name: name.isEmpty ? 'User #$id' : name, role: role);
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _sendBroadcast() async {
    final title   = _broadcastTitleCtrl.text.trim();
    final message = _broadcastMessageCtrl.text.trim();
    if (title.isEmpty || message.isEmpty) {
      _showSnack('Please fill in the title and message');
      return;
    }
    setState(() => _broadcastLoading = true);
    try {
      await _NotifApi.broadcast(
        token:      widget.token,
        title:      title,
        message:    message,
        recipients: _recipientEnum(_selectedRecipient),
      );
      _broadcastTitleCtrl.clear();
      _broadcastMessageCtrl.clear();
      _showSnack('Broadcast envoyé à $_selectedRecipient ✅');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _broadcastLoading = false);
    }
  }

  Future<void> _sendSupport() async {
    final user    = _selectedSupportUser;
    final title   = _supportTitleCtrl.text.trim();
    final message = _supportMessageCtrl.text.trim();
    if (user == null) { _showSnack('Please select a user'); return; }
    if (title.isEmpty)   { _showSnack('Please fill in a title'); return; }
    if (message.isEmpty) { _showSnack('Please write a message'); return; }

    setState(() => _supportLoading = true);
    try {
      await _NotifApi.support(
        token:   widget.token,
        userId:  user.id,
        title:   title,
        message: message,
      );
      _supportTitleCtrl.clear();
      _supportMessageCtrl.clear();
      _supportSearchCtrl.clear();
      setState(() { _selectedSupportUser = null; _supportResults = []; });
      _showSnack('Message support envoyé à ${user.name} ✅');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _supportLoading = false);
    }
  }

  Future<void> _sendWarning() async {
    final user    = _selectedWarnUser;
    final title   = _warnTitleCtrl.text.trim();
    final message = _warnMessageCtrl.text.trim();
    if (user == null)    { _showSnack('Please select a user'); return; }
    if (title.isEmpty)   { _showSnack('Please fill in a title'); return; }
    if (message.isEmpty) { _showSnack('Please write a warning message'); return; }

    setState(() => _warnLoading = true);
    try {
      await _NotifApi.support(
        token:   widget.token,
        userId:  user.id,
        title:   title,
        message: message,
      );
      _warnTitleCtrl.clear();
      _warnMessageCtrl.clear();
      _warnSearchCtrl.clear();
      setState(() { _selectedWarnUser = null; _warnResults = []; });
      _showSnack('Avertissement envoyé à ${user.name} ✅');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _warnLoading = false);
    }
  }

  Future<void> _blockUser(_SelectedUser user) async {
    setState(() => _warnLoading = true);
    try {
      await _NotifApi.blockUser(token: widget.token, userId: user.id);
      _showSnack('${user.name} a été bloqué ✅');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _warnLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),

              // ── Section 1: Broadcast ──
              _buildSectionCard(
                label: 'BROADCAST',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Title'),
                    _inputField(_broadcastTitleCtrl, 'Notification title ......'),
                    const SizedBox(height: 10),
                    _fieldLabel('Message'),
                    _textArea(_broadcastMessageCtrl, 'Write a message here ......'),
                    const SizedBox(height: 12),
                    _fieldLabel('Recipients'),
                    const SizedBox(height: 8),
                    _buildRecipientRow(),
                    const SizedBox(height: 14),
                    _broadcastLoading
                        ? _loadingBtn()
                        : _sendButton(onTap: _sendBroadcast),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 2: Support – Single user ──
              _buildSectionCard(
                label: 'SUPPORT - Single user',
                labelColor: const Color(0xFFA4CF4A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Search user'),
                    _searchUserField(
                      controller:   _supportSearchCtrl,
                      results:      _supportResults,
                      selectedUser: _selectedSupportUser,
                      onSearch:     (q) => _searchUsers(q, true),
                      onSelected:   (u) => setState(() {
                        _selectedSupportUser = u;
                        _supportResults      = [];
                        _supportSearchCtrl.clear();
                      }),
                      onClear: () => setState(() {
                        _selectedSupportUser = null;
                        _supportResults      = [];
                      }),
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel('Title'),
                    _inputField(_supportTitleCtrl, 'Notification title ......'),
                    const SizedBox(height: 10),
                    _fieldLabel('Message'),
                    _textArea(_supportMessageCtrl, 'Write a message here ......'),
                    const SizedBox(height: 14),
                    _supportLoading
                        ? _loadingBtn()
                        : _sendButton(onTap: _sendSupport),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 3: Warning / Block ──
              _buildSectionCard(
                label: 'Warning a user',
                labelColor: const Color(0xFFE67E22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Search user'),
                    _searchUserField(
                      controller:   _warnSearchCtrl,
                      results:      _warnResults,
                      selectedUser: _selectedWarnUser,
                      onSearch:     (q) => _searchUsers(q, false),
                      onSelected:   (u) => setState(() {
                        _selectedWarnUser = u;
                        _warnResults      = [];
                        _warnSearchCtrl.clear();
                      }),
                      onClear: () => setState(() {
                        _selectedWarnUser = null;
                        _warnResults      = [];
                      }),
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel('Title'),
                    _inputField(_warnTitleCtrl, 'Warning title ......'),
                    const SizedBox(height: 10),
                    _fieldLabel('Message'),
                    _textArea(
                      _warnMessageCtrl,
                      'Your account will be blocked due to violation',
                    ),
                    const SizedBox(height: 14),
                    _warnLoading
                        ? _loadingBtn()
                        : Row(
                            children: [
                              Expanded(
                                child: _outlineButton(
                                  label:     'Send warning',
                                  color:     const Color(0xFFFFF3CD),
                                  textColor: const Color(0xFF856404),
                                  onTap:     _sendWarning,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _outlineButton(
                                  label:     'Block directly',
                                  color:     const Color(0xFFFFD6D6),
                                  textColor: Colors.red,
                                  onTap: () {
                                    final user = _selectedWarnUser;
                                    if (user == null) {
                                      _showSnack('Please select a user');
                                      return;
                                    }
                                    _confirmBlock(user);
                                  },
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Card ──────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String label,
    required Widget child,
    Color labelColor = kPrimary,
  }) {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: labelColor)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── Search + Selected User Field ──────────────────────────────────────────
  Widget _searchUserField({
    required TextEditingController         controller,
    required List<Map<String, dynamic>>    results,
    required _SelectedUser?                selectedUser,
    required void Function(String)         onSearch,
    required void Function(_SelectedUser)  onSelected,
    required VoidCallback                  onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            onChanged:  onSearch,
            decoration: const InputDecoration(
              hintText: 'Type user name ......',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        // Dropdown results
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: kWhite,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: results.map((u) {
                final mapped = _mapUser(u);
                return InkWell(
                  onTap: () => onSelected(mapped),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: kPrimary,
                          child: Text(
                            mapped.name.isNotEmpty ? mapped.name[0] : '?',
                            style: const TextStyle(
                                color: kWhite,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(mapped.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Text(mapped.role,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Selected user chip
        if (selectedUser != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kPrimary,
                  child: Text(
                    selectedUser.name.isNotEmpty ? selectedUser.name[0] : '?',
                    style: const TextStyle(
                        color: kWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedUser.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(selectedUser.role,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Recipient Radio Row ───────────────────────────────────────────────────
  Widget _buildRecipientRow() {
    final options = ['All users', 'Clients', 'Merchants'];
    return Row(
      children: options.map((o) {
        final selected = _selectedRecipient == o;
        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => setState(() => _selectedRecipient = o),
            child: Row(
              children: [
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? kPrimary : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: kPrimary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 5),
                Text(o,
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
  );

  Widget _inputField(TextEditingController ctrl, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _textArea(TextEditingController ctrl, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _sendButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF72A843), Color(0xFFA0CA09)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF72A843).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('Send',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: kWhite)),
      ),
    );
  }

  Widget _loadingBtn() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(
            color: kWhite, strokeWidth: 2),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
      ),
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : kPrimaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmBlock(_SelectedUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Block User',
            style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark)),
        content: Text(
          'Are you sure you want to block ${user.name}?',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _blockUser(user);
            },
            child: const Text('Block',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}