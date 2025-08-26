import 'package:flutter/material.dart';
import 'package:bnkandroid/constants/api.dart';
import 'SignPage.dart';
import 'app_shell.dart';
import 'auth_state.dart';
import 'package:bnkandroid/constants/faq_api.dart';
import 'package:bnkandroid/constants/chat_api.dart';
import 'package:bnkandroid/user/CustomCardEditorPage.dart';
import 'package:bnkandroid/user/MainPage.dart';

// ★ 추가
import 'splash/splash_page.dart';

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

      // ★ 스플래시 게이트: 스플래시를 모달로 띄운 뒤 AppShell로 전환
      home: const _Bootstrapper(),

      routes: {
        '/home': (_) => const AppShell(),
      },

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

// ★ 스플래시를 띄운 뒤 AppShell을 보여주는 작은 게이트 위젯
class _Bootstrapper extends StatefulWidget {
  const _Bootstrapper({super.key});
  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  bool _ready = false;

  Future<void> _dummyInit() async {
    // main()에서 이미 초기화 끝났다면 비워둬도 됨.
    // 추가로 필요한 초기 비동기 작업이 있으면 여기에 작성.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 스플래시를 반투명 모달로 띄운 후 닫히면 홈 전환
      await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => SplashPage(onReady: _dummyInit),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ));
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? const AppShell() : const SizedBox.shrink();
  }
}
