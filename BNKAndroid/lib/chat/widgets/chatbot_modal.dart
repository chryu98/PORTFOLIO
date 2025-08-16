// lib/chat/widgets/chatbot_modal.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bnkandroid/constants/api.dart';
import 'package:bnkandroid/chat/widgets/chat_message.dart';

// 별칭으로 import (충돌 방지)
import 'package:bnkandroid/chat/chat_socket_service.dart' as bot;
import 'package:bnkandroid/chat/live_socket_service.dart' as live;

class ChatbotModal extends StatefulWidget {
  const ChatbotModal({super.key});
  @override
  State<ChatbotModal> createState() => _ChatbotModalState();
}

class _ChatbotModalState extends State<ChatbotModal> {
  static const _bnkRed = Color(0xFFE60012);
  static const _ink = Color(0xFF222222);

  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _bot = bot.ChatSocketService();
  final _live = live.LiveSocketService();

  final List<ChatMessage> _messages = [];
  int _botFailCount = 0;
  bool _escalated = false;
  int? _roomId;

  @override
  void dispose() {
    _live.disconnect();
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _isBotFail(Map<String, dynamic> r) {
    if (r.containsKey('found') && r['found'] == false) return true;
    if (r.containsKey('confidence') && (r['confidence'] ?? 1.0) < 0.45) return true;
    final text = (r['answer'] ?? r['message'] ?? '').toString();
    final bad = ['모르겠', '어려워', '담당자', '연결'];
    return bad.any((kw) => text.contains(kw));
  }

  Future<void> _sendToBot(String userText) async {
    setState(() => _messages.add(ChatMessage(fromUser: true, text: userText)));

    final r = await _bot.ask(userText);
    final botText = (r['answer'] ?? r['message'] ?? '답변을 생성할 수 없습니다.').toString();
    setState(() => _messages.add(ChatMessage(fromUser: false, text: botText)));

    if (_isBotFail(r)) {
      _botFailCount++;
      if (_botFailCount >= 2 && !_escalated) {
        await _escalateToHuman();
      } else {
        setState(() {});
      }
    }

    _scrollToEnd();
  }

  Future<void> _escalateToHuman() async {
    final rid = await _openRoomOnServer();
    if (rid == null) {
      setState(() {
        _messages.add(ChatMessage(fromUser: false, text: '상담사 연결에 실패했습니다. 잠시 후 다시 시도하세요.'));
      });
      return;
    }
    await _live.connect(
      roomId: rid,
      onMessage: (m) {
        final text = m['message']?.toString() ?? m['raw']?.toString() ?? '';
        setState(() => _messages.add(ChatMessage(fromUser: false, text: text)));
        _scrollToEnd();
      },
    );

    setState(() {
      _roomId = rid;
      _escalated = true;
      _messages.add(ChatMessage(fromUser: false, text: '상담사와 연결되었습니다. 질문을 입력해 주세요.'));
    });
  }

  Future<int?> _openRoomOnServer() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('jwt_token');
    if (token == null || token.isEmpty) {
      setState(() => _messages.add(ChatMessage(fromUser: false, text: '로그인이 필요합니다.')));
      return null;
    }
    final uri = Uri.parse('${API.baseUrl}/chat/room/open');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'type': 'ONE_TO_ONE'}),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final j = jsonDecode(resp.body);
        final rid = j['roomId'];
        if (rid is int) return rid;
        return int.tryParse('$rid');
      } catch (_) {}
    }
    return null;
  }

  void _sendToHuman(String text) {
    if (!_live.connected || _roomId == null) return;
    _live.sendToRoom(_roomId!, {
      'roomId': _roomId,
      'message': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
    setState(() => _messages.add(ChatMessage(fromUser: true, text: text)));
    _scrollToEnd();
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

  @override
  Widget build(BuildContext context) {
    final hint = _escalated ? '상담사에게 메시지 보내기…' : '질문을 입력하세요…';

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 420,
        height: 600,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              color: _bnkRed,
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'BNK 상담 챗봇',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + ((_botFailCount == 1 && !_escalated) ? 1 : 0),
                itemBuilder: (_, idx) {
                  if (_botFailCount == 1 && !_escalated && idx == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '정확한 답변이 어려워요. 한 번 더 실패하면 상담사에게 연결합니다.',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    );
                  }
                  final m = _messages[_botFailCount == 1 && !_escalated ? idx - 1 : idx];
                  final align = m.fromUser ? Alignment.centerRight : Alignment.centerLeft;
                  final bg = m.fromUser ? Colors.grey[200] : Colors.white;
                  final fg = _ink;

                  return Align(
                    alignment: align,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(m.text, style: TextStyle(color: fg)),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: hint,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (v) {
                        final t = v.trim();
                        if (t.isEmpty) return;
                        if (_escalated) {
                          _sendToHuman(t);
                        } else {
                          _sendToBot(t);
                        }
                        _msgCtrl.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final t = _msgCtrl.text.trim();
                      if (t.isEmpty) return;
                      if (_escalated) {
                        _sendToHuman(t);
                      } else {
                        _sendToBot(t);
                      }
                      _msgCtrl.clear();
                    },
                    child: const Text('전송'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
