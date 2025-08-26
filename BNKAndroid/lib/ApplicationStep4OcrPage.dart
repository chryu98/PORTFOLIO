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

    // OCR 호출 → 잠금 카드 자동 채움 (기능 변경 없음)
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
      _resultJson = null; // 초기화
    });

    try {
      final api = ApiClient(baseUrl: springBaseUrl);
      final resp = await api.sendVerification(
        idImage: _idFile!,
        faceImage: _faceFile!,
        applicationNo: widget.applicationNo,
      );

      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : jsonDecode(resp.data.toString()) as Map<String, dynamic>;

      final status = (data['status'] ?? '').toString().toUpperCase();
      final isPass = status == 'PASS';

      // ✅ PASS일 때만 하단 결과박스에 보여주도록 세팅
      if (mounted) {
        setState(() => _resultJson = isPass ? data : null);
      }

      if (isPass) {
        _showSnack('본인인증 성공! 다음 단계로 이동합니다.');
        _goStep5();
      } else {
        // 실패 정보는 사용자에게 노출하지 않고 모달만
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
        appBar: AppBar(

          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: _loading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 안내 문구 (디자인만 추가)
                    const SizedBox(height: 6),
                    const Text(
                      '본인 인증이 필요해요',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),

                    // ▶ 큰 카드 1: 신분증
                    _UploadCard(
                      title: '신분증 사진 업로드',
                      subtitle: '주민등록증 • 운전면허증',
                      file: _idFile,
                      onTap: _captureId,
                    ),
                    const SizedBox(height: 16),

                    // ▶ 큰 카드 2: 얼굴
                    _UploadCard(
                      title: '실시간 얼굴 사진 업로드',
                      subtitle: '정면에서 촬영해 주세요',
                      file: _faceFile,
                      onTap: _captureFace,
                    ),

                    const SizedBox(height: 20),

                    // 주민번호 잠금 표시(기능 유지)
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

                    const SizedBox(height: 24),

                    // 하단 “다음” 버튼(동작은 _submit 그대로)
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(_loading ? '전송 중...' : '다음'),
                      ),
                    ),

                    const SizedBox(height: 12),
                    if (_resultJson != null &&
                        ((_resultJson!['status'] ?? '').toString().toUpperCase() == 'PASS'))
                      _ResultBox(data: _resultJson!),
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
        backgroundColor: const Color(0xFFF5F7F8),
      ),
    );
  }
}

/// 업로드 카드(탭해서 촬영/선택). 파일이 있으면 미리보기, 없으면 안내문구.
class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: file == null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_a_photo_outlined, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      )
          : ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file!, fit: BoxFit.cover),
            // 우상단 변경 아이콘(시각적 보조 – 기능은 동일하게 onTap)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('다시 촬영', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: base,
    );
  }
}

/// 주민번호 잠금표시 + 보기 토글 (기능 그대로)
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
        color: Colors.white,
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
        color: Colors.white,
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
