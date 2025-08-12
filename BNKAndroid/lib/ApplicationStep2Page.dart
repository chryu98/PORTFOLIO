import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ApplicationStep1Page.dart' show ApplicationFormData, _StepHeader, kPrimaryRed, _fieldDec;

class ApplicationStep2Page extends StatefulWidget {
  final ApplicationFormData data;
  const ApplicationStep2Page({super.key, required this.data});

  @override
  State<ApplicationStep2Page> createState() => _ApplicationStep2PageState();
}

class _StepHeader extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const _StepHeader({required this.current, this.total = 2, super.key});

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

// Step2 전용 필드 데코레이터
InputDecoration _fieldDec(String hint) => InputDecoration(
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

class _ApplicationStep2PageState extends State<ApplicationStep2Page> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _finish() async {
    if (!_formKey.currentState!.validate()) return;

    widget.data
      ..email = _email.text.trim()
      ..phone = _phone.text.trim();

    // TODO: 여기서 백엔드 validateInfo 호출 붙이면 됨
    // ex) await CardApplyService.validateInfo(...)

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('임시 완료'),
        content: Text('입력 요약:\n${widget.data.toJson()}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const _StepHeader(current: 2, total: 2),
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
                      decoration: _fieldDec('이메일'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '이메일을 입력하세요';
                        final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
                        return ok ? null : '이메일 형식이 올바르지 않습니다';
                      },
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
                      decoration: _fieldDec('휴대전화'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                      (v == null || v.trim().length < 9) ? '휴대전화 번호를 입력하세요' : null,
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
              onPressed: _finish,
              child: const Text('다음'),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
