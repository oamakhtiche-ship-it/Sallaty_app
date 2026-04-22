// ─────────────────────────────────────────────────────────────────────────────
// conversation.dart — Sallaty Chat Room
//
// HOW THE BACKEND WEBSOCKET WORKS:
//
//  Protocol  : STOMP over raw WebSocket (NOT SockJS)
//  Endpoint  : ws://HOST:8080/ws
//
//  ┌─ CONNECT ─────────────────────────────────────────────────────────────┐
//  │  STOMP CONNECT frame with header:                                     │
//  │    Authorization: Bearer <jwt>                                        │
//  │  The server's JwtFilter verifies the token and sets the Principal.    │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  ┌─ SUBSCRIBE ───────────────────────────────────────────────────────────┐
//  │  Destination: /topic/messages/<conversationId>                        │
//  │  conversationId = "min(id1,id2):max(id1,id2)"  — built by the server │
//  │  The server checks that the authenticated user is a participant.      │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  ┌─ SEND ────────────────────────────────────────────────────────────────┐
//  │  Destination: /app/sendMessage                                        │
//  │  Body (JSON): { receiverId: int, content: string }                   │
//  │  senderId is taken from the JWT principal — never trust the client.   │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  ┌─ REST ────────────────────────────────────────────────────────────────┐
//  │  GET /api/messages/conversation/{otherUserId}                         │
//  │      → list of MessageDTO sorted by sentAt ascending                  │
//  │  PUT /api/messages/read/{conversationId}                              │
//  │      → mark all messages in the conversation as read                  │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  NOTE: The backend Message model only supports TEXT content.
//        Image / audio support would require adding new endpoints on the
//        server side.  The UI keeps those features but marks uploads as
//        TODO until the backend is extended.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'chat.dart' show kBaseUrl, kApiUrl;

// ─────────────────────────────────────────────────────────────────────────────
// MODEL — mirrors MessageDTO from the backend
// ─────────────────────────────────────────────────────────────────────────────
class Message {
  final String   id;           // server id (int cast to String for local use)
  final int      senderId;
  final int      receiverId;
  final String   conversationId;
  final String   content;      // text content (or empty for media)
  final String   type;         // 'text' | 'image' | 'audio'
  final String?  audioUrl;     // local path or remote URL
  final String?  imageUrl;     // local path or remote URL
  final DateTime createdAt;
  final bool     isRead;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
    required this.content,
    this.type         = 'text',
    this.audioUrl,
    this.imageUrl,
    required this.createdAt,
    this.isRead       = false,
  });

  // Deserialize from GET /api/messages/conversation/{id} response
  factory Message.fromJson(Map<String, dynamic> j) {
    return Message(
      id:             j['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId:       (j['senderId']   as num?)?.toInt() ?? 0,
      receiverId:     (j['receiverId'] as num?)?.toInt() ?? 0,
      conversationId: j['conversationId']?.toString() ?? '',
      content:        j['content']?.toString()         ?? '',
      type:           'text', // backend only stores text
      createdAt: j['sentAt'] != null
          ? DateTime.tryParse(j['sentAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: j['isRead'] as bool? ?? false,
    );
  }

  // Serialize to send via STOMP /app/sendMessage
  Map<String, dynamic> toStompPayload(int receiverId) => {
    'receiverId': receiverId,
    'content':    content,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// REST SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class MessageApiService {
  final Dio _dio;

  MessageApiService(String token)
      : _dio = Dio(BaseOptions(
    baseUrl: kApiUrl,
    headers: {'Authorization': 'Bearer $token'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// GET /api/messages/conversation/{otherUserId}
  Future<List<Message>> getMessages(int otherUserId) async {
    final res = await _dio.get('/messages/conversation/$otherUserId');
    final list = res.data as List<dynamic>;
    return list.map((j) => Message.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// PUT /api/messages/read/{conversationId}
  Future<void> markAsRead(String conversationId) async {
    await _dio.put('/messages/read/$conversationId');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STOMP WEBSOCKET SERVICE
//
// The backend uses Spring's STOMP message broker.
// We use the `stomp_dart_client` package which speaks STOMP natively.
//
// pubspec.yaml dependency to add:
//   stomp_dart_client: ^0.4.4   (or latest)
// ─────────────────────────────────────────────────────────────────────────────
class ChatStompService {
  StompClient? _client;
  bool _connected = false;
  StompUnsubscribe? _sub;

  void connect({
    required String token,
    required String conversationId,          // e.g. "12:34"
    required void Function(Message) onMessage,
    VoidCallback? onConnected,
  }) {
    final wsUrl = '${kBaseUrl.replaceFirst('http', 'ws')}/ws';

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        // Send JWT in the STOMP CONNECT frame (not in the URL)
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          _connected = true;
          onConnected?.call();

          // Subscribe to the conversation topic
          _sub = _client!.subscribe(
            destination: '/topic/messages/$conversationId',
            callback: (frame) {
              if (frame.body == null) return;
              try {
                final json = jsonDecode(frame.body!) as Map<String, dynamic>;
                final msg  = Message.fromJson(json);
                onMessage(msg);
              } catch (e) {
                debugPrint('STOMP parse error: $e');
              }
            },
          );
        },
        onDisconnect: (_) {
          _connected = false;
          debugPrint('STOMP disconnected');
        },
        onStompError: (frame) => debugPrint('STOMP error: ${frame.body}'),
        onWebSocketError: (e) => debugPrint('WS error: $e'),
        onWebSocketDone: () => _connected = false,
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
  }

  /// Send a text message via STOMP /app/sendMessage
  void send({
    required int    receiverId,
    required String content,
  }) {
    if (_client == null || !_connected) return;
    _client!.send(
      destination: '/app/sendMessage',
      body: jsonEncode({'receiverId': receiverId, 'content': content}),
    );
  }

  void disconnect() {
    _sub?.call();
    _client?.deactivate();
    _connected = false;
  }

  bool get isConnected => _connected;
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT ROOM SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ChatRoomScreen extends StatefulWidget {
  /// The conversationId as computed by the backend: "min:max" (e.g. "12:34")
  final String conversationId;

  /// Numeric id of the other participant
  final int    receiverId;
  final String receiverName;
  final String receiverAvatar;

  /// Numeric id of the current user
  final int    myUserId;
  final String myToken;

  /// Called by this screen whenever a new message is sent or received,
  /// so the ChatListScreen can update its preview.
  final void Function(String text, DateTime time, bool isMe)? onNewMessage;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.myUserId,
    required this.myToken,
    this.onNewMessage,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final MessageApiService _api;
  final ChatStompService        _stomp  = ChatStompService();
  final TextEditingController   _ctrl   = TextEditingController();
  final ScrollController        _scroll = ScrollController();
  final FocusNode               _focus  = FocusNode();
  final ImagePicker             _picker = ImagePicker();

  // Voice recording
  final AudioRecorder _recorder      = AudioRecorder();
  bool    _isRecording               = false;
  String? _recordingPath;

  List<Message> _messages    = [];
  bool          _isLoading   = true;
  bool          _stompReady  = false;

  @override
  void initState() {
    super.initState();
    _api = MessageApiService(widget.myToken);
    _loadHistory();
    _connectStomp();
  }

  // ── Load REST history ─────────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    try {
      final msgs = await _api.getMessages(widget.receiverId);
      if (!mounted) return;
      setState(() {
        _messages  = msgs;
        _isLoading = false;
      });
      _scrollToBottom();

      // Mark as read silently
      await _api.markAsRead(widget.conversationId);
    } catch (e) {
      debugPrint('History load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ── STOMP connection ──────────────────────────────────────────────────────
  void _connectStomp() {
    _stomp.connect(
      token:          widget.myToken,
      conversationId: widget.conversationId,
      onConnected: () {
        if (mounted) setState(() => _stompReady = true);
      },
      onMessage: (msg) {
        // Ignore echo of our own messages (the server broadcasts to everyone)
        if (msg.senderId == widget.myUserId) return;
        if (!mounted) return;
        setState(() => _messages.add(msg));
        _scrollToBottom();
        widget.onNewMessage?.call(msg.content, msg.createdAt, false);
      },
    );
  }

  // ── Send text ─────────────────────────────────────────────────────────────
  void _sendText() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();

    // Optimistic UI — add message immediately
    final localMsg = Message(
      id:             now.millisecondsSinceEpoch.toString(),
      senderId:       widget.myUserId,
      receiverId:     widget.receiverId,
      conversationId: widget.conversationId,
      content:        text,
      createdAt:      now,
    );

    setState(() => _messages.add(localMsg));
    _ctrl.clear();
    _scrollToBottom();

    // Send over STOMP
    _stomp.send(receiverId: widget.receiverId, content: text);

    widget.onNewMessage?.call(text, now, true);
  }

  // ── Voice recording ───────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission microphone requise'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _recordingPath!,
    );

    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopAndSendVoice() async {
    await _recorder.stop();
    if (mounted) setState(() => _isRecording = false);
    if (_recordingPath == null) return;

    final now      = DateTime.now();
    final localMsg = Message(
      id:             now.millisecondsSinceEpoch.toString(),
      senderId:       widget.myUserId,
      receiverId:     widget.receiverId,
      conversationId: widget.conversationId,
      content:        '[Audio message]',
      type:           'audio',
      audioUrl:       _recordingPath,
      createdAt:      now,
    );

    if (mounted) setState(() => _messages.add(localMsg));
    _scrollToBottom();

    // TODO: upload audio to server once the backend endpoint is added
    // Then send a text message like "[audio:{url}]" so the other side knows
    widget.onNewMessage?.call('🎤 Vocal', now, true);
  }

  Future<void> _cancelRecording() async {
    await _recorder.cancel();
    if (mounted) setState(() => _isRecording = false);
    _recordingPath = null;
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MediaPickerSheet(
        onCamera:  () async { Navigator.pop(ctx); await _pickImage(ImageSource.camera);  },
        onGallery: () async { Navigator.pop(ctx); await _pickImage(ImageSource.gallery); },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    final now      = DateTime.now();
    final localMsg = Message(
      id:             now.millisecondsSinceEpoch.toString(),
      senderId:       widget.myUserId,
      receiverId:     widget.receiverId,
      conversationId: widget.conversationId,
      content:        '[Image]',
      type:           'image',
      imageUrl:       file.path,
      createdAt:      now,
    );

    if (mounted) setState(() => _messages.add(localMsg));
    _scrollToBottom();

    // TODO: upload image to server once the backend endpoint is added
    widget.onNewMessage?.call('📷 Photo', now, true);
  }

  // ── Scroll ────────────────────────────────────────────────────────────────
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _stomp.disconnect();
    _recorder.dispose();
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final initials = widget.receiverName.isNotEmpty
        ? widget.receiverName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FBF6),
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF72A843)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar with online dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF5E6D0),
                  backgroundImage: widget.receiverAvatar.isNotEmpty
                      ? NetworkImage(widget.receiverAvatar)
                      : null,
                  child: widget.receiverAvatar.isEmpty
                      ? Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFFB87333),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                Positioned(
                  right:  0,
                  bottom: 0,
                  child: Container(
                    width:  9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _stompReady ? const Color(0xFF72A843) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(
                    fontFamily:  'Poppins',
                    fontWeight:  FontWeight.w500,
                    fontSize:    16,
                    height:      1.0,
                    color:       Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  _stompReady ? 'Connecté' : 'Connexion…',
                  style: TextStyle(
                    fontSize: 11,
                    color: _stompReady ? const Color(0xFF72A843) : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF72A843)))
                : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg   = _messages[index];
                  final isMe  = msg.senderId == widget.myUserId;
                  final prev  = index > 0 ? _messages[index - 1] : null;
                  final showAvatar = !isMe && (prev == null || prev.senderId == widget.myUserId);

                  return _MessageItem(
                    message:      msg,
                    isMe:         isMe,
                    showAvatar:   showAvatar,
                    senderAvatar: widget.receiverAvatar,
                    senderName:   widget.receiverName,
                    myId:         widget.myUserId,
                  );
                },
              ),
            ),
          ),

          // ── Input bar
          _InputBar(
            controller:  _ctrl,
            focusNode:   _focus,
            onSend:      _sendText,
            onAttach:    _showMediaPicker,
            isRecording: _isRecording,
            onMicStart:  _startRecording,
            onMicStop:   _stopAndSendVoice,
            onMicCancel: _cancelRecording,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _MessageItem extends StatelessWidget {
  final Message message;
  final bool    isMe;
  final bool    showAvatar;
  final String  senderAvatar;
  final String  senderName;
  final int     myId;

  const _MessageItem({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.senderAvatar,
    required this.senderName,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: showAvatar ? 10 : 2, bottom: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            SizedBox(
              width: 36,
              child: showAvatar
                  ? CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF5E6D0),
                backgroundImage:
                senderAvatar.isNotEmpty ? NetworkImage(senderAvatar) : null,
                child: senderAvatar.isEmpty
                    ? Text(
                  senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFFB87333),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
                    : null,
              )
                  : const SizedBox(),
            ),

          if (!isMe) const SizedBox(width: 6),

          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showAvatar && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontFamily:  'Poppins',
                        fontWeight:  FontWeight.w500,
                        fontSize:    12,
                        color:       Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                _BubbleContent(message: message, isMe: isMe),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _BubbleContent extends StatelessWidget {
  final Message message;
  final bool    isMe;

  const _BubbleContent({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.68;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF72A843) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(18),
          topRight:    const Radius.circular(18),
          bottomLeft:  Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4  : 18),
        ),
        boxShadow: [
          BoxShadow(
            color:    Colors.black.withOpacity(0.07),
            blurRadius: 6,
            offset:   const Offset(0, 2),
          ),
        ],
      ),
      child: switch (message.type) {
        'audio' => _AudioBubble(isMe: isMe, audioUrl: message.audioUrl),
        'image' when message.imageUrl != null =>
            _ImageBubble(imageUrl: message.imageUrl!, isMe: isMe, message: message),
        _ => _TextBubble(message: message, isMe: isMe),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEXT BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _TextBubble extends StatelessWidget {
  final Message message;
  final bool    isMe;

  const _TextBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize:   14,
              height:     1.3,
              color:      isMe ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(message.createdAt),
            style: TextStyle(
              color:    isMe ? Colors.white60 : Colors.grey.shade400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _AudioBubble extends StatefulWidget {
  final bool    isMe;
  final String? audioUrl;

  const _AudioBubble({required this.isMe, this.audioUrl});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final AudioPlayer _player   = AudioPlayer();
  bool     _playing           = false;
  Duration _duration          = Duration.zero;
  Duration _position          = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen(
            (s) { if (mounted) setState(() => _playing = s == PlayerState.playing); });
    _player.onDurationChanged.listen(
            (d) { if (mounted) setState(() => _duration = d); });
    _player.onPositionChanged.listen(
            (p) { if (mounted) setState(() => _position = p); });
    _player.onPlayerComplete.listen(
            (_) { if (mounted) setState(() => _position = Duration.zero); });
  }

  Future<void> _toggle() async {
    if (_playing) { await _player.pause(); return; }
    final url = widget.audioUrl;
    if (url == null) return;
    if (url.startsWith('http')) {
      await _player.play(UrlSource(url));
    } else {
      await _player.play(DeviceFileSource(url));
    }
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
          '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width:  34,
              height: 34,
              decoration: BoxDecoration(
                color:  widget.isMe ? Colors.white24 : const Color(0xFF72A843),
                shape:  BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size:  20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value:           progress,
              backgroundColor: widget.isMe ? Colors.white24 : Colors.grey.shade300,
              color:           widget.isMe ? Colors.white    : const Color(0xFF72A843),
              minHeight:       3,
              borderRadius:    BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _playing ? _fmt(_position) : _fmt(_duration),
            style: TextStyle(
              color:    widget.isMe ? Colors.white70 : Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _ImageBubble extends StatelessWidget {
  final String  imageUrl;
  final bool    isMe;
  final Message message;

  const _ImageBubble({
    required this.imageUrl,
    required this.isMe,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = !imageUrl.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft:     const Radius.circular(18),
        topRight:    const Radius.circular(18),
        bottomLeft:  Radius.circular(isMe ? 18 : 4),
        bottomRight: Radius.circular(isMe ? 4  : 18),
      ),
      child: Stack(
        children: [
          isLocal
              ? Image.file(File(imageUrl), width: 200, height: 160, fit: BoxFit.cover)
              : Image.network(imageUrl,    width: 200, height: 160, fit: BoxFit.cover),
          Positioned(
            bottom: 6,
            right:  8,
            child: Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT BAR
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final VoidCallback          onSend;
  final VoidCallback          onAttach;
  final bool                  isRecording;
  final VoidCallback          onMicStart;
  final VoidCallback          onMicStop;
  final VoidCallback          onMicCancel;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.isRecording,
    required this.onMicStart,
    required this.onMicStop,
    required this.onMicCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom > 0
        ? 8.0
        : 8.0 + MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomPad),
      child: isRecording
          ? Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.mic, color: Colors.red, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enregistrement… glisse pour annuler',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onMicCancel,
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onMicStop,
            child: Container(
              width:  42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF72A843), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      )
          : Row(
        children: [
          IconButton(
            icon:        Icon(Icons.attach_file, color: Colors.grey.shade500),
            onPressed:   onAttach,
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:        const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller:            controller,
                focusNode:             focusNode,
                maxLines:              4,
                minLines:              1,
                textCapitalization:    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:        'Tape quelque chose…',
                  hintStyle:       TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border:          InputBorder.none,
                  contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          GestureDetector(
            onLongPressStart: (_) => onMicStart(),
            onLongPressEnd:   (_) => onMicStop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.mic_none, color: Colors.grey.shade500, size: 28),
            ),
          ),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width:  42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF72A843), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDIA PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _MediaPickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _MediaPickerSheet({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color:        Color(0xFFF8FFF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  40,
            height: 4,
            decoration: BoxDecoration(
              color:        const Color(0xFFD7D8D7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Envoyer une photo',
            style: TextStyle(
              fontFamily:  'Poppins',
              fontSize:    18,
              fontWeight:  FontWeight.w500,
              color:       Color(0xFF72A843),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MediaOption(icon: Icons.camera_alt_outlined, label: 'Prendre une photo', onTap: onCamera),
              _MediaOption(icon: Icons.photo_library_outlined, label: 'Galerie',         onTap: onGallery),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;

  const _MediaOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width:  64,
            height: 64,
            decoration: BoxDecoration(
              color:        const Color(0xFFF0F8EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0E8C8)),
            ),
            child: Icon(icon, color: const Color(0xFF72A843), size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize:   12,
              fontFamily: 'Poppins',
              color:      Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}
