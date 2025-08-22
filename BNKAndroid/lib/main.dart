import 'package:flutter/material.dart';
import 'package:bnkandroid/constants/api.dart';
import 'SignPage.dart';
import 'app_shell.dart';
import 'auth_state.dart';
import 'package:bnkandroid/constants/faq_api.dart';
import 'package:bnkandroid/constants/chat_api.dart';
import 'package:bnkandroid/user/CustomCardEditorPage.dart';
import 'package:bnkandroid/user/MainPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await API.initBaseUrl();
    FAQApi.useLan(ip: '192.168.0.5', port: 8090);
    FAQApi.setPathPrefix('/api');
    ChatAPI.useFastAPI(ip: '192.168.0.5', port: 8000);
  } catch (e, _) {
    debugPrint('[API] init 실패: $e');
  }
  try {
    await AuthState.init();
    await AuthState.debugDump();
  } catch (e, _) {
    debugPrint('[AuthState] 초기화 실패: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BNK Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xffB91111),
          surface: Colors.white,
          background: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4E4E4E),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: Colors.black26,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          indicatorColor: const Color(0xffB91111).withOpacity(0.08),
          labelTextStyle: const MaterialStatePropertyAll(
            TextStyle(fontSize: 12, color: Color(0xFF444444)),
          ),
        ),
      ),

      // 앱이 처음 뜰 때 보여줄 화면
      home: const AppShell(),

      // ✅ 메인으로 점프하기 위한 네임드 라우트 등록
      routes: {
        '/home': (_) => const AppShell(),
      },

      // ✅ /sign 라우트 핸들링(기존 그대로)
      onGenerateRoute: (settings) {
        if (settings.name == '/sign') {
          final args = settings.arguments as Map<String, dynamic>?;
          final appNo = (args?['applicationNo'] as int?) ?? 0;
          return MaterialPageRoute(
            builder: (_) => SignPage(applicationNo: appNo),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
