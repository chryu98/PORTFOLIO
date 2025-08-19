import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed; // 색상만 재사용
import 'package:bnkandroid/security/secure_screen.dart';
import 'package:bnkandroid/security/screenshot_watcher.dart';

// ✅ Step5 화면
import 'ApplicationStep5AccountPage.dart' hide kPrimaryRed;

class ApplicationStep4OcrPage extends StatefulWidget {
  final int applicationNo; // 반드시 필요
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
  bool _pushing = false;

  @override
  void initState() {
    super.initState();
    // ✅ 웹에서는 미지원 플러그인 예외 방지
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

  void _goStep5() {
    if (_pushing) return;
    _pushing = true;

    Navigator.of(context, rootNavigator: true)
        .pushReplacement(
      MaterialPageRoute(
        builder: (_) => ApplicationStep5AccountPage(
          applicationNo: widget.applicationNo,
          cardNo: widget.cardNo, // ✅ 선택한 카드번호가 있다면 그대로 전달(null 허용)
        ),
      ),
    )
        .whenComplete(() {
      _pushing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen( // 캡처 방지(모바일에서 의미 있음)
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.black87),
          title: const Text('본인인증 (더미)'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, size: 80, color: kPrimaryRed),
              const SizedBox(height: 12),
              Text('신청번호: ${widget.applicationNo}'),
              if (widget.cardNo != null) ...[
                const SizedBox(height: 4),
                Text('카드번호: ${widget.cardNo}'),
              ],
              const SizedBox(height: 8),
              const Text('여기에 OCR/본인인증 화면이 들어갑니다. (더미)'),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _goStep5, // ✅ Step5로 이동
                child: const Text('다음'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
