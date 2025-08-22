// lib/custom/custom_benefit_page.dart
import 'package:bnkandroid/user/service/custom_card_service.dart';
import 'package:flutter/material.dart';


const kRed = Color(0xFFE4002B); // (있다면 기존 kPrimaryRed로 대체)

class CustomBenefitPage extends StatefulWidget {
  final int applicationNo; // 필요시 다음 단계 연계용
  final int customNo;      // 이 페이지 핵심 식별자

  const CustomBenefitPage({
    super.key,
    required this.applicationNo,
    required this.customNo,
  });

  @override
  State<CustomBenefitPage> createState() => _CustomBenefitPageState();
}

class _CustomBenefitPageState extends State<CustomBenefitPage> {
  bool _loading = true;
  bool _saving = false;
  CustomCardInfo? _info;

  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  // 빠른 문구(칩) 프리셋
  final List<String> _presets = const [
    '영화 30% 할인', '커피 10% 할인', '대중교통 5% 적립',
    '편의점 5% 할인', '온라인쇼핑 7% 적립', '주유 100원/L 할인',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final info = await CustomCardService.fetchOne(widget.customNo);
      if (!mounted) return;
      _info = info;
      _ctrl.text = info.customService ?? '';
    } catch (e) {
      if (!mounted) return;
      _toast('정보 조회 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ok = await CustomCardService.saveBenefit(
        customNo: widget.customNo,
        customService: _ctrl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        _toast('혜택이 저장되었습니다.');
        Navigator.of(context).pop(true); // or 다음 단계로 이동
      } else {
        _toast('저장 실패. 잠시 후 다시 시도해 주세요.');
      }
    } catch (e) {
      if (!mounted) return;
      _toast('오류: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _appendPreset(String s) {
    final now = _ctrl.text.trim();
    final next = now.isEmpty ? s : '$now\n• $s';
    _ctrl.text = next;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final st = _info?.statusEnum ?? CustomStatus.unknown;
    final disabled = st != CustomStatus.approved; // 승인 전에는 편집 잠금
    final statusLabel = switch (st) {
      CustomStatus.approved => '승인됨',
      CustomStatus.rejected => '반려됨',
      CustomStatus.pending  => '검토 중',
      _ => '알 수 없음',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('커스텀 혜택 설정'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(statusLabel),
              backgroundColor: switch (st) {
                CustomStatus.approved => const Color(0xFFE8F5E9),
                CustomStatus.rejected => const Color(0xFFFFEBEE),
                CustomStatus.pending  => const Color(0xFFFFF8E1),
                _ => const Color(0xFFEDEFF2),
              },
              labelStyle: TextStyle(
                color: switch (st) {
                  CustomStatus.approved => const Color(0xFF2E7D32),
                  CustomStatus.rejected => const Color(0xFFC62828),
                  CustomStatus.pending  => const Color(0xFFF9A825),
                  _ => const Color(0xFF5F6B7A),
                },
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // 1) 렌더된 카드 이미지 미리보기
          Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E8EC)),
              boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0F000000))],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('최종 이미지', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1.586, // 카드 비율(신용카드 규격)
                    child: Image.network(
                      CustomCardService.imageUrl(widget.customNo),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF5F7FA),
                        alignment: Alignment.center,
                        child: const Text('이미지를 불러오지 못했습니다.'),
                      ),
                    ),
                  ),
                ),
                if (_info?.aiReason?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text('AI 검토 메모: ${_info!.aiReason!}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
                if (_info?.reason?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text('반려 사유: ${_info!.reason!}',
                      style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2) 혜택 커스텀 편집
          Form(
            key: _formKey,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E8EC)),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0F000000))],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('혜택 설명', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _ctrl,
                    enabled: !disabled,
                    maxLines: 6,
                    minLines: 4,
                    decoration: const InputDecoration(
                      hintText: '예) 영화 30% / 커피 10% / 교통 5% 적립 등',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return '혜택 내용을 입력해 주세요.';
                      if (t.length > 1800) return '최대 1800자까지 가능합니다.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _presets.map((s) {
                      return ActionChip(
                        label: Text(s),
                        onPressed: disabled ? null : () => _appendPreset(s),
                      );
                    }).toList(),
                  ),
                  if (disabled) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '※ 승인(PENDING→APPROVED) 후에만 혜택 편집이 가능합니다.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (disabled || _saving) ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: kRed),
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: const Text('저장'),
            ),
          ),
        ),
      ),
    );
  }
}
