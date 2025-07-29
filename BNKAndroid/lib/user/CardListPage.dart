import 'package:bnkandroid/user/service/CardService.dart';
import 'package:flutter/material.dart';


import 'dart:convert';

import 'model/CardModel.dart';


void main() {
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

              // ✅ 프록시 URL 생성 (Spring 서버가 대신 이미지 요청)
              final proxyUrl = 'http://192.168.100.106:8090/proxy/image?url=${Uri.encodeComponent(card.cardUrl)}';


              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.network(
                      proxyUrl,
                      errorBuilder: (context, error, stackTrace) {
                        print('에러: $error');
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
