import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'ApplicationStep1Page.dart' show kPrimaryRed;
import 'package:bnkandroid/security/secure_screen.dart';
import 'package:bnkandroid/security/screenshot_watcher.dart';
import 'ApplicationStep5AccountPage.dart' hide kPrimaryRed;

import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/api_client.dart';
import 'widgets/guided_camera_page.dart';

class ApplicationStep4OcrPage extends StatefulWidget {
  const ApplicationStep4OcrPage({super.key, required this.applicationNo, required this.cardNo});
  final int applicationNo;
  final int cardNo;

  @override
  State<ApplicationStep4OcrPage> createState() => _ApplicationStep4OcrPageState();
}

class _ApplicationStep4OcrPageState extends State<ApplicationStep4OcrPage> {
  // ==== Config ====
  static const String springBaseUrl = 'http://192.168.0.5:8090';

  // ==== State ====
  File? _idFile;
  File? _faceFile;

  // OCR 표시용(수정 불가)
  String _front = '';
  String _gender = '';
  String _tail = '******';
  bool _masked = true;      // tail 마스킹 여부
  bool _revealTail = false; // 뒷자리 보기 토글

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
    super.dispose();
  }

  Future<bool> _ensureCamera() async {
    final st = await Permission.camera.request();
    if (st.isPermanentlyDenied) {
      _showSnack('설정에서 카메라 권한을 허용해 주세요.');
      openAppSettings();
      return false;
    }
    return st.isGranted;
  }

  void _showSnack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // 실패 모달(고정 문구, 관리자 느낌의 깔끔한 스타일)
  Future<void> _showVerifyFailDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: kPrimaryRed),
            const SizedBox(width: 8),
            const Text('인증 실패', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('얼굴인증에 실패했습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: kPrimaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // --- 신분증 촬영 + OCR 자동 채움 ---
  Future<void> _captureId() async {
    if (kIsWeb) {
      _showSnack('웹은 카메라 촬영을 지원하지 않아요.');
      return;
    }
    if (!await _ensureCamera()) return;

    final file = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const GuidedCameraPage(mode: GuidedMode.idCard)),
    );
    if (file == null) return;

    setState(() => _idFile = file);

    // OCR 호출 → 잠금 카드 자동 채움
    try {
      setState(() {
        _loading = true;
        _revealTail = false;
      });
      final api = ApiClient(baseUrl: springBaseUrl);
      final resp = await api.ocrIdOnly(idImage: file);

      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : jsonDecode(resp.data.toString()) as Map<String, dynamic>;

      if ((data['status'] ?? '') == 'OK') {
        final ocr = (data['ocr'] ?? {}) as Map<String, dynamic>;
        final front  = (ocr['front']  ?? '').toString();
        final gender = (ocr['gender'] ?? '').toString();
        final tail   = (ocr['tail']   ?? '').toString();
        final masked = (ocr['masked'] ?? true) == true;

        setState(() {
          _front  = front;
          _gender = gender;
          _tail   = masked ? '******' : (tail.isEmpty ? '******' : tail);
          _masked = masked || _tail == '******';
        });
        _showSnack('자동 채움 완료');
      } else {
        _showSnack('인증 실패: ${data['reason'] ?? ''}');
      }
    } catch (e) {
      _showSnack('OCR 호출 오류: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // --- 얼굴 촬영 ---
  Future<void> _captureFace() async {
    if (kIsWeb) {
      _showSnack('웹은 카메라 촬영을 지원하지 않아요.');
      return;
    }
    if (!await _ensureCamera()) return;

    final file = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const GuidedCameraPage(mode: GuidedMode.face)),
    );
    if (file == null) return;

    setState(() => _faceFile = file);
  }

  // --- 제출 ---
  Future<void> _submit() async {
    if (_idFile == null || _faceFile == null) {
      _showSnack('신분증/얼굴 이미지를 모두 촬영해 주세요.');
      return;
    }
    if (_front.length != 6 || _gender.isEmpty) {
      _showSnack('OCR 인식 실패: 신분증을 다시 촬영해 주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _resultJson = null;
    });

    try {
      final api = ApiClient(baseUrl: springBaseUrl);
      final resp = await api.sendVerification(
        idImage: _idFile!,
        faceImage: _faceFile!,
        applicationNo: widget.applicationNo, // ✅ 서버가 DB에서 주민번호를 조회
      );

      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : jsonDecode(resp.data.toString()) as Map<String, dynamic>;

      setState(() => _resultJson = data);

      final status = (data['status'] ?? '').toString().toUpperCase();
      if (status == 'PASS') {
        _showSnack('본인인증 성공! 다음 단계로 이동합니다.');
        _goStep5();
      } else {
        // ✅ 실패 시에는 사유/수치 노출 금지, 모달만 표시
        debugPrint('VERIFY FAIL (hidden to user): ${data['reason'] ?? data}');
        await _showVerifyFailDialog();
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
          applicationNo: widget.applicationNo,
          cardNo: widget.cardNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('본인인증')),
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: _loading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 미리보기 썸네일: 신분증(가로 비율), 얼굴(세로 비율)
                    Row(children: [
                      Expanded(
                        child: _ThumbBox(
                          title: '신분증',
                          file: _idFile,
                          onPick: _captureId,
                          aspectRatio: 4 / 3, // 가로형
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ThumbBox(
                          title: '얼굴',
                          file: _faceFile,
                          onPick: _captureFace,
                          aspectRatio: 3 / 4, // 세로형
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // OCR 잠금 표시
                    _RrnLockedCard(
                      front: _front,
                      gender: _gender.isNotEmpty ? _gender[0] : '',
                      tail: _tail,
                      masked: _masked,
                      revealTail: _revealTail,
                      onToggleReveal: () {
                        final hasRealTail = !_masked && _tail.length == 6 && _tail != '******';
                        if (!hasRealTail) {
                          _showSnack('마스킹 상태라 뒷자리를 표시할 수 없습니다.');
                          return;
                        }
                        setState(() => _revealTail = !_revealTail);
                      },
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(_loading ? '전송 중...' : '인증 요청'),
                      ),
                    ),

                    const SizedBox(height: 12),
                    if (_resultJson != null) _ResultBox(data: _resultJson!),
                  ],
                ),
              ),
            ),

            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 공용 썸네일(원하는 가로세로 비율로 표시)
class _ThumbBox extends StatelessWidget {
  const _ThumbBox({
    required this.title,
    required this.file,
    required this.onPick,
    required this.aspectRatio,
  });

  final String title;
  final File? file;
  final VoidCallback onPick;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final child = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: const Color(0xFFF5F5F5),
          child: file != null
              ? Image.file(file!, fit: BoxFit.cover)
              : const Center(child: Text('촬영 전')),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.camera_alt),
            label: Text('$title 촬영'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

/// 주민번호 잠금표시 + 보기 토글
class _RrnLockedCard extends StatelessWidget {
  const _RrnLockedCard({
    required this.front,
    required this.gender,
    required this.tail,
    required this.masked,
    required this.revealTail,
    required this.onToggleReveal,
  });

  final String front;
  final String gender;
  final String tail;
  final bool masked;
  final bool revealTail;
  final VoidCallback onToggleReveal;

  String _maskedTail(String _) => '******';

  @override
  Widget build(BuildContext context) {
    final f = front.length == 6 ? front : '------';
    final g = gender.isNotEmpty ? gender[0] : '-';
    final hasRealTail = !masked && tail.length == 6 && tail != '******';
    final shownTail = (hasRealTail && revealTail) ? tail : _maskedTail(tail);
    final rrnText = '$f-$g$shownTail';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock, size: 18),
            const SizedBox(width: 6),
            const Text('주민등록번호', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              tooltip: hasRealTail ? (revealTail ? '가리기' : '보기') : '표시 불가',
              onPressed: hasRealTail ? onToggleReveal : null,
              icon: Icon(revealTail ? Icons.visibility_off : Icons.visibility),
            ),
          ]),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(
              rrnText,
              style: const TextStyle(
                fontSize: 16,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Chip(
              label: Text(masked ? '마스킹 상태' : (hasRealTail ? '전체 인식' : '부분 인식')),
              backgroundColor: Colors.grey.shade200,
            ),
          ]),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString().toUpperCase();

    // ✅ 실패 시에는 상세 JSON(예: loss/이유) 노출 금지
    final bool isPass = status == 'PASS';
    final String pretty = isPass
        ? const JsonEncoder.withIndent('  ').convert(data)
        : '얼굴인증에 실패했습니다.';

    final Color color = isPass
        ? Colors.green
        : (status == 'ERROR' ? Colors.orange : Colors.red);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('결과', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Chip(
                label: Text(status),
                backgroundColor: color.withOpacity(0.1),
                labelStyle: TextStyle(color: color),
              ),
            ]),
            const SizedBox(height: 8),
            Text(pretty),
          ],
        ),
      ),
    );
  }
}
