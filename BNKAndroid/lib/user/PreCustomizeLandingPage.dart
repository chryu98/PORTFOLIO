import 'package:flutter/material.dart';
import 'package:bnkandroid/user/CustomCardEditorPage.dart';

class PreCustomizeLandingPage extends StatefulWidget {
  const PreCustomizeLandingPage({
    super.key,
    required this.memberNo,
  });

  final int? memberNo; // 로그인 안됐을 때 null 허용

  @override
  State<PreCustomizeLandingPage> createState() =>
      _PreCustomizeLandingPageState();
}

class _PreCustomizeLandingPageState extends State<PreCustomizeLandingPage> {
  static const kBrand = Color(0xFFB91111);

  // 샘플 이미지 (assets 사용)
  final String _heroUrl = 'assets/banner3.png';
  final List<String> _sampleUrls = [
    'assets/cusbanner1.png',
    'assets/cusbanner2.png',
    'assets/cusbanner3.png',
  ];

  // 금지 예시 텍스트
  final List<String> _banTexts = [
    '타인의 얼굴이 식별되는 사진',
    '상표/로고/저작권 있는 이미지',
    '폭력/혐오/음란 등 부적절한 콘텐츠',
  ];

  int _selectedIndex = 0; // 현재 선택된 썸네일

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final isSmall = w < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ─── 히어로 배너 ───
            SliverToBoxAdapter(
              child: _HeroBanner(
                imageUrl: _heroUrl,
                title: '나답게, 다르게, 특별하게',
                subtitle: '나만의 커스텀 카드로 표현하세요',
              ),
            ),

            // ─── "X 이런 사진은 안돼요 X" ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'X 이런 사진은 안돼요 X',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmall ? 22 : 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 큰 미리보기 카드
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1.15,
                          child: Image.asset(
                            _sampleUrls[_selectedIndex],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 선택된 썸네일에 맞는 금지 텍스트만 표시
                    Text(
                      _banTexts[_selectedIndex],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 썸네일 Row (큰 이미지 바깥 아래쪽)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_sampleUrls.length, (i) {
                        final selected = _selectedIndex == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? kBrand : Colors.transparent,
                                width: selected ? 2 : 0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                _sampleUrls[i],
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),




                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),

      // ─── 하단 CTA 버튼 ───
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, -4),
                blurRadius: 10,
              )
            ],
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kBrand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () {
                if (widget.memberNo == null || widget.memberNo == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인 후 이용 가능합니다.')),
                  );
                  return;
                }
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomCardEditorPage(memberNo: widget.memberNo!),
                    fullscreenDialog: true,
                  ),
                );
              },
              child: const Text('커스텀하기'),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  final String imageUrl;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bannerH = 400.0; // 배너 높이 조금 더 크게

    return SizedBox(
      height: bannerH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(imageUrl, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xB3000000),
                  Color(0x33000000),
                  Color(0x11000000),
                  Color(0x00000000),
                ],
              ),
            ),
          ),
          // ✅ 왼쪽 상단 뒤로가기 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    )),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
