// lib/faq/faq.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'service/FaqService.dart';
import 'model/FaqModel.dart';
import '../constants/faq_api.dart';
import '../constants/chat_api.dart';
import '../user/cardListPage.dart';
import '../chat/widgets/chatbot_modal.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  static const _bnkRed = Color(0xFFE60012);
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

  @override
  void initState() {
    super.initState();
    _goTo(0);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _queryCtrl.dispose();
    super.dispose();
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CardListPage()));
        return false;
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('FAQ'),
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
            child: Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        body: RefreshIndicator(
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

        // 챗봇 FAB
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => const ChatbotModal(),
            );
          },
          label: const Text('챗봇'),
          icon: const Icon(Icons.smart_toy_outlined),
          backgroundColor: _bnkRed,
          foregroundColor: Colors.white,
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
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
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
              label: Text(c, style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _ink,
              )),
              selected: selected,
              backgroundColor: Colors.white,
              selectedColor: _bnkRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: selected ? _bnkRed : Colors.black.withValues(alpha: 0.12)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _badge(m.category),
          title: Text(m.faqQuestion, style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
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
      border: Border.all(color: const Color(0xFFE60012).withValues(alpha: 0.2)),
    ),
    child: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            _pillButton(icon: Icons.chevron_left, label: '이전 20개', enabled: !_loading && _page > 0, onTap: () => _goTo(_page - 1)),
            const Spacer(),
            Text((_items.isEmpty && !_loading) ? '항목 없음' : '항목 $start–$end',
                style: const TextStyle(fontWeight: FontWeight.w600, color: _ink)),
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
    final side = primary ? BorderSide.none : BorderSide(color: Colors.black.withValues(alpha: 0.15));
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

// 디버그 런처(원하면 유지)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 스프링 FAQ 서버(필수)
  FAQApi.useLan(ip: '192.168.0.5', port: 8090); // 본인 IP
  FAQApi.setPathPrefix('/api');                 // 백엔드가 /api/faq 라우트일 때

  // 챗봇 서버 선택(둘 중 하나)
  ChatAPI.useFastAPI(ip: '192.168.0.5', port: 8000);      // FastAPI 직접
  // ChatAPI.useSpringProxy(ip: '192.168.0.5', port: 8090); // 스프링 프록시

  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: FaqPage()));
}
