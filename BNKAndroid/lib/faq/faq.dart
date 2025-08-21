// lib/faq/faq.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'service/FaqService.dart';
import 'model/FaqModel.dart';
import '../constants/faq_api.dart';
import '../constants/chat_api.dart';
import '../user/cardListPage.dart';
import '../chat/widgets/chatbot_modal.dart';
import '../constants/api.dart';  // 카드 API

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  // ── BNK 부산은행 톤
  static const _bnkRed = Color(0xFFD6001C);      // BNK 레드 (브랜드 메인)
  static const _bnkRedDark = Color(0xFFA80016);  // 딥 레드 (그라데이션 하단)
  static const _ink = Color(0xFF222222);
  static const _bg = Color(0xFFF5F6F8);
  static const int _pageSize = 20;

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

  // ── Tip Bubble(“궁금한 점…”)
  Timer? _tipTicker;
  bool _showTip = false;
  static const _tipInterval = Duration(seconds: 5);
  static const _tipVisibleFor = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _goTo(0);
    _startTipTicker();
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

  @override
  Widget build(BuildContext context) {
    // 상단 AppBar를 피해서 챗봇 버튼을 띄우기 위한 안전 오프셋
    final safeTop = MediaQuery.of(context).padding.top;
    final chatTopOffset = safeTop + kToolbarHeight + 8; // AppBar 아래 살짝 띄움

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CardListPage()));
        return false;
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text(
            'FAQ',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: _ink,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CardListPage()));
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.black.withOpacity(0.06)),
          ),
        ),

        // FAB를 상단-우측에 "화면 위로" 띄우기 위해 Stack 오버레이 사용
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
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

            // 오른쪽 위로 띄운 챗봇 FAB + Tip 말풍선
            Positioned(
              top: chatTopOffset,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Tip 말풍선 (5초마다 2.5초 표시)
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    offset: _showTip ? Offset.zero : const Offset(0.05, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _showTip ? 1 : 0,
                      child: _TipBubble(
                        text: '궁금한 점이 있으시면 눌러주세요',
                        bg: Colors.white,
                        fg: _ink,
                        border: Colors.black.withOpacity(0.12),
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
                        builder: (_) => const ChatbotModal(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchAndCategory() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
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
          decoration: InputDecoration(
            hintText: '검색어를 입력하세요',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: _bnkRed, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['전체', '카드'].map((c) {
            final selected = _selectedCat == c;
            return ChoiceChip(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: selected ? _bnkRed : Colors.black.withOpacity(0.12)),
              ),
              onSelected: (v) {
                if (!v) return;
                setState(() => _selectedCat = c);
                _goTo(0);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
      ],
    ),
  );

  Widget _errorCard() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: _bnkRed),
        const SizedBox(width: 8),
        Expanded(child: Text(_err)),
        TextButton(onPressed: () => _goTo(_page), child: const Text('다시 시도')),
      ]),
    ),
  );

  Widget _emptyCard() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: const [
        Icon(Icons.help_outline, size: 40, color: Colors.grey),
        SizedBox(height: 12),
        Text('검색 결과가 없습니다.'),
        SizedBox(height: 6),
        Text('카테고리/키워드를 바꿔 다시 시도해 주세요.', style: TextStyle(color: Colors.grey)),
      ]),
    ),
  );

  Widget _faqTile(FaqModel m) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _badge(m.category),
          title: Text(
            m.faqQuestion,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: 0.1,
            ),
          ),
          subtitle: (m.regDate != null)
              ? Text('업데이트 ${_fmt(m.regDate!)}', style: TextStyle(color: Colors.grey[600], fontSize: 12))
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SelectableText(m.faqAnswer, style: const TextStyle(height: 1.5)),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ),
  );

  Widget _badge(String cat) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEEF0),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _bnkRed.withOpacity(0.2)),
    ),
    child: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink)),
  );

  Widget _pager() {
    final start = _page * _pageSize + (_items.isEmpty ? 0 : 1);
    final end = _page * _pageSize + _items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            _pillButton(icon: Icons.chevron_left, label: '이전 20개', enabled: !_loading && _page > 0, onTap: () => _goTo(_page - 1)),
            const Spacer(),
            Text((_items.isEmpty && !_loading) ? '항목 없음' : '항목 $start–$end',
                style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
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
    final bg = primary ? _bnkRed : Colors.white;
    final fg = primary ? Colors.white : _ink;
    final side = primary ? BorderSide.none : BorderSide(color: Colors.black.withOpacity(0.15));
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
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

/// ─────────────────────────────────────────────────────────────────
/// 아주 깔끔한 BNK 톤 챗봇 FAB (상단 고정용 원형)
class _ChatFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact; // true: 원형(상단용), false: 라벨 포함 캡슐
  const _ChatFab({required this.onTap, this.compact = true});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // 상단 고정에 어울리는 “미니멀 원형” : 그림자 최소화, 경계만 살짝
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
              boxShadow: const [
                // 과한 그림자 제거하고, 미세한 깊이감만
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withOpacity(0.14),
              highlightColor: Colors.white.withOpacity(0.08),
              child: const Center(
                // 미니멀 로봇 아이콘 (알록달록/그림자 X)
                child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      );
    }

    // 필요 시 하단 배치: 라벨 포함 캡슐형
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
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.12),
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
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
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
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ),
        // 꼬리(오른쪽 아래)
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

