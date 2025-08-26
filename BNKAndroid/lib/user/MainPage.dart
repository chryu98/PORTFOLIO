import 'dart:convert';
import 'package:bnkandroid/CardDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:bnkandroid/user/CustomCardEditorPage.dart';
import 'package:bnkandroid/user/model/CardModel.dart';
import 'package:bnkandroid/constants/api.dart';
import 'package:bnkandroid/user/NaverMapPage.dart';
import 'package:bnkandroid/user/PreCustomizeLandingPage.dart';


class CardMainPage extends StatefulWidget {
  const CardMainPage({super.key});

  @override
  State<CardMainPage> createState() => _CardMainPageState();
}

class _CardMainPageState extends State<CardMainPage> {
  int? _memberNo;
  /// ── 무한 캐러셀 세팅
  static const int _kLoopBase = 1000;

  /// 배너 이미지 (원하면 네트워크 URL로 교체)
  final List<String> _bannerImages = const [
    'assets/banner1.png',
    'assets/banner2.png',
    'assets/banner3.png',
  ];
  final bool _bannerImagesAreAssets = true; // 네트워크 이미지면 false 로

  late final PageController _pageCtrl; // initialPage 필요
  int _current = 0;

  // ── 비교함 상태 (CardListPage와 동일 포맷)
  final compareIds = ValueNotifier<Set<String>>({});

  // ── 인기/추천
  late Future<List<CardModel>> _fPopular;

  @override
  void initState() {
    super.initState();
    _loadMemberNo();
    _pageCtrl = PageController(
      viewportFraction: 0.92,
      initialPage: _kLoopBase * (_bannerImages.isEmpty ? 1 : _bannerImages.length),
    );
    _fPopular = _fetchPopularTop3();
    _restoreCompare();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    compareIds.dispose();
    super.dispose();
  }

  Future<void> _loadMemberNo() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _memberNo = p.getInt('memberNo')); // 로그인 시 저장해둔 값
  }

  // ── 인기카드 Top3 로드
  Future<List<CardModel>> _fetchPopularTop3() async {
    final uri = Uri.parse('http://192.168.0.224:8090/api/cards/top3');

    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('(${res.statusCode}) 인기카드 조회 실패');
    }

    final body = utf8.decode(res.bodyBytes);
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw Exception('응답 형태가 올바르지 않습니다(List 아님).');
    }

    try {
      return decoded
          .cast<Map<String, dynamic>>()
          .map<CardModel>((m) => CardModel.fromJson(m))
          .toList();
    } catch (_) {
      String _s(dynamic v) => v == null ? '' : v.toString();
      return decoded.map<CardModel>((dynamic raw) {
        final m = raw as Map<String, dynamic>;
        return CardModel(
          cardNo: int.tryParse('${m['cardNo']}') ?? 0,
          cardName: _s(m['cardName']),
          cardBrand: _s(m['cardBrand']),
          cardSlogan: _s(m['cardSlogan']),
          cardUrl: _s(m['cardUrl']),
          viewCount: int.tryParse('${m['viewCount']}') ?? 0,
        );
      }).toList();
    }
  }



  void _openEditorIfLoggedIn() {
    if (_memberNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => PreCustomizeLandingPage(memberNo: _memberNo!), // ✅ 회원번호 전달
        fullscreenDialog: true,
      ),
    );
  }
  // ── 비교함 로컬 저장/복원
  Future<void> _restoreCompare() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('compareCards') ?? [];
    compareIds.value = raw.map((e) => jsonDecode(e)['cardNo'].toString()).toSet();
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

    final bannerCount = _bannerImages.isEmpty ? 1 : _bannerImages.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── 무한 캐러셀 (배경 이미지 + 오버레이 텍스트)
          Padding(
            padding: const EdgeInsets.only(top: 42), // ← 좌/우 0
            child: _EventCarousel(
              height: 280,
              controller: _pageCtrl,
              images: _bannerImages,
              imagesAreAssets: _bannerImagesAreAssets,
              // 무한 인덱스 → mod 로 현재 페이지 저장
              onPageChanged: (i) => setState(() => _current = i % bannerCount),
              onTapBanner: _openEditorIfLoggedIn, // ★ 여기만 추가
            ),
          ),
          const SizedBox(height: 16),

          // ── 인디케이터 (무한 슬라이더엔 AnimatedSmoothIndicator 사용)
          Center(
            child: AnimatedSmoothIndicator(
              activeIndex: _current,
              count: bannerCount,
              effect: WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: Color(0xFFB91111), // 🔴 활성(빨간색)
                dotColor: Color(0xBFCCCCCC),          // ⚪ 비활성
              ),
              onDotClicked: (to) {
                final curr = _pageCtrl.page?.round() ?? 0;
                final base = curr - (curr % bannerCount);
                _pageCtrl.animateToPage(
                  base + to,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ── 인기 · 추천카드
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
                    child: Text('불러오기 실패: ${snap.error}', style: const TextStyle(color: Colors.red)),
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
                    final slogan = (it.cardSlogan ?? '').trim();
                    return Padding(
                      padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
                      child: _CardListItem(
                        badge: i == 0 ? 'Top' : null,
                        title: it.cardName,
                        highlight: '${it.viewCount}회 조회',
                        brand: slogan.isEmpty ? (it.cardBrand ?? '') : slogan,
                        color: const [Color(0xFF3AA0E7), Color(0xFF7AB3C9), Color(0xFFE24A3B)][i % 3],
                        imageUrl: it.cardUrl,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CardDetailPage(
                                cardNo: it.cardNo.toString(),
                                compareIds: compareIds,
                                onCompareChanged: _saveCompare,
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

          // ── 안내 섹션
          _SectionHeader(title: '안내', onTapMore: () {}),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _FinanceQuickMenu(
              items: [
                _FinanceItem(
                  eyebrow: '직접 방문하실 때',
                  title: '영업점 위치안내',
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const NaverMapPage(), fullscreenDialog: false),
                    );
                  },
                ),
                _FinanceItem(eyebrow: '365일 24시간 현금이 필요할 때', title: '단기카드대출(현금서비스)'),
                _FinanceItem(eyebrow: '결제금액이 부담될 때', title: '일부결제금액이월약정(리볼빙)'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── 이벤트 배너(샘플)
          _SectionHeader(title: '이벤트', onTapMore: () {}),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _EventBanner(
              imagePathOrUrl: 'assets/event1.png', // ← 에셋 경로 또는 네트워크 URL
              isAsset: true,                              // 네트워크면 false
              darken: 0.25,                               // 텍스트 가독 위해 살짝 어둡게 (선택)
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              '1 / 8',
              style: TextStyle(color: Colors.black.withOpacity(0.45), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────── 위젯 조각 ─────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/logo.png',
          height: 28,
          errorBuilder: (_, __, ___) => const Text('BNK CARD', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// ───────── 금융 빠른메뉴 위젯들
class _FinanceItem {
  final String eyebrow;
  final String title;
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
                Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.06)),
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
                  Text(item.eyebrow,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.45), height: 1.1)),
                  const SizedBox(height: 4),
                  Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.1)),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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

/// ── 무한 캐러셀 + 배경이미지
class _EventCarousel extends StatelessWidget {
  final PageController controller;
  final ValueChanged<int>? onPageChanged;
  final double height;

  final List<String>? images;
  final bool imagesAreAssets;
  final VoidCallback? onTapBanner;

  const _EventCarousel({
    required this.controller,
    this.onPageChanged,
    this.height = 180,
    this.images,
    this.imagesAreAssets = true,
    this.onTapBanner,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = images != null && images!.isNotEmpty;
    final count = hasImages ? images!.length : 3;

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: controller,
        // itemCount 미지정 → 사실상 무한
        onPageChanged: onPageChanged,
        itemBuilder: (_, rawIndex) {
          final i = rawIndex % count;

          ImageProvider? bg;
          if (hasImages) {
            final path = images![i];
            bg = imagesAreAssets
                ? AssetImage(path)
                : NetworkImage(path) as ImageProvider;
          }

          final colors = [
            [const Color(0xFF2F80ED), const Color(0xFF56CCF2)],
            [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
            [const Color(0xFF1D976C), const Color(0xFF93F9B9)],
          ];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias, // 터치/리플 경계 일치
              child: InkWell(
                onTap:onTapBanner,
                child: _GradientCard(
                  colors: colors[i % colors.length],
                  height: height,
                  backgroundImage: bg,          // 이미지 배경
                  darken: bg != null ? 0.25 : 0, // 가독성 위해 살짝 어둡게
                  child: Stack(
                    children: const [
                      Positioned(
                        left: 14,
                        top: 14,
                        child: _EventTag(text: 'EVENT'),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              '내 라이프스타일에 맞춰',
                              style: TextStyle(
                                color: const Color(0x9AFFFFFF),
                                fontSize: 18,      // ✅ 첫 줄만 +4
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),   // ✅ 줄 간 간격 살짝
                            Text(
                              'BNK 커스텀 DIY 카드',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,      // 기존 유지
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ); // ← Padding 닫힘
        },
      ),
    );
  }

}

/// 이미지/그라디언트 배경 카드
class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double height;

  final ImageProvider? backgroundImage;
  final double darken; // 0.0 ~ 1.0

  const _GradientCard({
    this.colors = const [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    required this.child,
    this.height = 180,
    this.backgroundImage,
    this.darken = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return SizedBox(
        height: height,
        width: double.infinity,// ✅ 바깥에서 '확정된 크기' 제공
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (backgroundImage != null)
              Image(image: backgroundImage!, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                ),
              ),
            if (backgroundImage != null && darken > 0)
              Container(color: Colors.black.withOpacity(darken)),
            child,
          ],
        ),
      ),
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
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
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
        gradient: LinearGradient(colors: [color, color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: const Icon(Icons.credit_card, color: Colors.white, size: 34),
    );
  }

  Widget _buildThumb() {
    const double thumbSize = 88;
    if (imageUrl == null || imageUrl!.isEmpty) return _fallbackGradient();

    final proxied = '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(imageUrl!)}';
    return Container(
      width: thumbSize,
      height: thumbSize,
      margin: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FittedBox(
          fit: BoxFit.contain,
          child: RotatedBox(
            quarterTurns: 1, // 90°
            child: Image.network(
              proxied,
              loadingBuilder: (ctx, child, progress) => progress == null ? child : Container(color: Colors.black12),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFEE2D2D), borderRadius: BorderRadius.circular(999)),
                              child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          if (badge != null) const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18, // ← ✅ 추가/수정 (기존엔 fontSize 없음)
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 14, height: 1.4),
                          children: [
                            const TextSpan(text: ''),
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
                child: Icon(Icons.chevron_right_rounded, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  final String? imagePathOrUrl; // 에셋 경로 또는 네트워크 URL
  final bool isAsset;           // true면 AssetImage, false면 NetworkImage
  final double darken;          // 0.0~1.0, 배경 어둡게 (텍스트 가독성)

  const _EventBanner({
    this.imagePathOrUrl,
    this.isAsset = true,
    this.darken = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? bg;
    if (imagePathOrUrl != null && imagePathOrUrl!.isNotEmpty) {
      bg = isAsset
          ? AssetImage(imagePathOrUrl!)
          : NetworkImage(imagePathOrUrl!) as ImageProvider;
    }

    return _GradientCard(
      colors: const [Color(0xFF7F7FD5), Color(0xFF86A8E7)], // 이미지 없을 때 그라디언트
      height: 120,
      backgroundImage: bg,   // ✅ 이미지 적용
      darken: darken,        // ✅ 가독성 보정
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        alignment: Alignment.bottomLeft,
        child: const Text(
          '최대혜택!\n송금수수료 면제 + 캐시백',
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

