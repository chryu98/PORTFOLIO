// lib/user/CardListPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:bnkandroid/constants/api.dart';
import 'package:bnkandroid/user/service/CardService.dart';
import '../CardDetailPage.dart';
import '../ui/bnk_theme.dart';
import 'model/CardModel.dart';

/* ───────────────── Compare DTO ───────────────── */
class CompareCard {
  final String cardNo, cardName, cardUrl;
  CompareCard({
    required this.cardNo,
    required this.cardName,
    required this.cardUrl,
  });
  factory CompareCard.fromCardModel(CardModel c) =>
      CompareCard(cardNo: c.cardNo.toString(), cardName: c.cardName, cardUrl: c.cardUrl);
  factory CompareCard.fromJson(Map<String, dynamic> j) =>
      CompareCard(cardNo: j['cardNo'], cardName: j['cardName'] ?? '', cardUrl: j['cardUrl'] ?? '');
  Map<String, dynamic> toJson() => {'cardNo': cardNo, 'cardName': cardName, 'cardUrl': cardUrl};
}

/* ───────────────── Main Page ───────────────── */
class CardListPage extends StatefulWidget {
  const CardListPage({super.key});
  @override
  State<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage>
    with AutomaticKeepAliveClientMixin {
  static const double _GAP_AFTER_HEADER = 24;
  static const double _GAP_CAROUSEL_TO_CHIPS = 24;

  @override
  bool get wantKeepAlive => true;

  /* reactive state */
  final selType = ValueNotifier<String>('전체'); // 전체/신용/체크
  final compareIds = ValueNotifier<Set<String>>({}); // cardNo 집합

  /* async sources */
  late Future<List<CardModel>> _fCards, _fPopular;

  /* UI state */
  final _scrollCtl = ScrollController();
  final _searchCtl = TextEditingController();
  List<CardModel> _searchResults = [];
  List<String> _selectedTags = [];
  String _keyword = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fCards = CardService.fetchCards();
    _fPopular = CardService.fetchPopularCards();
    _restoreCompare();
  }

  @override
  void dispose() {
    selType.dispose();
    compareIds.dispose();
    _scrollCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  /* ───── compare persistence ───── */
  Future<void> _restoreCompare() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('compareCards') ?? [];
    compareIds.value = raw.map((e) => jsonDecode(e)['cardNo'] as String).toSet();
  }

  Future<void> _saveCompare() async {
    final p = await SharedPreferences.getInstance();
    p.setStringList(
      'compareCards',
      compareIds.value.map((id) => jsonEncode({'cardNo': id})).toList(),
    );
  }

  void _toggleCompare(CardModel c) {
    final s = compareIds.value.toSet();
    final id = c.cardNo.toString();
    if (s.contains(id)) {
      s.remove(id);
    } else if (s.length < 2) {
      s.add(id);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('최대 2개까지만 비교')));
    }
    compareIds.value = s;
    _saveCompare();
  }

  /* ───── 검색 ───── */
  Future<void> _performSearch() async {
    if (_keyword.isEmpty && _selectedTags.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await http.get(
          Uri.parse(API.searchCards(_keyword, selType.value, _selectedTags)));
      if (r.statusCode == 200) {
        final l = json.decode(utf8.decode(r.bodyBytes)) as List;
        setState(() => _searchResults =
            l.map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList());
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /* ───── UI: 상단 고정 헤더(검색 + 비교함바) ───── */
  SliverAppBar _buildPinnedHeader({required bool showCompareBar}) {
    final double baseHeight = 76;  // 비교함 바 없을 때
    final double withBarHeight = 150;  // 비교함 바 있을 때

    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: showCompareBar ? withBarHeight : baseHeight,
      collapsedHeight: showCompareBar ? withBarHeight : baseHeight,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ───── 검색창 + 필터 버튼 ─────
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchCtl,
                        onSubmitted: (v) {
                          _keyword = v.trim();
                          _performSearch();
                        },
                        onChanged: (v) {
                          if (v.trim().isEmpty) setState(() => _keyword = '');
                        },
                        decoration: InputDecoration(
                          hintText: '카드이름, 혜택으로 검색',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TagFilterModal(
                        selectedTags: _selectedTags,
                        onConfirm: (tags) {
                          setState(() => _selectedTags = tags);
                          _performSearch();
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ───── 비교함 바: 아이템 있을 때만 ─────
              if (showCompareBar)
                ValueListenableBuilder<Set<String>>(
                  valueListenable: compareIds,
                  builder: (context, ids, __) => CompareDockBar(
                    count: ids.length,
                    onOpen: _openCompareSheet,
                    onClear: () {
                      compareIds.value = {};
                      _saveCompare();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCompareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _buildCompareSheet(),
    );
  }

  /* ───── build ───── */
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder(
          future: Future.wait([_fCards, _fPopular]),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting || _loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || (snap.data![0] as List).isEmpty) {
              return const Center(child: Text('카드가 없습니다.'));
            }

            final all = snap.data![0] as List<CardModel>;
            final popular = snap.data![1] as List<CardModel>;

            return CustomScrollView(
              key: const PageStorageKey('cardScroll'),
              controller: _scrollCtl,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // 고정 헤더: 검색 + 비교함
                ValueListenableBuilder<Set<String>>(
                  valueListenable: compareIds,
                  builder: (_, ids, __) =>
                      _buildPinnedHeader(showCompareBar: ids.isNotEmpty),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // 캐러셀
                SliverToBoxAdapter(child: _buildCarousel(popular)),

                // 캐러셀 아래: 세그먼트 칩(항상 표시)
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: SegmentChipsBar(
                    selType: selType,
                    onChanged: () {
                      if (_keyword.isNotEmpty || _selectedTags.isNotEmpty) {
                        _performSearch();
                      } else {
                        setState(() {}); // 단순 필터만이면 그리드 리빌드
                      }
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // 카드 목록
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<String>(
                    valueListenable: selType,
                    builder: (_, String cur, __) {
                      // 리스트 필터링
                      List<CardModel> list = all;
                      if (_keyword.isNotEmpty || _selectedTags.isNotEmpty) {
                        list = _searchResults;
                      } else if (cur != '전체') {
                        list = all
                            .where((c) =>
                        (c.cardType ?? '')
                            .toLowerCase()
                            .replaceAll('카드', '')
                            .trim() ==
                            cur.toLowerCase())
                            .toList();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize
                              .min, // ✅ Sliver 안 Column 무한 높이 방지 (핵심)
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 10, bottom: 6, left: 4),
                              child: Text(
                                (cur == '전체')
                                    ? '전체카드'
                                    : '$cur카드 • ${list.length}개',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),

                            if (list.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text('검색 결과가 없어요',
                                      style: TextStyle(color: Colors.black54)),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                primary:
                                false, // ✅ 메인 스크롤러 아님을 명시 (핵심)
                                physics:
                                const NeverScrollableScrollPhysics(),
                                addAutomaticKeepAlives:
                                false, // (선택) 레이아웃 안전성 보강
                                addRepaintBoundaries:
                                false, // (선택) 레이아웃 안전성 보강
                                itemCount: list.length,
                                gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 13,
                                  mainAxisSpacing: 20,
                                  mainAxisExtent: 304,
                                ),
                                itemBuilder: (context, i) {
                                  final card = list[i];
                                  return FractionallySizedBox(
                                    widthFactor: 0.92,
                                    heightFactor: 0.92,
                                    child:
                                    ValueListenableBuilder<Set<String>>(
                                      valueListenable: compareIds,
                                      builder: (_, ids, __) => CardGridTile(
                                        card: card,
                                        selected: ids.contains(
                                            card.cardNo.toString()),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CardDetailPage(
                                                    cardNo:
                                                    card.cardNo.toString(),
                                                    compareIds: compareIds,
                                                    onCompareChanged:
                                                    _saveCompare,
                                                  ),
                                            ),
                                          );
                                        },
                                        onToggleCompare: _toggleCompare,
                                      ),
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 60),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  /* ───────────────── sub widgets ───────────────── */

  Widget _buildCarousel(List<CardModel> list) {
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Text('인기카드 이미지가 없습니다.'),
      );
    }

    return CarouselSlider(
      key: const PageStorageKey('popular_carousel'),
      options: CarouselOptions(
        height: 280,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: list.map((c) {
        final url =
            '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(c.popularImgUrl ?? c.cardUrl)}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailPage(
                  cardNo: c.cardNo.toString(),
                  compareIds: compareIds,
                  onCompareChanged: _saveCompare,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) =>
                  progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image)),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.cardName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (c.cardSlogan?.isNotEmpty ?? false)
                          Text(
                            c.cardSlogan!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 스크롤 가능한 비교 시트
  Widget _buildCompareSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtl) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: compareIds,
          builder: (_, ids, __) {
            if (ids.isEmpty) return const SizedBox.shrink();
            final list = ids.toList();

            return Material(
              color: Colors.white,
              child: SingleChildScrollView(
                controller: scrollCtl,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: list.map((id) {
                    return Expanded(
                      child: FutureBuilder<CardModel>(
                        future: CardService.fetchCompareCardDetail(id),
                        builder: (ctx, snap) {
                          if (!snap.hasData) {
                            return const SizedBox(
                              height: 180,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final c = snap.data!;
                          final brand = (c.cardBrand ?? '').toUpperCase();
                          final fee = '${c.annualFee ?? 0}원';
                          final feeDom =
                          (brand.contains('LOCAL') || brand.contains('BC'))
                              ? fee
                              : '없음';
                          final feeVisa =
                          brand.contains('VISA') ? fee : '없음';
                          final feeMaster =
                          brand.contains('MASTER') ? fee : '없음';

                          return Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(c.cardUrl)}',
                                  width: 80,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 80),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.cardName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.cardSlogan ?? '-',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                const Text('🔖 요약 혜택',
                                    style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),

                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: extractCategories(
                                    '${c.service}\n${c.sService ?? ''}',
                                    max: 6,
                                  ),
                                ),

                                const SizedBox(height: 8),
                                _feeItemWithIcon('assets/overseas_pay_domestic.png', feeDom),
                                const SizedBox(height: 4),
                                _feeItemWithIcon('assets/overseas_pay_visa.png', feeVisa),
                                const SizedBox(height: 4),
                                _feeItemWithIcon('assets/overseas_pay_master.png', feeMaster),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* ───────────────── 캐러셀 아래 세그먼트 칩 바 ───────────────── */
class SegmentChipsBar extends StatelessWidget {
  final ValueNotifier<String> selType;
  final VoidCallback onChanged; // 선택 변경 시 검색/필터 갱신

  const SegmentChipsBar({super.key, required this.selType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<String>(
        valueListenable: selType,
        builder: (context, cur, __) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['전체', '신용', '체크'].map((t) {
            final on = cur == t;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Theme(
                data: Theme.of(context).copyWith(
                  chipTheme: Theme.of(context).chipTheme.copyWith(checkmarkColor: Colors.white),
                ),
                child: ChoiceChip(
                  selected: on,
                  showCheckmark: true,
                  label: Text(t == '신용' ? '신용카드' : t == '체크' ? '체크카드' : '전체'),
                  selectedColor: const Color(0xffB91111),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: on ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  side: on ? BorderSide.none : const BorderSide(color: Color(0x22000000)),
                  onSelected: (_) {
                    selType.value = t;
                    onChanged();
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/* ───────────────── Card Tile ───────────────── */
class CardGridTile extends StatelessWidget {
  final CardModel card;
  final VoidCallback onTap;
  final void Function(CardModel) onToggleCompare;
  final bool selected;

  const CardGridTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onToggleCompare,
    required this.selected,
  });

  static const double _sloganBoxH = 36.0;

  @override
  Widget build(BuildContext context) {
    final imgUrl =
        '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}';

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 이미지
          AspectRatio(
            aspectRatio: 1.6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Image.network(
                        imgUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image, size: 40)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 카드명
          Text(
            card.cardName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 4),

          // 슬로건 (고정 높이)
          SizedBox(
            height: _sloganBoxH,
            child: (card.cardSlogan ?? '').isEmpty
                ? const SizedBox.shrink()
                : Text(
              card.cardSlogan!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.25,
                color: Color(0xFF8A8A8A),
              ),
            ),
          ),

          const SizedBox(height: 14),

          _CompareToggle(
            selected: selected,
            onPressed: () {
              HapticFeedback.lightImpact();
              onToggleCompare(card);
            },
          ),
        ],
      ),
    );
  }
}

/// "비교함 담기" / "✓ 비교함에 추가됨" 캡슐 토글
class _CompareToggle extends StatelessWidget {
  final bool selected;
  final VoidCallback onPressed;
  const _CompareToggle({required this.selected, required this.onPressed});

  static const _green = Color(0xFF2E7D32);
  static const _greenBg = Color(0xFFE8F5E9);
  static const _pillPad = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: _pillPad,
          decoration: BoxDecoration(
            color: _greenBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _green.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 16, color: _green),
              SizedBox(width: 6),
              Text(
                '비교함에 추가됨',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: _pillPad,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFDDDDDD)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Color(0xFF555555)),
            SizedBox(width: 6),
            Text(
              '비교함 담기',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────── util widgets (태그, 모달) ───────────────── */
List<Widget> extractCategories(String text, {int max = 5}) {
  const keys = {
    '커피': ['커피', '스타벅스', '이디야', '카페베네'],
    '편의점': ['편의점', 'GS25', 'CU', '세븐일레븐'],
    '베이커리': ['베이커리', '파리바게뜨', '뚜레쥬르', '던킨'],
    '영화': ['영화관', '영화', '롯데시네마', 'CGV'],
    '쇼핑': ['쇼핑몰', '쿠팡', '마켓컬리', 'G마켓', '다이소', '백화점', '홈쇼핑'],
    '외식': ['음식점', '레스토랑', '맥도날드', '롯데리아'],
    '교통': ['버스', '지하철', '택시', '대중교통', '후불교통'],
    '통신': ['통신요금', '휴대폰', 'SKT', 'KT', 'LGU+'],
    '교육': ['학원', '학습지'],
    '레저&스포츠': ['체육', '골프', '스포츠', '레저'],
    '구독': ['넷플릭스', '멜론', '유튜브프리미엄', '정기결제', '디지털 구독'],
    '병원': ['병원', '약국', '동물병원'],
    '공공요금': ['전기요금', '도시가스', '아파트관리비'],
    '주유': ['주유', '주유소', 'SK주유소', 'LPG'],
    '하이패스': ['하이패스'],
    '배달앱': ['쿠팡', '배달앱'],
    '환경': ['전기차', '수소차', '친환경'],
    '공유모빌리티': ['공유모빌리티', '카카오T바이크', '따릉이', '쏘카', '투루카'],
    '세무지원': ['세무', '전자세금계산서', '부가세'],
    '포인트&캐시백': ['포인트', '캐시백', '가맹점', '청구할인'],
    '놀이공원': ['놀이공원', '자유이용권'],
    '라운지': ['공항라운지'],
    '발렛': ['발렛파킹']
  };
  final lower = text.toLowerCase();
  final found = <String>{
    for (final e in keys.entries)
      if (e.value.any((k) => lower.contains(k.toLowerCase()))) e.key
  }.take(max);
  return found
      .map((t) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text('#$t',
          style: const TextStyle(fontSize: 12, color: Colors.red)),
    ),
  ))
      .toList();
}

class TagFilterModal extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onConfirm;
  const TagFilterModal(
      {super.key, required this.selectedTags, required this.onConfirm});
  @override
  State<TagFilterModal> createState() => _TagFilterModalState();
}

class _TagFilterModalState extends State<TagFilterModal> {
  static const tags = [
    '커피', '편의점', '베이커리', '영화', '쇼핑', '외식', '교통', '통신', '교육', '레저', '스포츠', '구독',
    '병원', '약국', '공공요금', '주유', '하이패스', '배달앱', '환경', '공유모빌리티', '세무지원', '포인트',
    '캐시백', '놀이공원', '라운지', '발렛'
  ];
  late List<String> sel;
  @override
  void initState() {
    super.initState();
    sel = List.from(widget.selectedTags);
  }

  void _toggle(String tag) {
    setState(() {
      if (sel.contains(tag)) {
        sel.remove(tag);
      } else if (sel.length < 5) {
        sel.add(tag);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('최대 5개 선택')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('원하는 혜택을 고르세요 (최대 5개)',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tags.map((t) {
              final on = sel.contains(t);
              return GestureDetector(
                onTap: () => _toggle(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: on ? const Color(0xfffdeeee) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: on ? Colors.red : Colors.grey.shade300),
                  ),
                  child: Text(
                    '#$t',
                    style: TextStyle(
                      color: on ? Colors.red : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91111),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                widget.onConfirm(sel);
                Navigator.pop(context);
              },
              child: const Text('적용'),
            ),
          )
        ]),
      ),
    );
  }
}

Widget _feeItemWithIcon(String assetPath, String feeText) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(assetPath, width: 24, height: 24),
      const SizedBox(width: 4),
      Text(feeText, style: const TextStyle(fontSize: 14)),
    ],
  );
}

/* ───────────────── 비교함 바 ───────────────── */
class CompareDockBar extends StatelessWidget {
  final int count;
  final VoidCallback onOpen;
  final VoidCallback onClear;
  const CompareDockBar({
    super.key,
    required this.count,
    required this.onOpen,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF1F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          Text(
            '비교함 $count개 담김',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: const Text('비우기'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onOpen,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
            const Text('비교하기', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
