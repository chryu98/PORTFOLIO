// lib/main.dart
import 'package:flutter/material.dart';
import 'package:bnkandroid/constants/api.dart';
import 'app_shell.dart';          // ✅ 푸터 포함 공용 쉘
import 'ui/bnk_theme.dart';       // ✅ 토스/카뱅 느낌의 커스텀 테마

void main() async {
  WidgetsFlutterBinding.ensureInitialized();   // 필수
  await API.initBaseUrl();                     // baseUrl 먼저 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BNK Card',
      debugShowCheckedModeBanner: false,
      theme: BNKTheme.light,                  // ✅ 커스텀 테마 적용
      home: const AppShell(),                 // ✅ 하단 푸터 고정되는 앱 쉘
    );
  }
}
