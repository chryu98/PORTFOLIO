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
  late Future<List<CardModel>> _futurePopularCards;

  @override
  void initState() {
    super.initState();
    _futureCards = CardService.fetchCards();
    _futurePopularCards = CardService.fetchPopularCards(); // 지금은 사용 안 하지만 유지 가능
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

          final cards = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 상단 인기 카드 슬라이더
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Builder(
                    builder: (context) {
                      // ✅ 1. popularImgUrl이 존재하는 카드만 필터링
                      final popularCards = cards
                          .where((card) => card.popularImgUrl != null && card.popularImgUrl!.trim().isNotEmpty)
                          .toList();

                      // ✅ 2. viewCount 기준 내림차순 정렬
                      popularCards.sort((a, b) => b.viewCount.compareTo(a.viewCount));

                      // ✅ 3. 최대 6개만 사용
                      final limitedCards = popularCards.take(6).toList();

                      // ✅ 4. 이미지가 없을 경우 대체 텍스트 출력
                      if (limitedCards.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('인기카드 이미지가 없습니다.'),
                        );
                      }

                      // ✅ 5. Carousel에 적용
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


                SizedBox(height: 24),

                // ✅ 전체 카드 타이틀
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '전체 카드',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(height: 12),

                // ✅ 전체 카드 그리드 리스트
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: cards.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 30,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final card = cards[index];
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

  /// ✅ 카드 이미지 출력 함수 (프록시 + 회전 적용)
  Widget _buildImageCard(String imageUrl, {bool rotate = false}) {
    final proxyUrl =
        '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(imageUrl)}';

    final image = Image.network(
      proxyUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) =>
          Center(child: Icon(Icons.broken_image)),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: rotate ? Transform.rotate(angle: pi / 2, child: image) : image,
    );
  }
}
