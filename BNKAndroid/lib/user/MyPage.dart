// lib/user/mypage.dart
import 'dart:convert';
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
const String kApiBase = 'http://192.168.100.106:8090';

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

class MyCardListPage extends StatelessWidget {
  final List<CardApplication> cards;
  MyCardListPage({super.key, required List<CardApplication> cards})
      : cards = _dedupe(cards);

  static List<CardApplication> _dedupe(List<CardApplication> src) {
    String norm(String? v) => (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final map = <String, CardApplication>{};
    for (final c in src) {
      final key = '${c.cardNo}-${norm(c.accountNumber)}';
      // 마지막으로 들어온(혹은 이미 최신으로 선별된) 것만 남김
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
    const double imgW = 90;   // 넓이 조금 키움
    const double imgH = 140;  // 세로형으로 더 크게
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

class _MyPageState extends State<MyPage> {
  String userName = '사용자';
  bool marketingPush = false;
  int? memberNo;

  List<CardApplication> _cards = [];
  bool _loadingCards = true;
  bool _loadingUser  = true;
  String? _cardLoadError;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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

        _loadCardHistory();
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

  Future<void> _loadCardHistory() async {
    if (memberNo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    setState(() => _loadingCards = true);

    // 날짜/최신도 계산
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

    // 계좌번호 정규화(숫자만 남김)
    String _normAcc(dynamic v) =>
        (v?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), '');

    try {
      final res = await http.post(
        Uri.parse('$kApiBase/user/api/card-list'),   // ← 호스트 통일!
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (res.statusCode == 200) {
        final raw = (json.decode(res.body) as List).cast<Map<String, dynamic>>();

        // 키: cardNo + 정규화된 계좌번호, 값: 가장 최신 레코드
        final Map<String, Map<String, dynamic>> pick = {};
        for (final e in raw) {
          final key = '${e['cardNo']}-${_normAcc(e['accountNumber'])}';
          final cur = pick[key];
          if (cur == null || _orderValue(e) > _orderValue(cur)) {
            pick[key] = e; // 더 최신으로 교체
          }
        }

        // 보여줄 리스트 생성(원본 -> CardApplication)
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
      if (res.statusCode != 200) throw Exception('push-member failed');
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

  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadUserInfo(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    '마이페이지',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kTitle),
                  ),
                ),
                const SizedBox(height: 18),

                // 사용자명 + 내정보관리
                Row(
                  children: [
                    Expanded(
                      child: _loadingUser
                          ? const _Skeleton(width: 140, height: 20)
                          : Text(
                        '$userName님',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // ▶ 글 겹침/넘침 방지
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

                // 마케팅 푸시 알림
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

                Center(
                  child: SizedBox(
                    width: 120,
                    height: 34,
                    child: OutlinedButton(
                      onPressed: _handleLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryRed,
                        side: const BorderSide(color: kBorderGray),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    const double imgW = 80;  // 넓이 업
    const double imgH = 120; // 세로 더 큼
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
