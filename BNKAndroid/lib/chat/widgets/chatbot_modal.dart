// lib/chat/widgets/chatbot_modal.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bnkandroid/chat/widgets/chat_message.dart';
import 'package:bnkandroid/chat/chat_socket_service.dart' as bot;
import 'package:bnkandroid/constants/api.dart';
import 'package:bnkandroid/user/loginpage.dart';
import 'package:bnkandroid/chat/live_chat_modal.dart';

class ChatbotModal extends StatefulWidget {
  final BuildContext hostContext;
  const ChatbotModal({super.key, required this.hostContext});

  @override
  State<ChatbotModal> createState() => _ChatbotModalState();
}

class _ChatbotModalState extends State<ChatbotModal> {
  // ── Brand colors
  static const _bnkRed = Color(0xFFE60012);
  static const _bnkRedDark = Color(0xFFB8000E);
  static const _ink = Color(0xFF222222);
  static const _bg = Color(0xFFF5F6F8);

  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _bot = bot.ChatSocketService();

  final List<ChatMessage> _messages = [];
  int _botFailCount = 0;
  bool _sending = false; // 중복 전송 방지
  bool _typing = false;  // 봇 타이핑 표시

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      fromUser: false,
      text: "안녕하세요, 부산은행 챗봇 ‘부뱅이’입니다.\n무엇을 도와드릴까요?",
    ));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _isBotFail(Map<String, dynamic> r) {
    if (r.containsKey('found') && r['found'] == false) return true;
    if (r.containsKey('confidence') && (r['confidence'] ?? 1.0) < 0.45) return true;
    final text = (r['answer'] ?? r['message'] ?? '').toString();
    const bad = ['모르겠', '어려워', '담당자', '연결', '이해하지 못했', '질문해 주실 수 있을까요'];
    return bad.any((kw) => text.contains(kw));
  }

  Future<void> _sendToBot(String userText) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _messages.add(ChatMessage(fromUser: true, text: userText));
      _typing = true;
    });

    try {
      final r = await _bot.ask(userText);
      final botText = (r['answer'] ?? r['message'] ?? '답변을 생성할 수 없습니다.').toString();

      setState(() {
        _messages.add(ChatMessage(fromUser: false, text: botText));
      });

      if (_isBotFail(r)) {
        _botFailCount++;
        if (_botFailCount >= 2) {
          final ok = await _confirmEscalation();
          if (ok == true) {
            await _escalateToHuman();
            return;
          }
        } else {
          setState(() {}); // 1회 실패 경고 노출만
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(fromUser: false, text: '서버와 통신 중 오류가 발생했습니다. 다시 시도해 주세요.'));
      });
    } finally {
      setState(() {
        _sending = false;
        _typing = false;
      });
      _scrollToEnd();
    }
  }

  Future<bool?> _confirmEscalation() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("상담사 연결"),
        content: const Text("정확한 답변이 어려워요.\n실시간 상담사에게 연결할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("아니요")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("연결")),
        ],
      ),
    );
  }

  Future<void> _escalateToHuman() async {
    final rid = await _openRoomOnServer();
    if (rid == null) return;

    if (!mounted) return;
    Navigator.of(context).pop(); // 챗봇 모달 닫기
    showDialog(
      context: widget.hostContext,
      barrierDismissible: false,
      useRootNavigator: false,                        // ← 중요!
      builder: (_) => LiveChatModal(roomId: rid),
    );

  }

  Future<int?> _openRoomOnServer() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('jwt_token');

    // 1) 로그인 유도
    if (token == null || token.isEmpty) {
      if (!mounted) return null;
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('로그인이 필요합니다'),
          content: const Text('실시간 상담을 이용하려면 로그인이 필요합니다.\n로그인 페이지로 이동할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('로그인')),
          ],
        ),
      );
      if (goLogin == true && mounted) {
        Navigator.of(context).pop();
        await LoginPage.goLoginThen(
          widget.hostContext,
              (_) => _OpenLiveChatAfterLogin(hostContext: widget.hostContext),
        );
      }
      return null;
    }

    // 2) memberNo 확보
    int? memberNo = sp.getInt('member_no') ?? _extractMemberNoFromJwt(token);
    if (memberNo == null) {
      final controller = TextEditingController(text: '1');
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('고객 번호 입력'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '예: 1'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('확인')),
          ],
        ),
      );
      if (ok == true) {
        memberNo = int.tryParse(controller.text.trim());
        if (memberNo != null) {
          await sp.setInt('member_no', memberNo!);
        }
      }
    }

    if (memberNo == null) {
      _showSnack('memberNo가 없어 상담방을 열 수 없습니다.');
      return null;
    }

    // 3) 방 생성 호출
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Member-No': memberNo.toString(),
    };
    final body = jsonEncode({'type': 'ONE_TO_ONE'});

    final urls = <String>[
      '${API.baseUrl}/chat/room/open',
      '${API.baseUrl}/api/chat/room/open',
    ];

    for (final u in urls) {
      final resp = await http.post(Uri.parse(u), headers: headers, body: body);
      final raw = utf8.decode(resp.bodyBytes);
      debugPrint('🛰️ POST $u → ${resp.statusCode}\n$raw');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final j = jsonDecode(raw);
          final rid = j['roomId'] ?? j['id'] ?? j['roomID'] ?? j['data']?['roomId'];
          final parsed = rid is int ? rid : int.tryParse('$rid');
          if (parsed != null && parsed > 0) return parsed;
        } catch (_) {}
      }
      if (resp.statusCode == 401) {
        _showSnack('상담방 생성 실패 (401). 로그인 또는 memberNo 확인이 필요합니다.');
        return null;
      }
    }

    // 개발 편의용: 수동 roomId 입력
    if (!mounted) return null;
    final manual = await _askManualRoomId();
    return manual;
  }

  Future<int?> _askManualRoomId() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('상담방 생성 API를 찾을 수 없습니다'),
        content: const Text('서버 경로가 준비되지 않은 듯 합니다.\n임시로 roomId를 직접 입력해 연결 테스트를 진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('roomId 입력')),
        ],
      ),
    );
    if (ok == true) {
      final ok2 = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('roomId 입력'),
          content: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '예: 123'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('연결')),
          ],
        ),
      );
      if (ok2 == true) {
        final v = int.tryParse(c.text.trim());
        if (v != null && v > 0) return v;
      }
    }
    return null;
  }

  int? _extractMemberNoFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      String norm(String s) => s
          .padRight(s.length + (4 - s.length % 4) % 4, '=')
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      final payload = jsonDecode(utf8.decode(base64Url.decode(norm(parts[1]))));
      final v = payload['memberNo'] ?? payload['member_no'];
      return v is int ? v : int.tryParse('$v');
    } catch (_) {
      return null;
    }
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
      // ❗ const 제거 (변수 참조 시 상수식 아님)
      shape: RoundedRectangleBorder(borderRadius: borderAll),
      child: ClipRRect(
        borderRadius: borderAll,
        child: SizedBox(
          width: 420,
          height: 600,
          child: Column(
            children: [
              // ── Header (BNK gradient + close)
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
                    // 챗봇 아바타
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    // ❗ const 제거(내부에 비상수 위젯 포함될 수 있음)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'BNK 상담 챗봇',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              _OnlineDot(),
                              SizedBox(width: 6),
                              Text(
                                '부뱅이가 도와드리고 있어요',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          )
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

                      Expanded(
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          itemCount: _messages.length +
                              ((_botFailCount == 1) ? 1 : 0) +
                              (_typing ? 1 : 0),
                          itemBuilder: (_, idx) {
                            if (_botFailCount == 1 && idx == 0) {
                              return const _WarnBanner();
                            }

                            final shift = (_botFailCount == 1) ? 1 : 0;
                            final isTypingRow = _typing && (idx == _messages.length + shift);
                            if (isTypingRow) {
                              return const _TypingBubble();
                            }

                            final m = _messages[idx - shift];
                            final mine = m.fromUser;

                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                                ),
                                decoration: BoxDecoration(
                                  color: mine ? Colors.white : const Color(0xFFFFF1F1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(mine ? 12 : 4),
                                    topRight: Radius.circular(mine ? 4 : 12),
                                    bottomLeft: const Radius.circular(12),
                                    bottomRight: const Radius.circular(12),
                                  ),
                                  border: Border.all(
                                    color: mine ? Colors.black12 : const Color(0xFFFFD6D6),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Text(
                                  m.text,
                                  style: const TextStyle(
                                    color: _ink,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Container(height: 1, color: Colors.black.withOpacity(0.06)),
                      // ── Input area
                      Container(
                        color: _bg,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                decoration: InputDecoration(
                                  hintText: '질문을 입력하세요…',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                                  suffixIcon: _sending
                                      ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                      : null,
                                ),
                                onSubmitted: (v) {
                                  final t = v.trim();
                                  if (t.isEmpty) return;
                                  _sendToBot(t);
                                  _msgCtrl.clear();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _bnkRed,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _sending
                                  ? null
                                  : () {
                                final t = _msgCtrl.text.trim();
                                if (t.isEmpty) return;
                                _sendToBot(t);
                                _msgCtrl.clear();
                              },
                              child: const Text(
                                '전송',
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

/// 로그인 후 자동으로 상담방을 열고 LiveChat 모달을 띄워주는 헬퍼 화면
class _OpenLiveChatAfterLogin extends StatefulWidget {
  final BuildContext hostContext; // ← 추가
  const _OpenLiveChatAfterLogin({required this.hostContext});
  @override
  State<_OpenLiveChatAfterLogin> createState() => _OpenLiveChatAfterLoginState();
}

class _OpenLiveChatAfterLoginState extends State<_OpenLiveChatAfterLogin> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('jwt_token');
      if (token == null || token.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      int? memberNo = sp.getInt('member_no') ?? _extractMemberNoFromJwt(token);
      memberNo ??= 1;

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Member-No': '$memberNo',
      };
      final payload = jsonEncode({'type': 'ONE_TO_ONE'});

      int? rid;
      for (final path in const ['/chat/room/open', '/api/chat/room/open']) {
        final url = '${API.baseUrl}$path';
        final resp = await http.post(Uri.parse(url), headers: headers, body: payload);
        final raw = utf8.decode(resp.bodyBytes);
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          try {
            final j = jsonDecode(raw);
            final id = (j is Map<String, dynamic>)
                ? (j['roomId'] ?? j['id'] ?? j['roomID'] ?? j['data']?['roomId'])
                : null;
            final parsed = (id is int) ? id : int.tryParse('$id');
            if (parsed != null && parsed > 0) {
              rid = parsed;
              break;
            }
          } catch (_) {}
        }
      }

      if (rid != null && mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: widget.hostContext,
          barrierDismissible: false,
          useRootNavigator: false, // ← 중요!
          builder: (_) => LiveChatModal(roomId: rid!),
        );
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(widget.hostContext).showSnackBar(
            const SnackBar(content: Text('상담방 생성에 실패했습니다. (경로/권한 확인 필요)')),
          );
        }
      }
    });
  }

  int? _extractMemberNoFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      String norm(String s) => s
          .padRight(s.length + (4 - s.length % 4) % 4, '=')
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      final payload = jsonDecode(utf8.decode(base64Url.decode(norm(parts[1]))));
      final v = payload['memberNo'] ?? payload['member_no'];
      return v is int ? v : int.tryParse('$v');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// ── UI Partials

class _WarnBanner extends StatelessWidget {
  const _WarnBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DB),
        border: Border.all(color: const Color(0xFFFFEDB5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF856404)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '정확한 답변이 어려워요. 한 번 더 실패하면 상담사에게 연결할지 물어볼게요.',
              style: TextStyle(color: Color(0xFF856404)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 4),
            _Dot(), _Dot(delay: 120), _Dot(delay: 240),
            SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
    );
  }
}

/// 작은 점 3개(타이핑 표시)
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({this.delay = 0});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = ((_c.value + (widget.delay / 900)) % 1.0);
        final scale = t < 0.5 ? (0.6 + t * 0.8) : (1.0 - (t - 0.5) * 0.8);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.scale(
            scale: scale,
            child: const CircleAvatar(radius: 3, backgroundColor: Colors.black38),
          ),
        );
      },
    );
  }
}
