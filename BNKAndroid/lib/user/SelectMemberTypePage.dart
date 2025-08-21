import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'TermsAgreePage.dart'; // 약관동의 페이지

const kPrimaryRed = Color(0xffB91111);

class SelectMemberTypePage extends StatefulWidget {
  const SelectMemberTypePage({super.key});

  @override
  State<SelectMemberTypePage> createState() => _SelectMemberTypePageState();
}

class _SelectMemberTypePageState extends State<SelectMemberTypePage> {
  String? _selectedRole;
  bool _loading = false;

  Future<void> _selectRole(String role) async {
    setState(() {
      _selectedRole = role;
      _loading = true;
    });

    try {
      // Flutter 웹용: 서버 LAN IP 사용
      final url = Uri.parse(
          'http://192.168.0.229:8090/user/api/regist/selectMemberType');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      );

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200 && data['redirectUrl'] != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TermsAgreePage(selectedRole: role),
          ),
        );
      } else {
        final msg = data['message'] ?? '알 수 없는 오류 발생';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 연결 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildRoleButton(String title, String role) {
    final bool selected = _selectedRole == role;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton(
        onPressed: _loading ? null : () => _selectRole(role),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 30),
          minimumSize: const Size.fromHeight(80),
          side: BorderSide(color: selected ? kPrimaryRed : Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: selected ? kPrimaryRed.withOpacity(0.1) : Colors.white,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: selected ? kPrimaryRed : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "회원 유형을 선택해 주세요",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                // const SizedBox(height: 6),
                // const Text(
                //   "회원 유형을 선택해 주세요",
                //   style: TextStyle(fontSize: 14, color: Colors.grey),
                // ),
                const SizedBox(height: 20),
                _buildRoleButton("일반회원(개인)", "ROLE_PERSON"),
                _buildRoleButton("개인사업자", "ROLE_OWNER"),
                _buildRoleButton("법인", "ROLE_CORP"),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
