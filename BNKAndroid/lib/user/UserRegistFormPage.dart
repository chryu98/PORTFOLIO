import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bnkandroid/postcode_search_page.dart';
import 'LoginPage.dart';

const kPrimaryRed = Color(0xffB91111);

class UserRegistFormPage extends StatefulWidget {
  final String role;
  final Map<String, String> agreedTerms;

  const UserRegistFormPage({
    super.key,
    required this.role,
    required this.agreedTerms,
  });

  @override
  State<UserRegistFormPage> createState() => _UserRegistFormPageState();
}

class _UserRegistFormPageState extends State<UserRegistFormPage> {
  int currentStep = 0; // 현재 단계

  // 스텝별 FormKey
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(), // Step 0
    GlobalKey<FormState>(), // Step 1
    GlobalKey<FormState>(), // Step 2
  ];

  // 아이디 메시지
  String usernameMsg = '';
  Color usernameMsgColor = Colors.red;

  // 비밀번호 메시지 상태 변수
  String passwordMsg = '';
  Color passwordMsgColor = Colors.red;

  // 비밀번호확인 메시지 상태 변수
  String passwordCheckMsg = '';
  Color passwordCheckMsgColor = Colors.red;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();
  final TextEditingController rrnFrontController = TextEditingController();
  final TextEditingController rrnBackController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController extraAddressController = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();

  bool usernameChecked = false;

  // 아이디 중복확인
  Future<void> checkUsername() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        usernameMsg = "아이디를 입력해주세요.";
        usernameMsgColor = Colors.red;
        usernameChecked = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.229:8090/user/api/regist/check-username"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": username},
      );
      final res = json.decode(response.body);
      setState(() {
        usernameMsg = res['msg'];
        usernameMsgColor = res['valid'] == true ? Colors.green : Colors.red;
        usernameChecked = res['valid'] == true;
      });
    } catch (e) {
      setState(() {
        usernameMsg = "서버와 통신 중 오류 발생";
        usernameMsgColor = Colors.red;
        usernameChecked = false;
      });
    }
  }

  // 비밀번호 유효성 검사
  bool isPasswordValid(String pw) {
    final pwRegex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,12}$',
    );
    return pwRegex.hasMatch(pw);
  }

  // 회원가입 제출
  Future<void> submitForm() async {
    if (!usernameChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("아이디 중복 확인을 해주세요.")),
      );
      return;
    }

    Map<String, dynamic> data = {
      "name": nameController.text.trim(),
      "username": usernameController.text.trim(),
      "password": passwordController.text.trim(),
      "passwordCheck": passwordCheckController.text.trim(),
      "rrnFront": rrnFrontController.text.trim(),
      "rrnBack": rrnBackController.text.trim(),
      "zipCode": zipCodeController.text.trim(),
      "address1": address1Controller.text.trim(),
      // 여기서 괄호를 포함해서 보냄
      "extraAddress": extraAddressController.text.trim().isNotEmpty
          ? " (${extraAddressController.text.trim()})"
          : "",
      "address2": address2Controller.text.trim(),
      "role": widget.role,
    };

    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.229:8090/user/api/regist/submit"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['msg'])),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['msg'] ?? "회원가입 실패")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("서버와 통신 중 오류 발생")),
      );
    }
  }

  // 단계 이동
  void nextStep() {
    if (_formKeys[currentStep].currentState!.validate()) {
      if (currentStep < 2) {
        setState(() => currentStep++);
      } else {
        submitForm();
      }
    }
  }

  void prevStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  // 주소 검색 버튼 눌렀을 때
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
    final stepPages = [
      // STEP 1 : 이름 + 아이디 + 비밀번호
      Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "성명(실명)"),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) return "성명을 입력해주세요.";
                if (!RegExp(r'^[가-힣]{2,20}$').hasMatch(value)) {
                  return "성명은 한글 2~20자여야 합니다.";
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: "아이디"),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "아이디를 입력해주세요.";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: checkUsername,
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryRed),
                  child: const Text("중복확인",
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(usernameMsg,
                style: TextStyle(color: usernameMsgColor, fontSize: 12)),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호"),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    passwordMsg = "비밀번호를 입력해주세요.";
                    passwordMsgColor = Colors.red;
                  } else if (!isPasswordValid(value)) {
                    passwordMsg = "영문, 숫자, 특수문자 포함 8~12자리여야 합니다.";
                    passwordMsgColor = Colors.red;
                  } else {
                    passwordMsg = "사용 가능한 비밀번호입니다.";
                    passwordMsgColor = Colors.green;
                  }
                  // 비밀번호 변경되면 확인 메시지 초기화
                  passwordCheckMsg = '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "비밀번호를 입력해주세요.";
                }
                // if (!isPasswordValid(value)) {
                //   return "영문, 숫자, 특수문자 포함 8~12자리여야 합니다.";
                // }
                return null;
              },
            ),
            const SizedBox(height: 4),
            Text(
              passwordMsg,
              style: TextStyle(color: passwordMsgColor, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordCheckController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호 확인"),
              onChanged: (value) {
                setState(() {
                  if (value != passwordController.text) {
                    passwordCheckMsg = "비밀번호가 일치하지 않습니다.";
                    passwordCheckMsgColor = Colors.red;
                  } else {
                    passwordCheckMsg = "비밀번호가 일치합니다.";
                    passwordCheckMsgColor = Colors.green;
                  }
                });
              },
              validator: (value) {
                if (value != passwordController.text) {
                  return "비밀번호가 일치하지 않습니다.";
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            Text(passwordCheckMsg,
                style: TextStyle(color: passwordCheckMsgColor, fontSize: 12)),
          ],
        ),
      ),

      // STEP 2 : 주민번호 입력
      Form(
        key: _formKeys[1],
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: rrnFrontController,
                decoration: const InputDecoration(labelText: "주민등록번호 앞자리"),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLength: 6,
                keyboardType: TextInputType.number,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                validator: (value) {
                  if (value == null || value.isEmpty) return "주민등록번호를 입력해주세요.";
                  if (!RegExp(r'^\d{6}$').hasMatch(value)) return "6자리 숫자만 입력해주세요.";
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: rrnBackController,
                decoration: const InputDecoration(labelText: "주민등록번호 뒷자리"),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLength: 7,
                obscureText: true,
                keyboardType: TextInputType.number,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                validator: (value) {
                  //if (value == null || value.isEmpty) return "주민등록번호를 입력해주세요.";
                  if (!RegExp(r'^\d{7}$').hasMatch(value ?? '')) return "7자리 숫자만 입력해주세요.";
                  return null;
                },
              ),
            ),
          ],
        ),
      ),

      // STEP 3 : 주소 입력
      Form(
        key: _formKeys[2],
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: zipCodeController,
                    decoration: const InputDecoration(labelText: "우편번호"),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "주소를 입력해주세요.";
                      return null;
                    },
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: searchAddress,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text("검색", style: TextStyle(color: kPrimaryRed)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            TextFormField(
                controller: address1Controller,
                decoration: const InputDecoration(labelText: "주소"),
                readOnly: true),
            const SizedBox(height: 5),
            TextFormField(
                controller: extraAddressController,
                decoration: const InputDecoration(labelText: "참고주소"),
                readOnly: true),
            const SizedBox(height: 5),
            TextFormField(
              controller: address2Controller,
              decoration: const InputDecoration(labelText: "상세주소"),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: currentStep > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: prevStep)
            : null,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "정보를 입력해주세요",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                IndexedStack(index: currentStep, children: stepPages),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(currentStep == 2 ? "회원가입" : "다음",
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
