import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed;
import 'package:bnkandroid/security/secure_screen.dart';
import 'package:bnkandroid/security/screenshot_watcher.dart';
import 'ApplicationStep5AccountPage.dart' hide kPrimaryRed;

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:permission_handler/permission_handler.dart';

import 'services/api_client.dart';
import 'widgets/guided_camera_page.dart';

class ApplicationStep4OcrPage extends StatefulWidget {
  const ApplicationStep4OcrPage({super.key, required this.applicationNo, this.cardNo});
  final int applicationNo;
  final int? cardNo;

  @override
  State<ApplicationStep4OcrPage> createState() => _ApplicationStep4OcrPageState();
}

class _ApplicationStep4OcrPageState extends State<ApplicationStep4OcrPage> {
  // ===== Config =====
  static const String springBaseUrl = 'http://192.168.0.5:8090';
  static const String aesKey = 'MySecretKey12345';

  // ===== State =====
  File? _idFile;
  File? _faceFile;

  // 자동채움 대상(읽기전용 기본)
  final _frontCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _tailCtrl = TextEditingController(text: '******');
  final _userNoCtrl = TextEditingController(text: 'user123');

  bool _maskedMode = true;   // OCR가 tail을 ******로 주면 true
  bool _editable = false;    // 수동수정 허용 toggle
  bool _loading = false;
  Map<String, dynamic>? _resultJson;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      ScreenshotWatcher.instance.start(context);
    }
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

  Future<bool> _ensureCamera() async {
    final st = await Permission.camera.request();
    return st.isGranted;
  }

  void _showSnack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _encryptRrn(String rrn) {
    final key = enc.Key.fromUtf8(aesKey);
    final ency = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb, padding: 'PKCS7'));
    return ency.encrypt(rrn, iv: enc.IV.fromLength(16)).base64;
  }

  Future<void> _captureId() async {
    if (kIsWeb) {
      _showSnack('웹은 카메라 촬영을 지원하지 않아요.');
      return;
    }
    if (!await _ensureCamera()) {
      _showSnack('카메라 권한이 필요합니다.');
      return;
    }
    final file = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const GuidedCameraPage(mode: GuidedMode.idCard)),
    );
    if (file == null) return;
    setState(() => _idFile = file);

    // ✅ OCR 호출 → 자동 채움
    try {
      setState(() => _loading = true);
      final api = ApiClient(baseUrl: springBaseUrl);
      final resp = await api.ocrIdOnly(idImage: file);
      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : jsonDecode(resp.data.toString()) as Map<String, dynamic>;

      if ((data['status'] ?? '') == 'OK') {
        final ocr = (data['ocr'] ?? {}) as Map<String, dynamic>;
        final front = (ocr['front'] ?? '').toString();
        final gender = (ocr['gender'] ?? '').toString();
        final tail = (ocr['tail'] ?? '').toString();
        final masked = (ocr['masked'] ?? true) == true;

        setState(() {
          _frontCtrl.text = front;
          _genderCtrl.text = gender;
          _tailCtrl.text = masked ? '******' : tail;
          _maskedMode = masked;
          _editable = false; // 기본은 자동값 그대로 사용
        });
        _showSnack('OCR 자동 채움 완료');
      } else {
        _showSnack('OCR 실패: ${data['reason'] ?? ''}');
        _editable = true; // 실패 시 수동 입력 허용
        setState(() {});
      }
    } catch (e) {
      _showSnack('OCR 호출 오류: $e');
      setState(() => _editable = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _captureFace() async {
    if (kIsWeb) {
      _showSnack('웹은 카메라 촬영을 지원하지 않아요.');
      return;
    }
    if (!await _ensureCamera()) {
      _showSnack('카메라 권한이 필요합니다.');
      return;
    }
    final file = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const GuidedCameraPage(mode: GuidedMode.face)),
    );
    if (file == null) return;
    setState(() => _faceFile = file);
  }

  Future<void> _submit() async {
    if (_idFile == null || _faceFile == null) {
      _showSnack('신분증/얼굴 이미지를 모두 촬영해 주세요.');
      return;
    }
    final front = _frontCtrl.text.trim();
    final gender = _genderCtrl.text.trim();
    final userNo = _userNoCtrl.text.trim();
    String tail = _tailCtrl.text.trim();

    if (front.length != 6 || gender.length != 1) {
      _showSnack('주민번호 앞6/성별1 확인');
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

    final expected = '$front-$gender$tail';
    final encryptedRrn = _encryptRrn(expected);

    setState(() {
      _loading = true;
      _resultJson = null;
    });

    try {
      final api = ApiClient(baseUrl: springBaseUrl);
      final resp = await api.sendVerification(
        idImage: _idFile!, faceImage: _faceFile!, encryptedRrn: encryptedRrn, userNo: userNo,
      );
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
    } on DioException catch (e) {
      _showSnack('업로드 오류: ${e.message}');
    } catch (e) {
      _showSnack('업로드 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goStep5() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ApplicationStep5AccountPage(
          applicationNo: widget.applicationNo, cardNo: widget.cardNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('본인인증'),
          actions: [
            TextButton.icon(
              onPressed: () => setState(() => _editable = !_editable),
              icon: Icon(_editable ? Icons.lock_open : Icons.lock, size: 18),
              label: Text(_editable ? '수정 중' : '자동값', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _loading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _ImageBox(title: '신분증', file: _idFile, onPick: _captureId)),
                const SizedBox(width: 12),
                Expanded(child: _ImageBox(title: '얼굴', file: _faceFile, onPick: _captureFace)),
              ]),
              const SizedBox(height: 16),
              _RrnForm(
                frontCtrl: _frontCtrl,
                genderCtrl: _genderCtrl,
                tailCtrl: _tailCtrl,
                maskedMode: _maskedMode,
                setMasked: (v) => setState(() => _maskedMode = v),
                readOnly: !_editable,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _userNoCtrl,
                decoration: const InputDecoration(
                  labelText: 'userNo (로그용)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48, width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryRed, foregroundColor: Colors.white),
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

class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.title, required this.file, required this.onPick});
  final String title; final File? file; final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final child = file != null
        ? ClipRRect(borderRadius: BorderRadius.circular(8),
        child: Image.file(file!, height: 140, width: double.infinity, fit: BoxFit.cover))
        : Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Center(child: Text('촬영 전')),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      child,
      const SizedBox(height: 8),
      SizedBox(width: double.infinity,
          child: OutlinedButton.icon(onPressed: onPick, icon: const Icon(Icons.camera_alt), label: Text('$title 촬영'))),
    ]);
  }
}

class _RrnForm extends StatelessWidget {
  const _RrnForm({
    required this.frontCtrl, required this.genderCtrl, required this.tailCtrl,
    required this.maskedMode, required this.setMasked, required this.readOnly,
  });

  final TextEditingController frontCtrl, genderCtrl, tailCtrl;
  final bool maskedMode, readOnly;
  final ValueChanged<bool> setMasked;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: TextField(
          controller: frontCtrl, readOnly: readOnly, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '앞 6자리', border: OutlineInputBorder()),
        )),
        const SizedBox(width: 12),
        SizedBox(width: 120, child: TextField(
          controller: genderCtrl, readOnly: readOnly, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '성별(1~4)', border: OutlineInputBorder()),
        )),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(
          controller: tailCtrl, readOnly: readOnly || maskedMode, keyboardType: TextInputType.text,
          decoration: const InputDecoration(labelText: '뒷 6자리 또는 ******', border: OutlineInputBorder()),
        )),
        const SizedBox(width: 12),
        Row(children: [
          const Text('마스킹'),
          Switch(value: maskedMode, onChanged: readOnly ? null : setMasked),
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
      width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E0E0)), borderRadius: BorderRadius.circular(8)),
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
