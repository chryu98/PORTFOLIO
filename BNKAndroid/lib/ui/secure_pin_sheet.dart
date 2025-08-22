// lib/ui/secure_pin_sheet.dart
import 'package:flutter/material.dart';

typedef PinValidator = String? Function(String pin);

enum PadStyle { card, flat }

class SecurePinSheet extends StatefulWidget {
  final String title1;
  final String title2;
  final bool requireConfirm;     // 신규 생성: true, 기존 인증: false
  final int minLen;              // 6으로 고정 사용 추천
  final int maxLen;              // 6으로 고정 사용 추천
  final PadStyle padStyle;       // card: 타일형(스샷 느낌), flat: 평면형
  final bool bankLayout;         // 하단을 "* 0 #" 로
  final bool enableShuffle;      // 숫자 재배열(은행 UI면 보통 false)
  final Duration autoDelay;
  final Color accent;            // 점/아이콘 색
  final Color padColor;          // 키패드 배경
  final PinValidator? policyValidator;

  const SecurePinSheet({
    super.key,
    required this.title1,
    required this.title2,
    this.requireConfirm = true,
    this.minLen = 6,
    this.maxLen = 6,
    this.padStyle = PadStyle.card,
    this.bankLayout = true,
    this.enableShuffle = false,
    this.autoDelay = const Duration(milliseconds: 120),
    this.accent = const Color(0xFFB91111),
    this.padColor = const Color(0xFFE9ECEF),
    this.policyValidator,
  });

  @override
  State<SecurePinSheet> createState() => _SecurePinSheetState();
}

class _SecurePinSheetState extends State<SecurePinSheet> {
  int _step = 1;
  final List<int> _digits = [];
  String? _first;
  String? _error;

  // 초기 배치(1~9 순서)
  List<int> _grid = const [1,2,3,4,5,6,7,8,9];
  void _shuffle() {
    final list = List<int>.generate(9, (i) => i + 1)..shuffle();
    setState(() => _grid = list);
  }

  void _push(int v) {
    if (_digits.length >= widget.maxLen) return;
    setState(() { _digits.add(v); _error = null; });
    if (_digits.length == widget.maxLen) {
      _autoMaybeSubmit();
    }
  }

  void _pop() {
    if (_digits.isEmpty) return;
    setState(() { _digits.removeLast(); _error = null; });
  }

  Future<void> _autoMaybeSubmit() async {
    await Future.delayed(widget.autoDelay);
    if (!mounted) return;
    await _submit();
  }

  Future<void> _submit() async {
    if (_digits.length < widget.minLen) return;
    final cur = _digits.join();

    // 정책 검사
    final msg = widget.policyValidator?.call(cur);
    if (msg != null) {
      setState(() {
        _error = msg;
        _digits.clear();
        _step = 1;
        _first = null;
      });
      return;
    }

    if (_step == 1 && widget.requireConfirm) {
      setState(() { _first = cur; _step = 2; _digits.clear(); _error = null; });
      return;
    }

    if (widget.requireConfirm && _first != cur) {
      setState(() {
        _error = '입력값이 일치하지 않습니다. 다시 입력해주세요.';
        _digits.clear(); _step = 1; _first = null;
      });
      return;
    }

    Navigator.of(context).pop<String>(cur);
  }

  @override
  Widget build(BuildContext context) {
    final dots = _digits.length;

    return FractionallySizedBox(
      heightFactor: 0.46,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(blurRadius: 16, color: Color(0x1A000000))],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 44, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(_step == 1 ? widget.title1 : widget.title2,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.maxLen, (i) {
                  final filled = i < dots;
                  return Container(
                    width: 10, height: 10, margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? widget.accent : const Color(0xFFE3E6EA),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: (widget.padStyle == PadStyle.card)
                    ? _buildCardPad()
                    : _buildFlatPad(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==== 카드형(스샷 느낌의 타일) ====
  Widget _buildCardPad() {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final avail = c.maxHeight - (gap * 3) - 12 - 12;
        final keyH = (avail / 4).clamp(52.0, 70.0);

        Widget tile(Widget child, {VoidCallback? onTap, bool primary = false}) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Container(
                  height: keyH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary ? widget.accent : const Color(0xFFE7EAF0)),
                    boxShadow: const [BoxShadow(blurRadius: 2, color: Color(0x14000000))],
                  ),
                  child: child,
                ),
              ),
            ),
          );
        }

        Widget numKey(int n) => tile(
          Text('$n', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          onTap: () => _push(n),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          color: widget.padColor,
          child: Column(
            children: [
              Row(children: _grid.sublist(0,3).map(numKey).toList()),
              const SizedBox(height: gap),
              Row(children: _grid.sublist(3,6).map(numKey).toList()),
              const SizedBox(height: gap),
              Row(children: _grid.sublist(6,9).map(numKey).toList()),
              const SizedBox(height: gap),
              Row(
                children: widget.bankLayout
                    ? [
                  // * : 삭제
                  tile(const Text('*', style: TextStyle(fontSize: 22)),
                      onTap: _pop),
                  // 0
                  numKey(0),
                  // # : 확인
                  tile(const Text('#', style: TextStyle(fontSize: 22)),
                      onTap: (_digits.length >= widget.minLen) ? _submit : null,
                      primary: true),
                ]
                    : [
                  tile(const Text('재배열'), onTap: widget.enableShuffle ? _shuffle : null),
                  numKey(0),
                  tile(const Icon(Icons.backspace_outlined), onTap: _pop),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==== 평면형(선택) ====
  Widget _buildFlatPad() => Container(
    decoration: BoxDecoration(
      color: widget.padColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: const Center(child: Text('flat pad (미사용)')),
  );
}
