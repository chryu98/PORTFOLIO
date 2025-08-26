// lib/application/ApplicationStep3JobPage.dart
import 'package:flutter/material.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed;
import 'user/service/card_apply_service.dart' as apply;
import 'ApplicationStep4OcrPage.dart';
// ✅ 5페이지(계좌연결)로 바로 이동
import 'ApplicationStep5AccountPage.dart';

// -------------------------
// 개발용: OCR 스킵 여부 (true면 Step5로 직행)
// -------------------------
const bool kSkipOcrForDev = false;

/// Step 3: 직업/거래목적/자금출처
class ApplicationStep3JobPage extends StatefulWidget {
  final int applicationNo;
  final int cardNo; // ✅ Step5 로 넘길 카드번호

  const ApplicationStep3JobPage({
    super.key,
    required this.applicationNo,
    required this.cardNo,
  });

  @override
  State<ApplicationStep3JobPage> createState() => _ApplicationStep3JobPageState();
}

class _ApplicationStep3JobPageState extends State<ApplicationStep3JobPage> {
  final _formKey = GlobalKey<FormState>();

  String? _job;
  String? _purpose;
  String? _fundSource;
  bool _saving = false;

  final List<String> _jobs = const ['직장인', '자영업자', '프리랜서', '학생', '주부', '무직', '기타'];
  final List<String> _purposes = const ['일상결제', '해외결제', '급여이체', '저축/적립', '투자', '고액결제', '기타'];
  final List<String> _fundSources = const ['근로소득', '사업소득', '부동산 임대소득', '금융소득', '기타소득'];

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: kPrimaryRed),
    ),
  );

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label을(를) 선택하세요.' : null;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final ok = await apply.CardApplyService.saveJobInfo(
        applicationNo: widget.applicationNo,
        job: _job!,
        purpose: _purpose!,
        fundSource: _fundSource!,
      );
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 실패')));
        return;
      }



      // ✅ OCR 스킵: Step5(계좌연결)로 곧장 이동
      if (kSkipOcrForDev) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ApplicationStep5AccountPage(
              applicationNo: widget.applicationNo,
              cardNo: widget.cardNo,
            ),
          ),
        );
      } else {
        //원래 흐름(필요 시 사용)
        await Navigator.of(context).push(
           MaterialPageRoute(
             builder: (_) => ApplicationStep4OcrPage(
              applicationNo: widget.applicationNo,
              cardNo: widget.cardNo,
             ),
           ),
         );
      }
    } on apply.ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _saving;

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
            const _StepHeader3(current: 3, total: 6), // 표시만 그대로 둠
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('이용 정보를 선택하세요',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    FullScreenSelectField(
                      value: _job,
                      options: _jobs,
                      decoration: _dec('직업선택'),
                      onChanged: (v) => setState(() => _job = v),
                      validator: (v) => _required(v, '직업'),
                    ),
                    const SizedBox(height: 12),
                    FullScreenSelectField(
                      value: _purpose,
                      options: _purposes,
                      decoration: _dec('거래 목적'),
                      onChanged: (v) => setState(() => _purpose = v),
                      validator: (v) => _required(v, '거래 목적'),
                    ),
                    const SizedBox(height: 12),
                    FullScreenSelectField(
                      value: _fundSource,
                      options: _fundSources,
                      decoration: _dec('자금 출처'),
                      onChanged: (v) => setState(() => _fundSource = v),
                      validator: (v) => _required(v, '자금 출처'),
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
              onPressed: isBusy ? null : _save,
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

class _StepHeader3 extends StatelessWidget {
  final int current;
  final int total;
  const _StepHeader3({required this.current, this.total = 4});

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

/// 풀스크린 선택 위젯
class FullScreenSelectField extends FormField<String> {
  FullScreenSelectField({
    Key? key,
    required List<String> options,
    String? value,
    required InputDecoration decoration,
    ValueChanged<String?>? onChanged,
    FormFieldValidator<String>? validator,
  }) : super(
    key: key,
    initialValue: value,
    validator: validator,
    builder: (state) {
      final selected = state.value;
      final hasError = state.hasError;
      final theme = Theme.of(state.context);

      Future<void> openPage() async {
        final result = await Navigator.of(state.context).push<String>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _SelectFullScreenPage(
              title: decoration.hintText ?? '선택',
              options: options,
              initial: selected,
            ),
          ),
        );
        if (result != null) {
          state.didChange(result);
          onChanged?.call(result);
        }
      }

      final showHint = (selected == null || selected.isEmpty);
      final dec = showHint ? decoration : decoration.copyWith(hintText: null);

      return InkWell(
        onTap: openPage,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          isEmpty: showHint,
          decoration: dec.copyWith(
            errorText: hasError ? state.errorText : null,
            suffixIcon:
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
          ),
          child: showHint
              ? const SizedBox(height: 20)
              : Text(
            selected!,
            style: TextStyle(
              color: Colors.black87,
              fontSize: theme.textTheme.bodyMedium?.fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    },
  );
}

class _SelectFullScreenPage extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? initial;

  const _SelectFullScreenPage({
    Key? key,
    required this.title,
    required this.options,
    this.initial,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sel = initial;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        leading: const CloseButton(color: Colors.black87),
        title: Text(title,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ColoredBox(
          color: Colors.white,
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F3F5)),
            itemBuilder: (_, i) {
              final opt = options[i];
              final isSelected = opt == sel;
              return ListTile(
                tileColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                minVerticalPadding: 12,
                title: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing:
                isSelected ? const Icon(Icons.check_rounded, color: kPrimaryRed) : null,
                onTap: () => Navigator.pop(context, opt),
              );
            },
          ),
        ),
      ),
    );
  }
}
