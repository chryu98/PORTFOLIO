// lib/faq/faq.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← FAB 위치 저장
import 'service/FaqService.dart';
import 'model/FaqModel.dart';
import '../constants/faq_api.dart';
import '../constants/chat_api.dart';
import '../user/cardListPage.dart';
import '../chat/widgets/chatbot_modal.dart';
import '../constants/api.dart';  // 카드 API
import '../feedback/feedback_sheet.dart';

// ===== FEEDBACK INJECT START =====
const bool kFeedbackOnFaqEnabled = true;   // <- 나중에 false로 끄면 끝
const int  kFeedbackFaqCardNo    = 999000; // FAQ용 더미 카드번호(백엔드 NOT NULL 회피)
// ===== FEEDBACK INJECT END =====

// ===== BACK NAV OPTION =====
const bool kBackFallbackToCardList = false; // 최상단에서만 CardList로 보낼지 여부

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  // ── BNK 부산은행 톤
  static const _bnkRed = Color(0xFFD6001C);
  static const _bnkRedDark = Color(0xFFA80016);
  static const _ink = Color(0xFF1C1C1F);
  static const _muted = Color(0xFF6C727F);
  static const _bg = Color(0xFFF5F6F8);
  static const _card = Colors.white;
  static const _line = Color(0xFFE9EDF3);
  static const int _pageSize = 20;

  // FEEDBACK
  bool _feedbackShownOnce = false;

  final _scroll = ScrollController();
  final _queryCtrl = TextEditingController();

  final List<String> _cats = const ['전체', '카드'];
  String _selectedCat = '전체';

  List<FaqModel> _items = [];
  int _page = 0;
  bool _last = false;
  bool _loading = false;
  String _err = '';

  Timer? _debounce;

  // Tip Bubble
  Timer? _tipTicker;
  bool _showTip = false;
  static const _tipInterval = Duration(seconds: 5);
  static const _tipVisibleFor = Duration(milliseconds: 2500);

  // ── Draggable Chat FAB 상태
  static const double _fabSize = 56;
  static const double _edgeMargin = 8;
  static const String _prefChatX = 'faq_chat_x';
  static const String _prefChatY = 'faq_chat_y';

  Offset? _chatPos;                 // FAB 현재 위치 (Stack 기준)
  Offset _chatPosStart = Offset.zero;
  bool _dragging = false;

  Future<void> _loadChatPos() async {
    final sp = await SharedPreferences.getInstance();
    final x = sp.getDouble(_prefChatX);
    final y = sp.getDouble(_prefChatY);
    if (x != null && y != null) {
      setState(() => _chatPos = Offset(x, y));
    }
  }

  Future<void> _saveChatPos() async {
    if (_chatPos == null) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_prefChatX, _chatPos!.dx);
    await sp.setDouble(_prefChatY, _chatPos!.dy);
  }

  Offset _clampChatPos(Offset p, Size screen) {
    final maxX = screen.width  - _fabSize - _edgeMargin;
    final maxY = screen.height - _fabSize - _edgeMargin;
    return Offset(
      p.dx.clamp(_edgeMargin, maxX),
      p.dy.clamp(_edgeMargin, maxY),
    );
  }

  @override
  void initState() {
    super.initState();
    _goTo(0);
    _startTipTicker();
    _loadChatPos(); // ← FAB 저장된 위치 복구

    // ===== FEEDBACK INJECT START =====
    if (kFeedbackOnFaqEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _feedbackShownOnce) return;
        _feedbackShownOnce = true;
        showFeedbackSheet(
          context,
          cardNo: kFeedbackFaqCardNo,
          userNo: null,
        );
      });
    }
    // ===== FEEDBACK INJECT END =====
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tipTicker?.cancel();
    _scroll.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _startTipTicker() {
    _tipTicker?.cancel();
    _tipTicker = Timer.periodic(_tipInterval, (_) {
      if (!mounted) return;
      setState(() => _showTip = true);
      Future.delayed(_tipVisibleFor, () {
        if (mounted) setState(() => _showTip = false);
      });
    });
  }

  String _effectiveQuery() {
    final base = _queryCtrl.text.trim();
    if (_selectedCat == '카드') {
      return base.isEmpty ? '카드' : (base.contains('카드') ? base : '카드 $base');
    }
    return base;
  }

  Future<void> _goTo(int page) async {
    if (page < 0) return;
    setState(() { _loading = true; _err = ''; });
    try {
      final r = await FaqService.fetch(page: page, size: _pageSize, query: _effectiveQuery());
      setState(() {
        _items = r.content;
        _last = r.last;
        _page = page;
      });
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() async => _goTo(0);

  // 뒤로가기 처리 공통 함수(현재는 사용 안 하지만 필요시 호출)
  Future<void> _handleBackPressed() async {
    final didPop = await Navigator.of(context).maybePop();
    if (!didPop && kBackFallbackToCardList) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CardListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          return true; // 기본 동작(이전 화면으로)
        }
        if (kBackFallbackToCardList) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CardListPage()),
          );
          return false;
        }
        return true; // 최상단이면 앱/셸 기본 동작(종료/탭 복귀 등)
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          automaticallyImplyLeading: false, // ← 왼쪽 위 뒤로가기 제거
          title: const Text(
            '고객센터',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.9, -1.0),
                end: Alignment(0.9, 1.0),
                colors: [_bnkRed, _bnkRedDark],
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic_outlined, color: _bnkRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '자주 묻는 질문과 챗봇을 통해 빠르게 해결하세요.',
                      style: TextStyle(color: _muted, fontSize: 13, height: 1.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        body: Stack(
          clipBehavior: Clip.none,
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              color: _bnkRed,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _searchAndCategory()),
                  if (_err.isNotEmpty) SliverToBoxAdapter(child: _errorCard()),
                  if (_items.isEmpty && _err.isEmpty && !_loading)
                    SliverToBoxAdapter(child: _emptyCard()),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => _faqTile(_items[i]),
                      childCount: _items.length,
                    ),
                  ),
                  SliverToBoxAdapter(child: _pager()),
                ],
              ),
            ),

            // ── 길게 눌러 이동 가능한 챗봇 FAB + Tip
            Builder(
              builder: (context) {
                // 초기 기본 위치(우상단 12px)
                final defaultPos = Offset(screen.width - _fabSize - 12, 12);
                final pos = _chatPos ?? defaultPos;

                return Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: GestureDetector(
                    onLongPressStart: (_) {
                      setState(() {
                        _dragging = true;
                        _chatPosStart = pos;
                      });
                    },
                    onLongPressMoveUpdate: (d) {
                      final next = _clampChatPos(_chatPosStart + d.offsetFromOrigin, screen);
                      setState(() => _chatPos = next);
                    },
                    onLongPressEnd: (_) async {
                      setState(() => _dragging = false);
                      await _saveChatPos();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                          offset: (_showTip && !_dragging) ? Offset.zero : const Offset(0.05, 0),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: (_showTip && !_dragging) ? 1 : 0,
                            child: _TipBubble(
                              text: '길게 눌러 이동할 수 있어요',
                              bg: Colors.white,
                              fg: _ink,
                              border: Colors.black12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ChatFab(
                          compact: true,
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) => ChatbotModal(hostContext: context),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── UI Blocks ─────────────────

  Widget _searchAndCategory() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 검색 상자
        Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: _muted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () => _goTo(0));
                  },
                  onSubmitted: (_) {
                    _debounce?.cancel();
                    FocusScope.of(context).unfocus();
                    _goTo(0);
                  },
                  decoration: const InputDecoration(
                    hintText: '검색어를 입력하세요',
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_queryCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: _muted),
                  onPressed: () {
                    _queryCtrl.clear();
                    _goTo(0);
                    setState(() {}); // clear 아이콘 즉시 갱신
                  },
                  tooltip: '지우기',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 카테고리
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['전체', '카드'].map((c) {
              final selected = _selectedCat == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    c,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _ink,
                    ),
                  ),
                  selected: selected,
                  backgroundColor: Colors.white,
                  selectedColor: _bnkRed,
                  side: BorderSide(color: selected ? _bnkRed : _line, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _selectedCat = c);
                    _goTo(0);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    ),
  );

  Widget _errorCard() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE4E6)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: _bnkRed),
        const SizedBox(width: 8),
        Expanded(child: Text(_err, style: TextStyle(color: _ink))),
        TextButton(
          onPressed: () => _goTo(_page),
          style: TextButton.styleFrom(
            foregroundColor: _bnkRed,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Text('다시 시도'),
        ),
      ]),
    ),
  );

  Widget _emptyCard() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(children: const [
        Icon(Icons.help_outline, size: 40, color: Colors.grey),
        SizedBox(height: 12),
        Text('검색 결과가 없습니다.', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('카테고리/키워드를 바꿔 다시 시도해 주세요.', style: TextStyle(color: Colors.grey)),
      ]),
    ),
  );

  Widget _faqTile(FaqModel m) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: _catStripe(m.category),
            title: Text(
              m.faqQuestion,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: 0.1,
              ),
            ),
            subtitle: (m.regDate != null)
                ? Text('업데이트 ${_fmt(m.regDate!)}', style: const TextStyle(color: _muted, fontSize: 12))
                : null,
            trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
            iconColor: _bnkRed,
            collapsedIconColor: _muted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: _card,
            collapsedBackgroundColor: _card,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: SelectableText(
                  m.faqAnswer,
                  style: const TextStyle(height: 1.56, fontSize: 15, color: _ink),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catStripe(String cat) {
    final Color stripe = switch (cat) {
      '카드' => _bnkRed,
      _ => const Color(0xFF2F6BFF),
    };
    return Container(
      width: 8,
      height: 28,
      decoration: BoxDecoration(
        color: stripe.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _pager() {
    final start = _page * _pageSize + (_items.isEmpty ? 0 : 1);
    final end = _page * _pageSize + _items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            _pillButton(icon: Icons.chevron_left, label: '이전 20개', enabled: !_loading && _page > 0, onTap: () => _goTo(_page - 1)),
            const Spacer(),
            Text(
              (_items.isEmpty && !_loading) ? '항목 없음' : '항목 $start–$end',
              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
            ),
            const Spacer(),
            _pillButton(icon: Icons.chevron_right, label: '다음 20개', primary: true, enabled: !_loading && !_last, onTap: () => _goTo(_page + 1)),
          ],
        ),
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final bg = primary ? _bnkRed : _card;
    final fg = primary ? Colors.white : _ink;
    final side = primary ? BorderSide.none : const BorderSide(color: _line);
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: side,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          elevation: 0,
          disabledForegroundColor: _muted.withOpacity(0.5),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

/// ─────────────────────────────────────────────────────────────────
/// BNK 톤 챗봇 FAB (상단 고정 원형)
class _ChatFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;
  const _ChatFab({required this.onTap, this.compact = true});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Semantics(
        button: true,
        label: '챗봇 열기',
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_FaqPageState._bnkRed, _FaqPageState._bnkRedDark],
              ),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withOpacity(0.14),
              highlightColor: Colors.white10,
              child: const Center(
                child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      );
    }

    // 필요 시 하단 배치
    return Semantics(
      button: true,
      label: '챗봇 열기',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_FaqPageState._bnkRed, _FaqPageState._bnkRedDark],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            splashColor: Colors.white12,
            highlightColor: Colors.white.withOpacity(0.06),
            child: const Padding(
              padding: EdgeInsets.only(left: 8, right: 14, top: 6, bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconCap(),
                  SizedBox(width: 10),
                  Text(
                    '챗봇',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCap extends StatelessWidget {
  const _IconCap();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.smart_toy_outlined, color: _FaqPageState._bnkRed, size: 24),
    );
  }
}

/// 말풍선 UI (오른쪽 아래 꼬리)
class _TipBubble extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final Color border;
  const _TipBubble({
    required this.text,
    required this.bg,
    required this.fg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Text(
            text,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ),
        Positioned(
          right: 10,
          bottom: -6,
          child: Transform.rotate(
            angle: 0.785398, // 45도
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: bg,
                border: Border(
                  right: BorderSide(color: border),
                  bottom: BorderSide(color: border),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
