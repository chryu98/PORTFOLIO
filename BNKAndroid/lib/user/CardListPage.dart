import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:bnkandroid/user/service/CardService.dart';
import 'package:bnkandroid/constants/api.dart';
import 'model/CardModel.dart';

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

  @override
  void initState() {
    super.initState();
    _futureCards = CardService.fetchCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('카드')),
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
                // ✅ 상단 슬라이더
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                    ),
                    items: cards.take(5).map((card) {
                      return _buildImageCard(card.cardUrl);
                    }).toList(),
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

                // ✅ 카드 목록 (그리드)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: cards.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Column(
                        children: [
                          Expanded(child: _buildImageCard(card.cardUrl)),
                          SizedBox(height: 4),
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

                SizedBox(height: 30), // 하단 여백
              ],
            ),
          );
        },
      ),
    );
  }

  /// 이미지 로딩 위젯 (슬라이더 및 리스트에서 공통 사용)
  Widget _buildImageCard(String imageUrl) {
    final proxyUrl =
        '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(imageUrl)}';

    return ClipRRect(
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
    );
  }
}
