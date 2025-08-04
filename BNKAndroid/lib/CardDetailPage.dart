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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
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

                  return Flexible(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12)),
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
                          const SizedBox(height: 8),
                          const Text('💳 연회비'),
                          Text('국내: $feeDom'),
                          Text('VISA: $feeVisa'),
                          Text('MASTER: $feeMaster'),
                          const SizedBox(height: 8),
                          const Text('🔖 요약 혜택', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...extractCategoriesAsWidget('${c.service}\n${c.sService ?? ''}'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.network(
                        imgUrl,
                        height: 240,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(card.cardName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(card.cardSlogan ?? '-', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: tags
                          .map((t) => Chip(
                        label: Text('#$t'),
                        backgroundColor: Colors.red.shade50,
                        labelStyle: const TextStyle(color: Colors.red),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('💳 연회비', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(children: [
                      _feeItem('국내', feeDomestic),
                      _feeItem('VISA', feeVisa),
                      _feeItem('MASTER', feeMaster),
                    ]),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _toggleCompare(card.cardNo.toString()),
                      icon: const Icon(Icons.compare),
                      label: Text(isInCompare ? "비교함 제거" : "비교함 담기"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('🔖 혜택 요약', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...buildBenefitSummaryWidgets('${card.service}\n${card.sService ?? ''}'),
                    const SizedBox(height: 30),
                    const Text('📌 상세 혜택', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(card.sService ?? '-', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: widget.compareIds,
                  builder: (context, ids, _) {
                    return FloatingActionButton.extended(
                      backgroundColor: Colors.red,
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
}
