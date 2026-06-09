import 'package:flutter/material.dart';
import 'dart:convert';

import '../services/greenway_ai_client.dart';

const _bg      = Color(0xFF081C0E);
const _surface = Color(0xFF0D2B18);
const _card    = Color(0xFF122E1C);
const _accent  = Color(0xFF52B788);
const _textPrim = Colors.white;

// ── Singleton untuk simpan history chat ─────────────────────────────────────
class GreenBotHistory {
  GreenBotHistory._();
  static final GreenBotHistory instance = GreenBotHistory._();

  final List<Map<String, String>> messages = [
    {
      'role': 'assistant',
      'message': 'Halo! Saya GreenBot 🌿\nAda yang bisa saya bantu terkait lingkungan hari ini?'
    }
  ];

  // Riwayat untuk dikirim ke API (format Groq)
  final List<Map<String, String>> apiHistory = [];
}
// ────────────────────────────────────────────────────────────────────────────

class GreenBotScreen extends StatefulWidget {
  const GreenBotScreen({super.key});
  @override
  State<GreenBotScreen> createState() => _GreenBotScreenState();
}

class _GreenBotScreenState extends State<GreenBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final GreenwayAiClient _aiClient = const GreenwayAiClient();

  // Ambil dari singleton → history tetap ada walau screen di-pop
  List<Map<String, String>> get _messages => GreenBotHistory.instance.messages;
  List<Map<String, String>> get _apiHistory => GreenBotHistory.instance.apiHistory;

  @override
  void initState() {
    super.initState();
    // Scroll ke bawah saat buka screen
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'message': text});
      _apiHistory.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final response = await _aiClient.chatCompletions(
        feature: 'chatbot',
        body: {
          'messages': [
            {
              'role': 'system',
              'content': 'Kamu adalah asisten lingkungan profesional bernama GreenBot. Jawab dalam Bahasa Indonesia, singkat dan jelas.'
            },
            ..._apiHistory, // kirim seluruh history → context terjaga
          ],
          'temperature': 0.7,
          'max_tokens': 512,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        setState(() {
          _messages.add({'role': 'assistant', 'message': reply});
          _apiHistory.add({'role': 'assistant', 'content': reply});
        });
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'message': 'Error ${response.statusCode}: Gagal menghubungi server.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'message': e is GreenwayAiException
              ? e.message
              : 'Tidak bisa terhubung ke server AI. Pastikan backend aktif dan HP satu Wi-Fi dengan laptop.'
        });
      });
    } finally {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Riwayat Chat?', style: TextStyle(color: _textPrim, fontWeight: FontWeight.w700)),
        content: Text('Chat akan dihapus dan dimulai ulang.', style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() {
                _messages.clear();
                _apiHistory.clear();
                _messages.add({'role': 'assistant', 'message': 'Halo! Saya GreenBot 🌿\nAda yang bisa saya bantu terkait lingkungan hari ini?'});
              });
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.15),
              border: Border.all(color: _accent.withOpacity(0.4)),
            ),
            child: const Icon(Icons.psychology_rounded, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GreenBot AI', style: TextStyle(color: _textPrim, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Asisten Lingkungan', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrim),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38),
            onPressed: _clearHistory,
            tooltip: 'Hapus riwayat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['role'] == 'user';
                return _buildBubble(isUser, m['message']!);
              },
            ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _dot(0), const SizedBox(width: 4), _dot(150), const SizedBox(width: 4), _dot(300),
                  ]),
                ),
              ]),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Opacity(
        opacity: val,
        child: Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent)),
      ),
    );
  }

  Widget _buildBubble(bool isUser, String message) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? _accent : _card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
            fontSize: 14, height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: _textPrim, fontSize: 14),
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
            decoration: InputDecoration(
              hintText: 'Tanya GreenBot...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              filled: true, fillColor: _bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: _accent, width: 1.2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sendMessage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isLoading ? _accent.withOpacity(0.4) : _accent,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
