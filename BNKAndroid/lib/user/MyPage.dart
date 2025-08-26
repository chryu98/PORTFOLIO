import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'EditProfilePage.dart';
import 'package:bnkandroid/auth_state.dart';
import 'package:bnkandroid/app_shell.dart';

const kPrimaryRed = Color(0xffB91111);
const kBorderGray  = Color(0xFFE6E8EE);
const kText        = Color(0xFF23272F);
const kTitle       = Color(0xFF111111);
const kBg          = Colors.white;

/// ✅ API 호스트 한 곳에서 관리
const String kApiBase = 'http://192.168.0.5:8090';

class CardApplication {
  final int cardNo;
  final String cardName;
  final String cardUrl;
  final String? accountNumber;
  final String status;

  CardApplication({
    required this.cardNo,
    required this.cardName,
    required this.cardUrl,
    this.accountNumber,
    required this.status,
  });
}

String cardStatusText(String status) {
  switch (status) {
    case 'SIGNED':   return '승인중';
    case 'APPROVED': return '발급완료';
    default:         return '';
  }
}

Color cardStatusColor(String status) {
  switch (status) {
    case 'SIGNED':   return Colors.orange;
    case 'APPROVED': return Colors.green;
    default:         return Colors.black38;
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

/// ─────────────────────────────────────────────────────────────────────────
///  SSE: 외부 패키지 없이 http.Stream 으로 간단 파서
/// ─────────────────────────────────────────────────────────────────────────
class _SimpleSseClient {
  final Uri url;
  final Map<String, String> headers;
  final void Function(Map<String, dynamic> data, String? event) onMessage;
  final void Function(Object error, StackTrace st)? onError;
  final void Function()? onConnected;
  final void Function()? onDisconnected;

  http.Client? _client;
  StreamSubscription<List<int>>? _sub;
  bool _closing = false;
  int _retry = 0;

  _SimpleSseClient({
    required this.url,
    required this.headers,
    required this.onMessage,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  Future<void> connect() async {
    if (_closing) return;
    _client = http.Client();
    try {
      final req = http.Request('GET', url);
      req.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        ...headers,
      });

      final resp = await _client!.send(req);
      if (resp.statusCode != 200) {
        throw HttpException('SSE connect failed: ${resp.statusCode}');
      }

      onConnected?.call();
      _retry = 0; // 성공하면 backoff 초기화

      final decoder = const Utf8Decoder();
      var buffer = StringBuffer();

      _sub = resp.stream.listen(
            (chunk) {
          buffer.write(decoder.convert(chunk));
          var text = buffer.toString();

          // 이벤트는 \n\n(빈줄) 로 구분
          int sep;
          while ((sep = text.indexOf('\n\n')) != -1 || (sep = text.indexOf('\r\n\r\n')) != -1) {
            final raw = text.substring(0, sep);
            text = text.substring(sep + (text.startsWith('\r\n') ? 4 : 2));
            _handleRawEvent(raw);
          }
          buffer = StringBuffer()..write(text);
        },
        onError: (e, st) {
          onError?.call(e, st ?? StackTrace.current);
          _scheduleReconnect();
        },
        onDone: () {
          onDisconnected?.call();
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e, st) {
      onError?.call(e, st);
      _scheduleReconnect();
    }
  }

  void _handleRawEvent(String raw) {
    String? event;
    final dataLines = <String>[];

    for (final line in raw.split(RegExp(r'\r?\n'))) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
    if (dataLines.isEmpty) return;

    final dataStr = dataLines.join('\n');
    try {
      final map = jsonDecode(dataStr) as Map<String, dynamic>;
      onMessage(map, event);
    } catch (_) {
      // data가 JSON이 아닐 수도 있으니, 필요하면 여기서 문자열로 전달하도록 확장
    }
  }

  void _scheduleReconnect() {
    if (_closing) return;
    _disposeStream();
    // 지수 백오프 (최대 30초)
    final secs = [1, 2, 4, 8, 15, 30][_retry.clamp(0, 5)];
    _retry = (_retry + 1).clamp(0, 5);
    Future.delayed(Duration(seconds: secs), () {
      if (!_closing) connect();
    });
  }

  void _disposeStream() {
    _sub?.cancel();
    _sub = null;
    _client?.close();
    _client = null;
  }

  Future<void> close() async {
    _closing = true;
    _disposeStream();
  }
}

/// 인앱 알림 모델
class InAppNotice {
  final int? pushNo;
  final String title;
  final String body;
  final DateTime ts;
  bool read;
  InAppNotice({
    this.pushNo,
    required this.title,
    required this.body,
    required this.ts,
    this.read = false,
  });
}

class _MyPageState extends State<MyPage> {
  String userName = '사용자';
  bool marketingPush = false;
  int? memberNo;

  List<CardApplication> _cards = [];
  bool _loadingCards = true;
  bool _loadingUser  = true;
  String? _cardLoadError;

  // ── 알림(SSE)
  _SimpleSseClient? _sse;
  bool _sseStarted = false;
  final List<InAppNotice> _inbox = [];
  OverlayEntry? _toastEntry;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _sse?.close();
    _removeToast();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) {
      setState(() => _loadingUser = false);
      return;
    }

    try {
      final url = Uri.parse('$kApiBase/user/api/get-info');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $jwt'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final user = data['user'] ?? {};
        final rawPush = data['pushYn'];
        final yn = (rawPush is bool)
            ? (rawPush ? 'Y' : 'N')
            : (rawPush?.toString().toUpperCase() ?? 'N');

        setState(() {
          userName      = (user['name'] ?? user['userName'] ?? '사용자').toString();
          memberNo      = (user['memberNo'] ?? user['id']) as int?;
          marketingPush = (yn == 'Y' || yn == '1' || yn == 'TRUE');
          _loadingUser  = false;
        });

        // 카드 내역
        _loadCardHistory();
        // SSE 연결(한 번만)
        if (!_sseStarted) {
          _sseStarted = true;
          _connectSse(jwt);
        }
      } else if (res.statusCode == 401) {
        _handleLogout();
      } else {
        setState(() => _loadingUser = false);
        _toast('사용자 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      setState(() => _loadingUser = false);
      _toast('네트워크 오류로 사용자 정보를 불러오지 못했습니다.');
    }
  }

  void _connectSse(String jwt) {
    final uri = Uri.parse('$kApiBase/api/sse/stream');
    _sse = _SimpleSseClient(
      url: uri,
      headers: {'Authorization': 'Bearer $jwt'},
      onConnected: () {
        // 연결됨
      },
      onDisconnected: () {
        // 끊김(자동 재접속 시도)
      },
      onError: (e, st) {
        // 로그용
      },
      onMessage: (data, event) {
        // event == 'marketing' 일 수도, 아닐 수도 있음. payload만 사용.
        final title = (data['title'] ?? '알림').toString();
        final body  = (data['body'] ?? '').toString();
        final tsMs  = (data['ts'] is num) ? (data['ts'] as num).toInt() : DateTime.now().millisecondsSinceEpoch;
        final pushNo = (data['pushNo'] is num) ? (data['pushNo'] as num).toInt() : null;

        final notice = InAppNotice(
          pushNo: pushNo,
          title: title,
          body: body,
          ts: DateTime.fromMillisecondsSinceEpoch(tsMs),
          read: false,
        );

        if (!mounted) return;
        setState(() {
          _inbox.insert(0, notice);
        });
        _showInAppToast(notice);
      },
    )..connect();
  }

  void _showInAppToast(InAppNotice n) {
    _removeToast();

    final entry = OverlayEntry(
      builder: (context) {
        return _SlideInFromRight(
          duration: const Duration(milliseconds: 250),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  _removeToast();
                  _openNoticeDetail(n);
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 12, right: 12),
                  padding: const EdgeInsets.all(12),
                  width: MediaQuery.of(context).size.width * 0.86,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderGray),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 12,
                        spreadRadius: 1,
                        color: Color(0x1A000000),
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.message_rounded, color: kPrimaryRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true)?.insert(entry);
    _toastEntry = entry;

    // 4초 후 자동 닫힘
    Future.delayed(const Duration(seconds: 4), _removeToast);
  }

  void _removeToast() {
    _toastEntry?.remove();
    _toastEntry = null;
  }

  Future<void> _loadCardHistory() async {
    if (memberNo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    setState(() => _loadingCards = true);

    int _orderValue(Map e) {
      DateTime? dt;
      final cand = e['appliedAt'] ?? e['createdAt'] ?? e['updatedAt'] ?? e['regDt'];
      if (cand is String) dt = DateTime.tryParse(cand);
      if (dt != null) return dt.millisecondsSinceEpoch;

      final n = e['applicationNo'] ?? e['id'] ?? e['applyId'];
      if (n is int) return n;
      if (n is String) return int.tryParse(n) ?? 0;
      return 0;
    }

    String _normAcc(dynamic v) =>
        (v?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), '');

    try {
      final res = await http.post(
        Uri.parse('$kApiBase/user/api/card-list'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (res.statusCode == 200) {
        final raw = (json.decode(res.body) as List).cast<Map<String, dynamic>>();

        final Map<String, Map<String, dynamic>> pick = {};
        for (final e in raw) {
          final key = '${e['cardNo']}-${_normAcc(e['accountNumber'])}';
          final cur = pick[key];
          if (cur == null || _orderValue(e) > _orderValue(cur)) {
            pick[key] = e;
          }
        }

        final list = pick.values.map((e) => CardApplication(
          cardNo: e['cardNo'],
          cardName: e['cardName'],
          cardUrl: e['cardUrl'],
          accountNumber: e['accountNumber'],
          status: e['status'],
        )).toList();

        setState(() {
          _cards = list;
          _cardLoadError = null;
        });
      } else if (res.statusCode == 401) {
        _handleLogout();
      } else {
        setState(() => _cardLoadError = '카드 내역을 불러오지 못했습니다.');
      }
    } catch (e) {
      setState(() => _cardLoadError = '네트워크 오류로 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loadingCards = false);
    }
  }

  Future<void> _updatePushPreference(bool enabled) async {
    if (memberNo == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    try {
      final url = Uri.parse('$kApiBase/user/api/push-member');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwt'},
        body: jsonEncode({'memberNo': memberNo, 'pushYn': enabled ? 'Y' : 'N'}),
      );

      if (res.statusCode == 200) {
        // ✅ 성공 시 알림 띄우기
        _toast(enabled ? '마케팅 푸시 알림이 활성화되었습니다.' : '마케팅 푸시 알림이 해제되었습니다.');
      } else {
        throw Exception('push-member failed');
      }
    } catch (e) {
      setState(() => marketingPush = !enabled);
      _toast('알림 설정 변경에 실패했습니다.');
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    AuthState.loggedIn.value = false;
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int get _unreadCount => _inbox.where((e) => !e.read).length;

  void _openInbox() {
    _removeToast();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.35,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorderGray, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 14),
                const Text('알림', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Divider(height: 1, color: kBorderGray),
                Expanded(
                  child: _inbox.isEmpty
                      ? const Center(child: Text('받은 알림이 없습니다.'))
                      : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (_, i) {
                      final n = _inbox[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Stack(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFF5F6FA),
                              child: Icon(Icons.message_rounded, color: kPrimaryRed),
                            ),
                            if (!n.read)
                              const Positioned(
                                right: 0, top: 0,
                                child: CircleAvatar(radius: 5, backgroundColor: kPrimaryRed),
                              ),
                          ],
                        ),
                        title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(_formatTime(n.ts), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).maybePop();   // ✅ 안전하게 닫기
                          Future.microtask(() => _openNoticeDetail(n)); // 닫힌 뒤 상세 열기
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1, color: kBorderGray),
                    itemCount: _inbox.length,
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // 모달 닫힐 때 모두 읽음 처리하고 뱃지 제거하고 싶다면:
      setState(() {
        for (final n in _inbox) n.read = true;
      });
    });
  }


  void _safeClose(BuildContext ctx) {
    final nav = Navigator.of(ctx, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  void _openNoticeDetail(InAppNotice n) {
    setState(() => n.read = true);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(n.title),
        content: SingleChildScrollView(child: Text(n.body)),
        actions: [
          TextButton(
            onPressed: () => _safeClose(dialogCtx), // ✅ 다이얼로그 context
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (now.difference(t).inDays == 0) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: const Text('마이페이지', style: TextStyle(color: kTitle, fontWeight: FontWeight.w800)),
        foregroundColor: Colors.black87,
        actions: [
          // 알림 종 + 뱃지
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: _openInbox,
                  tooltip: '알림',
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kPrimaryRed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 로그아웃 (상단으로 이동)
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadUserInfo(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자명 + 내정보관리
                Row(
                  children: [
                    Expanded(
                      child: _loadingUser
                          ? const _Skeleton(width: 140, height: 20)
                          : Text(
                        '$userName님',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfilePage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kText,
                        side: const BorderSide(color: kBorderGray),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('내정보관리', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: kBorderGray),

                const SizedBox(height: 16),

                // 마케팅 푸시 알림 스위치
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: kBorderGray),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '마케팅 푸시 알림',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText),
                        ),
                      ),
                      Switch(
                        value: marketingPush,
                        onChanged: (v) async {
                          setState(() => marketingPush = v);
                          await _updatePushPreference(v);
                        },
                        activeColor: kPrimaryRed,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 카드 신청 내역
                _CardHistorySection(
                  loading: _loadingCards,
                  errorText: _cardLoadError,
                  cards: _cards,
                  onTapAll: _cards.isEmpty
                      ? null
                      : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyCardListPage(cards: _cards)),
                  ),
                ),

                const SizedBox(height: 24),
                // (하단 로그아웃 버튼은 제거 — AppBar로 이동 완료)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyCardListPage extends StatelessWidget {
  final List<CardApplication> cards;
  MyCardListPage({super.key, required List<CardApplication> cards})
      : cards = _dedupe(cards);

  static List<CardApplication> _dedupe(List<CardApplication> src) {
    String norm(String? v) => (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final map = <String, CardApplication>{};
    for (final c in src) {
      final key = '${c.cardNo}-${norm(c.accountNumber)}';
      map[key] = c;
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 카드 신청 내역'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _cardRow(cards[i]),
      ),
      backgroundColor: Colors.white,
    );
  }

  /// ▶ 카드 이미지를 세로로 돌리고(90도) 사이즈를 키움
  Widget _cardRow(CardApplication card) {
    const double imgW = 90;
    const double imgH = 140;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: imgW,
            height: imgH,
            child: RotatedBox(
              quarterTurns: 1, // 90도 회전
              child: card.cardUrl.isNotEmpty
                  ? Image.network(
                '$kApiBase/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}',
                fit: BoxFit.cover,
              )
                  : Container(
                color: kBorderGray,
                alignment: Alignment.center,
                child: const Text('이미지 없음'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.cardName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                cardStatusText(card.status),
                style: TextStyle(fontSize: 14, color: cardStatusColor(card.status)),
              ),
              const SizedBox(height: 4),
              Text('연동 계좌번호: ${card.accountNumber ?? '계좌 없음'}',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardHistorySection extends StatelessWidget {
  final bool loading;
  final String? errorText;
  final List<CardApplication> cards;
  final VoidCallback? onTapAll;
  const _CardHistorySection({
    required this.loading,
    required this.cards,
    this.errorText,
    this.onTapAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorderGray),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      '카드 신청 내역',
                      style: TextStyle(fontWeight: FontWeight.w700, color: kTitle),
                    ),
                  ),
                ),
                if (onTapAll != null)
                  TextButton(
                    onPressed: onTapAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('전체보기 >', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator(color: kPrimaryRed)),
            )
          else if (errorText != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(errorText!, style: const TextStyle(color: Colors.black54)),
            )
          else if (cards.isEmpty)
              _emptyRow()
            else
              _filledRow(cards.first),
        ],
      ),
    );
  }

  /// ▶ 요약 카드에서도 이미지 세로로 크게 표시
  Widget _filledRow(CardApplication card) {
    const double imgW = 80;
    const double imgH = 120;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: imgW,
            height: imgH,
            child: RotatedBox(
              quarterTurns: 1,
              child: card.cardUrl.isNotEmpty
                  ? Image.network(
                '$kApiBase/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}',
                fit: BoxFit.cover,
              )
                  : Container(
                color: const Color(0xFFE9ECF3),
                alignment: Alignment.center,
                child: const Text('이미지 없음', style: TextStyle(fontSize: 10, color: Colors.black54)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '카드명: ${card.cardName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  cardStatusText(card.status),
                  style: TextStyle(fontSize: 13, color: cardStatusColor(card.status)),
                ),
                const SizedBox(height: 4),
                Text(
                  '연동 계좌번호: ${card.accountNumber ?? '계좌 없음'}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyRow() {
    return Row(
      children: [
        _verticalLabelBox(),
        const SizedBox(width: 14),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('카드명', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text('연동 계좌번호', style: TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _verticalLabelBox() {
    return Container(
      width: 56,
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECF3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Text(
          '카드\n이미지',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.2),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double width;
  final double height;
  const _Skeleton({required this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// 오른쪽에서 슥 들어오는 애니메이션 래퍼
class _SlideInFromRight extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const _SlideInFromRight({required this.child, required this.duration});
  @override
  State<_SlideInFromRight> createState() => _SlideInFromRightState();
}

class _SlideInFromRightState extends State<_SlideInFromRight> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _offset = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offset, child: widget.child);
  }
}
