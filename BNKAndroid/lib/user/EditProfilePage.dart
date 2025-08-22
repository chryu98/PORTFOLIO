import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bnkandroid/postcode_search_page.dart';
import 'MyPage.dart';

const kPrimaryRed = Color(0xffB91111);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  int? memberNo;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController extraAddressController = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();

  String _passwordMessage = '';
  Color _passwordMessageColor = Colors.green;

  String _passwordCheckMessage = '';
  Color _passwordCheckMessageColor = Colors.green;

  String _address2Message = '';
  Color _address2MessageColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
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
      final fullAddress = data['address1'] ?? '';
      String address1 = fullAddress;
      String extraAddress = '';

      if (fullAddress.contains('(') && fullAddress.contains(')')) {
        int start = fullAddress.indexOf('(');
        int end = fullAddress.indexOf(')');
        address1 = fullAddress.substring(0, start).trim();
        extraAddress = fullAddress.substring(start + 1, end).trim();
      }

      setState(() {
        memberNo = data['memberNo'];
        nameController.text = data['name'] ?? '';
        usernameController.text = data['username'] ?? '';
        zipCodeController.text = data['zipCode'] ?? '';
        address1Controller.text = address1;
        extraAddressController.text = extraAddress;
        address2Controller.text = data['address2'] ?? '';
      });
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordMessage = '';
        _passwordMessageColor = Colors.green;
      });
      return;
    }
    const pwRegex =
        '^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!@#\$%^&*()_+\\[\\]{}|\\\\;:\'",.<>?/`~\\-]).{8,12}\$';
    final isValid = RegExp(pwRegex).hasMatch(password);
    setState(() {
      _passwordMessage =
      isValid ? '사용 가능한 비밀번호입니다.' : '비밀번호 형식이 올바르지 않습니다.';
      _passwordMessageColor = isValid ? Colors.green : Colors.red;
    });
  }

  void _checkPasswordMatch() {
    if (passwordCheckController.text.isEmpty) {
      setState(() {
        _passwordCheckMessage = '';
        _passwordCheckMessageColor = Colors.green;
      });
      return;
    }

    setState(() {
      if (passwordController.text == passwordCheckController.text) {
        _passwordCheckMessage = '비밀번호가 일치합니다.';
        _passwordCheckMessageColor = Colors.green;
      } else {
        _passwordCheckMessage = '비밀번호가 일치하지 않습니다.';
        _passwordCheckMessageColor = Colors.red;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (address2Controller.text.trim().isEmpty) {
      setState(() {
        _address2Message = '상세주소를 입력해주세요.';
      });
      return;
    }

    if (passwordController.text != passwordCheckController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');
    if (jwt == null) return;

    String finalAddress1 = address1Controller.text.trim();
    if (extraAddressController.text.trim().isNotEmpty) {
      finalAddress1 += " (${extraAddressController.text.trim()})";
    }

    final response = await http.post(
      Uri.parse('http://192.168.0.229:8090/user/api/update'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'memberNo': memberNo.toString(),
        'username': usernameController.text,
        'zipCode': zipCodeController.text,
        'address1': finalAddress1,
        'address2': address2Controller.text,
        'extraAddress': extraAddressController.text,
        if (passwordController.text.isNotEmpty)
          'password': passwordController.text,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정보가 수정되었습니다.')),
      );

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

  void searchAddress() async {
    final result = await Navigator.push<Map<String, dynamic>?>(context,
        MaterialPageRoute(builder: (_) => const PostcodeSearchPage()));

    if (result != null) {
      String fullAddress = (result['roadAddress'] ?? '').toString();
      String address1 = fullAddress;
      String extraAddress = (result['extraAddress'] ?? '').toString();

      if (fullAddress.contains('(') && fullAddress.contains(')')) {
        int start = fullAddress.indexOf('(');
        int end = fullAddress.indexOf(')');
        address1 = fullAddress.substring(0, start).trim();
        extraAddress = fullAddress.substring(start + 1, end).trim();
      }

      setState(() {
        zipCodeController.text = (result['zonecode'] ?? '').toString();
        if (address1Controller.text != address1 ||
            extraAddressController.text != extraAddress) {
          address1Controller.text = address1;
          extraAddressController.text = extraAddress;
          address2Controller.text = '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  "회원정보 수정",
                  style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // 이름
                TextField(
                  controller: nameController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '성명',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                // 아이디
                TextField(
                  controller: usernameController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 새 비밀번호
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _validatePassword,
                    ),
                    if (_passwordMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _passwordMessage,
                        style:
                        TextStyle(color: _passwordMessageColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // 새 비밀번호 확인
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: passwordCheckController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호 확인',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _checkPasswordMatch(),
                    ),
                    if (_passwordCheckMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _passwordCheckMessage,
                        style: TextStyle(
                            color: _passwordCheckMessageColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // 주소
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: zipCodeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '우편번호',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: searchAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(80, 48),
                      ),
                      child: const Text('검색',
                          style: TextStyle(color: kPrimaryRed)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: address1Controller,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '주소',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: extraAddressController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '참고주소',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                // 상세주소
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: address2Controller,
                      decoration: InputDecoration(
                        labelText: '상세주소',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                            _address2Message.isEmpty ? Colors.grey : Colors.red,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _address2Message.isEmpty ? kPrimaryRed : Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _address2Message = value.trim().isEmpty
                              ? '상세주소를 입력해주세요.'
                              : '';
                        });
                      },
                    ),
                    if (_address2Message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _address2Message,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 100), // 스크롤 여백 확보
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '수정',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
