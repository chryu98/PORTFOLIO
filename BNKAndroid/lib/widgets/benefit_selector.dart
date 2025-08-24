// lib/widgets/benefit_selector.dart
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// BenefitSelector
/// - sourceText 를 분석해서 카테고리(커피/영화/교통...)를 감지하고
///   감지된 카테고리를 카드(아이콘+그라데이션)로 시각화.
/// - 카드 탭으로 선택/해제 가능 (선택 상태는 onSelectedChanged 로 알림)
/// - 하단에 줄 단위 문구를 칩으로 나열.
/// - 기본 사전(_DEFAULT_CATEGORY_KEYWORDS) 제공. 프로젝트 사전 주입 가능.
/// ---------------------------------------------------------------------------
class BenefitSelector extends StatefulWidget {
  /// 감지 대상 텍스트 (혜택 설명 전체)
  final String sourceText;

  /// 이미 선택된 카테고리 (초기값/외부제어)
  final Set<String> selected;

  /// 선택 상태가 바뀔 때 호출 (전체 선택 셋 전달)
  final ValueChanged<Set<String>>? onSelectedChanged;

  /// 카테고리 키워드 사전: 카테고리명 -> 키워드 목록
  /// (미전달 시 _DEFAULT_CATEGORY_KEYWORDS 사용)
  final Map<String, List<String>>? categoryKeywords;

  /// 카테고리 메타(아이콘/그라데이션) 커스터마이즈
  final Map<String, CategoryMeta>? categoryMeta;

  /// 프리셋 문구 (상단 입력칩처럼 외부에서 보여줄 때 사용하고 싶다면)
  final List<String>? presets;

  /// 프리셋 칩 탭 시 콜백 (예: 텍스트 입력창에 추가)
  final ValueChanged<String>? onTapPreset;

  /// 타이틀 라벨 (상단)
  final String title;

  /// 문구 목록 라벨 (하단)
  final String linesTitle;

  /// 카테고리 카드 최대 가로폭 (반응형에서 너무 커지지 않도록)
  final double cardMaxWidth;

  const BenefitSelector({
    super.key,
    required this.sourceText,
    this.selected = const {},
    this.onSelectedChanged,
    this.categoryKeywords,
    this.categoryMeta,
    this.presets,
    this.onTapPreset,
    this.title = '키워드 미리보기',
    this.linesTitle = '문구 목록',
    this.cardMaxWidth = 160,
  });

  @override
  State<BenefitSelector> createState() => _BenefitSelectorState();

  // 유틸: 외부에서 재사용할 수 있도록 공개
  static Map<String, int> detectCategories(
      String text, {
        Map<String, List<String>>? categoryKeywords,
      }) {
    final lower = text.toLowerCase();
    final dict = categoryKeywords ?? _DEFAULT_CATEGORY_KEYWORDS;
    final Map<String, int> hit = {};
    for (final entry in dict.entries) {
      final cat = entry.key;
      final keywords = entry.value;
      for (final k in keywords) {
        final pattern = RegExp(RegExp.escape(k.toLowerCase()));
        final matches = pattern.allMatches(lower);
        if (matches.isNotEmpty) {
          hit.update(cat, (v) => v + matches.length, ifAbsent: () => matches.length);
        }
      }
    }
    final sorted = hit.keys.toList()
      ..sort((a, b) {
        final c = (hit[b] ?? 0).compareTo(hit[a] ?? 0);
        return c != 0 ? c : a.compareTo(b);
      });
    return {for (final k in sorted) k: hit[k]!};
  }

  static List<String> splitLines(String raw) {
    final t = raw.replaceAll('\r\n', '\n');
    return t
        .split(RegExp(r'[\n/]+')) // 줄바꿈/슬래시 구분
        .map((s) => s.replaceFirst(RegExp(r'^\s*•\s*'), '').trim()) // '•' 불릿 제거
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class _BenefitSelectorState extends State<BenefitSelector> {
  late Map<String, int> _detected; // 카테고리명 -> 등장 횟수
  late List<String> _lines;
  late Set<String> _selected;

  Map<String, List<String>> get _dict =>
      widget.categoryKeywords ?? _DEFAULT_CATEGORY_KEYWORDS;

  Map<String, CategoryMeta> get _meta =>
      widget.categoryMeta ?? _DEFAULT_CATEGORY_META;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selected};
    _recompute();
  }

  @override
  void didUpdateWidget(covariant BenefitSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 sourceText 또는 selected 가 바뀌면 재계산/동기화
    if (oldWidget.sourceText != widget.sourceText ||
        oldWidget.categoryKeywords != widget.categoryKeywords) {
      _recompute();
    }
    if (oldWidget.selected != widget.selected) {
      _selected = {...widget.selected};
    }
  }

  void _recompute() {
    _detected = BenefitSelector.detectCategories(
      widget.sourceText,
      categoryKeywords: _dict,
    );
    _lines = BenefitSelector.splitLines(widget.sourceText);
    setState(() {});
  }

  void _toggle(String cat) {
    setState(() {
      if (_selected.contains(cat)) {
        _selected.remove(cat);
      } else {
        _selected.add(cat);
      }
    });
    widget.onSelectedChanged?.call(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cats = _detected.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E8EC)),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0F000000))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 타이틀 + (옵션) 프리셋 칩
          Row(
            children: [
              Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (widget.presets != null && widget.presets!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.presets!.map((s) {
                    return ActionChip(
                      label: Text(s),
                      onPressed: widget.onTapPreset == null
                          ? null
                          : () => widget.onTapPreset!(s),
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 카테고리 카드 영역
          if (cats.isEmpty)
            Text(
              '입력한 혜택 문구에 기반해 카테고리를 자동 인식해 보여줍니다.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          if (cats.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final maxW = widget.cardMaxWidth;
                final col = (constraints.maxWidth / (maxW + 12)).floor().clamp(1, 4);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: col,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.7, // 가로형 카드 비율
                  ),
                  itemBuilder: (_, i) {
                    final cat = cats[i];
                    final meta = _meta[cat] ?? _DEFAULT_CATEGORY_META_FALLBACK;
                    final count = _detected[cat]!;
                    final isOn = _selected.contains(cat);
                    return _CategoryCard(
                      title: cat,
                      count: count,
                      icon: meta.icon,
                      gradient: meta.gradient,
                      selected: isOn,
                      onTap: () => _toggle(cat),
                    );
                  },
                );
              },
            ),

          const SizedBox(height: 12),

          // 줄 단위 문구 칩
          if (_lines.isNotEmpty)
            Text(widget.linesTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (_lines.isNotEmpty) const SizedBox(height: 6),
          if (_lines.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _lines.map((s) {
                return Chip(
                  label: Text(s),
                  backgroundColor: const Color(0xFFF5F7FA),
                  side: const BorderSide(color: Color(0xFFE5E8EC)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/// 단일 카테고리 카드
class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.gradient,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF111827) : const Color(0xFFE5E8EC);
    final labelColor = selected ? Colors.black : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x12000000), offset: Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 26, color: Colors.black87),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle_rounded, size: 20, color: Colors.black87),
            ]),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: labelColor)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text('키워드 $count개', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 메타 정보 (아이콘 + 그라데이션)
class CategoryMeta {
  final IconData icon;
  final List<Color> gradient;
  const CategoryMeta(this.icon, this.gradient);
}

/// 기본 카테고리 사전 (필요시 외부에서 주입 가능)
const Map<String, List<String>> _DEFAULT_CATEGORY_KEYWORDS = {
  '커피': ['커피', '스타벅스', '이디야', '커피빈', '카페', '카페베네', '파스쿠찌'],
  '편의점': ['편의점', 'GS25', 'CU', '세븐일레븐', 'emart24'],
  '베이커리': ['베이커리', '파리바게뜨', '뚜레쥬르', '던킨', '크리스피'],
  '영화': ['영화', '영화관', 'CGV', '롯데시네마', '메가박스'],
  '쇼핑': ['쇼핑', '쇼핑몰', '쿠팡', '마켓컬리', 'G마켓', '11번가', '백화점', '홈쇼핑'],
  '외식': ['외식', '음식점', '레스토랑', '맥도날드', '버거킹', '롯데리아', '한식', '양식', '중식', '일식'],
  '교통': ['교통', '버스', '지하철', '택시', '카카오T', '티머니'],
  '주유': ['주유', '주유소', 'L당', '휘발유', '경유', 'L/리터'],
  '통신': ['통신', '요금제', '휴대폰요금', 'KT', 'SKT', 'LGU+', '알뜰폰'],
  '여행': ['여행', '항공', '호텔', '에어비앤비', '기차', 'KTX'],
  '배달': ['배달', '배달의민족', '요기요', '쿠팡이츠'],
  '마트': ['마트', '이마트', '홈플러스', '롯데마트', '코스트코'],
};

const Map<String, CategoryMeta> _DEFAULT_CATEGORY_META = {
  '커피': CategoryMeta(Icons.local_cafe_rounded, [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
  '편의점': CategoryMeta(Icons.storefront_rounded, [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
  '베이커리': CategoryMeta(Icons.cookie_rounded, [Color(0xFFFFEBEE), Color(0xFFFFCDD2)]),
  '영화': CategoryMeta(Icons.movie_creation_rounded, [Color(0xFFEDE7F6), Color(0xFFD1C4E9)]),
  '쇼핑': CategoryMeta(Icons.shopping_bag_rounded, [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
  '외식': CategoryMeta(Icons.restaurant_rounded, [Color(0xFFFFF8E1), Color(0xFFFFECB3)]),
  '교통': CategoryMeta(Icons.directions_transit_rounded, [Color(0xFFE0F7FA), Color(0xFFB2EBF2)]),
  '주유': CategoryMeta(Icons.local_gas_station_rounded, [Color(0xFFFFF3E0), Color(0xFFFFCC80)]),
  '통신': CategoryMeta(Icons.wifi_rounded, [Color(0xFFE8EAF6), Color(0xFFC5CAE9)]),
  '여행': CategoryMeta(Icons.flight_takeoff_rounded, [Color(0xFFE0F2F1), Color(0xFFB2DFDB)]),
  '배달': CategoryMeta(Icons.delivery_dining_rounded, [Color(0xFFF3E5F5), Color(0xFFE1BEE7)]),
  '마트': CategoryMeta(Icons.shopping_cart_rounded, [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
};

const CategoryMeta _DEFAULT_CATEGORY_META_FALLBACK =
CategoryMeta(Icons.local_offer_rounded, [Color(0xFFF5F7FA), Color(0xFFE5E8EC)]);
