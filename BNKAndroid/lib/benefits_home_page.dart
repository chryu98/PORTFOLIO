// lib/home/benefits_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../ApplicationStep1Page.dart' show kPrimaryRed; // 앱 공통 레드 재사용

class BenefitsHomePage extends StatefulWidget {
  const BenefitsHomePage({super.key});
  @override
  State<BenefitsHomePage> createState() => _BenefitsHomePageState();
}

class _BenefitsHomePageState extends State<BenefitsHomePage> {
  // 배너
  final _bannerCtl = PageController(viewportFraction: 0.92);
  int _bannerIndex = 0;
  Timer? _autoTimer;

  // 카드 커스텀
  double _hue = 0;          // 색상
  double _cashback = 1.0;   // % 예시

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerIndex + 1) % 3;
      _bannerCtl.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _bannerCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text('혜택', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.black87)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black87)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _bannerSection()),
          SliverToBoxAdapter(child: _quickActions()),
          SliverToBoxAdapter(child: _popularCards(context)),
          SliverToBoxAdapter(child: _customizeCard(context)),
          SliverToBoxAdapter(child: _eventsSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ----------------- 배너 -----------------
  Widget _bannerSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _bannerCtl,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemCount: 3,
              itemBuilder: (_, i) => _BannerCard(
                title: ['여름 혜택 대방출', '해외 결제 캐시백', '급여이체 이벤트'][i],
                subtitle: ['최대 5% 적립', '수수료 0원 + 2%', '편의점 상품권 증정'][i],
                color: [const Color(0xFFFFF0EC), const Color(0xFFEFF6FF), const Color(0xFFF4F6FA)][i],
                accent: [kPrimaryRed, const Color(0xFF0B57D0), const Color(0xFF0CA678)][i],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == _bannerIndex;
              return Container(
                width: active ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? kPrimaryRed : const Color(0x22000000),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ----------------- 빠른 진입 -----------------
  Widget _quickActions() {
    final items = [
      _QuickItem(Icons.credit_card, '카드'),
      _QuickItem(Icons.account_balance_wallet, '계좌'),
      _QuickItem(Icons.paid_outlined, '결제내역'),
      _QuickItem(Icons.card_giftcard, '이벤트'),
      _QuickItem(Icons.public, '환율'),
      _QuickItem(Icons.support_agent, '고객센터'),
      _QuickItem(Icons.lock, '보안'),
      _QuickItem(Icons.more_horiz, '더보기'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .95,
        ),
        itemBuilder: (_, i) => _QuickAction(item: items[i], onTap: () {}),
      ),
    );
  }

  // ----------------- 인기 카드 -----------------
  Widget _popularCards(BuildContext context) {
    final cards = [
      PopularCard('페이백 플러스', '해외 3%+α', kPrimaryRed),
      PopularCard('라이프 마일리지', '항공 2배 적립', const Color(0xFF0B57D0)),
      PopularCard('VIVA 체크', '편의점 5%', const Color(0xFF0CA678)),
      PopularCard('위클리 캐시백', '요일별 7%', const Color(0xFF8E5AF7)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secTitle('인기 카드'),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              padding: const EdgeInsets.only(right: 16),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _PopularCardTile(
                data: cards[i],
                onApply: () {
                  // TODO: 발급 플로우 연결
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- 카드 커스텀 -----------------
  Widget _customizeCard(BuildContext context) {
    final color = HSVColor.fromAHSV(1, _hue, .65, .95).toColor();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secTitle('나만의 카드 만들기'),
          const SizedBox(height: 10),
          _CardPreview(color: color, cashback: _cashback),
          const SizedBox(height: 14),
          const Text('색상', style: TextStyle(fontWeight: FontWeight.w700)),
          Slider(
            value: _hue, min: 0, max: 360,
            activeColor: kPrimaryRed,
            onChanged: (v) => setState(() => _hue = v),
          ),
          Row(
            children: [
              const Text('캐시백(예시)', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_cashback.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: _cashback, min: 0, max: 5, divisions: 10,
            activeColor: kPrimaryRed,
            onChanged: (v) => setState(() => _cashback = v),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                // TODO: 커스텀 설정으로 발급 페이지 이동
              },
              child: const Text('이 카드로 신청', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- 이벤트/공지 -----------------
  Widget _eventsSection() {
    final items = [
      ('새 학기 이벤트', '체크카드 교통 10% 추가'),
      ('BNK 페스티벌', '주말 2배 적립'),
      ('공지', '개인정보 처리방침 개정 안내'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secTitle('이벤트 & 공지'),
          const SizedBox(height: 10),
          ...items.map((e) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            dense: true,
            leading: const Icon(Icons.campaign_outlined, color: Colors.black54),
            title: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(e.$2),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          )),
        ],
      ),
    );
  }

  Widget _secTitle(String t) => Row(
    children: [
      Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    ],
  );
}

// ====== 작은 컴포넌트들 ======
class _BannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color accent;
  const _BannerCard({super.key, required this.title, required this.subtitle, required this.color, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent, side: BorderSide(color: accent, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {},
                    child: const Text('자세히 보기'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.credit_card, size: 48, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _QuickItem {
  final IconData icon; final String label;
  _QuickItem(this.icon, this.label);
}

class _QuickAction extends StatelessWidget {
  final _QuickItem item; final VoidCallback onTap;
  const _QuickAction({super.key, required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(item.label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class PopularCard {
  final String name, tag; final Color color;
  PopularCard(this.name, this.tag, this.color);
}

class _PopularCardTile extends StatelessWidget {
  final PopularCard data; final VoidCallback onApply;
  const _PopularCardTile({super.key, required this.data, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF1)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 미리보기
          Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [data.color.withOpacity(.9), data.color.withOpacity(.6)]),
            ),
            child: const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.credit_card, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(data.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(data.tag, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          SizedBox(
            height: 40, width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: data.color, width: 1.2),
                foregroundColor: data.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onApply,
              child: const Text('발급 신청'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  final Color color; final double cashback;
  const _CardPreview({super.key, required this.color, required this.cashback});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [color, color.withOpacity(.7)]),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000), offset: Offset(0, 6))],
      ),
      child: Stack(
        children: [
          const Positioned(right: 16, top: 16, child: Icon(Icons.nfc, color: Colors.white70)),
          const Positioned(right: 16, bottom: 16, child: Icon(Icons.credit_card, color: Colors.white70, size: 40)),
          Positioned(
            left: 16, bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BNK Custom', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                Text('캐시백 ~ ${cashback.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
