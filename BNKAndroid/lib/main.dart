
import 'package:bnkandroid/user/CustomCardEditorPage.dart';
import 'package:bnkandroid/user/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:bnkandroid/constants/api.dart';

import 'app_shell.dart';
import 'auth_state.dart'; // ✅ 푸터 포함 공용 쉘
import 'user/NaverMapPage.dart';
import 'webview/SpringCardEditorPage.dart';
// await NaverMapSdk.instance.initialize(clientId: "your client id");
// await NaverMapSdk.instance.initialize();


void main() async {
  await API.initBaseUrl();                     // baseUrl 먼저 초기화
  await AuthState.init();
  await AuthState.debugDump(); //자동로그인 체킹
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //웹뷰용 url
    const springUrl = 'http://192.168.0.224:8090/editor/card';

    return MaterialApp(
      title: 'BNK Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // ★ 전체 배경/표면 흰색 고정
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xffB91111),
          surface: Colors.white,
          background: Colors.white,
        ),
        // ★ 상단 AppBar 핑크 틴트 제거
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4E4E4E),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        // ★ 바텀시트도 흰색/틴트 제거
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        // ★ BottomAppBar(푸터 컨테이너 대신 BottomAppBar 쓸 때)
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: Colors.black26,
        ),
        // ★ NavigationBar(M3 하단바 쓸 때)
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          indicatorColor: const Color(0xffB91111).withOpacity(0.08),
          labelTextStyle: MaterialStatePropertyAll(
            TextStyle(fontSize: 12, color: const Color(0xFF444444)),
          ),
        ),
      ),
      home: const CustomCardEditorPage(), // ✅ 하단 푸터 고정되는 앱 쉘
    );
  }
}
