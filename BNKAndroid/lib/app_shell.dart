// lib/app_shell.dart
import 'package:flutter/material.dart';

import 'package:bnkandroid/user/CardListPage.dart';
import 'package:bnkandroid/user/LoginPage.dart';

// 커스텀 애니메이티드 하단바 (토스 스타일)
import 'package:bnkandroid/ui/toss_nav_bar.dart';

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
  int _index = 0;

  // ✅ 페이지 전환 애니메이션용 컨트롤러
  late final PageController _pageCtl;

  // 탭별 중첩 Navigator 상태 유지용 키
  final _navKeys = {
    AppTab.cards: GlobalKey<NavigatorState>(),
    AppTab.benefits: GlobalKey<NavigatorState>(),
    AppTab.support: GlobalKey<NavigatorState>(),
    AppTab.my: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    _pageCtl = PageController(initialPage: _index);

    AuthState.loggedIn.addListener(_onAuthChanged);
    InactivityService.instance.attachLifecycle();

    // 빌드 직후: 로그인 상태면 무활동 타이머 시작
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

    // 마이 탭 가드
    if (next == AppTab.my && !AuthState.loggedIn.value) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    // ✅ PageView 애니메이션으로 전환 (방향 감지 자동)
    setState(() => _index = i);
    InactivityService.instance.ping();
    await _pageCtl.animateToPage(
      i,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubicEmphasized, // 부드러운 토스 느낌
    );
  }

  // 각 탭의 루트(중첩 Navigator 유지)
  Widget _buildTabRoot(AppTab tab) {
    switch (tab) {
      case AppTab.cards:
        return const _KeepAlive(child: CardListPage());
      case AppTab.benefits:
        return const _KeepAlive(child: _Stub(title: '혜택/이벤트'));
      case AppTab.support:
        return const _KeepAlive(child: _Stub(title: '문의/고객센터'));
      case AppTab.my:
        return const _KeepAlive(child: _MyRoot());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = AppTab.values;

    return WillPopScope(
      onWillPop: () async {
        // 현재 탭에서 뒤로 갈 수 있으면 pop, 아니면 첫 탭으로
        final nav = _navKeys[tabs[_index]]!.currentState!;
        if (nav.canPop()) {
          nav.pop();
          InactivityService.instance.ping();
          return false;
        }
        if (_index != 0) {
          // 첫 탭으로 부드럽게 이동
          setState(() => _index = 0);
          await _pageCtl.animateToPage(
            0,
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
          // ✅ PageView로 전환(슬라이드)
          body: PageView(
            controller: _pageCtl,
            physics: const BouncingScrollPhysics(), // iOS 느낌; 원하면 NeverScrollableScrollPhysics()로 스와이프 비활성화
            onPageChanged: (i) {
              // 스와이프로 탭 변경 시에도 상태/바텀바 동기화
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

          // 하단바(토스 스타일) — 인디케이터 애니메이션만 담당
          bottomNavigationBar: TossNavBar(
            index: _index,
            onTap: (i) => _selectTab(i),
            items: const [
              TossNavItem(Icons.credit_card, '카드'),
              TossNavItem(Icons.local_offer_outlined, '혜택'),
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
        return const _Stub(title: '마이페이지(로그인 완료)');
      },
    );
  }
}

/// 임시 스텁 페이지
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
