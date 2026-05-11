import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'conversation.dart';

const String kBaseUrl = 'https://headstand-rosy-chlorine.ngrok-free.dev';
const String kApiUrl  = '$kBaseUrl/api';


class ConversationSummary {
  final String conversationId;
  final int    otherId;
  final String otherUserName;
  String       lastMessage;
  DateTime     lastMessageTime;
  int          unreadCount;

  ConversationSummary({
    required this.conversationId,
    required this.otherId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> j) {
    return ConversationSummary(
      conversationId:  j['conversationId']?.toString() ?? '',
      otherId:         (j['otherId'] as num?)?.toInt() ?? 0,
      otherUserName:   j['otherUserName']?.toString()  ?? 'Utilisateur',
      lastMessage:     j['lastMessage']?.toString()    ?? '',
      lastMessageTime: j['lastMessageTime'] != null
          ? DateTime.tryParse(j['lastMessageTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}


class Merchant {
  final int    id;
  final String name;
  final String shopName;
  final String wilaya;
  final String category;
  final String avatarUrl;
  final bool   isVerified;

  Merchant({
    required this.id,
    required this.name,
    required this.shopName,
    required this.wilaya,
    this.category   = '',
    this.avatarUrl  = '',
    this.isVerified = false,
  });

  factory Merchant.fromJson(Map<String, dynamic> j) {
    // ── Structure imbriquée { marchand: { user: {...} } } ──
    final marchand = j['marchand'] as Map<String, dynamic>?;
    if (marchand != null) {
      final user = marchand['user'] as Map<String, dynamic>?;

      final firstName = user?['firstName']?.toString() ?? '';
      final surname   = user?['surname']?.toString()   ?? '';
      final fullName  = marchand['fullName']?.toString() ?? '';

      String resolvedName = fullName.isNotEmpty
          ? fullName
          : '$firstName $surname'.trim();

      String avatarRaw = marchand['avatarUrl']?.toString()
          ?? user?['photoUrl']?.toString()
          ?? '';
      if (avatarRaw.isNotEmpty && !avatarRaw.startsWith('http')) {
        avatarRaw = '$kBaseUrl/$avatarRaw';
      }

      return Merchant(
        id: (marchand['userId'] as num?)?.toInt()
            ?? (user?['id'] as num?)?.toInt()
            ?? 0,
        name:       resolvedName,
        shopName:   marchand['shopName']?.toString()  ?? '',
        wilaya:     marchand['wilaya']?.toString()    ?? '',
        category:   marchand['category']?.toString()  ?? '',
        avatarUrl:  avatarRaw,
        isVerified: marchand['isVerified'] as bool?   ?? false,
      );
    }

    // ── Structure plate ──
    final firstName = j['firstName']?.toString() ?? '';
    final surname   = j['surname']?.toString()   ?? '';
    final fullName  = j['fullName']?.toString()  ?? '';

    String resolvedName = fullName.isNotEmpty
        ? fullName
        : '$firstName $surname'.trim();

    String avatarRaw = j['avatarUrl']?.toString()
        ?? j['photoUrl']?.toString()
        ?? '';
    if (avatarRaw.isNotEmpty && !avatarRaw.startsWith('http')) {
      avatarRaw = '$kBaseUrl/$avatarRaw';
    }

    return Merchant(
      id:         (j['id'] as num?)?.toInt()    ?? 0,
      name:       resolvedName,
      shopName:   j['shopName']?.toString()     ?? '',
      wilaya:     j['wilaya']?.toString()       ?? '',
      category:   j['category']?.toString()     ?? '',
      avatarUrl:  avatarRaw,
      isVerified: j['isVerified'] as bool?      ?? false,
    );
  }

  /// Display name : shopName si disponible, sinon name
  String get displayName =>
      shopName.isNotEmpty ? shopName : (name.isNotEmpty ? name : 'Marchand');
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE — ChatApiService
// ─────────────────────────────────────────────────────────────────────────────
class ChatApiService {
  late Dio _dio;

  ChatApiService([String? token]) {
    _dio = Dio(BaseOptions(
      baseUrl: kApiUrl,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // GET /api/messages/conversations
  Future<List<ConversationSummary>> getConversations() async {
    final res  = await _dio.get('/messages/conversations');
    final list = res.data as List<dynamic>;
    return list
        .map((j) => ConversationSummary.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Search merchants — gère les deux formats de réponse ──
  // Format 1 : List directe  [ { marchand: {...} }, ... ]
  // Format 2 : Map           { "offres": [...], "merchants": [...] }
  Future<List<Merchant>> searchMerchants(String query) async {
    final res = await _dio.get('/search', queryParameters: {'q': query});
    debugPrint('[CHAT SEARCH] raw data: ${res.data}');

    List<dynamic> rawList = [];

    if (res.data is List) {
      rawList = res.data as List<dynamic>;
    } else if (res.data is Map) {
      final map = res.data as Map<String, dynamic>;
      // Essaie plusieurs clés possibles
      rawList = (map['merchants']  as List<dynamic>?) ??
                (map['users']      as List<dynamic>?) ??
                (map['results']    as List<dynamic>?) ??
                (map['marchands']  as List<dynamic>?) ??
                [];
    }

    debugPrint('[CHAT SEARCH] rawList.length: ${rawList.length}');

    final seen      = <int>{};
    final merchants = <Merchant>[];

    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;
      debugPrint('[CHAT SEARCH] item: $item');
      final m = Merchant.fromJson(item);
      debugPrint('[CHAT SEARCH] parsed → id=${m.id} name=${m.name} shop=${m.shopName}');
      if (m.id != 0 && seen.add(m.id)) merchants.add(m);
    }

    return merchants;
  }

  Future<ConversationSummary> getOrCreateConversation({
    required int    myUserId,
    required int    merchantId,
    required String merchantName,
    required String merchantAvatar,
  }) async {
    final a   = myUserId < merchantId ? myUserId : merchantId;
    final b   = myUserId < merchantId ? merchantId : myUserId;
    final cid = '$a:$b';

    try {
      final convs    = await getConversations();
      final existing = convs.where((c) => c.conversationId == cid).toList();
      if (existing.isNotEmpty) return existing.first;
    } catch (_) {}

    return ConversationSummary(
      conversationId:  cid,
      otherId:         merchantId,
      otherUserName:   merchantName,
      lastMessage:     '',
      lastMessageTime: DateTime.now(),
      unreadCount:     0,
    );
  }

  Future<void> markAsRead(String conversationId) async {
    await _dio.put('/messages/read/$conversationId');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN — ChatListScreen
// ─────────────────────────────────────────────────────────────────────────────
class ChatListScreen extends StatefulWidget {
  final int    myUserId;
  final String myToken;

  const ChatListScreen({
    super.key,
    required this.myUserId,
    required this.myToken,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatApiService _api;
  final TextEditingController _searchController = TextEditingController();

  List<ConversationSummary> _conversations = [];
  List<ConversationSummary> _filtered      = [];
  bool    _isLoading = true;
  String? _error;

  bool           _searchMode    = false;
  List<Merchant> _searchResults = [];
  bool           _searchLoading = false;

  /// Total unread messages across all conversations
  int get totalUnread => _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  void initState() {
    super.initState();
    _api = ChatApiService(widget.myToken);
    _loadConversations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final convs = await _api.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = convs;
        _filtered      = List.from(convs);
        _isLoading     = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = 'Impossible de charger les conversations';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _searchMode    = false;
        _searchResults = [];
        _filtered      = List.from(_conversations);
      });
      return;
    }
    setState(() {
      _filtered = _conversations
          .where((c) => c.otherUserName.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
    _doMerchantSearch(q);
  }

  Future<void> _doMerchantSearch(String q) async {
    setState(() { _searchLoading = true; _searchMode = true; });
    try {
      final results = await _api.searchMerchants(q);
      if (!mounted) return;
      setState(() { _searchResults = results; _searchLoading = false; });
    } catch (e) {
      debugPrint('[ChatList] search error: $e');
      if (!mounted) return;
      setState(() { _searchResults = []; _searchLoading = false; });
    }
  }

  void _updateConversationPreview({
    required String   conversationId,
    required String   lastMessage,
    required DateTime time,
    required bool     isMe,
  }) {
    setState(() {
      final idx = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (idx == -1) return;
      final conv           = _conversations[idx];
      conv.lastMessage     = isMe ? 'Vous : $lastMessage' : lastMessage;
      conv.lastMessageTime = time;
      if (!isMe) conv.unreadCount++;
      _conversations.removeAt(idx);
      _conversations.insert(0, conv);
      final q = _searchController.text.toLowerCase();
      _filtered = q.isEmpty
          ? List.from(_conversations)
          : _conversations
              .where((c) => c.otherUserName.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _openChatWithMerchant(Merchant merchant) async {
    final a   = widget.myUserId < merchant.id ? widget.myUserId : merchant.id;
    final b   = widget.myUserId < merchant.id ? merchant.id : widget.myUserId;
    final cid = '$a:$b';

    if (!_conversations.any((c) => c.conversationId == cid)) {
      setState(() {
        _conversations.insert(0, ConversationSummary(
          conversationId:  cid,
          otherId:         merchant.id,
          otherUserName:   merchant.displayName,
          lastMessage:     '',
          lastMessageTime: DateTime.now(),
          unreadCount:     0,
        ));
        _filtered = List.from(_conversations);
      });
    }

    _searchController.clear();
    setState(() => _searchMode = false);

    await _navigateToChatRoom(
      cid,
      merchant.id,
      merchant.displayName,
      merchant.avatarUrl,
    );
  }

  Future<void> _navigateToChatRoom(
    String conversationId,
    int    receiverId,
    String receiverName,
    String receiverAvatar,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: conversationId,
          receiverId:     receiverId,
          receiverName:   receiverName,
          receiverAvatar: receiverAvatar,
          myUserId:       widget.myUserId,
          myToken:        widget.myToken,
          onNewMessage: (text, time, isMe) {
            _updateConversationPreview(
              conversationId: conversationId,
              lastMessage:    text,
              time:           time,
              isMe:           isMe,
            );
          },
        ),
      ),
    );

    final idx = _conversations.indexWhere((c) => c.conversationId == conversationId);
    if (idx != -1) {
      setState(() => _conversations[idx].unreadCount = 0);
      try { await _api.markAsRead(conversationId); } catch (_) {}
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inDays == 0)    return DateFormat('HH:mm').format(dt);
    if (diff.inDays == 1)    return 'Hier';
    return DateFormat('d MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0EA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily:  'Poppins',
            fontWeight:  FontWeight.w500,
            fontSize:    22,
            color:       Color(0xFF72A843),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF72A843)))
          : _error != null
              ? _buildError()
              : _buildConversationList(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadConversations,
            child: const Text('Réessayer', style: TextStyle(color: Color(0xFF72A843))),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text(
              'Aucune conversation pour l\'instant',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: const Color(0xFF72A843),
      child: ListView.separated(
        itemCount: _filtered.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, indent: 76, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final conv = _filtered[index];
          return _ConversationTile(
            name:      conv.otherUserName,
            lastMsg:   conv.lastMessage.isEmpty ? 'Démarrer la conversation' : conv.lastMessage,
            timeLabel: _formatTime(conv.lastMessageTime),
            unread:    conv.unreadCount,
            onTap: () async {
              setState(() => conv.unreadCount = 0);
              await _navigateToChatRoom(
                conv.conversationId,
                conv.otherId,
                conv.otherUserName,
                '',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF72A843)));
    }

    final allItems = <Widget>[];

    if (_filtered.isNotEmpty) {
      allItems.add(const _SectionHeader(title: 'Conversations'));
      for (final conv in _filtered) {
        allItems.add(_ConversationTile(
          name:      conv.otherUserName,
          lastMsg:   conv.lastMessage.isEmpty ? 'Démarrer la conversation' : conv.lastMessage,
          timeLabel: _formatTime(conv.lastMessageTime),
          unread:    conv.unreadCount,
          onTap: () async {
            setState(() => conv.unreadCount = 0);
            await _navigateToChatRoom(
              conv.conversationId,
              conv.otherId,
              conv.otherUserName,
              '',
            );
          },
        ));
      }
    }

    if (_searchResults.isNotEmpty) {
      allItems.add(const _SectionHeader(title: 'Marchands'));
      for (final merchant in _searchResults) {
        // Ne pas afficher si déjà dans les conversations filtrées
        if (_conversations.any((c) => c.otherId == merchant.id)) continue;
        allItems.add(_ConversationTile(
          name:      merchant.displayName,
          lastMsg:   merchant.wilaya.isNotEmpty ? merchant.wilaya : 'Marchand',
          timeLabel: '',
          unread:    0,
          onTap:     () => _openChatWithMerchant(merchant),
        ));
      }
    }

    if (allItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text('Aucun résultat', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(children: allItems);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily:    'Poppins',
          fontSize:      11,
          fontWeight:    FontWeight.w600,
          color:         Color(0xFF72A843),
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final String       name;
  final String       lastMsg;
  final String       timeLabel;
  final int          unread;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.lastMsg,
    required this.timeLabel,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    final initials  = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFF5E6D0),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color:      Color(0xFFB87333),
                      fontWeight: FontWeight.bold,
                      fontSize:   18,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top:   0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF72A843), shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize:   15,
                          color:      Color(0xFF000E08))),
                  const SizedBox(height: 4),
                  Text(lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        fontSize:   13,
                        color: hasUnread
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF888888),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (timeLabel.isNotEmpty)
              Text(timeLabel,
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    color: hasUnread
                        ? const Color(0xFF72A843)
                        : const Color(0xFF888888),
                  )),
          ],
        ),
      ),
    );
  }
}