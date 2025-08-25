import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'EditProfilePage.dart';
import 'package:bnkandroid/auth_state.dart';
import 'package:bnkandroid/app_shell.dart';

const kPrimaryRed = Color(0xffB91111);
const kBorderGray = Color(0xFFE6E8EE);
const kText = Color(0xFF23272F);
const kTitle = Color(0xFF111111);

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
    case 'SIGNED':
      return '승인중';
    case 'APPROVED':
      return '발급완료';
    default:
      return '';
  }
}

Color cardStatusColor(String status) {
  switch (status) {
    case 'SIGNED':
      return Colors.orange;
    case 'APPROVED':
      return Colors.green;
    default:
      return Colors.black38;
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class MyCardListPage extends StatelessWidget {
  final List<CardApplication> cards;

  const MyCardListPage({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 카드 신청 내역'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _buildCardItem(card);
        },
      ),
    );
  }

  Widget _buildCardItem(CardApplication card) {
    const double cardWidth = 160;
    const double cardHeight = cardWidth / 1.585;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: card.cardUrl.isNotEmpty
              ? Image.network(
            'http://192.168.0.229:8090/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}',
            width: cardWidth,
            height: cardHeight,
            fit: BoxFit.cover,
          )
              : Container(
            width: cardWidth,
            height: cardHeight,
            color: Colors.grey[300],
            child: const Center(child: Text('이미지 없음')),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.cardName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(cardStatusText(card.status),
                  style:
                  TextStyle(fontSize: 14, color: cardStatusColor(card.status))),
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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.229:8090/user/api/get-info'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['user'];
        setState(() {
          userName = user['name'] ?? '사용자';
          memberNo = user['memberNo'];
          marketingPush = (data['pushYn']?.toString() ?? 'N').toUpperCase() == 'Y';
        });
        _loadCardHistory();
      } else if (response.statusCode == 401) {
        _handleLogout();
      }
    } catch (e) {
      print('사용자 정보 로드 오류: $e');
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

  Future<void> _updatePushPreference(bool enabled) async {
    if (memberNo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.229:8090/user/api/push-member'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'memberNo': memberNo, 'pushYn': enabled ? 'Y' : 'N'}),
      );
      if (response.statusCode != 200) throw Exception();
    } catch (e) {
      setState(() => marketingPush = !enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 설정 변경에 실패했습니다.')),
      );
    }
  }

  Future<void> _loadCardHistory() async {
    if (memberNo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    setState(() => _loadingCards = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.229:8090/user/api/card-list'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          _cards = data
              .map((e) => CardApplication(
            cardNo: e['cardNo'],
            cardName: e['cardName'],
            cardUrl: e['cardUrl'],
            accountNumber: e['accountNumber'],
            status: e['status'],
          ))
              .toList();
        });
      } else if (response.statusCode == 401) {
        _handleLogout();
      }
    } catch (e) {
      print('카드 신청 내역 오류: $e');
    } finally {
      setState(() => _loadingCards = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('마이페이지',
                      style: const TextStyle(
                          color: kTitle,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildUserInfoCard(),
                  const SizedBox(height: 16),
                  _buildMarketingPush(),
                  const SizedBox(height: 16),
                  _buildCardHistory(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 120,
                height: 30,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kPrimaryRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: _handleLogout,
                  child: const Text('로그아웃', style: TextStyle(fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$userName 님',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kText)),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kText,
              side: const BorderSide(color: kBorderGray),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('내정보관리', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingPush() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('마케팅 푸시 알림', style: TextStyle(fontSize: 14)),
          Switch(
            value: marketingPush,
            onChanged: (v) async {
              setState(() => marketingPush = v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(v ? '마케팅 푸시 알림이 활성화되었습니다.' : '마케팅 푸시 알림이 비활성화되었습니다.'),
                  duration: const Duration(seconds: 2),
                ),
              );
              await _updatePushPreference(v);
            },
            activeColor: kPrimaryRed,
          ),
        ],
      ),
    );
  }

  Widget _buildCardHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: kBorderGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('카드 신청 내역', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  if (_cards.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyCardListPage(cards: _cards)),
                    );
                  }
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('전체보기 >', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _loadingCards
              ? const Center(child: CircularProgressIndicator())
              : _cards.isEmpty
              ? const Text('등록된 카드 신청 내역이 없습니다.', style: TextStyle(fontSize: 12))
              : _buildCardItem(_cards.first),
        ],
      ),
    );
  }

  Widget _buildCardItem(CardApplication card) {
    const double cardWidth = 160;
    const double cardHeight = cardWidth / 1.585;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: card.cardUrl.isNotEmpty
              ? Image.network(
            'http://192.168.0.229:8090/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}',
            width: cardWidth,
            height: cardHeight,
            fit: BoxFit.cover,
          )
              : Container(
            width: cardWidth,
            height: cardHeight,
            color: kBorderGray,
            child: const Center(child: Text('이미지 없음', style: TextStyle(fontSize: 10))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.cardName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(cardStatusText(card.status),
                  style: TextStyle(fontSize: 14, color: cardStatusColor(card.status))),
              const SizedBox(height: 4),
              Text('연동 계좌번호: ${card.accountNumber ?? '계좌 없음'}', style: const TextStyle(fontSize: 14, color: kText)),
            ],
          ),
        ),
      ],
    );
  }
}
