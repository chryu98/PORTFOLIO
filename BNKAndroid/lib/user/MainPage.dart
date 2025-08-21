import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CardMainPage extends StatefulWidget {
  const CardMainPage({super.key});

  @override
  State<CardMainPage> createState() => _CardMainPageState();
}

class _CardMainPageState extends State<CardMainPage> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.9);
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: _Logo(),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('로그인', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 24),
        children: [
          // 검색창
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 4),
            child: _SearchPill(
              hint: '민생회복 소비쿠폰 바로가기',
              onTapArrow: () {},
            ),
          ),

          // 이벤트 캐러셀
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 8),
            child: _EventCarousel(
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

          // 인기·추천카드
          _SectionHeader(title: '인기 · 추천카드', onTapMore: () {}),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(
              children: const [
                _CardListItem(
                  badge: 'New',
                  title: '생활 맞춤 10% 할인',
                  highlight: '정기결제 최대 20% 할인',
                  brand: '신한카드 Discount Plan',
                ),
                SizedBox(height: 12),
                _CardListItem(
                  badge: 'New',
                  title: '호시노 리조트 ~30% 할인',
                  highlight: '국내외 적립/결합 추가 적립',
                  brand: 'Haru(Hoshino Resorts)',
                  color: Color(0xFF7AB3C9),
                ),
                SizedBox(height: 12),
                _CardListItem(
                  title: '공과금·일상 10% 할인',
                  highlight: '주유소 60원/L 할인',
                  brand: '신한카드 Mr.Life',
                  color: Color(0xFFE24A3B),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 금융 섹션
          _SectionHeader(title: '금융', onTapMore: () {}),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _RoundedPanel(
              child: Column(
                children: const [
                  _FinanceRow(title: '장기카드대출(카드론)', sub: '목돈이 필요할 때'),
                  Divider(height: 1),
                  _FinanceRow(title: '단기카드대출(현금서비스)', sub: '365일 24시간 현금이 필요할 때'),
                  Divider(height: 1),
                  _FinanceRow(title: '일부결제금액이월약정(리볼빙)', sub: '결제금액이 부담될 때'),
                  Divider(height: 1),
                  _FinanceRow(title: '가계신용대출·사업자대출', sub: '목돈과 생활자금이 간편한'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 이벤트 배너
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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 로고가 없으면 텍스트로 대체
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFB91111), width: 1.2),
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

class _EventCarousel extends StatelessWidget {
  final PageController controller;
  final ValueChanged<int>? onPageChanged;

  const _EventCarousel({required this.controller, this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
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
            child: _GradientCard(
              colors: colors[i],
              child: Stack(
                children: [
                  const Positioned(
                    right: 16,
                    bottom: 12,
                    child: Icon(Icons.credit_card, size: 72, color: Colors.white70),
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
          );
        },
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;

  const _GradientCard({
    this.colors = const [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
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

class _CardListItem extends StatelessWidget {
  final String? badge;
  final String title;
  final String highlight;
  final String brand;
  final Color color;

  const _CardListItem({
    this.badge,
    required this.title,
    required this.highlight,
    required this.brand,
    this.color = const Color(0xFF3AA0E7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          // 썸네일(그라데이션 카드)
          Container(
            width: 68,
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
          ),
          const SizedBox(width: 8),
          // 텍스트
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEE2D2D),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      if (badge != null) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 12, height: 1.2),
                      children: [
                        TextSpan(text: highlight, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2046D1))),
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
            child: Icon(Icons.chevron_right_rounded, color: Colors.black54),
          )
        ],
      ),
    );
  }
}

class _RoundedPanel extends StatelessWidget {
  final Widget child;
  const _RoundedPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FinanceRow extends StatelessWidget {
  final String title;
  final String sub;

  const _FinanceRow({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(sub, style: TextStyle(color: Colors.black.withOpacity(0.55))),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
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
