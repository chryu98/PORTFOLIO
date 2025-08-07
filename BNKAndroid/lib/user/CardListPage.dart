// lib/card_list_page.dart
import 'dart:convert';
import 'dart:math';
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
  factory CompareCard.fromCardModel(CardModel c) => CompareCard(
      cardNo: c.cardNo.toString(), cardName: c.cardName, cardUrl: c.cardUrl);
  factory CompareCard.fromJson(Map<String, dynamic> j) => CompareCard(
      cardNo: j['cardNo'], cardName: j['cardName'] ?? '', cardUrl: j['cardUrl'] ?? '');
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
  Widget build(BuildContext ctx) =>
      MaterialApp(debugShowCheckedModeBanner: false,  theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,),
          home: CardListPage());
}

/* ───────────────── Main Page ───────────────── */
class CardListPage extends StatefulWidget {
  @override
  State<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /* reactive state */
  final selType    = ValueNotifier<String>('전체');   // 전체/신용/체크
  final compareIds = ValueNotifier<Set<String>>({}); // cardNo 집합

  /* async sources */
  late Future<List<CardModel>> _fCards, _fPopular;

  /* UI state */
  final _scrollCtl = ScrollController();
  final _searchCtl = TextEditingController();
  List<CardModel> _searchResults = [];
  List<String>    _selectedTags  = [];
  String _keyword = '';
  bool   _loading = false;

  /* layout */
  static const _CARD_ASPECT = 4 / 5;
  static const _GRID_RATIO  = 0.60; // overflow 방지
  static const _MAIN_SPAC   = 22.0;
  static const _CELL_PAD    = 6.0;

  @override
  void initState() {
    super.initState();
    _fCards   = CardService.fetchCards();
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
    final p   = await SharedPreferences.getInstance();
    final raw = p.getStringList('compareCards') ?? [];
    compareIds.value =
        raw.map((e) => jsonDecode(e)['cardNo'] as String).toSet();
  }

  Future<void> _saveCompare() async {
    final p = await SharedPreferences.getInstance();
    p.setStringList(
        'compareCards',
        compareIds.value
            .map((id) => jsonEncode({'cardNo': id}))
            .toList());
  }

  void _toggleCompare(CardModel c) {
    final s = compareIds.value.toSet();
    if (s.contains(c.cardNo.toString())) {
      s.remove(c.cardNo.toString());
    } else if (s.length < 2) {
      s.add(c.cardNo.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 2개까지만 비교')));
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
      final r = await http
          .get(Uri.parse(API.searchCards(_keyword, selType.value, _selectedTags)));
      if (r.statusCode == 200) {
        final l = json.decode(utf8.decode(r.bodyBytes)) as List;
        setState(() => _searchResults =
            l.map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList());
      }
    } finally {
      setState(() => _loading = false);
    }
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
          backgroundColor: Color(0xFFF4F6FA),
          foregroundColor: Color(0xFF4E4E4E),
          icon: const Icon(Icons.compare_arrows),
          label: Text('비교함 (${ids.length})'),
          onPressed: () => showModalBottomSheet(
              context: context, builder: (_) => _buildCompareModal()),
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

            final all     = snap.data![0] as List<CardModel>;
            final popular = snap.data![1] as List<CardModel>;

            return CustomScrollView(
              key: const PageStorageKey('cardScroll'),
              controller: _scrollCtl,
              slivers: [
                const SliverAppBar(
                    toolbarHeight: 20,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pinned: false),
                SliverToBoxAdapter(child: _buildCarousel(popular)),
                SliverToBoxAdapter(child: _buildTypeFilter()),
                SliverToBoxAdapter(child: _buildSearchBar()),
                /* 목록 영역 – 부분 빌드 */
                SliverToBoxAdapter(
                  child: ValueListenableBuilder(
                    valueListenable: selType,
                    builder: (_, String cur, __) {
                      /* 필터링 */
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

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cur != '전체')
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 24, top: 10, bottom: 4),
                              child: Text('$cur카드 목록',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: list.length,
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: _MAIN_SPAC,
                              crossAxisSpacing: 0,
                              childAspectRatio: _GRID_RATIO,
                            ),
                            itemBuilder: (c, i) => _buildGridItem(list[i]),
                          ),
                          const SizedBox(height: 140), // FAB 공간
                        ],
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
        final url = '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(c.popularImgUrl ?? c.cardUrl)}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailPage(
                  cardNo: c.cardNo.toString(),        // ✅ 카드번호
                  compareIds: compareIds,             // ✅ 비교 상태 넘김
                  onCompareChanged: _saveCompare,     // ✅ 저장 콜백
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
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





  Widget _buildTypeFilter() => ValueListenableBuilder(
    valueListenable: selType,
    builder: (_, String cur, __) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['전체', '신용', '체크'].map((t) {
          final sel = cur == t;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 11),
                  backgroundColor:
                  sel ? const Color(0xffB91111) : Colors.white,
                  foregroundColor: sel ? Colors.white : Colors.black87,
                  side: sel
                      ? BorderSide.none
                      : BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                selType.value = t;
                if (_keyword.isNotEmpty ||
                    _selectedTags.isNotEmpty) _performSearch();
              },
              child: Text(
                  t == '신용'
                      ? '신용카드'
                      : t == '체크'
                      ? '체크카드'
                      : '전체',
                  style: const TextStyle(fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    ),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    child: Row(children: [
      Expanded(
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
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black87)),
              contentPadding: const EdgeInsets.only(bottom: 4),
            ),
          )),
      const SizedBox(width: 8),
      const Icon(Icons.search, size: 20),
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
          ))
    ]),
  );

  Widget _buildGridItem(CardModel c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _CELL_PAD),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔹 카드 이미지 클릭 시 상세 페이지 이동
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailPage(
                  cardNo: c.cardNo.toString(),
                  compareIds: compareIds, // ✅ 상태 공유
                  onCompareChanged: _saveCompare, // ✅ 저장 콜백 전달
                ),
              ),
            );
          },
          child: AspectRatio(
            aspectRatio: _CARD_ASPECT,
            child: _buildImageCard(c.cardUrl, rotate: true),
          ),
        ),

        const SizedBox(height: 4),

        // 🔹 카드 이름 클릭 시 상세 페이지 이동
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailPage(
                  cardNo: c.cardNo.toString(),
                  compareIds: compareIds, // ✅ 상태 공유
                  onCompareChanged: _saveCompare, // ✅ 저장 콜백 전달
                ),
              ),
            );
          },
          child: Text(
            c.cardName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),

        // ✅ 비교함 버튼도 그대로 유지
        GestureDetector(
          onTap: () => _toggleCompare(c),
          child: ValueListenableBuilder(
            valueListenable: compareIds,
            builder: (_, Set<String> cur, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: cur.contains(c.cardNo.toString()),
                  onChanged: null,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Text('비교함 담기', style: TextStyle(fontSize: 11))
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildImageCard(String url, {bool rotate = false}) {
    final prox =
        '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(url)}';
    final img = Image.network(
      prox,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, p) =>
      p == null ? child : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __, ___) =>
      const Center(child: Icon(Icons.broken_image)),
    );
    return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: rotate ? Transform.rotate(angle: pi / 2, child: img) : img);
  }

  Widget _buildCompareModal() => ValueListenableBuilder(
    valueListenable: compareIds,
    builder: (_, Set<String> ids, __) {
      if (ids.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ids.map((id) {
            return FutureBuilder<CardModel>(
              future: CardService.fetchCompareCardDetail(id),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    width: 80,
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final c = snap.data!;
                final brand = (c.cardBrand ?? '').toUpperCase();
                final fee = '${c.annualFee ?? 0}원';
                final feeDom = brand.contains('LOCAL') || brand.contains('BC') ? fee : '없음';
                final feeVisa = brand.contains('VISA') ? fee : '없음';
                final feeMaster = brand.contains('MASTER') ? fee : '없음';

                return Flexible(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center, // ✅ 중앙 정렬
                      children: [
                        Image.network(
                          '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(c.cardUrl)}',
                          width: 80,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
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
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: extractCategories('${c.service}\n${c.sService ?? ''}')
                              .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 6),
                        _feeItemWithIcon('assets/overseas_pay_domestic.png', feeDom),
                        const SizedBox(height: 4),
                        _feeItemWithIcon('assets/overseas_pay_visa.png', feeVisa),
                        const SizedBox(height: 4),
                        _feeItemWithIcon('assets/overseas_pay_master.png', feeMaster),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      );
    },
  );

}

Widget _feeItemWithIcon(String assetPath, String feeText) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        assetPath,
        width: 24,
        height: 24,
      ),
      const SizedBox(width: 4),
      Text(
        feeText,
        style: const TextStyle(fontSize: 14),
      ),
    ],
  );
}

/* ───────────────── util widgets (태그, 모달) ↓ 그대로 ───────────────── */

List<Widget> extractCategoriesAsWidget(String text, {int max = 5}) {
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
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200)),
        child: Text('#$t',
            style:
            const TextStyle(fontSize: 12, color: Colors.red))),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('최대 5개 선택')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('원하는 혜택을 고르세요 (최대 5개)',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tags.map((t) {
              final on = sel.contains(t);
              return GestureDetector(
                onTap: () => _toggle(t),
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: on ? const Color(0xfffdeeee) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: on ? Colors.red : Colors.grey.shade300)),
                    child: Text('#$t',
                        style: TextStyle(
                            color: on ? Colors.red : Colors.black87,
                            fontWeight: FontWeight.w500))),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91111),
                  foregroundColor: Colors.white),
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
