import 'package:bnkandroid/user/CardListPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 이미 있는 페이지들 import
import 'package:bnkandroid/user/LoginPage.dart';

// 아래 두 개는 실제 페이지로 교체하세요
// import 'package:bnkandroid/benefits/BenefitsPage.dart';
// import 'package:bnkandroid/support/SupportPage.dart';

const kPrimaryRed = Color(0xffB91111);

enum AppTab { cards, benefits, support, my }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // 탭별 네비게이터(중첩) 상태 유지용 키
  final _navKeys = {
    AppTab.cards: GlobalKey<NavigatorState>(),
    AppTab.benefits: GlobalKey<NavigatorState>(),
    AppTab.support: GlobalKey<NavigatorState>(),
    AppTab.my: GlobalKey<NavigatorState>(),
  };

  // 로그인 여부 확인
  Future<bool> _isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('jwt') ?? p.getString('jwt_token');
    return t != null && t.isNotEmpty;
  }

  // 마이 탭 탭-가드
  Future<void> _selectTab(int i) async {
    final next = AppTab.values[i];
    if (next == AppTab.my && !await _isLoggedIn()) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            redirectBuilder: (_) => const AppShell(), // 로그인 완료 후 다시 AppShell(마이 탭 유지)
          ),
        ),
      );
      setState(() {}); // 로그인 상태 갱신
      return;
    }
    setState(() => _index = i);
  }

  // 각 탭의 루트 위젯
  Widget _buildTabRoot(AppTab tab) {
    switch (tab) {
      case AppTab.cards:
        return _KeepAlive(child: CardListPage()); //카드리스트
      case AppTab.benefits:
        return const _KeepAlive(child: _Stub(title: '혜택/이벤트')); // TODO: BenefitsPage로 교체
      case AppTab.support:
        return const _KeepAlive(child: _Stub(title: '문의/고객센터')); // TODO: SupportPage로 교체
      case AppTab.my:
        return const _KeepAlive(child: _MyRoot()); // 로그인 상태에 따라 내용 표시
    }
  }

  BottomNavigationBarItem _item(
      {required IconData icon, required String label}) {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = AppTab.values;

    return WillPopScope(
      onWillPop: () async {
        // 현재 탭에서 뒤로 갈 수 있으면 pop, 아니면 앱 종료 허용
        final nav = _navKeys[tabs[_index]]!.currentState!;
        if (nav.canPop()) {
          nav.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: tabs
              .map((t) => Navigator(
            key: _navKeys[t],
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (_) => _buildTabRoot(t),
              settings: settings,
            ),
          ))
              .toList(),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _index,
            onTap: _selectTab,
            selectedItemColor: kPrimaryRed,
            unselectedItemColor: const Color(0xFF98A2B3),
            showUnselectedLabels: true,
            items: [
              _item(icon: Icons.credit_card, label: '카드'),
              _item(icon: Icons.local_offer_outlined, label: '혜택'),
              _item(icon: Icons.headset_mic_outlined, label: '문의'),
              _item(icon: Icons.person_outline, label: '마이'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 발급 플로우 같은 "전체 화면"은 이렇게 열면 하단 푸터가 보이지 않음.
/// Navigator.of(context, rootNavigator: true).push(...)
Future<T?> pushFullScreen<T>(BuildContext context, Widget page) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(builder: (_) => page),
  );
}

/// 탭 루트에서 스크롤/상태 유지
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child, Key? key}) : super(key: key);

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// 마이 탭: 로그인 전/후 분기 (필요시 실제 페이지로 교체)
class _MyRoot extends StatefulWidget {
  const _MyRoot();

  @override
  State<_MyRoot> createState() => _MyRootState();
}

class _MyRootState extends State<_MyRoot> {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final t = p.getString('jwt') ?? p.getString('jwt_token');
      if (mounted) setState(() => _loggedIn = t != null && t.isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('로그인이 필요합니다'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      redirectBuilder: (_) => const AppShell(),
                    ),
                  ),
                );
                if (!mounted) return;
                setState(() {}); // 로그인 상태 갱신
              },
              child: const Text('로그인하기'),
            ),
          ],
        ),
      );
    }
    // TODO: 로그인 후 실제 마이페이지 위젯으로 교체
    return const _Stub(title: '마이페이지(로그인 완료)');
  }
}

/// 임시 스텁 페이지 (실제 페이지로 교체)
class _Stub extends StatelessWidget {
  final String title;
  const _Stub({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: Text(title), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Center(child: Text(title)),
      backgroundColor: Colors.white,
    );
  }
}
