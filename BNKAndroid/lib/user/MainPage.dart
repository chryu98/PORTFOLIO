import 'dart:convert';
import 'package:bnkandroid/CardDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;                         // ← 추가

import 'package:bnkandroid/user/CustomCardEditorPage.dart';
import 'package:bnkandroid/user/model/CardModel.dart';
import 'package:bnkandroid/constants/api.dart';                 // API.baseUrl, /proxy/image 등
import 'package:bnkandroid/user/NaverMapPage.dart';

class CardMainPage extends StatefulWidget {
  const CardMainPage({super.key});

  @override
  State<CardMainPage> createState() => _CardMainPageState();
}

class _CardMainPageState extends State<CardMainPage> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.9);
  int _current = 0;

  // ── 비교함 상태 (CardListPage와 동일 포맷으로 공유)
  final compareIds = ValueNotifier<Set<String>>({});

  // ── 인기/추천
  late Future<List<CardModel>> _fPopular;

  @override
  void initState() {
    super.initState();
    _fPopular = _fetchPopularTop3(); // ← CardService 호출 대신 로컬 HTTP 호출
    _restoreCompare();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    compareIds.dispose();
    super.dispose();
  }

  // ── 인기카드 Top3를 이 파일 내에서 직접 호출
  Future<List<CardModel>> _fetchPopularTop3() async {
    // 필요 시 '/cards/top3' → '/api/cards/top3' 로 변경
    final uri = Uri.parse('http://192.168.0.224:8090/api/cards/top3');

    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (res.statusCode != 200) {
      throw Exception('(${res.statusCode}) 인기카드 조회 실패');
    }

    // 한글 깨짐 방지
    final body = utf8.decode(res.bodyBytes);
    final decoded = jsonDecode(body);

    if (decoded is! List) {
      throw Exception('응답 형태가 올바르지 않습니다(List 아님).');
    }

    // 보통 CardModel에 fromJson(Map<String, dynamic>) 이 있을 확률이 높습니다.
    try {
      return decoded
          .cast<Map<String, dynamic>>()
          .map<CardModel>((m) => CardModel.fromJson(m))
          .toList();
    } catch (_) {
      // 만약 fromJson이 없다면, 아래 예시처럼 수동 매핑을 사용하세요.
      // (필드명은 서버 응답 키에 맞춰 조정)
      String _s(dynamic v) => v == null ? '' : v.toString();
      return decoded.map<CardModel>((dynamic raw) {
        final m = raw as Map<String, dynamic>;
        return CardModel(
          cardNo: int.tryParse('${m['cardNo']}') ?? 0,
          cardName: _s(m['cardName']),
          cardBrand: _s(m['cardBrand']),   // ← 여기
          cardSlogan: _s(m['cardSlogan']),
          cardUrl: _s(m['cardUrl']),       // ← 여기
          viewCount: int.tryParse('${m['viewCount']}') ?? 0,
        );
      }).toList();
    }
  }

  // ── 비교함 로컬 저장/복원 (CardListPage와 동일)
  Future<void> _restoreCompare() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('compareCards') ?? [];
    compareIds.value =
        raw.map((e) => jsonDecode(e)['cardNo'].toString()).toSet();
  }

  Future<void> _saveCompare() async {
    final p = await SharedPreferences.getInstance();
    p.setStringList(
      'compareCards',
      compareIds.value.map((id) => jsonEncode({'cardNo': id})).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [


          // 이벤트 캐러셀 (탭 → CustomCardEditorPage)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 42),
            child: _EventCarousel(
              height: 240,
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _current = i),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: SmoothPageIndicator(
              controller: _pageCtrl,
              count: 3,
              effect: const WormEffect(dotHeight: 8, dotWidth: 8),
            ),
          ),

          const SizedBox(height: 18),

          // 인기 · 추천카드 (탭 → CardDetailPage(cardNo, compareIds, onCompareChanged))
          _SectionHeader(title: '인기 · 추천카드', onTapMore: () {}),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: FutureBuilder<List<CardModel>>(
              future: _fPopular,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      '불러오기 실패: ${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('표시할 카드가 없습니다.'),
                  );
                }

                return Column(
                  children: List.generate(items.length, (i) {
                    final it = items[i];
                    return Padding(
                      padding:
                      EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
                      child: _CardListItem(
                        badge: i == 0 ? 'Top' : null,
                        title: it.cardName,
                        highlight: '${it.viewCount}회 조회',
                        brand: (it.cardBrand ?? '').isEmpty
                            ? (it.cardSlogan ?? '')
                            : (it.cardBrand ?? ''),
                        color: const [
                          Color(0xFF3AA0E7),
                          Color(0xFF7AB3C9),
                          Color(0xFFE24A3B)
                        ][i % 3],
                        imageUrl: it.cardUrl,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CardDetailPage(
                                cardNo: it.cardNo.toString(),
                                compareIds: compareIds, // 같은 인스턴스 공유
                                onCompareChanged: _saveCompare, // 저장 콜백 공유
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          // ───── 금융 빠른메뉴 섹션
          _SectionHeader(title: '안내', onTapMore: () {
            // TODO: 전체 보기 이동
          }),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _FinanceQuickMenu(
              items:  [
                _FinanceItem(
                  eyebrow: '직접 방문하실 때',
                  title: '영업점 위치안내',
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const NaverMapPage(),
                        fullscreenDialog: false, // 필요 시 true로 시트 느낌
                      ),
                    );
                  },
                ),
                _FinanceItem(
                  eyebrow: '365일 24시간 현금이 필요할 때',
                  title: '단기카드대출(현금서비스)',
                ),
                _FinanceItem(
                  eyebrow: '결제금액이 부담될 때',
                  title: '일부결제금액이월약정(리볼빙)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),





          // 이벤트 배너(샘플)
          _SectionHeader(title: '이벤트', onTapMore: () {}),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: const _EventBanner(),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              '2 / 8',
              style: TextStyle(
                color: Colors.black.withOpacity(0.45),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────── 위젯 조각 ─────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/logo.png',
          height: 28,
          errorBuilder: (_, __, ___) => const Text(
            'BNK CARD',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// ───────── 금융 빠른메뉴 위젯들
class _FinanceItem {
  final String eyebrow; // 작은 설명(캡션)
  final String title;   // 큰 타이틀
  final VoidCallback? onTap;
  const _FinanceItem({required this.eyebrow, required this.title, this.onTap});
}

class _FinanceQuickMenu extends StatelessWidget {
  final List<_FinanceItem> items;
  const _FinanceQuickMenu({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _FinanceTile(item: items[i]),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withOpacity(0.06),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinanceTile extends StatelessWidget {
  final _FinanceItem item;
  const _FinanceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.eyebrow,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.45),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}


class _SearchPill extends StatelessWidget {
  final String hint;
  final VoidCallback onTapArrow;

  const _SearchPill({required this.hint, required this.onTapArrow});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: onTapArrow,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: InkWell(
          onTap: onTapArrow,
          child: const Icon(Icons.arrow_forward_rounded),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          borderSide: BorderSide(color: Color(0xFFB91111), width: 1.2),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTapMore;

  const _SectionHeader({required this.title, this.onTapMore});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width * 0.04;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          InkWell(
            onTap: onTapMore,
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.chevron_right_rounded, size: 22),
            ),
          )
        ],
      ),
    );
  }
}

class _EventCarousel extends StatelessWidget {
  final PageController controller;
  final ValueChanged<int>? onPageChanged;
  final double height;

  const _EventCarousel({
    required this.controller,
    this.onPageChanged,
    this.height = 180, // 기본값
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: controller,
        onPageChanged: onPageChanged,
        itemCount: 3,
        itemBuilder: (_, i) {
          final colors = [
            [const Color(0xFF2F80ED), const Color(0xFF56CCF2)],
            [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
            [const Color(0xFF1D976C), const Color(0xFF93F9B9)],
          ];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomCardEditorPage()),
                );
              },
              child: _GradientCard(
                colors: colors[i],
                height: height,
                child: Stack(
                  children: [
                    const Positioned(
                      right: 16,
                      bottom: 12,
                      child: Icon(Icons.credit_card,
                          size: 72, color: Colors.white70),
                    ),
                    const Positioned(
                      left: 14,
                      top: 14,
                      child: _EventTag(text: 'EVENT'),
                    ),
                    const Positioned(
                      left: 14,
                      bottom: 18,
                      right: 14,
                      child: Text(
                        '기대 그 이상의 프리미엄\n최대 20만원 캐시백',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double height; // ✅ 추가

  const _GradientCard({
    this.colors = const [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    required this.child,
    this.height = 180, // 기본값
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, // ✅ 적용
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _EventTag extends StatelessWidget {
  final String text;
  const _EventTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ───────── 인기·추천 리스트 아이템
class _CardListItem extends StatelessWidget {
  final String? badge;
  final String title;
  final String highlight;
  final String brand;
  final Color color;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _CardListItem({
    this.badge,
    required this.title,
    required this.highlight,
    required this.brand,
    this.color = const Color(0xFF3AA0E7),
    this.imageUrl,
    this.onTap,
  });

  Widget _fallbackGradient() {
    const double thumbSize = 88;
    return Container(
      width: thumbSize,
      height: thumbSize,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.credit_card, color: Colors.white, size: 34),
    );
  }

  Widget _buildThumb() {
    const double thumbSize = 88; // ← 썸네일 크기 한 곳에서 조절

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _fallbackGradient();
    }

    final proxied =
        '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(imageUrl!)}';

    return Container(
      width: thumbSize,
      height: thumbSize,
      margin: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FittedBox(
          fit: BoxFit.contain, // 원본 비율 유지
          child: RotatedBox(
            quarterTurns: 1, // 90° 회전 (시계방향)
            child: Image.network(
              proxied,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(color: Colors.black12);
              },
              errorBuilder: (ctx, err, stack) => _fallbackGradient(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              _buildThumb(),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEE2D2D),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          if (badge != null) const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style:
                              const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.8),
                              fontSize: 12,
                              height: 1.2),
                          children: [
                            TextSpan(
                                text: highlight,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2046D1))),
                            const TextSpan(text: '  '),
                            TextSpan(text: brand),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child:
                Icon(Icons.chevron_right_rounded, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner();

  @override
  Widget build(BuildContext context) {
    return _GradientCard(
      colors: const [Color(0xFF7F7FD5), Color(0xFF86A8E7)],
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: const Text(
          '해외승급 최대혜택!\n송금수수료 면제 + 캐시백',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
