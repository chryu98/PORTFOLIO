// lib/widgets/secure_pin_sheet.dart
import 'package:flutter/material.dart';

enum PadStyle { card, flat }

class SecurePinSheet extends StatefulWidget {
  final String title1;
  final String title2;
  final int minLen;
  final int maxLen;

  // 색상 커스터마이즈 (기본값은 네이비 팔레트)
  final Color accent;   // 점/아이콘
  final Color padColor; // 키패드 배경

  final bool requireConfirm;        // 신규: true, 기존: false
  final bool autoSubmitOnMaxLen;    // maxLen 채우면 자동 진행
  final Duration autoDelay;         // 점(●) 채움 연출
  final PadStyle padStyle;          // flat(추천) / card
  final bool enableShuffle;         // '재배열' 사용

  const SecurePinSheet({
    super.key,
    required this.title1,
    required this.title2,
    this.minLen = 4,
    this.maxLen = 6,
    this.accent   = const Color(0xFF102A56), // 깊은 네이비
    this.padColor = const Color(0xFF345BA8), // 소프트 네이비
    this.requireConfirm = true,
    this.autoSubmitOnMaxLen = true,
    this.autoDelay = const Duration(milliseconds: 120),
    this.padStyle = PadStyle.flat,
    this.enableShuffle = true,
  });

  @override
  State<SecurePinSheet> createState() => _SecurePinSheetState();
}

class _SecurePinSheetState extends State<SecurePinSheet> {
  int _step = 1;
  final List<int> _digits = [];
  String? _first;
  String? _error;

  // 플랫 패드 초기 배치
  List<int> _grid = const [3, 1, 4, 8, 6, 9, 2, 5, 7];
  void _shuffle() {
    final list = List<int>.generate(9, (i) => i + 1)..shuffle();
    setState(() => _grid = list);
  }

  void _push(int v) {
    if (_digits.length >= widget.maxLen) return;
    setState(() { _digits.add(v); _error = null; });
    if (widget.autoSubmitOnMaxLen && _digits.length == widget.maxLen) {
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

    final cur = _digits.join();
    if (_step == 1) {
      if (widget.requireConfirm) {
        setState(() { _first = cur; _step = 2; _digits.clear(); _error = null; });
      } else {
        Navigator.of(context).pop<String>(cur);
      }
      return;
    }
    if (_first == cur) {
      Navigator.of(context).pop<String>(cur);
    } else {
      setState(() {
        _error = '입력값이 일치하지 않습니다. 다시 입력해주세요.';
        _digits.clear(); _step = 1; _first = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_digits.length < widget.minLen) return;
    if (widget.autoSubmitOnMaxLen && _digits.length == widget.maxLen) {
      await _autoMaybeSubmit(); return;
    }
    final cur = _digits.join();
    if (_step == 1) {
      if (widget.requireConfirm) {
        setState(() { _first = cur; _step = 2; _digits.clear(); _error = null; });
      } else {
        Navigator.of(context).pop<String>(cur);
      }
      return;
    }
    if (_first != cur) {
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
              Container(
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(_step == 1 ? widget.title1 : widget.title2,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),

              // ● 인디케이터
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
                child: widget.padStyle == PadStyle.flat
                    ? _buildFlatPad()
                    : _buildCardPad(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------- 플랫 ----------
  Widget _buildFlatPad() {
    return Container(
      decoration: BoxDecoration(
        color: widget.padColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 8.0;
          final avail = c.maxHeight - (gap * 3) - 14 - 14;
          final keyH = (avail / 4).clamp(52.0, 72.0);

          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              children: [
                _flatRow(_grid.sublist(0, 3), keyH),
                const SizedBox(height: gap),
                _flatRow(_grid.sublist(3, 6), keyH),
                const SizedBox(height: gap),
                _flatRow(_grid.sublist(6, 9), keyH),
                const SizedBox(height: gap),
                _flatSpecialRow(keyH),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _flatRow(List<int> nums, double keyH) => Row(
    children: nums.map((n) => _flatKeyNum(n, keyH)).toList(),
  );

  Widget _flatSpecialRow(double keyH) => Row(
    children: [
      _flatKeyLabel('재배열', keyH, onTap: widget.enableShuffle ? _shuffle : null),
      _flatKeyNum(0, keyH),
      _flatKeyIcon(Icons.backspace_outlined, keyH, onTap: _pop),
    ],
  );

  Widget _flatKeyNum(int n, double keyH) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _push(n),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Text(
            '$n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _flatKeyLabel(String text, double keyH, {VoidCallback? onTap}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: keyH,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(onTap == null ? 0.4 : 1),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _flatKeyIcon(IconData icon, double keyH, {VoidCallback? onTap}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: keyH,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: Colors.white.withOpacity(onTap == null ? 0.4 : 1),
          ),
        ),
      ),
    ),
  );

  // ---------- 카드형 ----------
  Widget _buildCardPad() {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final avail = c.maxHeight - (gap * 3) - 12 - 12;
        final keyH = (avail / 4).clamp(52.0, 70.0);

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _rowCard([3, 1, 4], keyH),
              const SizedBox(height: gap),
              _rowCard([8, 6, 9], keyH),
              const SizedBox(height: gap),
              _rowCard([2, 5, 7], keyH),
              const SizedBox(height: gap),
              Row(
                children: [
                  _keyCard(label: '지우기', keyH: keyH, onTap: _pop, isText: true),
                  _keyCard(labelNum: 0, keyH: keyH, onTap: () => _push(0)),
                  _keyCard(
                    icon: Icons.check_rounded,
                    keyH: keyH,
                    onTap: (_digits.length >= widget.minLen) ? _submit : null,
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rowCard(List<int> nums, double keyH) =>
      Row(children: nums.map((n) => _keyCard(labelNum: n, keyH: keyH, onTap: () => _push(n))).toList());

  Widget _keyCard({
    int? labelNum,
    String? label,
    IconData? icon,
    double? keyH,
    VoidCallback? onTap,
    bool isText = false,
    bool isPrimary = false,
  }) {
    final enabled = onTap != null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Container(
            height: keyH ?? 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(blurRadius: 2, color: Color(0x14000000))],
              border: Border.all(color: isPrimary ? widget.accent : const Color(0xFFE7EAF0)),
            ),
            child: icon != null
                ? Icon(icon, color: enabled ? widget.accent : const Color(0xFFB0B8C1))
                : isText
                ? Text(label!, style: const TextStyle(color: Color(0xFF6B7684), fontWeight: FontWeight.w600))
                : Text('$labelNum', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          ),
        ),
      ),
    );
  }
}
