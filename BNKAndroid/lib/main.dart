import 'package:flutter/material.dart';
import 'user/CardListPage.dart';
import 'package:bnkandroid/constants/api.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // 필수
  await API.initBaseUrl();                   // baseUrl 먼저 초기화!
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: CardListPage(),
    );
  }
}
