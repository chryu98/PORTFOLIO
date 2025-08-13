// lib/chat/widgets/chatbot_modal.dart
import 'dart:async';
import 'package:flutter/material.dart';
import './chat_message.dart';
import './chat_socket_service.dart';

class ChatbotModal extends StatefulWidget {
  const ChatbotModal({super.key});
  @override
  State<ChatbotModal> createState() => _ChatbotModalState();
}

class _ChatbotModalState extends State<ChatbotModal> {
  static const _bnkRed = Color(0xFFE60012);
  static const _ink = Color(0xFF222222);

  final _svc = ChatSocketService();
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();

  final List<ChatMessage> _msgs = [];
  bool _sending = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _svc.ensureConnected();
    _sub = _svc.stream.listen((m) {
      setState(() => _msgs.add(m));
      _autoScroll();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _msgs.add(ChatMessage(role: 'assistant', content: '안녕하세요! 부산은행 챗봇입니다. 무엇을 도와드릴까요?'));
      });
      _autoScroll();
    });
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _svc.close();
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await _svc.send(t);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _autoScroll();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPad = mq.viewInsets.bottom;

    return Material(
      color: Colors.black.withValues(alpha: 0.36),
      child: SafeArea(
        child: Center(
          child: Container(
            width: mq.size.width > 560 ? 520 : double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      const Text('부산은행 챗봇', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: _ink,
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // 메시지 리스트
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: const Color(0xFFF9FAFB),
                    child: ListView.builder(
                      controller: _scroll,
                      itemCount: _msgs.length,
                      itemBuilder: (_, i) => _bubble(_msgs[i]),
                    ),
                  ),
                ),

                // 입력 박스
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomPad),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: '질문을 입력하세요',
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: _bnkRed, width: 1.2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _send,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _bnkRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('보내기'),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final isUser = m.role == 'user';
    final bg = isUser ? const Color(0xFFE6F3FF) : Colors.white;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isUser
        ? const BorderRadius.only(
        topLeft: Radius.circular(14), topRight: Radius.circular(14),
        bottomLeft: Radius.circular(14))
        : const BorderRadius.only(
        topLeft: Radius.circular(14), topRight: Radius.circular(14),
        bottomRight: Radius.circular(14));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Text(m.content, style: const TextStyle(height: 1.45)),
          ),
        ],
      ),
    );
  }
}
