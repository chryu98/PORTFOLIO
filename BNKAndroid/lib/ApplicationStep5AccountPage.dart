// lib/ApplicationStep5AccountPage.dart
import 'package:flutter/material.dart';
import 'package:bnkandroid/user/service/account_service.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed; // 상단/버튼 컬러 재사용
import 'ApplicationStep6CardOptionPage.dart';

enum _PadStyle { card, flat }

class ApplicationStep5AccountPage extends StatefulWidget {
  final int applicationNo;
  final int? cardNo;

  const ApplicationStep5AccountPage({
    super.key,
    required this.applicationNo,
    this.cardNo,
  });

  @override
  State<ApplicationStep5AccountPage> createState() => _ApplicationStep5AccountPageState();
}

class _ApplicationStep5AccountPageState extends State<ApplicationStep5AccountPage> {
  bool _loading = true;

  // 서버 응답 원본
  List<Map<String, dynamic>> _accounts = [];

  // 선택/상태
  Map<String, dynamic>? _selectedAccount; // 드롭다운에서 선택한 계좌
  Map<String, dynamic>? _createdAccount;  // 자동생성된 계좌
  bool _pwdReady = false;                 // 자동생성 후 비번 설정 완료 여부

  // 실패 메시지 (자동생성 실패 시)
  String? _createError;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _loading = true);
    try {
      final res = await AccountService.state();

      if (res['status'] != null && (res['status'] as int) >= 400) {
        setState(() {
          _loading = false;
          _createError = '상태 조회 실패: 로그인/네트워크 확인';
        });
        return;
      }

      final list = (res['accounts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _accounts = list;
        _loading = false;
      });

      // 계좌가 없으면 → 오버레이로 자동 생성 플로우 시작
      if (mounted && list.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _autoCreateFlow());
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _createError = '상태 조회 실패: ${e is StateError ? e.message : '인증/네트워크 오류'}';
      });
    }
  }

  // 20일 내 생성 계좌가 하나라도 있으면 신규 개설 금지
  bool get _isNewOpenBlockedBy20Days {
    final now = DateTime.now();
    for (final a in _accounts) {
      final created = _parseDate(a['createdAt']);
      if (created == null) continue;
      final diff = now.difference(created).inDays;
      if (diff < 20) return true;
    }
    return false;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      if (v is String) return DateTime.tryParse(v);
    } catch (_) {}
    return null;
  }

  String _maskAccount(String acc) {
    final s = acc.replaceAll(RegExp(r'\s+'), '');
    if (s.length <= 4) return s;
    final head = s.substring(0, 3);
    final tail = s.substring(s.length - 2);
    return '$head-****-****-$tail';
  }

  // ===== 자동 생성 플로우(오버레이 로딩 → 결과 수신) =====
  Future<void> _autoCreateFlow() async {
    // 계좌가 있으면 자동생성 금지
    if (_accounts.isNotEmpty) {
      _snack('이미 보유 중인 계좌가 있어 자동 생성이 제한됩니다. 기존 계좌를 선택해주세요.');
      return;
    }

    final account = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _AutoCreateDialog(cardNo: widget.cardNo),
    );

    if (!mounted) return;

    if (account != null) {
      // 성공 → 화면을 '신규 계좌가 생성되었습니다' 상태로 전환
      setState(() {
        _createdAccount = account;
        _createError = null;
        _pwdReady = false;
      });
      _snack('신규 계좌가 생성되었습니다.');
      // 생성 직후 비밀번호 설정을 바로 유도하고 싶으면 아래 주석 해제
      // _showSetPasswordSheet(acNo: account['acNo'] as int);
    } else {
      // 실패 (다이얼로그에서 재시도 가능하지만, 사용자가 닫기를 누르면 null 가능)
      setState(() {
        _createError = '계좌 생성에 실패했습니다.';
      });
      _snack(_createError!);
    }
  }

  // ===== 신규 계좌 비밀번호 설정(보안 키패드) =====
  Future<void> _showSetPasswordSheet({required int acNo}) async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SecurePinSheet(
        title1: '비밀번호를 입력해주세요',
        title2: '한번 더 입력해주세요',
        minLen: 4,
        maxLen: 6,
        accent: Color(0xFFB91111),   // ✅ BNK 레드
        padColor: Color(0xFF9AA4AE), // ✅ 더 짙은 회색 패널
        requireConfirm: true,
        autoSubmitOnMaxLen: true,
        autoDelay: Duration(milliseconds: 120),
        padStyle: _PadStyle.flat,      // ★ 플랫 스타일
        enableShuffle: true,           // ★ 재배열 버튼
      ),
    );

    if (pin == null) return;

    final res = await AccountService.setPassword(acNo: acNo, pw1: pin, pw2: pin);
    if (!mounted) return;

    if (res['ok'] == true) {
      setState(() => _pwdReady = true);
      _snack('비밀번호 설정 완료');
    } else {
      _snack(res['message'] ?? '설정 실패');
    }
  }

  // ===== 기존 계좌 비밀번호 검증(보안 키패드) =====
  Future<void> _verifyExistingWithKeypad({
    required int acNo,
    required String accountNumber,
  }) async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SecurePinSheet(
        title1: '계좌 비밀번호를 입력해주세요',
        title2: '',
        minLen: 4,
        maxLen: 6,
        accent: Color(0xFFB91111),   // ✅ BNK 레드
        padColor: Color(0xFF4B5563), // ✅ 더 짙은 회색 패널
        requireConfirm: false,         // 1회 입력
        autoSubmitOnMaxLen: true,
        autoDelay: Duration(milliseconds: 120),
        padStyle: _PadStyle.flat,      // ★
        enableShuffle: true,           // ★
      ),
    );

    if (pin == null) return;

    final res = await AccountService.verifyAndSelect(acNo: acNo, password: pin);
    if (!mounted) return;

    if (res['ok'] == true) {
      _snack('계좌가 선택되었습니다.');
      _goStep6();                // ← 다음 단계 이동
      return;
    } else {
      _snack(res['message'] ?? '인증 실패');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _goStep6() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicationStep6CardOptionPage(
          applicationNo: widget.applicationNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        title: const Text('계좌 연결', style: TextStyle(color: Colors.black87)),
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: _accounts.isEmpty ? _buildAutoCreatedView() : _buildHasAccountView(),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _primaryButtonEnabled ? _onPrimaryPressed : null,
              child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  bool get _primaryButtonEnabled {
    if (_accounts.isEmpty) {
      // 자동 생성 케이스 → 비번 설정까지 마쳐야 다음 가능
      return _createdAccount != null && _pwdReady;
    } else {
      // 기존 계좌 선택 시, 하나 선택됐을 때만
      return _selectedAccount != null;
    }
  }

  Future<void> _onPrimaryPressed() async {
    if (_accounts.isEmpty) {
      if (_createdAccount != null && _pwdReady) {
        _goStep6(); // ← 여기서 이동
      } else {
        _snack('비밀번호 설정을 먼저 완료해주세요.');
      }
      return;
    }

    // 기존 계좌는 키패드 인증으로 분기
    final acNo = _selectedAccount!['acNo'] as int;
    final number = _selectedAccount!['accountNumber'] as String;
    await _verifyExistingWithKeypad(acNo: acNo, accountNumber: number);
  }

  // ----- VIEW: 계좌 없음 → (오버레이로 생성) → 성공 화면 -----
  Widget _buildAutoCreatedView() {
    if (_createdAccount != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const _StepIndicator(),
          const SizedBox(height: 18),
          const Text('신규 계좌가 생성되었습니다', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('아래 계좌번호로 카드를 연결합니다.'),
          const SizedBox(height: 20),
          _AccountNumberCard(number: _createdAccount!['accountNumber'] as String),
          const SizedBox(height: 16),
          if (!_pwdReady)
            _CTA(
              text: '계좌 비밀번호 설정',
              onTap: () => _showSetPasswordSheet(acNo: _createdAccount!['acNo'] as int),
            ),
          if (_pwdReady)
            const Text('비밀번호가 설정되었습니다.', style: TextStyle(color: Colors.black87)),
        ],
      );
    }

    // 실패/초기
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const _StepIndicator(),
        const SizedBox(height: 18),
        Text(
          _createError == null ? '신규 계좌를 만들어 연결하세요' : '계좌 생성에 실패했어요',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _createError ?? '네트워크/인증 상태를 확인한 뒤 진행해주세요.',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _CTA(
          text: '다시 시도',
          onTap: _autoCreateFlow,
          outline: true,
        ),
      ],
    );
  }

  // ----- VIEW: 계좌 있음 → 선택 + (옵션) 신규 개설 -----
  Widget _buildHasAccountView() {
    final blocked = _isNewOpenBlockedBy20Days;
    const accent = Color(0xFF9AA4AE); // 중간 회색
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const _StepIndicator(),
        const SizedBox(height: 18),
        const Text('계좌 선택', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),

        // 리스트는 토스처럼 큼직한 카드로
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: _accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = _accounts[i];
              final number = a['accountNumber'] as String;
              final selected = identical(_selectedAccount, a);

              return _AccountTile(
                title: _maskAccount(number),
                subtitle: '입출금 계좌', // 필요 없으면 null 로
                selected: selected,
                accent: accent,
                onTap: () => setState(() => _selectedAccount = a),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        if (!blocked) ...[
          // 토스 느낌의 연한 아웃라인 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _autoCreateFlow,
              child: const Text('신규 계좌 개설', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, size: 18, color: Colors.black45),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '최근 20일 이내 개설된 계좌가 있어 신규 개설이 제한됩니다.\n'
                        '기존 계좌로만 진행할 수 있어요.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),
      ],
    );
  }
}

// ===== 자동 생성 다이얼로그(로딩 + 실패 시 재시도) =====
class _AutoCreateDialog extends StatefulWidget {
  final int? cardNo;
  final Duration minDisplay; // 최소 표시 시간

  const _AutoCreateDialog({
    super.key,
    this.cardNo,
    this.minDisplay = const Duration(seconds: 2),
  });

  @override
  State<_AutoCreateDialog> createState() => _AutoCreateDialogState();
}

class _AutoCreateDialogState extends State<_AutoCreateDialog> {
  bool _running = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _kickoff();
  }

  Future<void> _kickoff() async {
    setState(() { _running = true; _error = null; });

    // 다이얼로그가 먼저 그려지도록 아주 짧게 대기
    await Future.delayed(const Duration(milliseconds: 150));

    final startedAt = DateTime.now();
    Map<String, dynamic>? account;
    String? error;

    try {
      final res = await AccountService.autoCreate(cardNo: widget.cardNo);
      if (res['created'] == true && res['account'] is Map) {
        account = (res['account'] as Map).cast<String, dynamic>();
      } else {
        error = (res['message'] ?? '계좌 생성에 실패했습니다.').toString();
      }
    } catch (e) {
      error = e is StateError ? e.message : '네트워크/인증 오류';
    }

    // 최소 표시 시간 보장
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < widget.minDisplay) {
      await Future.delayed(widget.minDisplay - elapsed);
    }

    if (!mounted) return;

    if (account != null) {
      Navigator.of(context).pop<Map<String, dynamic>>(account);
      return;
    }

    setState(() { _running = false; _error = error ?? '알 수 없는 오류입니다.'; });
  }

  @override
  Widget build(BuildContext context) {
    final title   = _running ? '계좌가 없으시네요' : '계좌 생성 실패';
    final message = _running ? '신규 계좌를 만들어드릴게요.\n잠시만 기다려주세요.' : (_error ?? '');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),

            if (_running)
              const SizedBox(height: 32, width: 32, child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('닫기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _kickoff, // 재시도
                      child: const Text('재시도'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _AccountTile({
    required this.title,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? accent : const Color(0xFFE9ECF1);
    final bgColor     = Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1.0),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // 왼쪽 아이콘(은행/계좌 느낌)
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF6B7684)),
            ),
            const SizedBox(width: 12),

            // 계좌 번호(마스킹) + 서브텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8B95A1), fontWeight: FontWeight.w500,
                        )),
                  ],
                ],
              ),
            ),

            // 선택 인디케이터(토스풍 라디오)
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? accent : const Color(0xFFD4DAE4), width: 2),
              ),
              child: selected
                  ? Center(
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ====== 소품 위젯들 ======
class _AccountNumberCard extends StatelessWidget {
  final String number;
  const _AccountNumberCard({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('계좌번호', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

class _CTA extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool outline;

  const _CTA({required this.text, required this.onTap, this.outline = false});

  @override
  Widget build(BuildContext context) {
    final base = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outline
          ? OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: base,
          side: const BorderSide(color: Color(0xFFB91111), width: 1.2),
        ),
        onPressed: onTap,
        child: const Text('신규 계좌 개설',
            style: TextStyle(color: Color(0xFFB91111), fontWeight: FontWeight.w600)),
      )
          : ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryRed, shape: base),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Row(
        children: [
          Expanded(child: Container(color: kPrimaryRed)),
          Container(width: 36, color: const Color(0xFFF0F0F0)),
        ],
      ),
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

  // ✨ BNK 부드러운 네이비 팔레트
  final Color accent;   // 점/아이콘
  final Color padColor; // 키패드 배경

  final bool requireConfirm;        // 신규: true, 기존: false
  final bool autoSubmitOnMaxLen;    // maxLen 채우면 자동 진행
  final Duration autoDelay;         // 점(●) 채움 연출
  final _PadStyle padStyle;         // flat(추천) / card
  final bool enableShuffle;         // '재배열' 사용

  const _SecurePinSheet({
    super.key,
    required this.title1,
    required this.title2,
    this.minLen = 4,
    this.maxLen = 6,
    this.accent   = const Color(0xFF102A56), // ▲ 깊은 네이비
    this.padColor = const Color(0xFF345BA8), // ▲ 소프트 네이비
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

  // 플랫 패드 배치 (초기값은 토스 느낌)
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

    // 화면 높이에 따라 시트 높이 자동 보정 → 오버플로우 방지
    final h = MediaQuery.of(context).size.height;
    final factor = h < 740 ? 0.48 : 0.44; // 작은 화면일수록 약간 더 높게

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

              // === 키패드 ===
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

  // --------- 플랫(부산은행 소프트 네이비) ----------
  Widget _buildFlatPad() {
    return Container(
      decoration: BoxDecoration(
        color: widget.padColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          // 세로 공간을 4줄로 균등 분배 → 고정 height 제거(오버플로우 방지)
          const gap = 8.0;        // 줄 사이 간격
          final avail = c.maxHeight - (gap * 3) - 14 - 14; // 상하 패딩 여유
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

  // ---------- 기존 카드형(참고) ----------
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

