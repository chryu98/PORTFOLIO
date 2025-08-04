import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';
import '../user/model/CardModel.dart';
import '../user/service/CardService.dart';

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

List<Widget> buildBenefitSummaryWidgets(String text) {
  const categoryKeywords = {
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

  final lowerText = text.toLowerCase();
  final widgets = <Widget>[];

  for (final entry in categoryKeywords.entries) {
    final category = entry.key;
    final keywords = entry.value;
    final matched = keywords.where((k) => lowerText.contains(k.toLowerCase())).toList();

    if (matched.isNotEmpty) {
      final lines = text.split(RegExp(r'\n|•|-|·')).where((line) {
        return keywords.any((k) => line.toLowerCase().contains(k.toLowerCase()));
      }).toList();

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#$category',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 14)),
              const SizedBox(height: 6),
              ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line.trim(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              )),
            ],
          ),
        ),
      );
    }
  }

  return widgets;
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
        backgroundColor: const Color(0xffB91111),
        foregroundColor: Colors.white,
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
                    Center(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Image.network(
                          imgUrl,
                          height: 160,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(card.cardName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(card.cardSlogan ?? '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          )),
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleCompare(card.cardNo.toString()),
                        icon: const Icon(Icons.compare),
                        label: Text(isInCompare ? "비교함 제거" : "비교함 담기"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('연회비'),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _feeItemWithIcon('assets/overseas_pay_domestic.png', feeDomestic),
                              const SizedBox(height: 6),
                              _feeItemWithIcon('assets/overseas_pay_visa.png', feeVisa),
                              const SizedBox(height: 6),
                              _feeItemWithIcon('assets/overseas_pay_master.png', feeMaster),
                            ],
                          ),
                          const SizedBox(height: 16), // ✅ 해시태그 간격

                        ],
                      ),
                    ),


                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _sectionTitle('혜택 요약'),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: buildBenefitSummaryWidgets('${card.service}\n${card.sService ?? ''}'),
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
                bottom: 20,
                right: 20,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: widget.compareIds,
                  builder: (context, ids, _) {
                    if (ids.isEmpty) return const SizedBox();
                    return FloatingActionButton.extended(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.compare_arrows),
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
