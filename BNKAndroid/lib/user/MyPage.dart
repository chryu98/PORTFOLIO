import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'EditProfilePage.dart';

const kPrimaryRed = Color(0xffB91111);
const kBorderGray = Color(0xFFE6E8EE);
const kBackground = Color(0xFFF4F6FA);
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

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');
    if (savedName != null && savedName.isNotEmpty) {
      setState(() => userName = savedName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 헤더
              Align(
                alignment: Alignment.centerLeft,
                child: Text('마이페이지', style: TextStyle(color: kTitle, fontSize: 16)),
              ),
              const SizedBox(height: 24),

              // 사용자 이름 + 내 정보 관리
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$userName 님',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kText,
                    ),
                  ),
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
                      side: BorderSide(color: kBorderGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('내정보관리', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: kBorderGray, thickness: 1),

              const SizedBox(height: 16),
              // 마케팅 푸시 알림
              SwitchListTile(
                title: const Text('마케팅 푸시 알림', style: TextStyle(fontSize: 14)),
                value: marketingPush,
                onChanged: (v) => setState(() => marketingPush = v),
                activeColor: kPrimaryRed,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),
              // 카드 신청 내역
              _buildCardHistory(),

              const SizedBox(height: 16),
              // 문의 내역
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
              const Text('카드 신청 내역', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('전체보기 >', style: TextStyle(fontSize: 12)),
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
                child: const Center(child: Text('카드\n이미지', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('카드명', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 4),
                  Text('연동 계좌번호', style: TextStyle(fontSize: 12, color: kText)),
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
              const Text('문의 내역', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('전체보기 >', style: TextStyle(fontSize: 12)),
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
