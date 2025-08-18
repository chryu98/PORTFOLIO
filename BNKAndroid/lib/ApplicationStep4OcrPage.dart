import 'package:flutter/material.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed; // 색상만 재사용
import 'package:bnkandroid/security/secure_screen.dart';
import 'package:bnkandroid/security/screenshot_watcher.dart';

class ApplicationStep4OcrPage extends StatefulWidget {
  final int applicationNo; // ← 반드시 필요!
  const ApplicationStep4OcrPage({super.key, required this.applicationNo});

  @override
  State<ApplicationStep4OcrPage> createState() => _ApplicationStep4OcrPageState();
}

class _ApplicationStep4OcrPageState extends State<ApplicationStep4OcrPage> {
  @override
  void initState() {
    super.initState();
    // 캡처 감지 (모바일에서만 동작, 웹은 무시)
    ScreenshotWatcher.instance.start(context);
  }

  @override
  void dispose() {
    ScreenshotWatcher.instance.stop();
    super.dispose();
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
                onPressed: () {
                  // 실제 구현에선 OCR 완료 후 다음 단계/완료 화면으로 이동
                  Navigator.of(context).pop(true);
                },
                child: const Text('완료'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
