import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:http/http.dart' as http;

import 'package:bnkandroid/user/LoginPage.dart';
import 'package:bnkandroid/user/service/card_apply_service.dart';
import 'package:bnkandroid/constants/api.dart';
import 'package:bnkandroid/user/model/CardModel.dart';
import 'package:bnkandroid/user/service/CardService.dart';
import 'ApplicationStep1Page.dart';

import 'package:bnkandroid/navigation/guards.dart';
import 'package:bnkandroid/app_shell.dart' show pushFullScreen; // root push helper

// ApiException이 정의된 위치에 맞춰 import
// 예시: import 'package:bnkandroid/constants/api_exception.dart';

/// 혜택 아이콘(카테고리 이미지) 높이
const double kBenefitIconHeight = 150;

/// 카테고리명 → 이미지 자산 경로
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
  '공유모빌리티': 'assets/rent.png',
  '발렛': 'assets/valet.png',
  '하이패스': 'assets/highpass.png',
  '세무지원': 'assets/taxsupport.png',
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
    height: height,
    child: Image.asset(
      path,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    ),
  );
}

bool _looksLikeDetail(String s) {
  final t = s.trim();
  final hasNumberOrUnit = RegExp(r'(\d+[%원]|[0-9,]+|월|최대|이상|이하)').hasMatch(t);
  final hasDetailWord = RegExp(
    r'(무료|무제한|청구|적립|캐시백|면제|추가|포인트|포함|제외|가능|지원|제공|적용|환급|수수료|라운지|발급|이용)',
  ).hasMatch(t);
  final looksLikeShortTitle =
      t.length <= 14 && !hasNumberOrUnit && RegExp(r'(혜택|할인|서비스)\s*$').hasMatch(t);
  final hasParen = t.contains('(') || t.contains(')');

  return (hasNumberOrUnit || hasDetailWord || hasParen) && !looksLikeShortTitle;
}

String? _categoryOf(String line, Map<String, List<String>> keywordMap) {
  final src = line.toLowerCase();
  for (final e in keywordMap.entries) {
    for (final k in e.value) {
      if (src.contains(k.toLowerCase())) return e.key;
    }
  }
  return null;
}

List<TextSpan> _percentHighlight(String content) {
  final regex = RegExp(r'(\d{1,2}(?:\.\d+)?%|[0-9,]+원)');
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in regex.allMatches(content)) {
    if (m.start > last) spans.add(TextSpan(text: content.substring(last, m.start)));
    spans.add(TextSpan(
      text: content.substring(m.start, m.end),
      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xffB91111)),
    ));
    last = m.end;
  }
  if (last < content.length) spans.add(TextSpan(text: content.substring(last)));
  return spans;
}

Widget buildGroupedBenefitBox(String category, List<String> details) {
  return Center(
    child: Container(
      width: 390,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildCategoryHeader(category, height: kBenefitIconHeight),
          const SizedBox(height: 12),
          ...details.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 13),
                children: _percentHighlight(d),
              ),
            ),
          )),
        ],
      ),
    ),
  );
}

/// 카테고리 추출
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
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rate != null) ...[
          Text(rate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xffB91111))),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(alignment: Alignment.center, child: buildCategoryHeader(category, height: 40)),
              const SizedBox(height: 4),
              Text(line, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 통문자열 → 요약 박스 리스트
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
      .split(RegExp(r'[\r\n]+|•|·|◆|▶|▪|●'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final Map<String, List<String>> groups = {};
  String? lastCat;

  for (final line in lines) {
    final detected = _categoryOf(line, keywordMap);
    final cat = detected ?? lastCat;

    if (!_looksLikeDetail(line)) {
      if (detected != null) lastCat = detected;
      continue;
    }

    if (cat != null) {
      groups.putIfAbsent(cat, () => <String>[]).add(line);
      lastCat = cat;
    }
  }

  final widgets = <Widget>[];
  var idx = 0;
  for (final entry in groups.entries) {
    widgets.add(_AnimatedOnVisible(
      key: Key('benefit_group_${idx++}'),
      child: buildGroupedBenefitBox(entry.key, entry.value),
    ));
  }
  return widgets;
}

class _AnimatedOnVisible extends StatefulWidget {
  final Widget child;
  const _AnimatedOnVisible({super.key, required this.child});
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
          setState(() => _isVisible = true);
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
    if (match.start > lastIndex) {
      spans.add(TextSpan(text: content.substring(lastIndex, match.start)));
    }
    spans.add(TextSpan(
      text: content.substring(match.start, match.end),
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
    ));
    lastIndex = match.end;
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: buildCategoryHeader(category, height: 160)),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 13), children: spans),
          ),
        ],
      ),
    ),
  );
}

/// 해시태그 위젯
List<Widget> extractCategoriesAsWidget(String text, {int max = 5}) {
  return extractCategories(text, max: max)
      .map((tag) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red),
      ),
      child: Text('#$tag', style: const TextStyle(fontSize: 12, color: Colors.red)),
    ),
  ))
      .toList();
}

/* ──────────────────────────────── Detail Page ─────────────────────────────── */

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

  /// 발급 시작 (로그인 체크 → 필요 시 로그인 → 이어서 발급)
  Future<void> _startCardApplication(String cardNoStr) async {
    final cardNo = int.tryParse(cardNoStr);
    if (cardNo == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('잘못된 카드 번호입니다.')),
      );
      return;
    }

    // ✅ 1) 로그인 가드: 미로그인이면 LoginPage를 root로 띄우고, 성공 시 이후 로직 실행
    await ensureLoggedInAndRun(context, () async {
      try {
        // ✅ 2) 서버에 발급 시작 요청
        final start = await CardApplyService.start(cardNo: cardNo);

        if (!mounted) return;

        // ✅ 3) 발급 플로우는 반드시 "루트 네비게이터"로 푸시
        await pushFullScreen(
          context,
          ApplicationStep1Page(
            cardNo: cardNo,
            applicationNo: start.applicationNo,
            isCreditCard: start.isCreditCard,
          ),
        );
      } on ApiException catch (e) {
        // 🔁 4) 토큰 만료 등 인증 오류(401) → 재로그인 유도 후 1회 재시도
        final status = _extractStatusCode(e); // 기존 헬퍼 그대로 사용
        if (status == 401) {
          if (!mounted) return;
          final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          if (ok == true) {
            // 재로그인 성공 → 1회 재시도
            await _startCardApplication(cardNo.toString());
          }
          return;
        }

        if (!mounted) return;
        final msg = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('발급 시작 실패: $msg')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('발급 시작 오류: $e')),
        );
      }
    });
  }


  /// ---- 여기 아래 두 개 헬퍼를 같은 파일(같은 클래스 안 or 바깥) 에 추가하세요 ----

  int _extractStatusCode(dynamic e) {
    try {
      // 1) e.statusCode (가장 흔한 케이스)
      final sc = (e as dynamic).statusCode;
      if (sc is int) return sc;
    } catch (_) {}

    try {
      // 2) e.code (일부 생성 클라이언트가 code 필드 사용)
      final code = (e as dynamic).code;
      if (code is int) return code;
    } catch (_) {}

    try {
      // 3) e.response?.statusCode (Dio/일부 구현)
      final resp = (e as dynamic).response;
      final sc = (resp as dynamic)?.statusCode;
      if (sc is int) return sc;
    } catch (_) {}

    return 0; // 알 수 없음
  }

  String _extractErrorMessage(dynamic e) {
    // body.message → message → toString 순으로 시도
    try {
      final body = (e as dynamic).body;
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}

    try {
      final msg = (e as dynamic).message;
      if (msg != null) return msg.toString();
    } catch (_) {}

    return e.toString();
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
                    return const SizedBox(width: 80, height: 120, child: CircularProgressIndicator());
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
                              child: Text('#$tag',
                                  style: const TextStyle(fontSize: 11, color: Colors.red)),
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
    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.compareIds,
      builder: (context, ids, __) {
        final hasCompare = ids.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('카드 상세정보'),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF4E4E4E),
            bottom: hasCompare
                ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _TopCompareBar(
                  count: ids.length,
                  onOpen: _showCompareModal,
                  onClear: () {
                    widget.compareIds.value = {};
                    widget.onCompareChanged();
                    setState(() {});
                  },
                ),
              ),
            )
                : null,
          ),
          body: FutureBuilder<CardModel>(
            future: _futureCard,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final card = snapshot.data!;
              final imgUrl = '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}';
              final brand = (card.cardBrand ?? '').toUpperCase();
              final fee = '${(card.annualFee ?? 0)}원';
              final feeDomestic = (brand.contains('LOCAL') || brand.contains('BC')) ? fee : '없음';
              final feeVisa = brand.contains('VISA') ? fee : '없음';
              final feeMaster = brand.contains('MASTER') ? fee : '없음';
              final tags = extractCategories('${card.service}\n${card.sService ?? ''}');
              final isInCompare = widget.compareIds.value.contains(card.cardNo.toString());

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 300,
                      color: const Color(0xFFF4F6FA),
                      alignment: Alignment.center,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Image.network(
                          imgUrl,
                          height: 160,
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
                      child: Text(
                        card.cardSlogan ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _CompareToggle(
                      selected: isInCompare,
                      onPressed: () => _toggleCompare(card.cardNo.toString()),
                    ),

                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                        children: tags
                            .map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text('#$t', style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 18),

                    const SizedBox(height: 30),
                    Align(alignment: Alignment.centerLeft, child: _sectionTitle('혜택 요약')),
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
                        (card.notice != null && card.notice!.trim().isNotEmpty) ? card.notice! : '유의사항이 없습니다.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
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
                  height: 50, // ✅ 숫자
                  child: ElevatedButton.icon( // ✅ 버튼은 child에
                    onPressed: () => _startCardApplication(card.cardNo.toString()),
                    icon: const Icon(Icons.credit_card),
                    label: const Text('카드 발급하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffB91111),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _feeItemWithIcon(String assetPath, String feeText) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(assetPath, width: 24, height: 24),
        const SizedBox(width: 4),
        Text(feeText, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: Colors.black, margin: const EdgeInsets.only(right: 8)),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF444444))),
      ],
    );
  }
}

/* ───────────── 상단 고정 비교함 바 ───────────── */

class _TopCompareBar extends StatelessWidget {
  final int count;
  final VoidCallback onOpen;
  final VoidCallback onClear;
  const _TopCompareBar({
    super.key,
    required this.count,
    required this.onOpen,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFF1F4)),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          Text('비교함 $count개 담김',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
          const Spacer(),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: const Text('비우기'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onOpen,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('비교하기', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/* ───────────── 카드리스트와 동일한 비교 토글 ───────────── */

class _CompareToggle extends StatelessWidget {
  final bool selected;
  final VoidCallback onPressed;
  const _CompareToggle({required this.selected, required this.onPressed});

  static const _green = Color(0xFF2E7D32);
  static const _greenBg = Color(0xFFE8F5E9);
  static const _pillPad = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: _pillPad,
          decoration: BoxDecoration(
            color: _greenBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _green.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 16, color: _green),
              SizedBox(width: 6),
              Text('비교함에 추가됨',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _green)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: _pillPad,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Color(0xFF555555)),
            SizedBox(width: 6),
            Text('비교함 담기',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
          ],
        ),
      ),
    );
  }
}

/* ───────────── 접이식 섹션 ───────────── */

class SectionTile extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const SectionTile({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

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
            Container(width: 4, height: 20, color: Colors.black, margin: const EdgeInsets.only(right: 8)),
            Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF444444))),
            const Spacer(),
            IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.black87),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ],
        ),
        if (_isExpanded) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: widget.child),
      ],
    );
  }
}

/// 로그인 후 자동으로 발급 시작 API를 호출해 Step1로 넘겨주는 중간 페이지
class _ContinueApplicationPage extends StatefulWidget {
  final int cardNo;
  const _ContinueApplicationPage({required this.cardNo});

  @override
  State<_ContinueApplicationPage> createState() => _ContinueApplicationPageState();
}

class _ContinueApplicationPageState extends State<_ContinueApplicationPage> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    try {
      final start = await CardApplyService.start(cardNo: widget.cardNo);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationStep1Page(
            cardNo: widget.cardNo,
            applicationNo: start.applicationNo,
            isCreditCard: start.isCreditCard,
          ),
        ),
      );
    } on ApiException catch (e) {
      final status = _extractStatusCode(e); // ← 헬퍼 사용
      if (status == 401) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(
              redirectBuilder: (_) => _ContinueApplicationPage(cardNo: widget.cardNo),
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      final msg = _extractErrorMessage(e); // ← 헬퍼 사용
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('발급 시작 실패: $msg')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('발급 시작 오류: $e')),
      );
      Navigator.pop(context);
    }
  }
  int _extractStatusCode(dynamic e) {
    // 1) e.statusCode
    try {
      final sc = (e as dynamic).statusCode;
      if (sc is int) return sc;
    } catch (_) {}

    // 2) e.code
    try {
      final c = (e as dynamic).code;
      if (c is int) return c;
    } catch (_) {}

    // 3) e.response?.statusCode (Dio 스타일)
    try {
      final resp = (e as dynamic).response;
      final sc = (resp as dynamic)?.statusCode;
      if (sc is int) return sc;
    } catch (_) {}

    return 0;
  }

  String _extractErrorMessage(dynamic e) {
    // body.message → message → toString()
    try {
      final body = (e as dynamic).body;
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}

    try {
      final msg = (e as dynamic).message;
      if (msg != null) return msg.toString();
    } catch (_) {}

    return e.toString();
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
