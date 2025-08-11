// lib/faq/faq.dart
import 'package:flutter/material.dart';
import 'service/FaqService.dart';
import 'model/FaqModel.dart';
import '../constants/faq_api.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final _scroll = ScrollController();
  final _queryCtrl = TextEditingController();

  List<FaqModel> _items = [];
  int _page = 0;
  bool _last = false;
  bool _loading = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 160) {
        if (!_loading && !_last) _load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      if (reset) { _page = 0; _last = false; _items = []; _err = ''; }
    });
    try {
      final r = await FaqService.fetch(
        page: _page,
        size: 20,
        query: _queryCtrl.text.trim(),
      );
      setState(() {
        _items.addAll(r.content);
        _last = r.last;
        _page += 1;
      });
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _header()),
            if (_err.isNotEmpty) SliverToBoxAdapter(child: _error()),
            if (_items.isEmpty && _err.isEmpty && !_loading)
              SliverToBoxAdapter(child: _empty()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) => _tile(_items[i]),
                childCount: _items.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.6))
                      : _last
                      ? Text('마지막 항목입니다.',
                      style: TextStyle(color: Colors.grey[600]))
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: TextField(
      controller: _queryCtrl,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _load(reset: true),
      decoration: InputDecoration(
        hintText: '검색어를 입력하세요',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _error() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(_err)),
        TextButton(onPressed: () => _load(reset: true), child: const Text('다시 시도')),
      ]),
    ),
  );

  Widget _empty() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: const [
        Icon(Icons.help_outline, size: 40, color: Colors.grey),
        SizedBox(height: 12),
        Text('검색 결과가 없습니다.'),
        SizedBox(height: 6),
        Text('키워드를 바꿔 다시 시도해 주세요.', style: TextStyle(color: Colors.grey)),
      ]),
    ),
  );

  Widget _tile(FaqModel m) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _badge(m.category),
          title: Text(m.question, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF333333))),
          subtitle: (m.regDate != null)
              ? Text('업데이트 ${_fmt(m.regDate!)}', style: TextStyle(color: Colors.grey[600], fontSize: 12))
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SelectableText(m.answer, style: const TextStyle(height: 1.5)),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ),
  );

  Widget _badge(String cat) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
    child: Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
  );

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

// 디버그 런처 (이 파일만 우클릭 → Run)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FAQApi.initBaseUrl();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: FaqPage()));
}
