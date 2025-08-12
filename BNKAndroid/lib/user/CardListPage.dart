// lib/card_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:bnkandroid/constants/api.dart';
import 'package:bnkandroid/user/service/CardService.dart';
import '../CardDetailPage.dart';
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

/* ───────────────── Entry point ───────────────── */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await API.initBaseUrl();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext ctx) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    home: CardListPage(),
  );
}

/* ───────────────── Main Page ───────────────── */
class CardListPage extends StatefulWidget {
  @override
  State<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage> with AutomaticKeepAliveClientMixin {
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

  /* layout */
  static const _GRID_CHILD_ASPECT = 0.70;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 2개까지만 비교')));
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
      final r = await http.get(Uri.parse(API.searchCards(_keyword, selType.value, _selectedTags)));
      if (r.statusCode == 200) {
        final l = json.decode(utf8.decode(r.bodyBytes)) as List;
        setState(() => _searchResults =
            l.map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList());
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /* ───── UI: 핀 고정 헤더(필터+검색) ───── */
  SliverAppBar _buildPinnedSearchAndFilter() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 128,
      collapsedHeight: 128,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 세그먼트(전체/신용/체크) - 그대로
              ValueListenableBuilder(
                valueListenable: selType,
                builder: (context, String cur, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['전체', '신용', '체크'].map((t) {
                    final on = cur == t;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Theme(
                        // ✅ 체크표시 색만 흰색으로
                        data: Theme.of(context).copyWith(
                          chipTheme: Theme.of(context).chipTheme.copyWith(
                            checkmarkColor: Colors.white,
                          ),
                        ),
                        child: ChoiceChip(
                          selected: on,
                          showCheckmark: true, // 기본값이지만 명시해둠
                          label: Text(t == '신용' ? '신용카드' : t == '체크' ? '체크카드' : '전체'),
                          selectedColor: const Color(0xffB91111),   // 선택 시 빨강
                          backgroundColor: Colors.white,            // 비선택 배경
                          labelStyle: TextStyle(
                            color: on ? Colors.white : Colors.black87, // 선택 시 글자 흰색
                            fontWeight: FontWeight.w600,
                          ),
                          side: on
                              ? BorderSide.none
                              : const BorderSide(color: Color(0x22000000)), // 비선택 테두리 살짝
                          onSelected: (_) {
                            selType.value = t;
                            if (_keyword.isNotEmpty || _selectedTags.isNotEmpty) {
                              _performSearch();
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // 검색창: 배경은 다시 연회색 그대로
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchCtl,
                        onSubmitted: (v) { _keyword = v.trim(); _performSearch(); },
                        onChanged: (v) { if (v.trim().isEmpty) setState(() => _keyword = ''); },
                        decoration: InputDecoration(
                          hintText: '카드이름, 혜택으로 검색',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA), // ← 원래값으로
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
                        onConfirm: (tags) { setState(() => _selectedTags = tags); _performSearch(); },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  /* ───── build ───── */
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: ValueListenableBuilder(
        valueListenable: compareIds,
        builder: (_, Set<String> ids, __) => ids.isNotEmpty
            ? FloatingActionButton.extended(
          backgroundColor: const Color(0xFFF4F6FA),
          foregroundColor: const Color(0xFF4E4E4E),
          label: Text('비교함 (${ids.length})'),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true, // 중요
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => _buildCompareSheet(), // 스크롤 가능 모달
          ),
        )
            : const SizedBox.shrink(),
      ),
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
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                _buildPinnedSearchAndFilter(),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(child: _buildCarousel(popular)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)), // 캐러셀과 목록 사이 갭

                // 카드 목록
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<String>(
                    valueListenable: selType,
                    builder: (_, String cur, __) {
                      // ── 리스트 필터링
                      List<CardModel> list = all;
                      if (_keyword.isNotEmpty || _selectedTags.isNotEmpty) {
                        list = _searchResults;
                      } else if (cur != '전체') {
                        list = all.where((c) =>
                        (c.cardType ?? '')
                            .toLowerCase()
                            .replaceAll('카드', '')
                            .trim() == cur.toLowerCase()
                        ).toList();
                      }

                      // ── 항상 제목 표시: 전체/신용/체크 + 개수
                      final String titleText =
                          '${cur == '전체' ? '전체카드' : '$cur카드'} • ${list.length}개';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목 (전체 = 개수 숨김, 신용/체크 = 개수 표시)
                            Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 6, left: 4),
                              child: Text(
                                (cur == '전체') ? '전체카드' : '$cur카드 • ${list.length}개',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),

                            // 목록/빈 상태
                            if (list.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text('검색 결과가 없어요', style: TextStyle(color: Colors.black54)),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: list.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 20,   // 기존 18 → 22
                                  crossAxisSpacing: 13,  // 기존 12 → 14
                                  childAspectRatio: _GRID_CHILD_ASPECT, // 기존값 유지
                                ),
                                itemBuilder: (context, i) {
                                  final card = list[i];
                                  return FractionallySizedBox(
                                    widthFactor: 0.92,   // ← 0.85~0.95 사이로 취향대로 조절
                                    heightFactor: 0.92,  // ← widthFactor와 동일하게 맞추면 비율 유지
                                    child: ValueListenableBuilder<Set<String>>(
                                      valueListenable: compareIds,
                                      builder: (_, ids, __) => CardGridTile(
                                        card: card,
                                        selected: ids.contains(card.cardNo.toString()),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CardDetailPage(
                                                cardNo: card.cardNo.toString(),
                                                compareIds: compareIds,
                                                onCompareChanged: _saveCompare,
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

                            const SizedBox(height: 140), // FAB 공간
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
                  progress == null ? child : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            style: const TextStyle(color: Colors.white, fontSize: 12),
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
                          (brand.contains('LOCAL') || brand.contains('BC')) ? fee : '없음';
                          final feeVisa = brand.contains('VISA') ? fee : '없음';
                          final feeMaster = brand.contains('MASTER') ? fee : '없음';

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
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.cardSlogan ?? '-',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                const Text('🔖 요약 혜택',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),

                                // 칩 위젯 리스트 그대로 사용 (문자열 변환 X)
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



  @override
  Widget build(BuildContext context) {
    final imgUrl =
        '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: Colors.white,                      // ← 핑크 틴트 방지
        surfaceTintColor: Colors.transparent,     // ← 핑크 틴트 방지
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1) 이미지 영역: 하단 여백 ↑ (54 → 70) 선에 안 닿게
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 70),
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),

            // 2) 하단 정보 바: 가운데 정렬 + 슬로건 2줄
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FA),                         // ✅ 원하는 연회색
                  // 경계선도 살짝 밝게 바꾸면 더 자연스러워요(선택)
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),

                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,   // ← 가운데 정렬
                  children: [
                    Text(
                      card.cardName,
                      textAlign: TextAlign.center,                 // ← 가운데 정렬
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (card.cardSlogan?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.cardSlogan!,
                        textAlign: TextAlign.center,               // ← 가운데 정렬
                        maxLines: 2,                               // ← 두 줄까지
                        overflow: TextOverflow.ellipsis,           // 넘치면 …
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          height: 1.2,                             // 줄간격 살짝
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 비교 토글 배지(그대로)
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: () => onToggleCompare(card),
                icon: Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: selected ? const Color(0xffB91111) : Colors.black54,
                ),
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
    for (final e in keys.entries) if (e.value.any((k) => lower.contains(k.toLowerCase()))) e.key
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
      child: Text('#$t', style: const TextStyle(fontSize: 12, color: Colors.red)),
    ),
  ))
      .toList();
}

class TagFilterModal extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onConfirm;
  const TagFilterModal({super.key, required this.selectedTags, required this.onConfirm});
  @override
  State<TagFilterModal> createState() => _TagFilterModalState();
}

class _TagFilterModalState extends State<TagFilterModal> {
  static const tags = [
    '커피',
    '편의점',
    '베이커리',
    '영화',
    '쇼핑',
    '외식',
    '교통',
    '통신',
    '교육',
    '레저',
    '스포츠',
    '구독',
    '병원',
    '약국',
    '공공요금',
    '주유',
    '하이패스',
    '배달앱',
    '환경',
    '공유모빌리티',
    '세무지원',
    '포인트',
    '캐시백',
    '놀이공원',
    '라운지',
    '발렛'
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 5개 선택')));
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
            child: Text('원하는 혜택을 고르세요 (최대 5개)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    style: TextStyle(color: on ? Colors.red : Colors.black87, fontWeight: FontWeight.w500),
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
