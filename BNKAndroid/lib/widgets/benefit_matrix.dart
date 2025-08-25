// ============================================================================
// lib/widgets/benefit_matrix.dart
// UX v6: '자세히' 제거, 중앙정렬(− % +), 20% 총합 가드
// - 카드 탭 시: 총합이 가득 찼고 현재 항목이 0%면 토스트만 띄우고 시트 미오픈
// - + 버튼/시트 + 버튼: 총합 초과 시 토스트 + 햅틱, 증가 차단
// - 롱프레스: 0% 리셋
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 선택 결과 모델
class CategoryChoice {
  final int percent;
  final String? sub;
  const CategoryChoice({this.percent = 0, this.sub});

  CategoryChoice copyWith({int? percent, String? sub}) =>
      CategoryChoice(percent: percent ?? this.percent, sub: sub ?? this.sub);
}

/// 스펙(아이콘/브랜드/퍼센트 제약)
class CategorySpec {
  final String name;
  final IconData icon;
  final List<String> subs; // 브랜드 목록(없으면 빈 리스트)
  final int minPercent;
  final int maxPercent; // 기본 20%
  final int step;

  const CategorySpec({
    required this.name,
    required this.icon,
    this.subs = const [],
    this.minPercent = 0,
    this.maxPercent = 20,
    this.step = 1,
  });

  String get displayName => name;
}

/// 기본 카테고리 스펙(예시) – 모두 maxPercent=20 + 병원 추가
const List<CategorySpec> kDefaultSpecs = [
  CategorySpec(name: '편의점', icon: Icons.storefront_rounded, subs: ['GS25', 'CU', '이마트24', '세븐일레븐']),
  CategorySpec(name: '베이커리', icon: Icons.cookie_rounded, subs: ['파리바게뜨', '뚜레쥬르', '던킨', '크리스피']),
  CategorySpec(name: '주유', icon: Icons.local_gas_station_rounded, subs: ['SK에너지', 'GS칼텍스', '현대오일뱅크', 'S-OIL']),
  CategorySpec(name: '영화', icon: Icons.movie_creation_rounded, subs: ['CGV', '롯데시네마', '메가박스']),
  CategorySpec(name: '쇼핑', icon: Icons.shopping_bag_rounded, subs: ['쿠팡', '마켓컬리', 'G마켓', '11번가']),
  CategorySpec(name: '배달앱', icon: Icons.delivery_dining_rounded, subs: ['배달의민족', '요기요', '쿠팡이츠']),
  CategorySpec(name: '대중교통', icon: Icons.directions_transit_rounded),
  CategorySpec(name: '이동통신', icon: Icons.wifi_rounded, subs: ['SKT', 'KT', 'LGU+']),
  CategorySpec(name: '병원', icon: Icons.local_hospital_rounded),
];

/// 조사 붙이기(을/를, 은/는 등)
String _josa(String word, String pair) {
  final parts = pair.split('/');
  if (parts.length != 2) return pair;
  if (word.isEmpty) return parts[1];
  final code = word.codeUnitAt(word.length - 1);
  final isHangul = code >= 0xAC00 && code <= 0xD7A3;
  var hasBatchim = false;
  if (isHangul) {
    final jong = (code - 0xAC00) % 28;
    hasBatchim = jong != 0;
  }
  return hasBatchim ? parts[0] : parts[1];
}

const Map<String, String> _brandNoun = {
  '쇼핑': '쇼핑몰',
  '영화': '영화관',
  '편의점': '편의점',
  '배달앱': '배달앱',
  '대중교통': '대중교통',
  '이동통신': '이동통신',
  '주유': '주유소',
  '병원': '병원',
};

String _brandTitle(String category) {
  final noun = _brandNoun[category] ?? category;
  final euneun = _josa(noun, '은/는');
  return '주로 쓰는 $noun$euneun 어디인가요?';
}

class BenefitMatrix extends StatefulWidget {
  final Map<String, CategoryChoice> selections;
  final List<CategorySpec> specs;
  final ValueChanged<Map<String, CategoryChoice>> onChanged;
  final int maxTotal; // ✅ 총합 제한 (부모에서 20 전달)

  const BenefitMatrix({
    super.key,
    required this.selections,
    required this.onChanged,
    this.specs = kDefaultSpecs,
    this.maxTotal = 100,
  });

  @override
  State<BenefitMatrix> createState() => _BenefitMatrixState();
}

class _BenefitMatrixState extends State<BenefitMatrix> {
  late Map<String, CategoryChoice> _map;

  @override
  void initState() {
    super.initState();
    _map = {...widget.selections};
  }

  @override
  void didUpdateWidget(covariant BenefitMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.selections, widget.selections)) {
      _map = {...widget.selections};
    }
  }

  void _emit() => widget.onChanged({..._map});

  int _total() => _map.values.fold(0, (p, c) => p + c.percent);
  CategoryChoice _get(String name) => _map[name] ?? const CategoryChoice();

  void _set(String name, CategoryChoice value) {
    _map[name] = value;
    _emit();
    setState(() {});
  }

  void _overToast() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('총합이 ${widget.maxTotal}%를 초과할 수 없어요'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _openPercentSheet(CategorySpec spec) async {
    final cur = _get(spec.name);
    int temp = cur.percent;

    // 현재 다른 항목 합
    final others = _total() - cur.percent;
    final allowedMax = (others >= widget.maxTotal)
        ? cur.percent // 이미 꽉 참 → 현재값 이상 불가
        : (cur.percent + (widget.maxTotal - others));
    final hardMax = allowedMax.clamp(spec.minPercent, spec.maxPercent).toInt();

    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${spec.displayName} 비율', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('최대 $hardMax% 까지 설정 가능', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundIconButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        temp = ((temp - spec.step).clamp(spec.minPercent, hardMax)).toInt();
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                    const SizedBox(width: 16),
                    Text('$temp%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 16),
                    _RoundIconButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        temp = ((temp + spec.step).clamp(spec.minPercent, hardMax)).toInt();
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, temp),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('적용'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;

    if (picked == 0) {
      _set(spec.name, const CategoryChoice(percent: 0, sub: null));
      return;
    }

    _set(spec.name, _get(spec.name).copyWith(percent: picked));

    if (spec.subs.isNotEmpty && (_get(spec.name).sub == null || _get(spec.name).sub!.isEmpty)) {
      await _openBrandSheet(spec);
    }
  }

  Future<void> _openBrandSheet(CategorySpec spec) async {
    String? temp = _get(spec.name).sub;

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _brandTitle(spec.displayName),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: spec.subs.map((s) {
                    final selected = s == temp;
                    return ChoiceChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (_) {
                        temp = s;
                        (ctx as Element).markNeedsBuild();
                      },
                      shape: StadiumBorder(
                        side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFCBD5E1)),
                      ),
                      selectedColor: const Color(0xFFEFF4FF),
                      labelStyle: TextStyle(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: temp == null ? null : () => Navigator.pop(ctx, temp),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('선택'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    _set(spec.name, _get(spec.name).copyWith(sub: picked));
  }

  void _inc(CategorySpec spec) {
    final c = _get(spec.name);
    final total = _total();
    final remaining = (widget.maxTotal - total).clamp(0, widget.maxTotal);
    if (remaining <= 0) {
      _overToast();
      return;
    }
    if (c.percent >= spec.maxPercent) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 ${spec.maxPercent}% 입니다'), duration: const Duration(milliseconds: 800)),
      );
      return;
    }
    final inc = spec.step.clamp(0, remaining);
    final next = ((c.percent + inc).clamp(spec.minPercent, spec.maxPercent)).toInt();
    HapticFeedback.lightImpact();
    _set(spec.name, c.copyWith(percent: next));
    if (next > 0 && spec.subs.isNotEmpty && (c.sub == null || c.sub!.isEmpty)) {
      _openBrandSheet(spec);
    }
  }

  void _dec(CategorySpec spec) {
    final c = _get(spec.name);
    if (c.percent <= spec.minPercent) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소치입니다'), duration: Duration(milliseconds: 700)),
      );
      return;
    }
    final next = ((c.percent - spec.step).clamp(spec.minPercent, spec.maxPercent)).toInt();
    HapticFeedback.lightImpact();
    _set(spec.name, c.copyWith(percent: next, sub: next == 0 ? null : c.sub));
  }

  @override
  Widget build(BuildContext context) {
    final specs = widget.specs;

    return LayoutBuilder(builder: (context, cons) {
      final w = cons.maxWidth;
      final col = w < 480 ? 2 : w < 820 ? 3 : 4;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: specs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: col,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (_, i) {
          final spec = specs[i];
          final choice = _get(spec.name);
          final selected = choice.percent > 0;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final total = _total();
              // 총합 꽉 찼고 현재 항목이 0%면 증가 의도 → 가드
              if (total >= widget.maxTotal && choice.percent == 0) {
                _overToast();
                return;
              }
              _openPercentSheet(spec);
            },
            onLongPress: () {
              if (choice.percent > 0) {
                HapticFeedback.mediumImpact();
                _set(spec.name, const CategoryChoice(percent: 0, sub: null));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF1F5FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? const Color(0xFF3B82F6) : const Color(0xFFE5E8EC),
                  width: selected ? 1.6 : 1,
                ),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0F000000), offset: Offset(0, 3))],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(spec.icon, size: 22, color: Colors.black87),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(spec.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF3B82F6)),
                    ],
                  ),
                  const Spacer(),
                  // 중앙 정렬: −  %  +
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundIconButton(icon: Icons.remove_rounded, onTap: () => _dec(spec)),
                      const SizedBox(width: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (c, anim) => ScaleTransition(scale: anim, child: c),
                        child: Text(
                          '${choice.percent}%',
                          key: ValueKey(choice.percent),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RoundIconButton(icon: Icons.add_rounded, onTap: () => _inc(spec)),
                    ],
                  ),
                  if ((choice.sub ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(choice.sub!, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                  ],
                  if (spec.subs.isNotEmpty && choice.percent > 0 && (choice.sub ?? '').isEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7E7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFFCACA)),
                      ),
                      child: const Text('브랜드 선택 필요', style: TextStyle(fontSize: 11, color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}
