// lib/ApplicationStep5AccountPage.dart
import 'package:flutter/material.dart';
import 'package:bnkandroid/user/service/account_service.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed;
import 'ApplicationStep6CardOptionPage.dart';
import 'ui/pin/fullscreen_pin_pad.dart';

class ApplicationStep5AccountPage extends StatefulWidget {
  final int applicationNo;
  final int cardNo;

  const ApplicationStep5AccountPage({
    super.key,
    required this.applicationNo,
    required this.cardNo,
  });

  @override
  State<ApplicationStep5AccountPage> createState() => _ApplicationStep5AccountPageState();
}

class _ApplicationStep5AccountPageState extends State<ApplicationStep5AccountPage> {
  bool _loading = true;

  // 서버 응답 원본
  List<Map<String, dynamic>> _accounts = [];

  // 생성 제한(최근 20일) – 서버가 주면 우선 사용, 없으면 클라이언트에서 계산
  bool? _recentLockedFromServer;

  // 선택/상태
  Map<String, dynamic>? _selectedAccount; // 선택한 기존 계좌
  Map<String, dynamic>? _createdAccount;  // 자동 생성된 새 계좌
  bool _pwdReady = false;                 // 새 계좌 비번 설정 완료 여부

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

      final list = (res['accounts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _accounts = list;
        if (res.containsKey('recentCreatedWithinDays')) {
          _recentLockedFromServer = res['recentCreatedWithinDays'] == true;
        }
        _loading = false;
      });

      // 계좌가 없을 때만 자동 생성 플로우 시작
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

  // 정책 계산(서버 플래그 우선, 없으면 createdAt 기반으로 20일 계산)
  bool get _isNewOpenBlockedBy20Days {
    if (_recentLockedFromServer != null) return _recentLockedFromServer!;
    final now = DateTime.now();
    for (final a in _accounts) {
      final created = _parseDate(a['createdAt']);
      if (created == null) continue;
      if (now.difference(created).inDays < 20) return true;
    }
    return false;
  }

  DateTime? _parseDate(dynamic v) {
    if (v is String) {
      try { return DateTime.tryParse(v); } catch (_) {}
    }
    return null;
  }

  String _maskAccount(String acc) {
    final s = acc.replaceAll(RegExp(r'\s+'), '');
    if (s.length <= 4) return s;
    final head = s.substring(0, 3);
    final tail = s.substring(s.length - 2);
    return '$head-****-****-$tail';
  }

  // ===== 자동 생성 플로우(오버레이 로딩 → 서버 판단) =====
  Future<void> _autoCreateFlow() async {
    if (_isNewOpenBlockedBy20Days) {
      _snack('최근 20일 이내 개설된 계좌가 있어 신규 개설이 제한됩니다.');
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
      setState(() {
        _createdAccount = account;
        _createError = null;
        _pwdReady = false;
      });
      _snack('신규 계좌가 생성되었습니다.');
    } else {
      setState(() => _createError = '계좌 생성에 실패했습니다.');
      _snack(_createError!);
    }
  }

  // ===== 새 계좌 비밀번호 설정(전체화면 시큐어 패드) =====
  Future<void> _showSetPasswordSheet({required int acNo}) async {
    final pin = await FullscreenPinPad.open(
      context,
      title: '계좌 비밀번호를 입력해주세요',
      confirm: true,   // 새 비번 2회
      length: 6,
      birthYmd: null,
    );
    if (pin == null) return;

    final res = await AccountService.setPassword(acNo: acNo, pw1: pin, pw2: pin);
    if (!mounted) return;

    if (res['ok'] == true) {
      // ✅ 새 계좌를 이번 신청에 사용할 계좌로 서버 세션에 명시
      await AccountService.selectAccount(acNo: acNo);

      setState(() => _pwdReady = true);
      _snack('비밀번호 설정 완료');
    } else {
      _snack(res['message'] ?? '설정 실패');
    }
  }

  // ===== 기존 계좌 인증(전체화면 시큐어 패드) =====
  Future<void> _verifyExistingWithKeypad({
    required int acNo,
    required String accountNumber,
  }) async {
    final pin = await FullscreenPinPad.open(
      context,
      title: '계좌 비밀번호를 입력해주세요',
      confirm: false,  // 1회 입력
      length: 6,
      birthYmd: null,
    );
    if (pin == null) return;

    final res = await AccountService.verifyAndSelect(acNo: acNo, password: pin);
    if (!mounted) return;

    if (res['ok'] == true) {
      _goStep6();
    } else {
      _snack(res['message'] ?? '비밀번호가 올바르지 않습니다');
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
          cardNo: widget.cardNo,
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
      return _createdAccount != null && _pwdReady;
    } else {
      return _selectedAccount != null;
    }
  }

  Future<void> _onPrimaryPressed() async {
    if (_accounts.isEmpty) {
      // 안전망: 비번 설정 단계에서 select가 실패했을 가능성 대비
      if (_createdAccount != null && _pwdReady) {
        final acNo = (_createdAccount!['acNo'] as num).toInt();
        await AccountService.selectAccount(acNo: acNo);
        _goStep6();
      } else {
        _snack('비밀번호 설정을 먼저 완료해주세요.');
      }
      return;
    }

    // 기존 계좌는 키패드 인증
    final acNo = (_selectedAccount!['acNo'] as num).toInt();
    final number = _selectedAccount!['accountNumber'] as String;
    await _verifyExistingWithKeypad(acNo: acNo, accountNumber: number);
  }

  // ----- VIEW: 계좌 없음 → (오버레이 생성) → 성공/실패 화면 -----
  Widget _buildAutoCreatedView() {
    if (_createdAccount != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const _StepIndicator(current: 4, total: 6),
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
              onTap: () => _showSetPasswordSheet(acNo: (_createdAccount!['acNo'] as num).toInt()),
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
        const _StepIndicator(current: 4, total: 6),
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
    const accent = Color(0xFF9AA4AE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const _StepIndicator(current: 4, total: 6),
        const SizedBox(height: 18),
        const Text('계좌 선택', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: _accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = _accounts[i];
              final number = a['accountNumber'] as String;
              final selected = (_selectedAccount?['acNo'] == a['acNo']);

              return _AccountTile(
                title: _maskAccount(number),
                subtitle: '입출금 계좌',
                selected: selected,
                accent: accent,
                onTap: () => setState(() => _selectedAccount = a),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        if (!blocked) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _autoCreateFlow, // 계좌가 있어도 정책은 서버가 판단
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
                    '최근 20일 이내 개설된 계좌가 있어 신규 개설이 제한됩니다.\n기존 계좌로만 진행할 수 있어요.',
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
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF6B7684)),
            ),
            const SizedBox(width: 12),
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
        child: const Text(
          '신규 계좌 개설',
          style: TextStyle(color: Color(0xFFB91111), fontWeight: FontWeight.w600),
        ),
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
  final int current; // 1-based
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Row(
        children: List.generate(total, (i) {
          final active = (i + 1) <= current;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              color: active ? kPrimaryRed : const Color(0xFFF0F0F0),
            ),
          );
        }),
      ),
    );
  }
}
