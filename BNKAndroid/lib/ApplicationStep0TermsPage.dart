// lib/application_step0_terms_page.dart
import 'dart:io' show Platform, File;

import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:bnkandroid/constants/api.dart' as api; // ApiException, authHeader
import 'package:bnkandroid/user/LoginPage.dart';

// 모델/서비스
import 'package:bnkandroid/user/model/TermItem.dart';
import 'package:bnkandroid/user/service/ApplyTermsService.dart';
import 'package:bnkandroid/user/service/card_apply_service.dart' as apply;

// Step1 실제 경로 맞추세요
import 'ApplicationStep1Page.dart';

const kPrimaryRed = Color(0xffB91111);

class ApplicationStep0TermsPage extends StatefulWidget {
  final int cardNo;
  const ApplicationStep0TermsPage({super.key, required this.cardNo});

  @override
  State<ApplicationStep0TermsPage> createState() => _ApplicationStep0TermsPageState();
}

class _ApplicationStep0TermsPageState extends State<ApplicationStep0TermsPage> {
  bool _loading = true;
  bool _posting = false;
  bool _openingLogin = false;

  int? _memberNo;
  List<TermItem> _terms = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);

      // 디버그: 현재 토큰 헤더 출력
      final h = await api.API.authHeader();
      // ignore: avoid_print
      print('[Step0] calling customer-info headers=$h');

      final memberNo = await ApplyTermsService.fetchMemberNo(cardNo: widget.cardNo);
      final items = await ApplyTermsService.fetchTerms(cardNo: widget.cardNo);

      if (!mounted) return;
      setState(() {
        _memberNo = memberNo;
        _terms = items;
      });
    } on api.ApiException catch (e) {
      if (e.statusCode == 401) {
        if (_openingLogin) return;
        _openingLogin = true;

        if (!mounted) return;
        final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        _openingLogin = false;

        if (ok == true) {
          await Future.delayed(const Duration(milliseconds: 120));
          await _load();
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        Navigator.pop(context);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('약관 불러오기 실패: ApiException(${e.statusCode})')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('약관 불러오기 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 필수 항목이 모두 "동의됨"
  bool get _allRequiredAgreed => _terms.where((t) => t.isRequired).every((t) => t.agreed);

  // 모두 동의(시각적 체크) → 미동의 필수부터 순차 동의 받기
  Future<void> _startSequentialAgreement() async {
    setState(() {
      for (final t in _terms) t.checked = true; // 얇은 체크
    });
    final firstIdx = _terms.indexWhere((t) => t.isRequired && !t.agreed);
    if (firstIdx != -1) {
      await _openPdfTabs(initialIndex: firstIdx, autoFlow: true);
    }
  }

  Future<void> _openPdfTabs({required int initialIndex, bool autoFlow = false}) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TermsPdfTabs(
          terms: _terms,
          initialIndex: initialIndex,
          autoFlow: autoFlow,
          primaryColor: kPrimaryRed,
          onAgree: (pdfNo) {
            final t = _terms.firstWhere((e) => e.pdfNo == pdfNo);
            setState(() {
              t.agreed = true;  // 실제 동의 완료
              t.checked = true; // 시각적 체크 보장
            });
          },
        ),
      ),
    );

    if (res == true && autoFlow) {
      final next = _terms.indexWhere((t) => t.isRequired && !t.agreed);
      if (next != -1) {
        await _openPdfTabs(initialIndex: next, autoFlow: true);
      }
    }
  }

  Future<void> _saveAgreementsAndNext() async {
    if (_memberNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인 해주세요.')),
      );
      return;
    }
    if (!_allRequiredAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관을 모두 동의해야 진행할 수 있습니다.')),
      );
      return;
    }

    try {
      setState(() => _posting = true);

      // 1) 동의 저장
      final agreedPdfNos = _terms.where((t) => t.agreed).map((e) => e.pdfNo).toList();
      await ApplyTermsService.saveAgreements(
        memberNo: _memberNo!,
        cardNo: widget.cardNo,
        pdfNos: agreedPdfNos,
      );

      // 2) 발급 시작 → Step1
      final start = await apply.CardApplyService.start(cardNo: widget.cardNo);

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ApplicationStep1Page(
            cardNo: widget.cardNo,
            applicationNo: start.applicationNo,
            isCreditCard: start.isCreditCard,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('진행 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 발급 — 약관 동의'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '카드를 만들려면\n약관 동의가 필요해요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              // 모두 동의
              InkWell(
                onTap: _startSequentialAgreement,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _terms.isNotEmpty && _terms.every((t) => t.checked)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: kPrimaryRed,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('모두 동의',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 리스트
              Expanded(
                child: ListView.separated(
                  itemCount: _terms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = _terms[i];
                    return _TermRow(
                      term: t,
                      onView: () => _openPdfTabs(initialIndex: i),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _posting ? null : _saveAgreementsAndNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allRequiredAgreed ? kPrimaryRed : Colors.grey.shade300,
                    foregroundColor: _allRequiredAgreed ? Colors.white : Colors.black54,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _posting
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────────── Item Row (3상태 아이콘) ───────────────────────────── */

class _TermRow extends StatelessWidget {
  final TermItem term;
  final Future<void> Function() onView; // 아이콘/보기 클릭 시 PDF 열기

  const _TermRow({required this.term, required this.onView});

  // ○(회색) / ◯✓(빨강 아웃라인) / ●✓(빨강)
  Icon _statusIcon(TermItem t) {
    if (t.agreed) return const Icon(Icons.check_circle, color: kPrimaryRed);
    if (t.checked) return const Icon(Icons.check_circle_outline, color: kPrimaryRed);
    return const Icon(Icons.radio_button_unchecked, color: Colors.black38);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // 아이콘 눌러도 항상 PDF 열기(직접 토글 금지)
          InkWell(onTap: onView, child: _statusIcon(term)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: term.isRequired ? Colors.grey.shade200 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        term.isRequired ? '(필수)' : '(선택)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: term.isRequired ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              term.pdfName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (term.agreed) const Icon(Icons.check, size: 16, color: Colors.green),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onView,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2),
                    child: Text('보기', style: TextStyle(decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/* ───────────────────────────── PDF Tabs (네트워크 스트리밍) ───────────────────────────── */

class TermsPdfTabs extends StatefulWidget {
  final List<TermItem> terms;
  final int initialIndex;
  final void Function(int pdfNo) onAgree;
  final bool autoFlow;
  final Color primaryColor;

  const TermsPdfTabs({
    super.key,
    required this.terms,
    required this.initialIndex,
    required this.onAgree,
    this.autoFlow = false,
    this.primaryColor = kPrimaryRed,
  });

  @override
  State<TermsPdfTabs> createState() => _TermsPdfTabsState();
}

class _TermsPdfTabsState extends State<TermsPdfTabs> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final Map<int, Uint8List> _cache = {};        // pdfNo -> bytes 캐시
  final Map<int, String> _err = {};             // pdfNo -> 에러 메시지
  bool _downloading = false;                    // 하단 [다운로드] 버튼 로딩

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.terms.length, vsync: this, initialIndex: widget.initialIndex);
    // 최초 탭 것부터 미리 로드 (선택)
    _ensureLoaded(widget.terms[_tab.index].pdfNo);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      _ensureLoaded(widget.terms[_tab.index].pdfNo);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded(int pdfNo) async {
    if (_cache.containsKey(pdfNo) || _err.containsKey(pdfNo)) return;
    try {
      final headers = await api.API.authHeader();
      final url = '${api.API.baseUrl}/api/card/apply/pdf/$pdfNo';
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      // 간단한 시그니처 체크(%PDF)
      final b = res.bodyBytes;
      if (b.length < 4 || !(b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46)) {
        throw Exception('PDF 시그니처 아님');
      }
      setState(() {
        _cache[pdfNo] = Uint8List.fromList(b);
      });
    } catch (e) {
      setState(() {
        _err[pdfNo] = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _agreeCurrent() async {
    final t = widget.terms[_tab.index];
    widget.onAgree(t.pdfNo);

    if (widget.autoFlow) {
      final nextIdx = widget.terms.indexWhere((e) => e.isRequired && !e.agreed);
      if (nextIdx != -1) {
        _tab.animateTo(nextIdx);
        return;
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _downloadCurrent() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앱에서는 파일 저장을 지원하지 않습니다.')),
      );
      return;
    }
    setState(() => _downloading = true);
    final t = widget.terms[_tab.index];
    try {
      // 캐시에 없으면 먼저 받아오기
      if (!_cache.containsKey(t.pdfNo)) {
        await _ensureLoaded(t.pdfNo);
      }
      final data = _cache[t.pdfNo];
      if (data == null) throw Exception('PDF 데이터 없음');

      final dir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      final file = File('${dir!.path}/term_${t.pdfNo}.pdf');
      await file.writeAsBytes(data, flush: true);
      await OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('다운로드 실패: $e')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Widget _paneFor(TermItem t) {
    final data = _cache[t.pdfNo];
    final err = _err[t.pdfNo];

    if (data != null) {
      return SfPdfViewer.memory(
        data,
        key: ValueKey('pdf_${t.pdfNo}'),
        pageSpacing: 8,
        onDocumentLoaded: (_) => print('[PDF] loaded pdfNo=${t.pdfNo}, bytes=${data.length}'),
        onDocumentLoadFailed: (d) {
          print('[PDF] FAILED (viewer) pdfNo=${t.pdfNo} code=${d.error} desc=${d.description}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF 렌더 실패: ${d.description}')),
          );
        },
      );
    }

    if (err != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('불러오기 실패\n$err', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _ensureLoaded(t.pdfNo),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 아직 로딩 전이면 트리거
    _ensureLoaded(t.pdfNo);
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 상세'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: widget.primaryColor,
          unselectedLabelColor: Colors.black54,
          tabs: [
            for (final t in widget.terms)
              Tab(text: t.pdfName.length > 12 ? '${t.pdfName.substring(0, 12)}…' : t.pdfName),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        physics: const BouncingScrollPhysics(),
        children: [for (final t in widget.terms) _paneFor(t)],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _downloading ? null : _downloadCurrent,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _downloading
                      ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('다운로드'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _agreeCurrent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('동의'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

