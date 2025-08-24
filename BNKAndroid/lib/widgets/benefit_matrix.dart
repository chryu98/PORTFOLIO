// lib/widgets/benefit_matrix.dart
import 'package:flutter/material.dart';

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
  final int maxPercent;
  final int step;

  const CategorySpec({
    required this.name,
    required this.icon,
    this.subs = const [],
    this.minPercent = 0,
    this.maxPercent = 10,
    this.step = 1,
  });

  String get displayName => name;
}

/// 기본 카테고리 스펙(예시)
const List<CategorySpec> kDefaultSpecs = [
  CategorySpec(
    name: '편의점',
    icon: Icons.storefront_rounded,
    subs: ['GS25', 'CU', '이마트24', '세븐일레븐'],
    maxPercent: 7,
  ),
  CategorySpec(
    name: '베이커리',
    icon: Icons.cookie_rounded,
    subs: ['파리바게뜨', '뚜레쥬르', '던킨', '크리스피'],
  ),
  CategorySpec(
    name: '주유',
    icon: Icons.local_gas_station_rounded,
    subs: ['SK에너지', 'GS칼텍스', '현대오일뱅크', 'S-OIL'],
  ),
  CategorySpec(
    name: '영화',
    icon: Icons.movie_creation_rounded,
    subs: ['CGV', '롯데시네마', '메가박스'],
  ),
  CategorySpec(
    name: '쇼핑',
    icon: Icons.shopping_bag_rounded,
    subs: ['쿠팡', '마켓컬리', 'G마켓', '11번가'],
  ),
  CategorySpec(
    name: '배달앱',
    icon: Icons.delivery_dining_rounded,
    subs: ['배달의민족', '요기요', '쿠팡이츠'],
  ),
  CategorySpec(
    name: '대중교통',
    icon: Icons.directions_transit_rounded,
  ),
  CategorySpec(
    name: '이동통신',
    icon: Icons.wifi_rounded,
    subs: ['SKT', 'KT', 'LGU+'],
  ),
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

/// 카테고리 → 자연스러운 명사 치환(원하면 수정)
const Map<String, String> _brandNoun = {
  '쇼핑': '쇼핑몰',
  '영화': '영화관',
  '편의점': '편의점',
  '배달앱': '배달앱',
  '대중교통': '대중교통',
  '이동통신': '이동통신',
  '주유': '주유소',
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

  const BenefitMatrix({
    super.key,
    required this.selections,
    required this.onChanged,
    this.specs = kDefaultSpecs,
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
    // 외부에서 selections가 갱신되면 반영
    if (!identical(oldWidget.selections, widget.selections)) {
      _map = {...widget.selections};
    }
  }

  void _emit() => widget.onChanged({..._map});

  CategoryChoice _get(String name) => _map[name] ?? const CategoryChoice();

  void _set(String name, CategoryChoice value) {
    _map[name] = value;
    _emit();
    setState(() {});
  }

  Future<void> _openPercentSheet(CategorySpec spec) async {
    final cur = _get(spec.name);
    int temp = cur.percent;

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
                Text('원하는 혜택 비율을 설정하세요', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        temp = (temp - spec.step).clamp(spec.minPercent, spec.maxPercent);
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                    const SizedBox(width: 16),
                    Text('$temp%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 16),
                    _RoundIconButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        temp = (temp + spec.step).clamp(spec.minPercent, spec.maxPercent);
                        (ctx as Element).markNeedsBuild();
                      },
                    ),
                    const Spacer(),
                    Text('최대 ${spec.maxPercent}%', style: const TextStyle(color: Colors.black54)),
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

    // 비율 0이면 브랜드 초기화
    if (picked == 0) {
      _set(spec.name, const CategoryChoice(percent: 0, sub: null));
      return;
    }

    // 비율만 변경
    _set(spec.name, _get(spec.name).copyWith(percent: picked));

    // 브랜드 필요하고 아직 선택 안했으면 곧바로 브랜드 시트
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
                /// 🔹 요청 카피: 주로 쓰는 {카테고리}{은/는} 어디인가요?
                Text(
                  _brandTitle(spec.displayName),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  '선택하신 브랜드 기준으로 혜택을 최적화해 드릴게요',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
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
    final next = (c.percent + spec.step).clamp(spec.minPercent, spec.maxPercent);
    _set(spec.name, c.copyWith(percent: next));
    if (next > 0 && spec.subs.isNotEmpty && (c.sub == null || c.sub!.isEmpty)) {
      _openBrandSheet(spec);
    }
  }

  void _dec(CategorySpec spec) {
    final c = _get(spec.name);
    final next = (c.percent - spec.step).clamp(spec.minPercent, spec.maxPercent);
    // 0이 되면 브랜드 초기화
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
            onTap: () => _openPercentSheet(spec),
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
                        child: Text(spec.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF3B82F6)),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _RoundIconButton(icon: Icons.remove_rounded, onTap: () => _dec(spec)),
                      const SizedBox(width: 12),
                      Text('${choice.percent}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 12),
                      _RoundIconButton(icon: Icons.add_rounded, onTap: () => _inc(spec)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          await _openPercentSheet(spec);
                        },
                        child: const Text('자세히'),
                      ),
                    ],
                  ),
                  if ((choice.sub ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      choice.sub!,
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
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
