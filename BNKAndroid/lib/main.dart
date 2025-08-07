import 'package:bnkandroid/user/LoginPage.dart';
import 'package:flutter/material.dart';
import 'user/CardListPage.dart';
import 'package:bnkandroid/constants/api.dart';
import 'user/NaverMapPage.dart';

// await NaverMapSdk.instance.initialize(clientId: "your client id");
// await NaverMapSdk.instance.initialize();

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


      home: NaverMapPage(),


    );
  }
}
