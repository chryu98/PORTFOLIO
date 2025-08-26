// lib/ApplicationStep2Page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ApplicationStep1Page.dart' show ApplicationFormData; // ← public 클래스만 import
import 'ApplicationStep3JobPage.dart';
import 'user/service/card_apply_service.dart';

// ⬇️ 캡처 방지/감지
import 'package:bnkandroid/security/secure_screen.dart';
import 'package:bnkandroid/security/screenshot_watcher.dart';

const kPrimaryRed = Color(0xffB91111);

/// Step 진행바(파일 로컬 전용)
class _StepHeader2 extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const _StepHeader2({required this.current, this.total = 4});

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

/// Step2 전용 필드 데코레이터(파일 로컬 전용)
InputDecoration _fieldDec2(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: Colors.grey.shade400), // 빈 칸 힌트 회색
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

class ApplicationStep2Page extends StatefulWidget {
  final ApplicationFormData data;
  const ApplicationStep2Page({super.key, required this.data});

  @override
  State<ApplicationStep2Page> createState() => _ApplicationStep2PageState();
}

class _ApplicationStep2PageState extends State<ApplicationStep2Page> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = false;

  Color _colorFor(TextEditingController c) =>
      c.text.isEmpty ? Colors.grey.shade400 : Colors.black87;

  void _attachFieldListeners() {
    for (final c in [_email, _phone]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _attachFieldListeners();

    // ⬇️ 스크린샷 감지 시작 (알림/로그 처리)
    ScreenshotWatcher.instance.start(context);

    // Step1에서 넘어온 값이 있으면 프리필
    if ((widget.data.email ?? '').isNotEmpty) _email.text = widget.data.email!;
    if ((widget.data.phone ?? '').isNotEmpty) _phone.text = _formatPhone(widget.data.phone!);
  }

  @override
  void dispose() {
    // ⬇️ 스크린샷 감지 정지
    ScreenshotWatcher.instance.stop();

    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _formatPhone(String raw) {
    // 숫자만 추출
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    final a = digits.substring(0, 3);
    final b = digits.substring(3, 7);
    final c = digits.substring(7, digits.length > 11 ? 11 : digits.length);
    return '$a-$b-$c';
  }

  String _ensurePhonePattern(String formatted) {
    // 백엔드 정규식: ^010-[0-9]{4}-[0-9]{4}$
    return formatted;
  }

  Future<void> _finish() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (widget.data.applicationNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신청번호가 없습니다. Step1을 먼저 완료해주세요.')),
      );
      return;
    }

    final email = _email.text.trim();
    final phone = _ensurePhonePattern(_formatPhone(_phone.text.trim()));

    setState(() => _loading = true);
    try {
      final ok = await CardApplyService.validateContact(
        applicationNo: widget.data.applicationNo!,
        email: email,
        phone: phone,
      );

      if (!mounted) return;
      if (ok) {
        widget.data
          ..email = email
          ..phone = phone;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicationStep3JobPage(
              applicationNo: widget.data.applicationNo!, // Step1에서 받은 신청번호 그대로 전달
              cardNo: widget.data.cardNo!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연락처 저장 실패')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다. 다시 로그인 후 시도해주세요.')),
        );
        // TODO: 로그인 화면 이동
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return '이메일을 입력하세요';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
    return ok ? null : '이메일 형식이 올바르지 않습니다';
  }

  String? _phoneValidator(String? v) {
    final input = _formatPhone((v ?? '').trim());
    final ok = RegExp(r'^010-[0-9]{4}-[0-9]{4}$').hasMatch(input);
    return ok ? null : '휴대전화는 010-1234-5678 형식으로 입력하세요';
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _loading;

    return SecureScreen(
      child: PopScope(
        canPop: true, // 시스템 뒤로가기도 허용하되, 우리가 정리 동작 추가
        onPopInvoked: (didPop) {
          if (didPop) return;
          FocusManager.instance.primaryFocus?.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).maybePop(); // 한 단계만 닫기
            }
          });
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                const _StepHeader2(current: 2, total: 6),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('정보를 입력해주세요',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: _fieldDec2('example@google.com'),
                          style: TextStyle(color: _colorFor(_email)),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '이메일로 계약서(신청서) 및 약관, 금융거래정보제공내역이\n'
                              '교부되어 전자적 교부로 보존됩니다. 홈페이지/모바일앱>문서함에서도\n'
                              '계약서를 확인할 수 있어요.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          decoration: _fieldDec2('휴대전화 (예: 010-1234-5678)'),
                          style: TextStyle(color: _colorFor(_phone)),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))
                          ],
                          validator: _phoneValidator,
                          onChanged: (v) {
                            final f = _formatPhone(v);
                            if (f != v) {
                              final pos = f.length;
                              _phone.value = TextEditingValue(
                                text: f,
                                selection: TextSelection.collapsed(offset: pos),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isBusy ? null : _finish,
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
