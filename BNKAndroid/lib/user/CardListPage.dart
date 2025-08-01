import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:bnkandroid/constants/api.dart';
import 'package:bnkandroid/user/service/CardService.dart';
import 'model/CardModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CompareCard {
  final String cardNo;
  final String cardName;
  final String cardUrl;

  CompareCard({
    required this.cardNo,
    required this.cardName,
    required this.cardUrl,
  });

  factory CompareCard.fromCardModel(CardModel card) {
    return CompareCard(
      cardNo: card.cardNo.toString(),
      cardName: card.cardName,
      cardUrl: card.cardUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'cardNo': cardNo,
    'cardName': cardName,
    'cardUrl': cardUrl,
  };

  factory CompareCard.fromJson(Map<String, dynamic> json) {
    return CompareCard(
      cardNo: json['cardNo'],
      cardName: json['cardName'],
      cardUrl: json['cardUrl'],
    );
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await API.initBaseUrl();
  runApp(MaterialApp(home: CardListPage(), debugShowCheckedModeBanner: false));
}

class CardListPage extends StatefulWidget {
  @override
  _CardListPageState createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage> {
  late Future<List<CardModel>> _futureCards;
  late Future<List<CardModel>> _futurePopularCards;

  List<CardModel> _searchResults = [];
  List<CompareCard> compareCards = []; // ✅ 비교함 리스트
  List<String> _selectedTags = [];
  String _keyword = '';
  String selectedType = '전체';
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureCards = CardService.fetchCards();
    _futurePopularCards = CardService.fetchPopularCards();
    _loadCompareList();
  }

  Future<void> _loadCompareList() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('compareCards') ?? [];
    setState(() {
      compareCards = data.map((e) => CompareCard.fromJson(jsonDecode(e))).toList();
    });
  }

  // ✅ 비교함 저장
  Future<void> _saveCompareList() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = compareCards.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('compareCards', encoded);
  }
  // ✅ 비교함 담기/제거
  void _toggleCompare(CardModel card) {
    final cardId = card.cardNo.toString();
    final isSelected = compareCards.any((c) => c.cardNo == cardId);

    setState(() {
      if (isSelected) {
        compareCards.removeWhere((c) => c.cardNo == cardId);
        print('❌ 제거됨: $cardId');
      } else {
        if (compareCards.length >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('최대 2개까지만 비교할 수 있습니다.')),
          );
          return;
        }
        compareCards.add(CompareCard.fromCardModel(card));
        print('✅ 담김: $cardId');
      }
    });

    _saveCompareList();
  }

  // ✅ 포함 여부 체크
  bool _isInCompare(CardModel card) {
    return compareCards.any((c) => c.cardNo == card.cardNo.toString());
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final url = API.searchCards(_keyword, selectedType, _selectedTags);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _searchResults = data.map((e) => CardModel.fromJson(e)).toList();
        });
      } else {
        throw Exception('검색 실패');
      }
    } catch (e) {
      print("검색 실패: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 20,
      ),
      body: SafeArea(
        child: FutureBuilder<List<CardModel>>(
          future: _futureCards,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('카드가 없습니다.'));
            }

            final allCards = snapshot.data!;
            final displayCards = (_keyword.isNotEmpty || _selectedTags.isNotEmpty)
                ? _searchResults
                : (selectedType == '전체'
                ? allCards
                : allCards.where((card) {
              final type = card.cardType?.toLowerCase().replaceAll('카드', '').trim();
              return type == selectedType.toLowerCase();
            }).toList());

            final screenHeight = MediaQuery.of(context).size.height;

            final imageHeight = screenHeight * 0.19;

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 120), // ✅ 오버플로우 방지 하단 여백 추가
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FutureBuilder<List<CardModel>>(
                      future: _futurePopularCards,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('인기카드 이미지가 없습니다.'),
                          );
                        }

                        final popularCards = snapshot.data!;
                        return Container(
                          color: Colors.white,
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 280,
                              autoPlay: true,
                              enlargeCenterPage: true,
                              viewportFraction: 0.9,
                            ),
                            items: popularCards.map((card) {
                              final imageUrl = card.popularImgUrl ?? card.cardUrl;
                              final proxyUrl = '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(imageUrl)}';

                              return Stack(
                                children: [
                                  // 카드 이미지
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      proxyUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),

                                  // 텍스트 오버레이
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            card.cardName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          if (card.cardSlogan != null && card.cardSlogan!.isNotEmpty)
                                            Text(
                                              card.cardSlogan!,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 40), // ✅ 기존 여백 유지

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['전체', '신용', '체크'].map((type) {
                      final isSelected = selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            minimumSize: Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: isSelected ? Color(0xFFB91111) : Colors.white,
                            foregroundColor: isSelected ? Colors.white : Colors.black87,
                            side: isSelected
                                ? BorderSide.none
                                : BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedType = type;
                            });
                          },
                          child: Text(
                            type == '신용' ? '신용카드' : type == '체크' ? '체크카드' : '전체',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                          controller: _searchController,
                          onSubmitted: (value) {
                          setState(() => _keyword = value.trim());
                          _performSearch();
                          },
                          onChanged: (value) {
                          final trimmed = value.trim();
                          if (trimmed.isEmpty) {
                          setState(() {
                          _keyword = '';
                          _searchResults = []; // 검색 결과 초기화
                          });
                          }
                          },
                            decoration: InputDecoration(
                              hintText: '카드이름, 혜택으로 검색',
                              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade400),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black87),
                              ),
                              contentPadding: EdgeInsets.only(bottom: 4),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.search, size: 20, color: Colors.black87),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.tune),
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => TagFilterModal(
                                selectedTags: _selectedTags,
                                onConfirm: (tags) {
                                  setState(() => _selectedTags = tags);
                                  _performSearch();
                                },
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  if (selectedType != '전체')
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, bottom: 6),
                      child: Text(
                        '${selectedType}카드 목록',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        GridView.builder(
                          itemCount: displayCards.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 0,
                            mainAxisSpacing: 30,
                            childAspectRatio: 0.6,
                          ),
                          itemBuilder: (context, index) {
                            final card = displayCards[index];
                            return Column(
                              children: [
                                SizedBox(
                                  height: imageHeight,
                                  child: _buildImageCard(card.cardUrl, rotate: true),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  card.cardName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                CheckboxListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  value: _isInCompare(card),
                                  onChanged: (_) => _toggleCompare(card),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '비교함 담기',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        /// ✅ FloatingActionButton과 겹치지 않도록 충분한 여백
                        SizedBox(height: 140),
                      ],
                    ),
                  ),

                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: () {
        print('🧪 현재 compareCards 길이: ${compareCards.length}');
        return compareCards.isNotEmpty
            ? FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => _buildCompareModal(),
            );
          },
          label: Text("비교함 (${compareCards.length})"),
          icon: Icon(Icons.compare),
          backgroundColor: Colors.red,
        )
            : null;
      }(),
    );
  }


  Widget _buildImageCard(String imageUrl, {bool rotate = false}) {
    final proxyUrl = '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(imageUrl)}';
    final image = Image.network(
      proxyUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.white,
        child: rotate ? Transform.rotate(angle: pi / 2, child: image) : image,
      ),
    );
  }
  Widget _buildCompareModal() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: compareCards.map((c) {
          return ListTile(
            leading: Image.network(c.cardUrl, width: 50),
            title: Text(c.cardName),
            trailing: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  compareCards.removeWhere((x) => x.cardNo == c.cardNo);
                });
                _saveCompareList();
                Navigator.pop(context);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

}

class TagFilterModal extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onConfirm;

  const TagFilterModal({required this.selectedTags, required this.onConfirm});

  @override
  _TagFilterModalState createState() => _TagFilterModalState();
}

class _TagFilterModalState extends State<TagFilterModal> {
  final List<String> allTags = [
    '커피', '편의점', '베이커리', '영화', '쇼핑', '외식',
    '교통', '통신', '교육', '레저', '스포츠', '구독',
    '병원', '약국', '공공요금', '주유', '하이패스',
    '배달앱', '환경', '공유모빌리티', '세무지원', '포인트',
    '캐시백', '놀이공원', '라운지', '발렛'
  ];

  late List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.selectedTags);
  }

  void toggleTag(String tag) {
    setState(() {
      if (selected.contains(tag)) {
        selected.remove(tag);
      } else {
        if (selected.length < 5) {
          selected.add(tag);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('최대 5개까지 선택 가능합니다.')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery
            .of(context)
            .viewInsets
            .bottom + 40, // ✅ 여유 여백 추가
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ wrap content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('원하는 혜택을 골라보세요 (최대 5개)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allTags.map((tag) {
                final isSelected = selected.contains(tag);
                return GestureDetector(
                  onTap: () => toggleTag(tag),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xfffdeeee) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.red : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: isSelected ? Colors.red : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(selected);
                  Navigator.pop(context);
                },
                child: Text('적용'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB91111),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

