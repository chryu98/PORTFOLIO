import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';
import '../user/model/CardModel.dart';
import '../user/service/CardService.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'ApplicationStep1Page.dart';

/// 카테고리와 GIF 자산 경로 매핑
const Map<String, String> kCategoryGifPath = {
  '놀이공원': 'assets/amusementpark.png',
  '베이커리': 'assets/bread.png',
  '교통': 'assets/bus.png',
  '포인트&캐시백': 'assets/cashback.png',
  '커피': 'assets/coffee.png',
  '통신': 'assets/communication.png',
  '편의점': 'assets/conveniencestore.png',
  '배달앱': 'assets/delivery.png',
  '교육': 'assets/education.png',
  '환경': 'assets/environment.png',
  '주유': 'assets/gasstation.png',
  '병원': 'assets/hospital.png',
  '라운지': 'assets/lounge.png',
  '영화': 'assets/movie.png',
  '외식': 'assets/restaurant.png',
  '쇼핑': 'assets/shopping.png',
  '레저&스포츠': 'assets/sport.png',
  '구독': 'assets/subscribe.png',
  '공공요금': 'assets/bills.png',
  '공유모빌리티': 'assets/rent.png', // 임시 매핑(렌트/카셰어 느낌)
  '발렛': 'assets/valet.png', // 파일명이 ballet.gif면 valet.gif로 바꿔 쓰는 걸 권장
  //'하이패스', '세무지원' 은 GIF 없다면 자동으로 텍스트 표시됨
  '하이패스' : 'assets/highpass.png',
  '세무지원' : 'assets/taxsupport.png',
};

Widget buildCategoryHeader(String category, {double height = 22}) {
  final path = kCategoryGifPath[category];
  if (path == null) {
    return Text(
      '#$category',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.orange,
      ),
    );
  }
  return SizedBox(
    height: height,                // 기존 텍스트 높이 느낌과 비슷하게
    child: Image.asset(
      path,
      fit: BoxFit.contain,
      gaplessPlayback: true,       // 깜빡임 줄이기
      filterQuality: FilterQuality.low,
    ),
  );
}


/// 🔍 키워드 기반 카테고리 추출
List<String> extractCategories(String text, {int max = 5}) {
  const keywords = {
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
  final result = <String>{};

  for (var entry in keywords.entries) {
    if (result.length >= max) break;
    for (var keyword in entry.value) {
      if (lower.contains(keyword.toLowerCase())) {
        result.add(entry.key);
        break;
      }
    }
  }

  return result.toList();
}

Widget buildSimpleBenefitBox(String category, String line, {String? rate}) {
  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rate != null) ...[
          Text(rate,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xffB91111),
              )),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: buildCategoryHeader(category, height: 40), // ← 28~34 정도 권장
              ),
              const SizedBox(height: 4),
              Text(line,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  )),
            ],
          ),
        ),
      ],
    ),
  );
}

/// ✅ 통문자열 → 요약 박스 리스트로 자동 변환 (퍼센트 강조만)


List<Widget> buildSummarizedBenefits(String rawText) {
  final Map<String, List<String>> keywordMap = {
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

  final lines = rawText
      .split(RegExp(r'\n|(?<!\d)-|•|·|◆|▶|\(\d+\)|(?=\d+\.\s)'))
      .map((e) => e.trim().replaceFirst(RegExp(r'^(\d+\.|\(\d+\))\s*'), ''))
      .where((e) => e.isNotEmpty)
      .toList();

  final widgets = <Widget>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    for (final entry in keywordMap.entries) {
      final category = entry.key;
      final keywords = entry.value;

      if (keywords.any((k) => line.contains(k))) {
        widgets.add(_AnimatedOnVisible(
          key: Key('benefit_$i'),
          child: buildCleanBenefitBox(category, line),
        ));
        break;
      }
    }
  }

  return widgets;
}

class _AnimatedOnVisible extends StatefulWidget {
  final Widget child;

  const _AnimatedOnVisible({Key? key, required this.child}) : super(key: key);

  @override
  State<_AnimatedOnVisible> createState() => _AnimatedOnVisibleState();
}

class _AnimatedOnVisibleState extends State<_AnimatedOnVisible> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: AnimatedOpacity(
        opacity: _isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _isVisible ? Offset.zero : const Offset(0, 0.2),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}


Widget buildCleanBenefitBox(String category, String content) {
  final percentRegex = RegExp(r'(\d{1,2}%|\d{1,2}\.\d+%)');
  final spans = <TextSpan>[];

  final matches = percentRegex.allMatches(content);
  int lastIndex = 0;

  for (final match in matches) {
    final matchStart = match.start;
    final matchEnd = match.end;

    if (matchStart > lastIndex) {
      spans.add(TextSpan(text: content.substring(lastIndex, matchStart)));
    }

    spans.add(TextSpan(
      text: content.substring(matchStart, matchEnd),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
    ));

    lastIndex = matchEnd;
  }

  if (lastIndex < content.length) {
    spans.add(TextSpan(text: content.substring(lastIndex)));
  }

  return Center(
    child: Container(
      width: 390,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),

      // 내부는 왼쪽 정렬
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // ← 가운데 정렬
        children: [
          Center(
            child: buildCategoryHeader(category, height: 80), // ← 크기 키움 (32~40 추천)
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center, // ← 본문 텍스트 가운데
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 13),
              children: spans,
            ),
          ),
        ],
      ),
    ),
  );
}




/// 🏷️ 해시태그 형태로 보여줄 때 사용하는 위젯 리스트
List<Widget> extractCategoriesAsWidget(String text, {int max = 5}) {
  return extractCategories(text, max: max)
      .map((tag) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red),
      ),
      child: Text('#$tag',
          style: const TextStyle(fontSize: 12, color: Colors.red)),
    ),
  ))
      .toList();
}

class CardDetailPage extends StatefulWidget {
  final String cardNo;
  final ValueNotifier<Set<String>> compareIds;
  final VoidCallback onCompareChanged;

  const CardDetailPage({
    super.key,
    required this.cardNo,
    required this.compareIds,
    required this.onCompareChanged,
  });

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  late Future<CardModel> _futureCard;

  @override
  void initState() {
    super.initState();
    _futureCard = CardService.fetchCompareCardDetail(widget.cardNo);
  }

  void _toggleCompare(String cardNo) {
    final s = widget.compareIds.value.toSet();
    if (s.contains(cardNo)) {
      s.remove(cardNo);
    } else if (s.length < 2) {
      s.add(cardNo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 2개까지만 비교 가능합니다')),
      );
      return;
    }
    widget.compareIds.value = s;
    widget.onCompareChanged();
    setState(() {});
  }

  Future<void> _startCardApplication(String cardNo) async {
    try {
      final url = '${API.baseUrl}/api/application/start';
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cardNo': cardNo}),
      );

      if (res.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(res.bodyBytes));
        final applicationNo = jsonData['applicationNo'];
        final isCreditCard = jsonData['isCreditCard']?.toString();

        // Step 1 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicationStep1Page(
              applicationNo: applicationNo,
              isCreditCard: isCreditCard == 'Y',
            ),
          ),
        );
      } else {
        print('❌ 서버 응답 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ 카드 신청 오류: $e');
    }
  }


  void _showCompareModal() {
    final ids = widget.compareIds.value;
    if (ids.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비교할 카드 2개를 담아주세요.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.compareIds.value.map((id) {
              return FutureBuilder<CardModel>(
                future: CardService.fetchCompareCardDetail(id),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const SizedBox(
                        width: 80,
                        height: 120,
                        child: CircularProgressIndicator());
                  }
                  final c = snap.data!;
                  final brand = (c.cardBrand ?? '').toUpperCase();
                  final fee = '${c.annualFee ?? 0}원';
                  final feeDom = brand.contains('LOCAL') || brand.contains('BC') ? fee : '없음';
                  final feeVisa = brand.contains('VISA') ? fee : '없음';
                  final feeMaster = brand.contains('MASTER') ? fee : '없음';
                  final tags = extractCategories('${c.service}\n${c.sService ?? ''}');

                  return Flexible(
                    child: Container(
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
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
                          ),
                          const SizedBox(height: 8),
                          Text(c.cardName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(c.cardSlogan ?? '-', style: const TextStyle(fontSize: 12)),

                          /// ✅ 해시태그 추가 영역
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: extractCategories('${c.service}\n${c.sService ?? ''}')
                                .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(fontSize: 11, color: Colors.red),
                              ),
                            ))
                                .toList(),
                          ),
                          const SizedBox(height: 6),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _feeItemWithIcon('assets/overseas_pay_domestic.png', feeDom),
                              const SizedBox(height: 4),
                              _feeItemWithIcon('assets/overseas_pay_visa.png', feeVisa),
                              const SizedBox(height: 4),
                              _feeItemWithIcon('assets/overseas_pay_master.png', feeMaster),
                            ],
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 상세정보'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xffB91111),
      ),
      body: FutureBuilder<CardModel>(
        future: _futureCard,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final card = snapshot.data!;
          final imgUrl = '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}';
          final brand = (card.cardBrand ?? '').toUpperCase();
          final fee = '${(card.annualFee ?? 0)}원';

          final feeDomestic = (brand.contains('LOCAL') || brand.contains('BC')) ? fee : '없음';
          final feeVisa = brand.contains('VISA') ? fee : '없음';
          final feeMaster = brand.contains('MASTER') ? fee : '없음';

          final tags = extractCategories('${card.service}\n${card.sService ?? ''}');
          final isInCompare = widget.compareIds.value.contains(card.cardNo.toString());

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 300, // 상단 전체 높이 (배경 포함)
                      color: const Color(0xFFF4F6FA), // 연한 블루그레이 배경
                      alignment: Alignment.center,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Image.network(
                          imgUrl,
                          height: 160, // 이미지 자체 높이만 제어
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Text(
                        card.cardName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF4E4E4E),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(card.cardSlogan ?? '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          )),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleCompare(card.cardNo.toString()),

                        label: Text(
                          isInCompare ? "-   비교함 제거" : "+   비교함 담기",
                          style: const TextStyle(color: Color(0xFF4E4E4E)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF4F6FA), // 연한 그레이
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),


                    Align(
                      alignment: Alignment.center, // ← 생략해도 무방
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // ← ✅ start → center
                        children: [
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center, // ✅ 중심 정렬
                            children: [
                              _feeItemWithIcon('assets/overseas_pay_domestic.png', feeDomestic),
                              const SizedBox(width: 30),
                              _feeItemWithIcon('assets/overseas_pay_visa.png', feeVisa),
                              const SizedBox(width: 30),
                              _feeItemWithIcon('assets/overseas_pay_master.png', feeMaster),
                            ],
                          ),
                          const SizedBox(height: 16),

                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text('#$t', style: const TextStyle(color: Colors.red, fontSize: 13)),
                        )).toList(),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Divider(),
                    const SizedBox(height: 18),



                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _sectionTitle('혜택 요약'),
                    ),
                    const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.center,
                    child: AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: buildSummarizedBenefits('${card.service}\n${card.sService ?? ''}')
                            .asMap()
                            .entries
                            .map(
                              (entry) => AnimationConfiguration.staggeredList(
                            position: entry.key,
                            delay: Duration(milliseconds: (50 * pow(entry.key + 1, 1.2)).toInt()),
                            duration: const Duration(milliseconds: 300),
                            child: SlideAnimation(
                              verticalOffset: 20.0,
                              curve: Curves.easeOut,
                              child: FadeInAnimation(
                                duration: const Duration(milliseconds: 300),
                                child: entry.value,
                              ),
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  ),


                  const SizedBox(height: 30),
                    SectionTile(
                      title: '유의사항',
                      child: Text(
                        (card.notice != null && card.notice!.trim().isNotEmpty)
                            ? card.notice!
                            : '유의사항이 없습니다.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                right: 20,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: widget.compareIds,
                  builder: (context, ids, _) {
                    if (ids.isEmpty) return const SizedBox();
                    return FloatingActionButton.extended(
                      backgroundColor: Color(0xFFF4F6FA),
                      foregroundColor: Color(0xFF4E4E4E),

                      label: Text('비교함 (${ids.length})'),
                      onPressed: _showCompareModal,
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<CardModel>(
        future: _futureCard,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final card = snapshot.data!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _startCardApplication(card.cardNo.toString()),
                icon: const Icon(Icons.credit_card),
                label: const Text("카드 발급하기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffB91111),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

  }

  Widget _feeItem(String label, String value) => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(value),
    ]),
  );

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

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: Colors.black, margin: const EdgeInsets.only(right: 8)),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF444444),
          ),
        ),
      ],
    );
  }
}

class SectionTile extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const SectionTile({
    Key? key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<SectionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: Colors.black,
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF444444),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ],
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: widget.child,
          ),
      ],
    );
  }
}
