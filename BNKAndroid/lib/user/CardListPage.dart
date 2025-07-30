import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:bnkandroid/user/service/CardService.dart';
import 'package:bnkandroid/constants/api.dart';
import 'model/CardModel.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await API.initBaseUrl();
  runApp(MaterialApp(
    home: CardListPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class CardListPage extends StatefulWidget {
  @override
  _CardListPageState createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage> {
  late Future<List<CardModel>> _futureCards;
  String selectedType = '전체';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureCards = CardService.fetchCards();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.19;

    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: FutureBuilder<List<CardModel>>(
        future: _futureCards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('카드가 없습니다.'));
          }

          final allCards = snapshot.data!;

          final filteredCards = selectedType == '전체'
              ? allCards
              : allCards.where((card) {
            final type = card.cardType?.toLowerCase().replaceAll('카드', '').trim();
            return type == selectedType.toLowerCase();
          }).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 인기 카드 슬라이더
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Builder(
                    builder: (context) {
                      final popularCards = allCards
                          .where((card) => card.popularImgUrl != null && card.popularImgUrl!.trim().isNotEmpty)
                          .toList();
                      popularCards.sort((a, b) => b.viewCount.compareTo(a.viewCount));
                      final limitedCards = popularCards.take(6).toList();

                      if (limitedCards.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('인기카드 이미지가 없습니다.'),
                        );
                      }

                      return CarouselSlider(
                        options: CarouselOptions(
                          height: 200,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                        ),
                        items: limitedCards.map((card) {
                          final imageUrl = card.popularImgUrl ?? card.cardUrl;
                          return _buildImageCard(imageUrl, rotate: false);
                        }).toList(),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // 🔘 필터 버튼 (작게!)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['전체', '신용', '체크'].map((type) {
                    final isSelected = selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 6),
                          minimumSize: Size(0, 30), // 최소 크기 ↓↓↓
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
                          style: TextStyle(fontSize: 12), // 더 작게
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 12),

                // 🔍 검색창 (underline + 아이콘)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          readOnly: true,
                          onTap: () {
                            // 상세 검색 연결
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
                      Icon(Icons.tune, size: 20, color: Colors.black54),
                    ],
                  ),
                ),

                SizedBox(height: 14),

                if (selectedType != '전체')
                  Padding(
                    padding: const EdgeInsets.only(left: 14.0, bottom: 6),
                    child: Text(
                      '${selectedType}카드 목록',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),

                // 카드 그리드 출력
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: filteredCards.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 30,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final card = filteredCards[index];
                      return Column(
                        children: [
                          SizedBox(
                            height: imageHeight,
                            child: _buildImageCard(card.cardUrl, rotate: true),
                          ),
                          SizedBox(height: 3),
                          Text(
                            card.cardName,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
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
      child: rotate ? Transform.rotate(angle: pi / 2, child: image) : image,
    );
  }
}
