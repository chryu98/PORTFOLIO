import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bnkandroid/postcode_search_page.dart'; // 우편번호 검색 페이지 import
import 'MyPage.dart';

const kPrimaryRed = Color(0xffB91111);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController extraAddressController = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token'); // 로그인 페이지와 동일한 키
    if (jwt == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.0.229:8090/user/api/get-info'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        nameController.text = data['name'] ?? '';
        usernameController.text = data['username'] ?? '';
        zipCodeController.text = data['zipCode'] ?? '';
        address1Controller.text = data['address1'] ?? '';
        extraAddressController.text = data['extraAddress'] ?? '';
        address2Controller.text = data['address2'] ?? '';
      });
    } else {
      print('회원 정보 로드 실패: ${response.statusCode}');
    }
  }

  Future<void> _saveProfile() async {
    if (passwordController.text != passwordCheckController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    // final data = {
    //   'zipCode': zipCodeController.text,
    //   'address1': address1Controller.text,
    //   'extraAddress': extraAddressController.text,
    //   'address2': address2Controller.text,
    //   if (passwordController.text.isNotEmpty)
    //     'password': passwordController.text,
    // };

    final response = await http.post(
      Uri.parse('http://192.168.0.229:8090/user/api/update'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': usernameController.text,
        'zipCode': zipCodeController.text,
        'address1': address1Controller.text,
        'address2': address2Controller.text,
        'extraAddress': extraAddressController.text,
        if (passwordController.text.isNotEmpty) 'password': passwordController.text,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정보가 수정되었습니다.')),
      );

      // 수정 후 MyPage로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: ${response.statusCode}')),
      );
    }
  }

  // 우편번호 검색
  void searchAddress() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => const PostcodeSearchPage()),
    );

    if (result != null) {
      setState(() {
        zipCodeController.text = (result['zonecode'] ?? '').toString();
        address1Controller.text =
        (result['roadAddress'] ?? '').toString().isNotEmpty
            ? (result['roadAddress'] ?? '')
            : (result['jibunAddress'] ?? '');
        extraAddressController.text = (result['extraAddress'] ?? '').toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원정보 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              readOnly: true,
              decoration: const InputDecoration(labelText: '성명'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: usernameController,
              readOnly: true,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordCheckController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: zipCodeController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: '우편번호'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: searchAddress,
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryRed),
                  child: const Text('검색', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: address1Controller,
              readOnly: true,
              decoration: const InputDecoration(labelText: '주소'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: extraAddressController,
              readOnly: true,
              decoration: const InputDecoration(labelText: '참고주소'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: address2Controller,
              decoration: const InputDecoration(labelText: '상세주소'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }
}
