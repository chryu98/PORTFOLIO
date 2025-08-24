import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'EditProfilePage.dart';

const kPrimaryRed = Color(0xffB91111);
const kBorderGray = Color(0xFFE6E8EE);
const kText = Color(0xFF23272F);
const kTitle = Color(0xFF111111);

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String userName = '사용자';
  bool marketingPush = false;
  int? memberNo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 🔹 사용자 정보와 memberNo 불러오기
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.229:8090/user/api/get-info'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        //print('서버 응답: ${response.body}');

        final data = json.decode(response.body);

        // userDto 데이터 가져오기
        final user = data['user'];
        final userNameFromServer = user['name'] ?? '사용자';
        final memberNoFromServer = user['memberNo'];

        // pushYn 별도 가져오기
        final pushYn = (data['pushYn']?.toString() ?? 'N').toUpperCase();
        final marketingPushFromServer = pushYn == 'Y';

        setState(() {
          userName = userNameFromServer;
          memberNo = memberNoFromServer;
          marketingPush = marketingPushFromServer;
        });
      } else {
        print('사용자 정보 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 정보 로드 오류: $e');
    }
  }


  // 🔹 마케팅 푸시 설정 업데이트
  Future<void> _updatePushPreference(bool enabled) async {
    if (memberNo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token'); // JWT 가져오기
    if (jwt == null) return;

    final pushYn = enabled ? 'Y' : 'N';
    final url = Uri.parse('http://192.168.0.229:8090/user/api/push-member');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'memberNo': memberNo,
          'pushYn': pushYn,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('푸시 수신 동의 업데이트 실패');
      }
    } catch (e) {
      // 실패 시 UI 롤백
      setState(() => marketingPush = !enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 설정 변경에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kText),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Text(
                '마이페이지',
                style: const TextStyle(
                    color: kTitle, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 사용자 정보 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$userName 님',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kText)),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfilePage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: kText,
                        side: const BorderSide(color: kBorderGray),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child:
                      const Text('내정보관리', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 마케팅 푸시
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('마케팅 푸시 알림', style: TextStyle(fontSize: 14)),
                    Switch(
                      value: marketingPush,
                      onChanged: (v) async {
                        setState(() => marketingPush = v);
                        final message = v
                            ? '마케팅 푸시 알림이 활성화되었습니다.'
                            : '마케팅 푸시 알림이 비활성화되었습니다.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(message),
                              duration: const Duration(seconds: 2)),
                        );
                        await _updatePushPreference(v);
                      },
                      activeColor: kPrimaryRed,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildCardHistory(),
              const SizedBox(height: 16),
              _buildInquiryHistory(),
            ],
          ),
        ),
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
              const Text('카드 신청 내역',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child:
                const Text('전체보기 >', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                color: kBorderGray,
                child: const Center(
                    child: Text('카드\n이미지',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 10))),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('카드명', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 4),
                  Text('연동 계좌번호',
                      style: TextStyle(fontSize: 12, color: kText)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryHistory() {
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
              const Text('문의 내역',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child:
                const Text('전체보기 >', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('최근 내 문의 내용', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          const Text('답변 내용', style: TextStyle(fontSize: 12, color: kText)),
        ],
      ),
    );
  }
}
