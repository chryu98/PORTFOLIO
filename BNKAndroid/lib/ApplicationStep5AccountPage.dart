// lib/ApplicationStep5AccountPage.dart
import 'package:flutter/material.dart';
import 'package:bnkandroid/user/service/account_service.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed;
import 'ApplicationStep6CardOptionPage.dart';
// ▼ 8번 페이지와 동일한 전체화면 시큐어 패드 사용
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
      // 생성 직후 비밀번호 설정을 바로 유도하려면:
      // _showSetPasswordSheet(acNo: account['acNo'] as int);
    } else {
      // 실패
      setState(() {
        _createError = '계좌 생성에 실패했습니다.';
      });
      _snack(_createError!);
    }
  }

  // ===== 신규 계좌 비밀번호 설정(전체화면 시큐어 패드) =====
  Future<void> _showSetPasswordSheet({required int acNo}) async {
    final pin = await FullscreenPinPad.open(
      context,
      title: '계좌 비밀번호를 입력해주세요',
      confirm: true,   // 새 비번 → 2회 확인
      length: 6,       // 6자리 통일
      birthYmd: null,  // 알면 'YYYYMMDD' 전달
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

  // ===== 기존 계좌 비밀번호 검증(전체화면 시큐어 패드) =====
  Future<void> _verifyExistingWithKeypad({
    required int acNo,
    required String accountNumber,
  }) async {
    final pin = await FullscreenPinPad.open(
      context,
      title: '계좌 비밀번호를 입력해주세요',
      confirm: false,  // 검증은 1회 입력
      length: 6,
      birthYmd: null,
    );
    if (pin == null) return;

    final res = await AccountService.verifyAndSelect(acNo: acNo, password: pin);
    if (!mounted) return;

    if (res['ok'] == true) {
      _snack('계좌가 선택되었습니다.');
      _goStep6();
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
        _goStep6();
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
