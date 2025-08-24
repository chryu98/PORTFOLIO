// lib/custom/custom_benefit_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:bnkandroid/user/service/custom_card_service.dart';

// 매트릭스(퍼센트/브랜드 선택)
import 'package:bnkandroid/widgets/benefit_matrix.dart'
    show BenefitMatrix, CategoryChoice, CategorySpec, kDefaultSpecs;

const kBrand = Color(0xFFE4002B);

class CustomBenefitPage extends StatefulWidget {
  final int applicationNo;
  final int customNo;
  final bool showImagePreview;
  final bool allowEditBeforeApproval;

  /// 전 단계에서 만든 카드 미리보기 이미지(bytes). 있으면 우선 노출.
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

  /// 스펙(아이콘/브랜드 목록/퍼센트 범위) – 필요 시 정책에 맞게 교체
  final List<CategorySpec> _specs = kDefaultSpecs;

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

      // 서버에 매트릭스를 저장한다면 여기서 불러와 _choices 세팅
      // _choices = await CustomCardService.fetchBenefitMatrix(widget.customNo);
    } catch (e) {
      if (!mounted) return;
      _toast('정보 조회 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───────────────────────── helpers

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  int get _totalPercent =>
      _choices.values.fold(0, (p, e) => p + e.percent.clamp(0, 100));

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
      // 간단 라벨 룰: 적립 카테고리
      final accrueCats = {'대중교통', '교통', '이동통신', '주유', '배달앱'};
      final label = accrueCats.contains(cat) ? '적립' : '할인';
      final subPart = sub.isEmpty ? '' : '($sub) ';
      lines.add('• $cat ${subPart}$percent% $label');
    }
    return lines.join('\n');
  }

  /// 저장 전 검사: 1) 최소 한 개 선택 2) 브랜드 필요한데 미선택이면 에러
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
    if (!_validateBeforeSave()) return;

    setState(() => _saving = true);
    try {
      // 텍스트 영역은 UI에서 제거했지만, 서버에는 자동 생성 문구를 보냄
      final composed = _composeTextFromChoices();

      final ok1 = await CustomCardService.saveBenefit(
        customNo: widget.customNo,
        customService: composed,
      );

      // 매트릭스도 저장할 거면 API에 맞춰 주석 해제
      // final payload = _choices.map((k, v) => MapEntry(k, {
      //   'percent': v.percent,
      //   'sub': v.sub,
      // }));
      // final ok2 = await CustomCardService.saveBenefitMatrix(
      //   customNo: widget.customNo,
      //   body: payload,
      // );

      if (!mounted) return;
      if (ok1 /* && ok2 */) {
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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

            // 1) 선택 요약(브랜드 + 퍼센트 포함) — 기존 "키워드/문구목록" 섹션 대체
            _SectionCard(
              title: '선택 요약',
              child: _SelectedSummaryGrid(
                choices: _choices,
                specs: _specs,
              ),
            ),

            const SizedBox(height: 12),

            // 2) 실제 선택/편집 매트릭스
            _SectionCard(
              title: '선택 매트릭스',
              trailing: _TotalPill(total: _totalPercent),
              child: BenefitMatrix(
                selections: _choices,
                onChanged: (next) => setState(() => _choices = {...next}),
              ),
            ),

            // ✅ 텍스트 "혜택 설명" 섹션 완전 제거 (요청사항)
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_saving || disabled) ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: kBrand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _saving
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.save_rounded),
              label: const Text('저장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
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
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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

/* -------------------- Reusable fintech-ish section -------------------- */

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

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

/* -------------------- Preview image (bytes > network > placeholder) --- */

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
