// lib/app_shell.dart
import 'package:flutter/material.dart';

import 'package:bnkandroid/user/CardListPage.dart';
import 'package:bnkandroid/user/MainPage.dart';
import 'package:bnkandroid/user/LoginPage.dart';
import 'package:bnkandroid/faq/faq.dart';
import 'package:bnkandroid/ui/toss_nav_bar.dart';
import 'package:bnkandroid/user/MyPage.dart';

import 'auth_state.dart';
import 'idle/inactivity_service.dart';

const kPrimaryRed = Color(0xffB91111);

enum AppTab { cards, benefits, support, my }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // ✅ 앱 시작 시 "메인" 탭이 첫 화면이 되도록 (cards = 메인)
  int _index = AppTab.cards.index;

  // 페이지 전환 애니메이션용 컨트롤러
  late final PageController _pageCtl;

  // 탭별 중첩 Navigator 상태 유지용 키
  final _navKeys = {
    AppTab.cards: GlobalKey<NavigatorState>(),
    AppTab.benefits: GlobalKey<NavigatorState>(),
    AppTab.support: GlobalKey<NavigatorState>(),
    AppTab.my: GlobalKey<NavigatorState>(),
  };

  // ✅ 뒤로가기 시 돌아갈 홈 탭 역시 "메인"
  final int _homeIndex = AppTab.cards.index;

  @override
  void initState() {
    super.initState();
    _pageCtl = PageController(initialPage: _index);

    AuthState.loggedIn.addListener(_onAuthChanged);
    InactivityService.instance.attachLifecycle();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AuthState.loggedIn.value) {
        InactivityService.instance.start(context);
      }
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (AuthState.loggedIn.value) {
      InactivityService.instance.start(context);
    } else {
      InactivityService.instance.stop();
    }
    setState(() {}); // UI 갱신
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    InactivityService.instance.stop();
    InactivityService.instance.detachLifecycle();
    AuthState.loggedIn.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _selectTab(int i) async {
    final next = AppTab.values[i];

    // 마이 탭 접근 가드
    if (next == AppTab.my && !AuthState.loggedIn.value) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    setState(() => _index = i);
    InactivityService.instance.ping();
    await _pageCtl.animateToPage(
      i,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  // 각 탭의 루트(중첩 Navigator 유지)
  Widget _buildTabRoot(AppTab tab) {
    switch (tab) {
      case AppTab.cards:
        return const _KeepAlive(child: CardMainPage()); // 메인
      case AppTab.benefits:
        return const _KeepAlive(child: CardListPage()); // 카드
      case AppTab.support:
        return const _KeepAlive(child: FaqPage());
      case AppTab.my:
        return const _KeepAlive(child: _MyRoot());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = AppTab.values;

    return WillPopScope(
      onWillPop: () async {
        // 현재 탭에서 뒤로 갈 수 있으면 pop, 아니면 홈(메인) 탭으로
        final nav = _navKeys[tabs[_index]]!.currentState!;
        if (nav.canPop()) {
          nav.pop();
          InactivityService.instance.ping();
          return false;
        }
        if (_index != _homeIndex) {
          setState(() => _index = _homeIndex);
          await _pageCtl.animateToPage(
            _homeIndex,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubicEmphasized,
          );
          return false;
        }
        return true; // 앱 종료
      },
      child: _ActivityCapture(
        onActivity: InactivityService.instance.ping,
        child: Scaffold(
          body: PageView(
            controller: _pageCtl,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) {
              setState(() => _index = i);
              InactivityService.instance.ping();
            },
            children: tabs
                .map(
                  (t) => _KeepAlive(
                child: Navigator(
                  key: _navKeys[t],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (_) => _buildTabRoot(t),
                    settings: settings,
                  ),
                ),
              ),
            )
                .toList(),
          ),
          bottomNavigationBar: TossNavBar(
            index: _index,
            onTap: (i) => _selectTab(i),
            items: const [
              TossNavItem(Icons.local_offer_outlined, '메인'),  // index 0 -> 메인
              TossNavItem(Icons.credit_card, '카드'),
              TossNavItem(Icons.headset_mic_outlined, '문의'),
              TossNavItem(Icons.person_outline, '마이'),
            ],
          ),
        ),
      ),
    );
  }
}

// 전체 화면 푸시 헬퍼(루트 네비게이터)
Future<T?> pushFullScreen<T>(BuildContext context, Widget page) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(builder: (_) => page),
  );
}

// 탭 루트에서 스크롤/상태 유지
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

/// 마이 탭: 로그인 전/후 분기
class _MyRoot extends StatelessWidget {
  const _MyRoot();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.loggedIn,
      builder: (_, loggedIn, __) {
        if (!loggedIn) {
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
                  },
                  child: const Text('로그인하기'),
                ),
              ],
            ),
          );
        }
        return const MyPage();
      },
    );
  }
}

/// 임시 스텁 페이지 (미사용)
class _Stub extends StatelessWidget {
  final String title;
  const _Stub({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black),
      body: Center(child: Text(title)),
      backgroundColor: Colors.white,
    );
  }
}

/// 화면 전역의 탭/스크롤/포인터 입력 → ping
class _ActivityCapture extends StatelessWidget {
  final Widget child;
  final VoidCallback onActivity;

  const _ActivityCapture({required this.child, required this.onActivity});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        onActivity();
        return false;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => onActivity(),
        onPointerMove: (_) => onActivity(),
        onPointerSignal: (_) => onActivity(),
        child: child,
      ),
    );
  }
}
