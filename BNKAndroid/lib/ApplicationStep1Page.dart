import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api.dart';

class ApplicationStep1Page extends StatefulWidget {
  final int applicationNo;

  const ApplicationStep1Page({super.key, required this.applicationNo, required bool isCreditCard});

  @override
  State<ApplicationStep1Page> createState() => _ApplicationStep1PageState();
}

class _ApplicationStep1PageState extends State<ApplicationStep1Page> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameEngController = TextEditingController();
  final _rrnFrontController = TextEditingController();
  final _rrnTailController = TextEditingController();
  bool _useExistingAccount = true;

  Future<void> _submitUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final url = '${API.baseUrl}/api/application/userinfo';

    final body = {
      "infoNo": null,
      "applicationNo": widget.applicationNo,
      "name": _nameController.text,
      "nameEng": _nameEngController.text,
      "rrnFront": _rrnFrontController.text,
      "rrnTailEnc": _rrnTailController.text, // 실제론 암호화 필요
      "isExistingAccount": _useExistingAccount ? "Y" : "N"
    };

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('개인정보 저장 완료')),
        );
        // TODO: Step 2 페이지로 이동
        // Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicationStep2Page(applicationNo: widget.applicationNo)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${res.statusCode}')),
        );
      }
    } catch (e) {
      print('❌ 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청 중 오류 발생')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1단계: 개인정보 입력')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, '이름', validator: (v) => v!.isEmpty ? '이름을 입력하세요' : null),
              _buildTextField(_nameEngController, '영문 이름', validator: (v) => v!.isEmpty ? '영문이름 입력' : null),
              _buildTextField(_rrnFrontController, '주민번호 앞자리(6자리)', keyboardType: TextInputType.number,
                  validator: (v) => v!.length != 6 ? '6자리 입력' : null),
              _buildTextField(_rrnTailController, '주민번호 뒷자리(7자리)', obscureText: true, keyboardType: TextInputType.number,
                  validator: (v) => v!.length != 7 ? '7자리 입력' : null),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('기존 계좌 사용'),
                  Switch(
                    value: _useExistingAccount,
                    onChanged: (v) => setState(() => _useExistingAccount = v),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitUserInfo,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white),
                child: const Text('다음 단계로'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
