// lib/ApplicationStep2Page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ApplicationStep1Page.dart' show ApplicationFormData; // ← public 클래스만 import
import 'user/service/card_apply_service.dart';

const kPrimaryRed = Color(0xffB91111);

/// Step 진행바(파일 로컬 전용)
class _StepHeader2 extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const _StepHeader2({required this.current, this.total = 2});

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

  @override
  void initState() {
    super.initState();
    // Step1에서 넘어온 값이 있으면 프리필
    if ((widget.data.email ?? '').isNotEmpty) _email.text = widget.data.email!;
    if ((widget.data.phone ?? '').isNotEmpty) _phone.text = _formatPhone(widget.data.phone!);
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _formatPhone(String raw) {
    // 숫자만 추출
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    // 010이 아니어도 010으로 강제 안내하고 싶다면 여기서 처리 가능
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
    // 사용자가 010이 아니게 입력했다면 010으로 보정하는 대신, 여기서는 그대로 검증만 하고 에러는 validator에서
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
        // 로컬 데이터에도 저장
        widget.data
          ..email = email
          ..phone = phone;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연락처 저장 완료')),
        );

        // TODO: 다음 단계로 이동하고 싶으면 여기서 push
        // Navigator.push(context, MaterialPageRoute(builder: (_) => NextStepPage(...)));

        Navigator.pop(context, true); // 일단 완료 후 이전 화면으로
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연락처 저장 실패')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      // 401: 미로그인
      if (e.status == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다. 다시 로그인 후 시도해주세요.')),
        );
        // TODO: 로그인 화면으로 보내려면 여기서 네비게이션
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
    // 백엔드: 010-1234-5678 형식만 허용
    final ok = RegExp(r'^010-[0-9]{4}-[0-9]{4}$').hasMatch(input);
    return ok ? null : '휴대전화는 010-1234-5678 형식으로 입력하세요';
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _loading;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black87),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            const _StepHeader2(current: 2, total: 2),
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
                      decoration: _fieldDec2('이메일'),
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
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
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
    );
  }
}
