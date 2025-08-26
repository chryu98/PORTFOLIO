// lib/ApplicationStep1Page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bnkandroid/app_shell.dart' show pushFullScreen; // 루트 푸시 helper
import 'package:bnkandroid/security/secure_screen.dart';        // 화면 캡처/미러링 방지(가능한 플랫폼)
import 'package:bnkandroid/security/screenshot_watcher.dart';   // 스크린샷/화면녹화 시도 알림

import 'ApplicationStep2Page.dart';
import 'user/service/card_apply_service.dart';

const kPrimaryRed = Color(0xffB91111);

/* ───────────────────────── 폼 데이터 ───────────────────────── */

class ApplicationFormData {
  int? applicationNo;
  int? cardNo;
  bool? isCreditCard;

  String? name;
  String? engFirstName;
  String? engLastName;
  String? rrnFront; // 6
  String? rrnBack;  // 7

  String? email;
  String? phone;

  Map<String, dynamic> toJson() => {
    'applicationNo': applicationNo,
    'cardNo': cardNo,
    'isCreditCard': isCreditCard,
    'name': name,
    'engFirstName': engFirstName,
    'engLastName': engLastName,
    'rrnFront': rrnFront,
    'rrnBack': rrnBack,
    'email': email,
    'phone': phone,
  };
}

/* ───────────────────────── UI 공통 ───────────────────────── */

class _StepHeader extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const _StepHeader({required this.current, this.total = 3});

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

InputDecoration _fieldDec(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: Colors.grey.shade400),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: kPrimaryRed),
  ),
);

/* ───────────────────────── 페이지 ───────────────────────── */

class ApplicationStep1Page extends StatefulWidget {
  final int cardNo;
  final int? applicationNo; // /start 응답(선택)
  final bool? isCreditCard;

  const ApplicationStep1Page({
    super.key,
    required this.cardNo,
    this.applicationNo,
    this.isCreditCard,
  });

  @override
  State<ApplicationStep1Page> createState() => _ApplicationStep1PageState();
}

class _ApplicationStep1PageState extends State<ApplicationStep1Page> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _engFirst = TextEditingController();
  final _engLast = TextEditingController();
  final _rrnFront = TextEditingController();
  final _rrnBack = TextEditingController();

  bool _submitting = false;
  bool _prefilling = false;

  Color _colorFor(TextEditingController c) =>
      c.text.isEmpty ? Colors.grey.shade400 : Colors.black87;

  void _attachFieldListeners() {
    for (final c in [_name, _engFirst, _engLast, _rrnFront, _rrnBack]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _attachFieldListeners();
    _loadPrefill(); // 로그인 기반 프리필 시도

    // ⬇️ (Android/iOS만) 스크린샷/녹화 시도시 토스트/다이얼로그 알림
    ScreenshotWatcher.instance.start(context);
  }

  @override
  void dispose() {
    ScreenshotWatcher.instance.stop();

    _name.dispose();
    _engFirst.dispose();
    _engLast.dispose();
    _rrnFront.dispose();
    _rrnBack.dispose();
    super.dispose();
  }

  Future<void> _loadPrefill() async {
    setState(() => _prefilling = true);
    try {
      final p = await CardApplyService.prefill(); // {name, rrnFront}
      if (p != null) {
        if ((_name.text).trim().isEmpty) _name.text = p['name'] ?? '';
        if ((_rrnFront.text).trim().isEmpty) _rrnFront.text = p['rrnFront'] ?? '';
        if (mounted) setState(() {});
      }
    } on ApiException catch (e) {
      if (e.status == 401 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다. (프리필 미적용)')),
        );
      }
    } finally {
      if (mounted) setState(() => _prefilling = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final resp = await CardApplyService.validateInfo(
        cardNo: widget.cardNo,
        name: _name.text.trim(),
        engFirstName: _engFirst.text.trim(),
        engLastName: _engLast.text.trim(),
        rrnFront: _rrnFront.text.trim(),
        rrnBack: _rrnBack.text.trim(),
        applicationNo: widget.applicationNo, // 있으면 중복 생성 방지
      );

      if (resp.success) {
        final data = ApplicationFormData()
          ..applicationNo = resp.applicationNo ?? widget.applicationNo
          ..cardNo = widget.cardNo
          ..isCreditCard = widget.isCreditCard
          ..name = _name.text.trim()
          ..engFirstName = _engFirst.text.trim()
          ..engLastName = _engLast.text.trim()
          ..rrnFront = _rrnFront.text.trim()
          ..rrnBack = _rrnBack.text.trim();

        if (!mounted) return;

        // ✅ 발급 플로우는 루트 네비로 푸시
        await pushFullScreen(context, ApplicationStep2Page(data: data));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? '검증 실패')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다. 다시 로그인 후 시도해주세요.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _submitting || _prefilling;

    return SecureScreen( // ⬅️ 화면 캡처/미러링 차단(가능한 플랫폼)
      child: PopScope(
        canPop: true, // 시스템 뒤로가기 허용
        onPopInvoked: (didPop) {
          if (didPop) return;
          // 우리 쪽 종료: 키보드 내리고 다음 프레임에 안전 pop
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
          ),

          // 🔥 웹/크롬에서 레이아웃 깨짐 방지를 위해 body를 ListView 하나로 단순화
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                const _StepHeader(current: 1, total: 6),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '정보를 입력해주세요',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),

                // 한글 이름
                TextFormField(
                  controller: _name,
                  decoration: _fieldDec('이름'),
                  style: TextStyle(color: _colorFor(_name)),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '이름을 입력하세요' : null,
                ),
                const SizedBox(height: 6),
                const Text(
                  '여권 이름과 동일해야 합니다.\n* 여권 이름과 다르면 해외에서 카드를 사용할 수 없습니다.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // 영문 성 / 이름
                TextFormField(
                  controller: _engLast,
                  decoration: _fieldDec('영문 성'),
                  style: TextStyle(color: _colorFor(_engLast)),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '영문 성을 입력하세요' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _engFirst,
                  decoration: _fieldDec('영문 이름'),
                  style: TextStyle(color: _colorFor(_engFirst)),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '영문 이름을 입력하세요' : null,
                ),
                const SizedBox(height: 10),

                // 주민번호 앞 6자리
                TextFormField(
                  controller: _rrnFront,
                  decoration: _fieldDec('주민등록번호 앞자리'),
                  style: TextStyle(color: _colorFor(_rrnFront)),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                  (v == null || v.length != 6) ? '앞 6자리를 입력하세요' : null,
                ),
                const SizedBox(height: 10),

                // 주민번호 뒤 7자리
                TextFormField(
                  controller: _rrnBack,
                  decoration: _fieldDec('주민등록번호 뒷자리'),
                  style: TextStyle(color: _colorFor(_rrnBack)),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  validator: (v) =>
                  (v == null || v.length != 7) ? '뒤 7자리를 입력하세요' : null,
                ),

                // bottomNavigationBar와 겹치지 않도록 여백
                const SizedBox(height: 100),
              ],
            ),
          ),

          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isBusy) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isBusy
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('다음'),
                ),
              ),
            ),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
