import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bnkandroid/user/CardListPage.dart';
import 'package:bnkandroid/user/LoginPage.dart';

// 커스텀 애니메이티드 하단바
import 'package:bnkandroid/ui/animated_nav_bar.dart';

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

  final _navKeys = {
    AppTab.cards: GlobalKey<NavigatorState>(),
    AppTab.benefits: GlobalKey<NavigatorState>(),
    AppTab.support: GlobalKey<NavigatorState>(),
    AppTab.my: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    AuthState.loggedIn.addListener(_onAuthChanged);
    InactivityService.instance.attachLifecycle();

    // 빌드 완료 후 로그인 상태면 타이머 시작
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
    InactivityService.instance.stop();
    InactivityService.instance.detachLifecycle();
    AuthState.loggedIn.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _selectTab(int i) async {
    final next = AppTab.values[i];
    if (next == AppTab.my && !AuthState.loggedIn.value) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    setState(() => _index = i);
  }

  Widget _buildTabRoot(AppTab tab) {
    switch (tab) {
      case AppTab.cards:
        return _KeepAlive(child: CardListPage());
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
        final nav = _navKeys[tabs[_index]]!.currentState!;
        if (nav.canPop()) {
          nav.pop();
          InactivityService.instance.ping();
          return false;
        }
        return true;
      },
      child: _ActivityCapture(
        onActivity: InactivityService.instance.ping,
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
          bottomNavigationBar: AnimatedAttachNavBar(
            index: _index,
            onTap: (i) {
              InactivityService.instance.ping();
              _selectTab(i);
            },
            items: const [
              AttachNavItem(Icons.credit_card, '카드'),
              AttachNavItem(Icons.local_offer_outlined, '혜택'),
              AttachNavItem(Icons.headset_mic_outlined, '문의'),
              AttachNavItem(Icons.person_outline, '마이'),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> pushFullScreen<T>(BuildContext context, Widget page) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(builder: (_) => page),
  );
}

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

/// 마이 탭
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

/// 임시 페이지
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
