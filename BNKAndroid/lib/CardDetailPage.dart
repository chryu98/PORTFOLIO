import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';
import '../user/model/CardModel.dart';
import '../user/service/CardService.dart';

List<String> extractCategories(String text, {int max = 5}) {
  const keywords = {
    '교통': ['지하철', '버스', '택시', '후불교통'],
    '통신': ['통신요금', '휴대폰', 'SKT', 'KT', 'LGU+'],
    '교육': ['학원', '학습지'],
    '병원': ['병원', '약국'],
    '공공요금': ['전기요금', '도시가스', '아파트관리비'],
    '포인트&캐시백': ['포인트', '캐시백', '청구할인'],
    '기타': []
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

List<Widget> extractCategoriesAsWidget(String text, {int max = 5}) {
  return extractCategories(text, max: max)
      .map((tag) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text('#$tag', style: const TextStyle(fontSize: 12, color: Colors.red)),
    ),
  ))
      .toList();
}

class CardDetailPage extends StatefulWidget {
  final String cardNo;
  const CardDetailPage({super.key, required this.cardNo});

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  late Future<CardModel> _futureCard;
  bool _isInCompare = false;

  @override
  void initState() {
    super.initState();
    _futureCard = CardService.fetchCompareCardDetail(widget.cardNo);
  }

  Future<void> _checkCompare(CardModel card) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('compareCards') ?? [];
    final existing = rawList.map((e) => jsonDecode(e)['cardNo'] as String).toList();

    setState(() {
      _isInCompare = existing.contains(card.cardNo.toString());
    });
  }

  Future<void> _toggleCompare(CardModel card) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('compareCards') ?? [];
    final cardId = card.cardNo.toString();

    final existing = rawList.map((e) => jsonDecode(e)['cardNo'].toString()).toList();

    if (existing.contains(cardId)) {
      rawList.removeWhere((e) => jsonDecode(e)['cardNo'].toString() == cardId);
      print("➖ 비교함에서 제거됨: $cardId");
    } else if (existing.length >= 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 2개까지만 비교할 수 있습니다.')),
        );
      }
      return;
    } else {
      rawList.add(jsonEncode({'cardNo': cardId}));
      print("➕ 비교함에 추가됨: $cardId");
    }

    await prefs.setStringList('compareCards', rawList);
    await _checkCompare(card);

    Navigator.pop(context, true); // 상태 변경을 알림
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final card = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkCompare(card));

          final imgUrl = '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}';
          final brand = (card.cardBrand ?? '').toUpperCase();
          final fee = '${(card.annualFee ?? 0).toString()}원';

          final feeDomestic = (brand.contains('LOCAL') || brand.contains('BC')) ? fee : '없음';
          final feeVisa = brand.contains('VISA') ? fee : '없음';
          final feeMaster = brand.contains('MASTER') ? fee : '없음';

          final tags = extractCategories('${card.service}\n${card.sService ?? ''}');

          return SingleChildScrollView(
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
                Text(card.cardName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                  onPressed: () => _toggleCompare(card),
                  icon: const Icon(Icons.compare),
                  label: Text(_isInCompare ? "비교함 제거" : "비교함 담기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const Text('🔖 혜택 요약', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...extractCategoriesAsWidget('${card.service}\n${card.sService ?? ''}'),
                const SizedBox(height: 30),
                const Text('📌 상세 혜택', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(card.sService ?? '-', style: const TextStyle(fontSize: 13)),
              ],
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
}
