import 'dart:async';
import 'package:flutter/material.dart';

const kBnkRed = Color(0xFFD6001C);
const kInk = Color(0xFF4A4033); // 따뜻한 잉크색
const kBg = Colors.white;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onReady});
  final Future<void> Function() onReady; // 초기화 비동기 작업 (없으면 () async {} 전달)

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _ac;       // 로고/텍스트 페이드 & 스케일
  late final AnimationController _barAC;    // 레드 바 진행(반복)
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _barWidth;   // 레드 바 애니메이션(0→1 반복)

  @override
  void initState() {
    super.initState();

    // 메인 애니메이션 (로고/텍스트)
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScale = Tween(begin: 0.86, end: 1.0)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutBack));
    _logoOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ac, curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));
    _subtitleOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ac, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    // 로딩 바 애니메이션(반복)
    _barAC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _barWidth = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _barAC, curve: Curves.easeInOut));

    _run();
  }

  Future<void> _run() async {
    _ac.forward();
    // 실제 초기화 수행
    await widget.onReady();
    // 최소 노출 시간 보장(짧게)
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    // 전환 직전 바 애니메이션 정지/꽉 채움(스냅 느낌)
    _barAC.stop();
    _barAC.value = 1.0;

    // 스플래시 닫기
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _barAC.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_ac, _barAC]),
          builder: (_, __) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BNK 워드마크(텍스트 기반)
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: const _BnkWordmark(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ⬇️ ‘하나뿐인’ 로딩 표시: 레드 진행 바
                  SizedBox(
                    width: size.width * 0.5,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _barWidth.value, // 0~1 반복
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: kBnkRed,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Opacity(
                    opacity: _subtitleOpacity.value,
                    child: const Text(
                      '부산은행 카드',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: kInk,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// BNK 워드마크(이미지 없이 벡터 느낌으로 텍스트 구성)
class _BnkWordmark extends StatelessWidget {
  const _BnkWordmark();

  @override
  Widget build(BuildContext context) {
    // 큰 “BNK” + 작은 레드 포인트
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Text(
          'BNK',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: kBnkRed,
            height: 1.0,
          ),
        ),
        Positioned(
          right: -14,
          top: 14,
          child: Transform.rotate(
            angle: 0.2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: kBnkRed,
                borderRadius: BorderRadius.only(topRight: Radius.circular(2)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
