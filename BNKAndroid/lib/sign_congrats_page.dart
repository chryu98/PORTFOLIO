// lib/sign/sign_congrats_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

// 피드백 시트 (프로젝트 경로에 맞게 유지)
import '../feedback/feedback_sheet.dart';

class SignCongratsPage extends StatefulWidget {
  final int applicationNo;
  final VoidCallback onDone;

  const SignCongratsPage({
    super.key,
    required this.applicationNo,
    required this.onDone,
  });

  @override
  State<SignCongratsPage> createState() => _SignCongratsPageState();
}

class _SignCongratsPageState extends State<SignCongratsPage>
    with TickerProviderStateMixin {
  late final AnimationController _introAC;   // 체크 아이콘 등장
  late final Animation<double> _introScale;  // 0→1 탄성

  late final AnimationController _pulseAC;   // 체크 아이콘 펄스
  late final Animation<double> _pulseScale;  // 1.0↔1.07
  int _pulseCount = 0;
  static const int _pulseTarget = 5;         // 펄스 5회

  late final ConfettiController _confetti;

  // ---- 피드백 노출 제어 ----
  static const bool kAskFeedbackOnSignupEnabled = true; // 필요시 false
  static const int  kFeedbackSignupCardNo = 999001;

  bool _feedbackShown = false;  // 한 번만 보여주기
  bool _busy = false;           // 더블탭 방지

  @override
  void initState() {
    super.initState();

    // 체크 아이콘 등장 애니메이션
    _introAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _introScale = CurvedAnimation(parent: _introAC, curve: Curves.easeOutBack);
    _introAC.forward();

    // 체크 아이콘 펄스(작아졌다가 커졌다가) - 5회
    _pulseAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseAC, curve: Curves.easeInOut));

    _pulseAC.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        _pulseAC.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseCount += 1;               // forward+reverse 한 세트 = 1회
        if (_pulseCount < _pulseTarget) {
          _pulseAC.forward();
        }
      }
    });
    _pulseAC.forward();

    // 콘페티: 아주 짧게
    _confetti = ConfettiController(duration: const Duration(milliseconds: 700));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
    });
  }

  @override
  void dispose() {
    _introAC.dispose();
    _pulseAC.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _goHomeSafe() {
    // 1차: 콜백 사용 (호출자가 라우팅 정의)
    try {
      widget.onDone();
    } catch (_) {
      // ignore
    }
    // 2차 안전망: 루트 네비게이터로 홈 이동
    if (mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/home', (r) => false);
    }
  }

  Future<void> _handleDonePressed() async {
    if (_busy) return;
    _busy = true;

    // 첫 클릭이면 피드백 1회 노출만 하고, 닫히면 다시 누를 수 있게 만든다 (자동 이동 없음)
    if (kAskFeedbackOnSignupEnabled && !_feedbackShown) {
      try {
        await showFeedbackSheet(
          context,
          cardNo: kFeedbackSignupCardNo,
          userNo: null,
        );
      } catch (_) {
        // 취소/에러여도 그대로 진행
      } finally {
        setState(() {
          _feedbackShown = true; // 다음 클릭부터는 바로 메인으로
          _busy = false;         // 다시 누를 수 있게 해제
        });
      }
      return; // 첫 클릭은 여기서 종료(자동 이동 X)
    }

    // 이미 피드백을 보여준 상태면 즉시 메인 이동
    _goHomeSafe();
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    const bnkRed = Color(0xFFE60012);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.09,
              numberOfParticles: 14,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: 0.28,
              shouldLoop: false,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // intro(등장) * pulse(펄스) 중첩
                  ScaleTransition(
                    scale: _introScale,
                    child: ScaleTransition(
                      scale: _pulseScale,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: bnkRed.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: bnkRed.withOpacity(0.2)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 86,
                            color: bnkRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '축하합니다!\n가입이 완료되었습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '신청번호: ${widget.applicationNo}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _handleDonePressed,
                      child: const Text('메인으로'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
