import 'package:flutter/material.dart';
import 'package:bnkandroid/user/service/CardService.dart';
import 'package:bnkandroid/constants/api.dart'; // ✅ API 경로 확인 필요
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
    _futureCards = CardService.fetchCards(); // 카드 리스트 API 호출
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('카드 목록')),
      body: FutureBuilder<List<CardModel>>(
        future: _futureCards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('에러: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('카드가 없습니다.'));

          final cards = snapshot.data!;
          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];

              // ✅ Spring 서버에서 프록시 호출 (baseUrl 사용)
              final proxyUrl =
                  '${API.baseUrl}/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.network(
                      proxyUrl,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image);
                      },
                    ),
                  ),
                  title: Text(card.cardName),
                  subtitle: Text(card.cardSlogan ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
