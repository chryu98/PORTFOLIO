// lib/ApplicationStep1Page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ApplicationStep2Page.dart';
import 'user/service/Card_Apply_Service.dart';

const kPrimaryRed = Color(0xffB91111);

/// 두 단계에서 주고받을 임시 폼 데이터
class ApplicationFormData {
  int? applicationNo;
  int? cardNo;
  bool? isCreditCard;

  String? name;
  String? engFirstName;
  String? engLastName;
  String? rrnFront; // 6자리
  String? rrnBack;  // 7자리

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

/// 상단 얇은 단계 표시 바
class _StepHeader extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const _StepHeader({required this.current, this.total = 2});

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

class ApplicationStep1Page extends StatefulWidget {
  // ✅ cardNo는 validate 호출에 꼭 필요하므로 필수로 변경
  final int cardNo;
  final int? applicationNo; // /start에서 받은 값(선택)
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

  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _engFirst.dispose();
    _engLast.dispose();
    _rrnFront.dispose();
    _rrnBack.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ApplicationStep2Page(data: data)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? '검증 실패')),
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
            const _StepHeader(current: 1, total: 2),
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
                      controller: _name,
                      decoration: _fieldDec('이름'),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '이름을 입력하세요' : null,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '여권 이름과 동일해야 합니다.\n* 여권 이름과 다르면 해외에서 카드를 사용할 수 없습니다.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _engLast,
                      decoration: _fieldDec('영문 성'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '영문 성을 입력하세요' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _engFirst,
                      decoration: _fieldDec('영문 이름'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '영문 이름을 입력하세요' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _rrnFront,
                      decoration: _fieldDec('주민등록번호 앞자리'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (v) =>
                      (v == null || v.length != 6) ? '앞 6자리를 입력하세요' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _rrnBack,
                      decoration: _fieldDec('주민등록번호 뒷자리'),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                      validator: (v) =>
                      (v == null || v.length != 7) ? '뒤 7자리를 입력하세요' : null,
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
              onPressed: _loading ? null : _submit,
              child: _loading
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
