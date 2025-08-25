// ============================================================================
// lib/custom/custom_benefit_page.dart
// UX v6: 총합 20% 제한, 프리셋, 진행바+남은%, 하단 고정 Dock(큰 '카드 발급')
// - 카드 탭/플러스 시 20% 초과 가드 메시지 (BenefitMatrix 쪽에서 처리)
// ============================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bnkandroid/user/service/custom_card_service.dart';

// 매트릭스(퍼센트/브랜드 선택)
import 'package:bnkandroid/widgets/benefit_matrix.dart'
    show BenefitMatrix, CategoryChoice, CategorySpec, kDefaultSpecs;

const kBrand = Color(0xFFE4002B);
const _kMaxPercent = 20; // ✅ 총합 제한 20%

class CustomBenefitPage extends StatefulWidget {
  final int applicationNo;
  final int customNo;
  final bool showImagePreview;
  final bool allowEditBeforeApproval;
  final Uint8List? initialPreviewBytes;

  const CustomBenefitPage({
    super.key,
    required this.applicationNo,
    required this.customNo,
    this.showImagePreview = false,
    this.allowEditBeforeApproval = false,
    this.initialPreviewBytes,
  });

  @override
  State<CustomBenefitPage> createState() => _CustomBenefitPageState();
}

class _CustomBenefitPageState extends State<CustomBenefitPage> {
  bool _loading = true;
  bool _saving = false;
  CustomCardInfo? _info;

  /// 카테고리 선택 상태: 예) '편의점' -> {percent:5, sub:'CU'}
  Map<String, CategoryChoice> _choices = {};

  /// 스펙(아이콘/브랜드 목록/퍼센트 범위)
  final List<CategorySpec> _specs = kDefaultSpecs; // (항목별 maxPercent=20)

  /// 프리셋 (총합 20%)
  late final Map<String, Map<String, CategoryChoice>> _presets = {
    '편의점형': {
      '편의점': const CategoryChoice(percent: 10, sub: 'CU'),
      '배달앱': const CategoryChoice(percent: 5, sub: '배달의민족'),
      '쇼핑': const CategoryChoice(percent: 5, sub: '쿠팡'),
    },
    '주유형': {
      '주유': const CategoryChoice(percent: 12, sub: '현대오일뱅크'),
      '대중교통': const CategoryChoice(percent: 8),
    },
    '병원형': {
      '병원': const CategoryChoice(percent: 10),
      '대중교통': const CategoryChoice(percent: 5),
      '쇼핑': const CategoryChoice(percent: 5, sub: '마켓컬리'),
    },
    '온라인형': {
      '쇼핑': const CategoryChoice(percent: 10, sub: '쿠팡'),
      '배달앱': const CategoryChoice(percent: 5, sub: '요기요'),
      '영화': const CategoryChoice(percent: 5, sub: 'CGV'),
    },
  };

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
      // selections 서버 저장 시 여기서 불러오기
      // _choices = await CustomCardService.fetchBenefitMatrix(widget.customNo);
    } catch (e) {
      if (!mounted) return;
      _toast('정보 조회 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  int get _totalPercent =>
      _choices.values.fold(0, (p, e) => p + e.percent.clamp(0, _kMaxPercent));
  int get _remaining => (_kMaxPercent - _totalPercent).clamp(-999, 999);
  bool get _isOver => _totalPercent > _kMaxPercent;

  /// 선택 상태 → 서버 전송용 설명 문구 자동 생성
  String _composeTextFromChoices() {
    final items = _choices.entries
        .where((e) => e.value.percent > 0)
        .toList()
      ..sort((a, b) {
        final c = b.value.percent.compareTo(a.value.percent);
        return c != 0 ? c : a.key.compareTo(b.key);
      });

    final lines = <String>[];
    for (final e in items) {
      final cat = e.key;
      final sub = (e.value.sub ?? '').trim();
      final percent = e.value.percent;
      final accrueCats = {'대중교통', '교통', '이동통신', '주유', '배달앱'};
      final label = accrueCats.contains(cat) ? '적립' : '할인';
      final subPart = sub.isEmpty ? '' : '($sub) ';
      lines.add('• $cat ${subPart}$percent% $label');
    }
    return lines.join('\n');
  }

  bool _validateBeforeSave() {
    final hasAny = _choices.values.any((c) => c.percent > 0);
    if (!hasAny) {
      _toast('최소 1개 이상의 혜택을 선택해 주세요.');
      return false;
    }
    for (final e in _choices.entries) {
      final spec = _specs.firstWhere(
            (s) => s.name == e.key,
        orElse: () => const CategorySpec(name: '', icon: Icons.help_outline),
      );
      if (e.value.percent > 0 && spec.subs.isNotEmpty) {
        if (e.value.sub == null || e.value.sub!.isEmpty) {
          _toast('${e.key} 브랜드를 선택해 주세요.');
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _save() async {
    if (_isOver) {
      _toast('총합이 20%를 초과했어요. 자동맞춤으로 정리해 주세요.');
      HapticFeedback.selectionClick();
      return;
    }
    if (!_validateBeforeSave()) return;

    setState(() => _saving = true);
    try {
      final composed = _composeTextFromChoices();
      final ok1 = await CustomCardService.saveBenefit(
        customNo: widget.customNo,
        customService: composed,
      );
      if (!mounted) return;
      if (ok1) {
        _toast('혜택이 저장되었습니다.');
        Navigator.of(context).pop(true);
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

  CategorySpec _specOf(String name) => _specs.firstWhere(
        (s) => s.name == name,
    orElse: () => const CategorySpec(name: '', icon: Icons.help_outline),
  );

  void _applyPreset(String name) {
    final preset = _presets[name];
    if (preset == null) return;

    final Map<String, CategoryChoice> next = {};
    for (final e in preset.entries) {
      final spec = _specOf(e.key);
      final pct = e.value.percent.clamp(spec.minPercent, spec.maxPercent);
      next[e.key] = e.value.copyWith(percent: pct);
    }
    setState(() => _choices = next);
    _toast('“$name” 프리셋을 적용했어요.');
  }

  /// 총합 20% 자동 정렬: 과할 땐 비례 축소, 모자라면 상위 항목부터 채움
  Future<void> _autoBalance() async {
    if (_choices.isEmpty) return;
    final target = _kMaxPercent; // 20

    final entries = _choices.entries
        .where((e) => e.value.percent > 0)
        .toList()
      ..sort((a, b) => b.value.percent.compareTo(a.value.percent));

    final total = _totalPercent;

    if (total > target) {
      final scale = target / total;
      final Map<String, CategoryChoice> next = {};
      for (final e in entries) {
        final spec = _specOf(e.key);
        final raw = (e.value.percent * scale);
        int snapped = (((raw / spec.step).round() * spec.step)
            .clamp(spec.minPercent, spec.maxPercent))
            .toInt();
        next[e.key] = e.value.copyWith(percent: snapped);
      }
      int diff = target - next.values.fold(0, (p, v) => p + v.percent);
      for (final e in entries) {
        if (diff == 0) break;
        final spec = _specOf(e.key);
        final cur = next[e.key]!.percent;
        final tryVal = ((cur + diff.sign * spec.step)
            .clamp(spec.minPercent, spec.maxPercent))
            .toInt();
        if (tryVal != cur) {
          next[e.key] = e.value.copyWith(percent: tryVal);
          diff = target - next.values.fold(0, (p, v) => p + v.percent);
        }
      }
      setState(() => _choices = next);
      _toast('총합을 20%로 맞췄어요.');
      HapticFeedback.lightImpact();
      return;
    }

    int remain = target - total;
    final Map<String, CategoryChoice> next = {..._choices};
    for (final e in entries) {
      if (remain <= 0) break;
      final spec = _specOf(e.key);
      final cur = next[e.key]!.percent;
      final can = (spec.maxPercent - cur).clamp(0, target);
      if (can <= 0) continue;
      final stepFill = (remain ~/ spec.step) * spec.step;
      final add = stepFill.clamp(0, can);
      if (add > 0) {
        next[e.key] = e.value.copyWith(percent: cur + add);
        remain -= add;
      }
    }
    setState(() => _choices = next);
    _toast('남은 퍼센트를 채워 20%로 맞췄어요.');
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final st = _info?.statusEnum ?? CustomStatus.unknown;
    final disabled = widget.allowEditBeforeApproval ? false : (st != CustomStatus.approved);

    final statusLabel = switch (st) {
      CustomStatus.approved => '승인됨',
      CustomStatus.rejected => '반려됨',
      CustomStatus.pending  => '검토 중',
      _ => '알 수 없음',
    };

    final statusColor = switch (st) {
      CustomStatus.approved => const Color(0xFF0EA5E9),
      CustomStatus.rejected => const Color(0xFFEF4444),
      CustomStatus.pending  => const Color(0xFFF59E0B),
      _ => const Color(0xFF94A3B8),
    };

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('커스텀 혜택 설정', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
            ),
          )
        ],
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120), // ⬅️ bottom dock 여백
          children: [
            if (widget.showImagePreview)
              _SectionCard(
                title: '최종 이미지',
                child: _PreviewCardImage(
                  customNo: widget.customNo,
                  info: _info,
                  bytes: widget.initialPreviewBytes,
                ),
              ),
            if (widget.showImagePreview) const SizedBox(height: 12),

            // 프리셋
            _SectionCard(
              title: '추천 프리셋',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in _presets.keys)
                    ActionChip(
                      label: Text(name),
                      onPressed: () => _applyPreset(name),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 선택 요약
            _SectionCard(
              title: '선택 요약',
              child: _SelectedSummaryGrid(
                choices: _choices,
                specs: _specs,
              ),
            ),

            const SizedBox(height: 12),

            // 실제 선택/편집 매트릭스
            _SectionCard(
              title: '원하시는 혜택을 골라주세요',
              trailing: _TotalPill(total: _totalPercent),
              child: BenefitMatrix(
                selections: _choices,
                onChanged: (next) => setState(() => _choices = {...next}),
                specs: _specs,
                maxTotal: _kMaxPercent, // ✅ 총합 20% 제한 전달
              ),
            ),
          ],
        ),
      ),

      // ▶ 하단 고정 Dock
      bottomNavigationBar: _BottomDock(
        total: _totalPercent,
        remaining: _remaining,
        over: _isOver,
        saving: _saving,
        onAuto: _autoBalance,
        onSave: _save,
      ),
    );
  }
}

/* -------------------- Bottom Dock -------------------- */

class _BottomDock extends StatelessWidget {
  final int total;
  final int remaining;
  final bool over;
  final bool saving;
  final VoidCallback onAuto;
  final VoidCallback onSave;

  const _BottomDock({
    required this.total,
    required this.remaining,
    required this.over,
    required this.saving,
    required this.onAuto,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, -8)),
          ],
          border: const Border(top: BorderSide(color: Color(0xFFE7E8EC))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 라벨 + 진행바 (중앙 정렬)
            Column(
              children: [
                Text(
                  over
                      ? '총합 $total% · 초과 ${total - _kMaxPercent}%'
                      : '총합 $total% · 남은 ${remaining.abs()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: over ? Colors.redAccent : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (total / _kMaxPercent).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEDEFF3),
                    color: over ? Colors.redAccent : kBrand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 버튼 라인: 자동맞춤 + 큰 카드 발급
            Row(
              children: [
                OutlinedButton(
                  onPressed: onAuto,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text('자동맞춤(20%)'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: saving || over ? null : onSave,
                    icon: saving
                        ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.credit_card_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('카드 발급', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrand,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: kBrand.withOpacity(.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
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

/* -------------------- 선택 요약(브랜드 + 퍼센트) -------------------- */

class _SelectedSummaryGrid extends StatelessWidget {
  final Map<String, CategoryChoice> choices;
  final List<CategorySpec> specs;

  const _SelectedSummaryGrid({required this.choices, required this.specs});

  @override
  Widget build(BuildContext context) {
    final items = choices.entries
        .where((e) => e.value.percent > 0)
        .toList()
      ..sort((a, b) {
        final c = b.value.percent.compareTo(a.value.percent);
        return c != 0 ? c : a.key.compareTo(b.key);
      });

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '아직 선택한 혜택이 없어요. 아래에서 혜택을 선택해 주세요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      );
    }

    return LayoutBuilder(builder: (context, cons) {
      final w = cons.maxWidth;
      final col = w < 480 ? 2 : w < 720 ? 3 : 4;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: col,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.1,
        ),
        itemBuilder: (_, i) {
          final e = items[i];
          final spec = specs.firstWhere(
                (s) => s.name == e.key,
            orElse: () => const CategorySpec(name: '', icon: Icons.local_offer_rounded),
          );
          final sub = (e.value.sub ?? '').trim();
          final percent = e.value.percent;
          final accrueCats = {'대중교통', '교통', '이동통신', '주유', '배달앱'};
          final label = accrueCats.contains(e.key) ? '적립' : '할인';

          return _SummaryCard(
            icon: spec.icon,
            title: e.key,
            subtitle: sub.isEmpty ? '$percent% $label' : '$sub · $percent% $label',
          );
        },
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SummaryCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F8FA), Color(0xFFEFF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EC)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x0F000000), offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) {
    final showHeader = (title != null && (title!.trim().isNotEmpty));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E8EC)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x0F000000), offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader)
            Row(children: [
              Text(title!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              if (trailing != null) trailing!,
            ]),
          if (showHeader) const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TotalPill extends StatelessWidget {
  final int total;
  const _TotalPill({required this.total});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('총합 ${total}%', style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/* -------------------- Preview image -------------------- */

class _PreviewCardImage extends StatelessWidget {
  final int customNo;
  final CustomCardInfo? info;
  final Uint8List? bytes;

  const _PreviewCardImage({
    required this.customNo,
    required this.info,
    this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (bytes != null && bytes!.isNotEmpty) {
      img = Image.memory(bytes!, fit: BoxFit.cover);
    } else {
      img = Image.network(
        CustomCardService.imageUrl(customNo),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFF5F7FA),
          alignment: Alignment.center,
          child: const Text('이미지 준비 중입니다.'),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(aspectRatio: 1.586, child: img),
    );
  }
}
