// lib/chat/widgets/chatbot_modal.dart
import 'dart:async';
import 'package:flutter/material.dart';

// 기존 챗봇 서비스/모델 (네 프로젝트 경로 유지)
import './chat_message.dart';
import './chat_socket_service.dart';

// 실시간 상담(STOMP) 서비스 (파일 경로 주의: lib/chat/live_socket_service.dart)
import '../live_socket_service.dart';

class ChatbotModal extends StatefulWidget {
  const ChatbotModal({super.key});
  @override
  State<ChatbotModal> createState() => _ChatbotModalState();
}

class _ChatbotModalState extends State<ChatbotModal> {
  static const _bnkRed = Color(0xFFE60012);
  static const _ink = Color(0xFF222222);

  // 1) 챗봇용(기존)
  final _svc = ChatSocketService();
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();

  final List<ChatMessage> _msgs = [];
  bool _sending = false;
  StreamSubscription? _sub;

  // 2) 실시간 상담용(STOMP)
  final _live = LiveSocketService();
  bool _liveReady = false;                 // 상담 연결 후 true
  final String _wsBase = 'ws://192.168.0.5:8090'; // 서버 IP:PORT
  String _roomId = 'user-6';               // 관리자/웹과 동일 규칙
  String _sender = 'user6';                // 로그인 사용자명

  @override
  void initState() {
    super.initState();

    // 챗봇 스트림
    _svc.ensureConnected();
    _sub = _svc.stream.listen((m) {
      setState(() => _msgs.add(m));
      _autoScroll();
      // 실패 문구 수신 시 배너는 build에서 표시 (조건만 충족)
    });

    // 오프닝 메시지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _msgs.add(ChatMessage(
          role: 'assistant',
          content: '안녕하세요! 부산은행 챗봇입니다. 무엇을 도와드릴까요?',
        ));
      });
      _autoScroll();
    });
  }

  // ❗ 스샷 기준 실패 문구 포함
  bool _looksLikeFallback(String text) {
    return text.contains('이해하지 못했') ||    // ← 스샷 문구
        text.contains('답변을 찾지 못했') ||
        text.contains('상담사') ||
        text.contains('연결해드릴까요');
  }

  Future<void> _connectLive() async {
    await _live.connect(
      wsBase: _wsBase,
      roomId: _roomId,
      sender: _sender,
    );

    _live.onMessage = (m) {
      setState(() {
        final txt = (m['message'] ?? '').toString();
        _msgs.add(ChatMessage(role: 'assistant', content: txt));
      });
      _autoScroll();
    };

    // 최초 알림(선택)
    _live.sendText('[사용자 연결] 챗봇에서 실시간 상담으로 전환 요청');
    setState(() => _liveReady = true);
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
    _live.disconnect();
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty || _sending) return;

    // 상담 모드면 STOMP로 전송
    if (_liveReady) {
      _msgCtrl.clear();
      setState(() => _msgs.add(ChatMessage(role: 'user', content: t)));
      _autoScroll();
      _live.sendText(t);
      return;
    }

    // 기본: 챗봇으로 전송
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

    // 실패 메시지 하나라도 있고, 아직 상담 연결 안 됐으면 배너 표시
    final showHandoff = !_liveReady &&
        _msgs.any((m) => m.role == 'assistant' && _looksLikeFallback(m.content));

    return Material(
      // Flutter 버전에 따라 withValues가 없으면 withOpacity(0.36)로 바꾸세요.
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

                // 전환 배너
                if (showHandoff)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '챗봇이 해결하지 못했어요. 실시간 상담사에게 연결할까요?',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _connectLive,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _bnkRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('상담 연결'),
                        ),
                      ],
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
                            hintText: _liveReady ? '상담사에게 메시지 보내기' : '질문을 입력하세요',
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
                              : Text(_liveReady ? '보내기(상담)' : '보내기'),
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
