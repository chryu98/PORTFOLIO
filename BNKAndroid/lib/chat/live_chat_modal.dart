// lib/chat/live_chat_modal.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'live_socket_service.dart';
import 'live_chat_message.dart';
import 'package:bnkandroid/constants/api.dart';

class LiveChatModal extends StatefulWidget {
  final int roomId;
  const LiveChatModal({super.key, required this.roomId});

  @override
  State<LiveChatModal> createState() => _LiveChatModalState();
}

class _LiveChatModalState extends State<LiveChatModal> {
  // ── Brand
  static const _bnkRed = Color(0xFFE60012);
  static const _bnkRedDark = Color(0xFFB8000E);
  static const _ink = Color(0xFF222222);
  static const _bg = Color(0xFFF5F6F8);

  final _svc = LiveSocketService();
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final List<LiveChatMessage> _messages = [];

  bool _loadingHistory = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory().then((_) => _connectWS());
  }

  Future<void> _connectWS() async {
    await _svc.connect(
      roomId: widget.roomId,
      onMessage: (m) {
        // 서버 브로드캐스트만 반영 (로컬 echo 금지)
        setState(() => _messages.add(LiveChatMessage.fromJson(m)));
        _scrollToEnd();
      },
    );
    setState(() {}); // 연결 상태 점 갱신
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _error = null;
    });

    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('jwt_token');
      if (token == null || token.isEmpty) {
        _error = '로그인이 필요합니다.';
        return;
      }

      final base = API.baseUrl;
      final headers = {'Authorization': 'Bearer $token'};
      final urls = <String>[
        '$base/chat/room/${widget.roomId}/history',
        '$base/api/chat/room/${widget.roomId}/history',
      ];

      bool ok = false;
      for (final url in urls) {
        final r = await http.get(Uri.parse(url), headers: headers);
        if (r.statusCode == 200) {
          final body = jsonDecode(utf8.decode(r.bodyBytes));
          final list = body is List ? body : (body['history'] ?? body['messages'] ?? []);
          _messages
            ..clear()
            ..addAll(list.map<LiveChatMessage>((e) => LiveChatMessage.fromJson(e)));
          ok = true;
          break;
        }
        if (r.statusCode == 404) continue;
        _error = '히스토리 로드 실패: ${r.statusCode}';
        break;
      }
      if (!ok && _error == null) _error = '상담 히스토리 경로를 찾지 못했습니다.';
    } catch (e) {
      _error = '히스토리 로드 중 오류: $e';
    } finally {
      _loadingHistory = false;
      if (mounted) setState(() {});
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    _svc.disconnect();
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    if (!_svc.connected) {
      _showSnack('아직 연결 중입니다. 잠시 후 다시 시도해 주세요.');
      return;
    }

    // 로컬 add 금지 → 서버 방송 수신 시에만 리스트에 추가
    _svc.sendToRoom(widget.roomId, {'message': text});
    _msgCtrl.clear();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // 상단만 크게 둥글게, 하단은 부드럽게
    const borderAll = BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.white,
      elevation: 0,
      // const 사용하지 않음: 변수 참조로 인한 Invalid constant value 방지
      shape: RoundedRectangleBorder(borderRadius: borderAll),
      child: ClipRRect(
        borderRadius: borderAll,
        child: SizedBox(
          width: 420,
          height: 600,
          child: Column(
            children: [
              // ── Header (BNK gradient + room + 상태점 + 닫기)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_bnkRed, _bnkRedDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    // 심플 아이콘 박스
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BNK 부산은행 1:1 상담',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _ConnDot(connected: _svc.connected),
                              const SizedBox(width: 6),
                              Text(
                                _svc.connected ? '연결됨 • Room #${'' + widget.roomId.toString()}' : '연결 중…',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // ── Body
              Expanded(
                child: Container(
                  color: _bg,
                  child: Column(
                    children: [
                      Container(height: 1, color: Colors.black.withOpacity(0.04)),
                      if (_loadingHistory)
                        const Expanded(child: Center(child: CircularProgressIndicator()))
                      else if (_error != null)
                        Expanded(
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8DB),
                                border: Border.all(color: const Color(0xFFFFEDB5)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFF856404)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: Color(0xFF856404)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              final mine = m.isMine ?? false;
                              final isAgent = (m.senderType?.toUpperCase() == 'ADMIN');

                              // 말풍선 스타일: 상담원=연한 레드, 사용자=화이트, 상대(비상담원)=라이트 그레이
                              final Color bubbleColor = isAgent
                                  ? const Color(0xFFFFF1F1)
                                  : (mine ? Colors.white : const Color(0xFFF1F3F4));
                              final Color borderColor = isAgent
                                  ? const Color(0xFFFFD6D6)
                                  : (mine ? Colors.black12 : const Color(0xFFE6E6E6));

                              final ts = (m.at != null)
                                  ? '${m.at!.hour.toString().padLeft(2, '0')}:${m.at!.minute.toString().padLeft(2, '0')}'
                                  : '';

                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 300),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: bubbleColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(mine ? 12 : 4),
                                        topRight: Radius.circular(mine ? 4 : 12),
                                        bottomLeft: const Radius.circular(12),
                                        bottomRight: const Radius.circular(12),
                                      ),
                                      border: Border.all(color: borderColor),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        if (isAgent)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: Text(
                                              '상담원',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          m.message,
                                          style: const TextStyle(color: _ink, height: 1.35),
                                        ),
                                        if (ts.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              ts,
                                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // 하단 구분선
                      Container(height: 1, color: Colors.black.withOpacity(0.06)),

                      // ── Input
                      Container(
                        color: _bg,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                decoration: InputDecoration(
                                  hintText: '메시지를 입력하세요…',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.black12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.black12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _bnkRed, width: 1.2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _bnkRed,
                                padding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _send,
                              icon: const Icon(Icons.send, size: 16, color: Colors.white),
                              label: const Text(
                                '보내기',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 연결 상태 점
class _ConnDot extends StatelessWidget {
  final bool connected;
  const _ConnDot({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.white : Colors.white54;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(connected ? 0.25 : 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
    );
  }
}
