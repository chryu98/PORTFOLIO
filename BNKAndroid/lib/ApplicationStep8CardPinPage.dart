// lib/ApplicationStep8CardPinPage.dart
import 'package:flutter/material.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed;
import 'package:bnkandroid/constants/api.dart' as API;                // ✅ ApiException 캐치용
import 'package:bnkandroid/user/service/card_password_service.dart' as cps;

enum _PadStyle { card, flat }

class ApplicationStep8CardPinPage extends StatefulWidget {
  final int cardNo;

  const ApplicationStep8CardPinPage({
    super.key,
    required this.cardNo,
  });

  @override
  State<ApplicationStep8CardPinPage> createState() => _ApplicationStep8CardPinPageState();
}

class _ApplicationStep8CardPinPageState extends State<ApplicationStep8CardPinPage> {
  bool _saving = false;

  Future<void> _openPadAndSave() async {
    if (_saving) return; // 중복 클릭 방지

    // 1) 보안 키패드 열기
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SecurePinSheet(
        title1: '카드 비밀번호를 입력해주세요',
        title2: '한 번 더 입력해주세요',
        minLen: 4,
        maxLen: 6,
        accent: kPrimaryRed,
        padColor: Color(0xFF9AA4AE),
        requireConfirm: true,          // 두 번 확인
        autoSubmitOnMaxLen: true,
        autoDelay: Duration(milliseconds: 120),
        padStyle: _PadStyle.flat,
        enableShuffle: true,           // 키패드 재배열
      ),
    );

    // 시트 닫힘
    if (pin == null) return;
    if (!mounted) return;

    // 2) 기본 검증 (서버도 재검증함)
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('숫자 4~6자리로 입력해주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 3) 저장 요청
      final result = await cps.CardPasswordService.savePin(
        cardNo: widget.cardNo,
        pin1: pin,
        pin2: pin,
      );
      if (!mounted) return;

      // 4) 결과 처리
      if (result.ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '카드 비밀번호가 저장되었습니다.')),
        );
        Navigator.of(context).pop(true); // 현재 화면 종료(필요 시 다음 단계로 교체)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '저장에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } on API.ApiException catch (e) {
      if (!mounted) return;
      var msg = e.message ?? '요청 처리 중 오류가 발생했습니다.';
      if (e.statusCode == 401) {
        msg = '로그인이 필요합니다. 다시 로그인해 주세요.';
      } else if (e.statusCode == 400) {
        msg = '형식 오류: 숫자 4~6자리로 입력했는지 확인해주세요.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black87),
        title: const Text('카드 비밀번호 설정', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white, elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _StepHeader8(current: 8, total: 8),
            SizedBox(height: 16),
            Text(
              '카드 결제/인증에 사용할 비밀번호(4~6자리 숫자)를 설정합니다.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '※ 보안을 위해 숫자 키패드가 무작위로 재배열될 수 있어요.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saving ? null : _openPadAndSave,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('비밀번호 설정'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader8 extends StatelessWidget {
  final int current; final int total;
  const _StepHeader8({required this.current, this.total = 8});
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

/// ========================
///  보안 숫자 키패드 시트
/// ========================
class _SecurePinSheet extends StatefulWidget {
  final String title1;
  final String title2;
  final int minLen;
  final int maxLen;

  final Color accent;   // 점/아이콘
  final Color padColor; // 키패드 배경

  final bool requireConfirm;        // 신규: true, 기존: false
  final bool autoSubmitOnMaxLen;    // maxLen 채우면 자동 진행
  final Duration autoDelay;         // 점(●) 채움 연출
  final _PadStyle padStyle;         // flat / card
  final bool enableShuffle;         // '재배열' 사용

  const _SecurePinSheet({
    super.key,
    required this.title1,
    required this.title2,
    this.minLen = 4,
    this.maxLen = 6,
    this.accent   = const Color(0xFF102A56),
    this.padColor = const Color(0xFF345BA8),
    this.requireConfirm = true,
    this.autoSubmitOnMaxLen = true,
    this.autoDelay = const Duration(milliseconds: 120),
    this.padStyle = _PadStyle.flat,
    this.enableShuffle = true,
  });

  @override
  State<_SecurePinSheet> createState() => _SecurePinSheetState();
}

class _SecurePinSheetState extends State<_SecurePinSheet> {
  int _step = 1;
  final List<int> _digits = [];
  String? _first;
  String? _error;

  // 최초 배열(임의 시작)
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
    if (!RegExp(r'^\d+$').hasMatch(cur)) return; // 숫자만 허용

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
                child: widget.padStyle == _PadStyle.flat
                    ? _buildFlatPad()
                    : _buildCardPad(),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
