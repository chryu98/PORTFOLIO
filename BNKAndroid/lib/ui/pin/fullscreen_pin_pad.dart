// lib/ui/pin/fullscreen_pin_pad.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FullscreenPinPad {
  /// 전면 모달로 6자리 PIN 입력을 받습니다.
  /// - [confirm] true면 2회 입력 확인
  /// - [birthYmd] 생년월일(YYYYMMDD 또는 YYMMDD) 금지
  static Future<String?> open(
      BuildContext context, {
        String title = '비밀번호를 입력해주세요',
        bool confirm = false,
        int length = 6,
        String? birthYmd,
        Color accent = const Color(0xFFB91111), // BNK red
      }) {
    return Navigator.of(context).push<String>(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => _PinFullscreenPage(
          title: title,
          confirm: confirm,
          length: length,
          birthYmd: birthYmd,
          accent: accent,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }
}

class _PinFullscreenPage extends StatefulWidget {
  final String title;
  final bool confirm;
  final int length;
  final String? birthYmd;
  final Color accent;

  const _PinFullscreenPage({
    required this.title,
    required this.confirm,
    required this.length,
    required this.birthYmd,
    required this.accent,
  });

  @override
  State<_PinFullscreenPage> createState() => _PinFullscreenPageState();
}

class _PinFullscreenPageState extends State<_PinFullscreenPage> {
  int step = 1;
  final List<int> digits = [];
  String? first;
  String? error;

  // 초기 배치(토스 느낌)
  List<int> grid = const [1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  void initState() {
    super.initState();
    _shuffle(); // 시작부터 셔플
  }

  void _shuffle() {
    final list = List<int>.generate(9, (i) => i + 1)..shuffle();
    setState(() => grid = list);
  }

  void _push(int v) {
    if (digits.length >= widget.length) return;
    HapticFeedback.lightImpact();
    setState(() {
      error = null;
      digits.add(v);
    });
    if (digits.length == widget.length) _autoSubmit();
  }

  void _pop() {
    if (digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      error = null;
      digits.removeLast();
    });
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  // 규칙 금지: 생년월일, 3연속 동일, 연속증가/감소(>=5), 000000
  bool _isForbidden(String s) {
    // 000000
    if (RegExp(r'^0+$').hasMatch(s)) return true;

    // 3개 이상 동일 숫자 연속
    if (RegExp(r'(.)\1\1').hasMatch(s)) return true;

    // 증가/감소 연속 시퀀스(5자리 이상)
    bool _isSeq(String t) {
      bool inc = true, dec = true;
      for (int i = 1; i < t.length; i++) {
        if (t.codeUnitAt(i) != t.codeUnitAt(i - 1) + 1) inc = false;
        if (t.codeUnitAt(i) != t.codeUnitAt(i - 1) - 1) dec = false;
      }
      return inc || dec;
    }
    for (int i = 0; i <= s.length - 5; i++) {
      if (_isSeq(s.substring(i, i + 5))) return true;
    }

    // 생년월일(YYMMDD / YYYYMMDD의 뒤 6자리) 금지
    final b = widget.birthYmd?.replaceAll(RegExp(r'\D'), '');
    if (b != null && b.isNotEmpty) {
      final yy6 = (b.length >= 6) ? b.substring(b.length - 6) : null;
      if (s == yy6) return true;
      if (b.length == 8) {
        // 8자리 전체도 혹시 쓰지 않도록(앞 6/뒤 6)
        final front6 = b.substring(0, 6);
        if (s == front6) return true;
      }
    }
    return false;
  }

  Future<void> _autoSubmit() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final cur = digits.join();

    if (_isForbidden(cur)) {
      setState(() {
        error = '사용할 수 없는 조합입니다.\n(생년월일·연속·반복 숫자 금지)';
        digits.clear();
      });
      return;
    }

    if (step == 1 && widget.confirm) {
      setState(() {
        first = cur;
        step = 2;
        digits.clear();
        error = null;
      });
      return;
    }

    if (step == 2 && widget.confirm) {
      if (first != cur) {
        setState(() {
          error = '두 입력이 일치하지 않아요. 다시 입력해주세요.';
          first = null;
          step = 1;
          digits.clear();
        });
        return;
      }
    }

    Navigator.of(context).pop(cur);
  }

  @override
  Widget build(BuildContext context) {
    final filled = digits.length;
    final l = widget.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _cancel,
        ),
        backgroundColor: Colors.white,
        elevation: 0.4,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(height: 3, width: 72, color: widget.accent.withOpacity(.2)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              step == 1 ? widget.title : '한번 더 입력해주세요',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            // ●●●●●●
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(l, (i) {
                final isFilled = i < filled;
                return Container(
                  width: 14, height: 14, margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? widget.accent : const Color(0xFFE3E6EA),
                  ),
                );
              }),
            ),

            if (error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],

            const Spacer(),

            // 숫자 키패드 (3x4)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _NumberPad(
                grid: grid,
                accent: const Color(0xFFD9D9D9),
                onPressed: _push,
                onBackspace: _pop,
                onShuffle: _shuffle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final List<int> grid; // 1..9 셔플된 배열
  final ValueChanged<int> onPressed;
  final VoidCallback onBackspace;
  final VoidCallback onShuffle;
  final Color accent;

  const _NumberPad({
    required this.grid,
    required this.onPressed,
    required this.onBackspace,
    required this.onShuffle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ...grid,
      -1, // shuffle
      0,
      -2, // backspace
    ];

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final spacing = 10.0;
      final itemW = (w - spacing * 2) / 3;
      final itemH = itemW * .78; // 카드처럼 낮게

      Widget buildBtn(int v) {
        final enabled = v >= 0 || v == -1 || v == -2;
        Widget? child;
        VoidCallback? onTap;

        if (v >= 0) {
          child = Text('$v', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700));
          onTap = () => onPressed(v);
        } else if (v == -1) {
          child = const Text('재배열', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
          onTap = onShuffle;
        } else if (v == -2) {
          child = const Icon(Icons.backspace_outlined, size: 22);
          onTap = onBackspace;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Container(
            width: itemW,
            height: itemH,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent, width: 1),
            ),
            child: child,
          ),
        );
      }

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: keys.map(buildBtn).toList(),
      );
    });
  }
}
