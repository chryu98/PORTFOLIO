import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed; // 색상 재사용
import 'package:bnkandroid/security/secure_screen.dart';
import 'package:bnkandroid/security/screenshot_watcher.dart';

import 'ApplicationStep5AccountPage.dart' hide kPrimaryRed;

// HTTP & 파일 전송
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http_parser/http_parser.dart';

class ApplicationStep4OcrPage extends StatefulWidget {
  final int applicationNo; // 필수
  final int? cardNo;       // Step5에 넘길 카드 번호(선택)

  const ApplicationStep4OcrPage({
    super.key,
    required this.applicationNo,
    this.cardNo,
  });

  @override
  State<ApplicationStep4OcrPage> createState() => _ApplicationStep4OcrPageState();
}

class _ApplicationStep4OcrPageState extends State<ApplicationStep4OcrPage> {
  // ====== 환경설정 ======
  static const String springBaseUrl = 'http://192.168.0.5:8090'; // << 스프링 주소:포트
  static const String aesKey = 'MySecretKey12345'; // Java AESUtil과 동일(16바이트)
  final String userNoDefault = 'user123'; // 테스트용 기본 userNo

  // ====== 상태/컨트롤 ======
  final _picker = ImagePicker();
  File? _idFile;
  File? _faceFile;

  final _frontCtrl = TextEditingController();  // 주민번호 앞 6자리
  final _genderCtrl = TextEditingController(); // 1~4
  final _tailCtrl = TextEditingController(text: '******');   // 기본 마스킹
  final _userNoCtrl = TextEditingController();

  bool _maskedMode = true; // 기본 마스킹 모드(front+gender만 비교)
  bool _loading = false;
  Map<String, dynamic>? _resultJson; // 응답 표시
  bool _pushing = false;

  @override
  void initState() {
    super.initState();
    // 스크린샷 감지(모바일에서만)
    if (!kIsWeb) {
      ScreenshotWatcher.instance.start(context);
    }
    _userNoCtrl.text = userNoDefault;
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      ScreenshotWatcher.instance.stop();
    }
    _frontCtrl.dispose();
    _genderCtrl.dispose();
    _tailCtrl.dispose();
    _userNoCtrl.dispose();
    super.dispose();
  }

  // ====== 도우미 ======
  String _encryptRrn(String rrn) {
    // AES-ECB + PKCS7 (Java AESUtil과 호환)
    final key = enc.Key.fromUtf8(aesKey);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb, padding: 'PKCS7'));
    final iv = enc.IV.fromLength(16); // ECB라 실제 사용되진 않지만 시그니처상 필요
    return encrypter.encrypt(rrn, iv: iv).base64;
  }

  Future<void> _pickId() async {
    if (kIsWeb) {
      _showSnack('웹에서는 카메라 촬영을 사용할 수 없어요.');
      return;
    }
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 92);
    if (x != null) setState(() => _idFile = File(x.path));
  }

  Future<void> _pickFace() async {
    if (kIsWeb) {
      _showSnack('웹에서는 카메라 촬영을 사용할 수 없어요.');
      return;
    }
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 92);
    if (x != null) setState(() => _faceFile = File(x.path));
  }

  void _toggleMask(bool v) {
    setState(() {
      _maskedMode = v;
      if (_maskedMode) {
        _tailCtrl.text = '******';
      } else {
        if (_tailCtrl.text == '******') _tailCtrl.clear();
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====== 업로드 & 검증 ======
  Future<void> _submit() async {
    if (_idFile == null || _faceFile == null) {
      _showSnack('신분증/셀카 이미지를 모두 촬영해 주세요.');
      return;
    }

    final front = _frontCtrl.text.trim();
    final gender = _genderCtrl.text.trim();
    String tail = _tailCtrl.text.trim();
    final userNo = _userNoCtrl.text.trim();

    if (front.length != 6 || gender.length != 1) {
      _showSnack('주민번호 형식을 확인해 주세요(앞6, 성별1).');
      return;
    }
    if (_maskedMode) {
      tail = '******';
    } else if (tail.length != 6) {
      _showSnack('뒷자리는 6자리여야 합니다.');
      return;
    }
    if (userNo.isEmpty) {
      _showSnack('userNo를 입력해 주세요.');
      return;
    }

    final expectedRrn = '$front-$gender$tail';
    final encryptedRrn = _encryptRrn(expectedRrn);

    setState(() {
      _loading = true;
      _resultJson = null;
    });

    try {
      final dio = Dio(BaseOptions(
        baseUrl: springBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
      ));

      final form = FormData.fromMap({
        'idImage': await MultipartFile.fromFile(
          _idFile!.path,
          filename: 'id_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'faceImage': await MultipartFile.fromFile(
          _faceFile!.path,
          filename: 'face_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'encryptedRrn': encryptedRrn,
        'userNo': userNo,
      });

      final resp = await dio.post('/api/verify', data: form);
      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : jsonDecode(resp.data.toString()) as Map<String, dynamic>;

      setState(() => _resultJson = data);

      final status = (data['status'] ?? '').toString().toUpperCase();
      if (status == 'PASS') {
        _showSnack('본인인증 성공! 다음 단계로 이동합니다.');
        _goStep5();
      } else if (status == 'ERROR') {
        _showSnack('서버 오류: ${data['reason'] ?? ''}');
      } else {
        _showSnack('인증 실패: ${data['reason'] ?? ''}');
      }
    } catch (e) {
      _showSnack('업로드 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goStep5() {
    if (_pushing) return;
    _pushing = true;

    Navigator.of(context, rootNavigator: true)
        .pushReplacement(
      MaterialPageRoute(
        builder: (_) => ApplicationStep5AccountPage(
          applicationNo: widget.applicationNo,
          cardNo: widget.cardNo,
        ),
      ),
    )
        .whenComplete(() => _pushing = false);
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.black87),
          title: const Text('본인인증'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        backgroundColor: Colors.white,
        body: AbsorbPointer(
          absorbing: _loading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Expanded(child: _ImageBox(
                    title: '신분증',
                    file: _idFile,
                    onPick: _pickId,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ImageBox(
                    title: '셀카',
                    file: _faceFile,
                    onPick: _pickFace,
                  )),
                ],
              ),
              const SizedBox(height: 16),
              _RrnInputs(
                frontCtrl: _frontCtrl,
                genderCtrl: _genderCtrl,
                tailCtrl: _tailCtrl,
                maskedMode: _maskedMode,
                onToggleMask: _toggleMask,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _userNoCtrl,
                decoration: const InputDecoration(
                  labelText: 'userNo (로그용)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? '전송 중...' : '인증 요청'),
                ),
              ),
              const SizedBox(height: 12),
              if (_resultJson != null) _ResultBox(data: _resultJson!),
            ]),
          ),
        ),
      ),
    );
  }
}

// ====== 위젯들 ======
class _ImageBox extends StatelessWidget {
  const _ImageBox({
    required this.title,
    required this.file,
    required this.onPick,
  });

  final String title;
  final File? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final img = file != null
        ? ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(file!, height: 140, width: double.infinity, fit: BoxFit.cover),
    )
        : Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Center(child: Text('촬영 전')),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        img,
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.camera_alt),
            label: Text('$title 촬영'),
          ),
        )
      ],
    );
  }
}

class _RrnInputs extends StatelessWidget {
  const _RrnInputs({
    required this.frontCtrl,
    required this.genderCtrl,
    required this.tailCtrl,
    required this.maskedMode,
    required this.onToggleMask,
  });

  final TextEditingController frontCtrl;
  final TextEditingController genderCtrl;
  final TextEditingController tailCtrl;
  final bool maskedMode;
  final ValueChanged<bool> onToggleMask;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: TextField(
          controller: frontCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '앞 6자리 (예: 820701)',
            border: OutlineInputBorder(),
          ),
        )),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: TextField(
            controller: genderCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '성별(1~4)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(
          controller: tailCtrl,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: '뒷 6자리 또는 ******',
            border: OutlineInputBorder(),
          ),
        )),
        const SizedBox(width: 12),
        Row(children: [
          const Text('마스킹'),
          Switch(value: maskedMode, onChanged: onToggleMask),
        ]),
      ]),
    ]);
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    final status = (data['status'] ?? '').toString().toUpperCase();
    final color = status == 'PASS' ? Colors.green : (status == 'ERROR' ? Colors.orange : Colors.red);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('결과', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Chip(label: Text(status), backgroundColor: color.withOpacity(0.1), labelStyle: TextStyle(color: color)),
          ]),
          const SizedBox(height: 8),
          Text(pretty),
        ]),
      ),
    );
  }
}
