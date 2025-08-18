// lib/ApplicationStep4OcrDummyPage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bnkandroid/security/secure_screen.dart';
// ↓ 알림까지 원하면 주석 해제하시고 initState/dispose에서 start/stop 호출
// import 'package:bnkandroid/security/screenshot_watcher.dart';

const kPrimaryRed = Color(0xffB91111);

class ApplicationStep4OcrDummyPage extends StatefulWidget {
  /// 이전 단계에서 받은 신청번호(로그 등 표시에만 사용. 필수 아님)
  final int? applicationNo;

  /// 다음으로 보낼 화면이 있으면 지정. 없으면 pop(true)로 끝냄.
  final WidgetBuilder? nextBuilder;

  const ApplicationStep4OcrDummyPage({
    super.key,
    this.applicationNo,
    this.nextBuilder,
  });

  @override
  State<ApplicationStep4OcrDummyPage> createState() => _ApplicationStep4OcrDummyPageState();
}

class _ApplicationStep4OcrDummyPageState extends State<ApplicationStep4OcrDummyPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 스크린샷 시도 알림까지 원하면 사용
    // ScreenshotWatcher.instance.start(context);
  }

  @override
  void dispose() {
    // ScreenshotWatcher.instance.stop();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await Future.delayed(const Duration(milliseconds: 400)); // 더미 대기 (OCR 흉내)
      if (!mounted) return;

      if (widget.nextBuilder != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: widget.nextBuilder!),
        );
      } else {
        // 다음 화면 지정이 없으면, 성공값만 반환하며 닫기
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen( // 캡처 방지
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) return;
          FocusManager.instance.primaryFocus?.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).maybePop();
            }
          });
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).maybePop();
                  }
                });
              },
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: const Text('본인 확인 (더미)', style: TextStyle(color: Colors.black87)),
            centerTitle: false,
          ),
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                const _StepHeader(current: 4, total: 4),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 더미 OCR 가이드 카드
                        Container(
                          width: 300,
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6E8EE)),
                          ),
                          child: Stack(
                            children: [
                              // 가이드 프레임
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: 240,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFB9C2D0),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                ),
                              ),
                              // 아이디/카메라 아이콘
                              const Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.badge_outlined, size: 56, color: Color(0xFF9AA3AF)),
                              ),
                              const Positioned(
                                right: 16,
                                bottom: 16,
                                child: Icon(Icons.photo_camera_outlined, size: 28, color: Color(0xFF9AA3AF)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '신분증을 프레임에 맞춰주세요\n(현재는 더미 단계로 “다음”을 누르면 넘어갑니다)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                        ),
                        if (widget.applicationNo != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '신청번호: ${widget.applicationNo}',
                            style: const TextStyle(fontSize: 12, color: Colors.black38),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _busy ? null : _goNext,
                  child: _busy
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('다음'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 상단 단계 표시(4단계 기준)
class _StepHeader extends StatelessWidget {
  final int current;
  final int total;
  const _StepHeader({required this.current, this.total = 4});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = (i + 1) <= current;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            color: active ? kPrimaryRed : const Color(0xFFE5E5E5),
          ),
        );
      }),
    );
  }
}
