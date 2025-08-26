// lib/application_step0_terms_page.dart
import 'dart:io' show Platform, File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
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

Future<bool> _hasJwt() async {
  final h = await api.API.authHeader();
  final auth = h['Authorization'] ?? '';
  return auth.isNotEmpty;
}



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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
        Navigator.pop(context);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('약관 불러오기 실패: ApiException(${e.statusCode})')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('약관 불러오기 실패: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _allRequiredAgreed =>
      _terms.where((t) => t.isRequired).every((t) => t.agreed);

  Future<void> _startSequentialAgreement() async {
    setState(() {
      for (final t in _terms) t.checked = true; // 얇은 체크
    });
    final firstIdx = _terms.indexWhere((t) => t.isRequired && !t.agreed);
    if (firstIdx != -1) {
      await _openPdfTabs(initialIndex: firstIdx, autoFlow: true);
    }
  }

  // ── 흰 배경 페이드 전환으로 약관 탭 열기 ───────────────────────────────
  Future<void> _openPdfTabs({required int initialIndex, bool autoFlow = false}) async {
    final res = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => TermsPdfTabs(
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
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );

    if (res == true && autoFlow) {
      final next = _terms.indexWhere((t) => t.isRequired && !t.agreed);
      if (next != -1) {
        await Future.delayed(const Duration(milliseconds: 80));
        await _openPdfTabs(initialIndex: next, autoFlow: true);
      }
    }
  }

  Future<void> _saveAgreementsAndNext() async {
    if (_memberNo == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인 해주세요.')));
      return;
    }
    if (!_allRequiredAgreed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('필수 약관을 모두 동의해야 진행할 수 있습니다.')));
      return;
    }

    try {
      setState(() => _posting = true);

      final agreedPdfNos = _terms.where((t) => t.agreed).map((e) => e.pdfNo).toList();
      await ApplyTermsService.saveAgreements(
        memberNo: _memberNo!,
        cardNo: widget.cardNo,
        pdfNos: agreedPdfNos,
      );

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('진행 실패: $e')));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 흰 배경
      appBar: AppBar(

        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
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
  final Future<void> Function() onView;

  const _TermRow({required this.term, required this.onView});

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

/* ───────────────────────────── PDF Tabs (마지막 페이지 도달 시만 동의 활성) ───────────────────────────── */

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

  // 앱에서: 메모리/파일 캐시
  final Map<int, Uint8List> _cache = {};
  final Map<int, String> _err = {};
  final Map<int, String> _filePath = {};

  // 마지막 페이지 제어
  final Map<int, PdfViewerController> _controllers = {};
  final Map<int, int> _pageCount = {};
  final Map<int, int> _pageNow = {};
  final Set<int> _lastToastShown = {};

  bool _downloading = false;

  PdfViewerController _ctrl(int pdfNo) =>
      _controllers.putIfAbsent(pdfNo, () => PdfViewerController());

  bool get _canAgreeNow {
    final pdfNo = widget.terms[_tab.index].pdfNo;
    final c = _pageCount[pdfNo] ?? 0;
    final n = _pageNow[pdfNo] ?? 0;
    return c > 0 && n >= c;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.terms.length, vsync: this, initialIndex: widget.initialIndex);

    // 최초 탭: 앱이면 미리 받기, 웹이면 네트워크 위젯이 직접 로드
    if (!kIsWeb) _ensureLoaded(widget.terms[_tab.index].pdfNo);

    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      if (!kIsWeb) _ensureLoaded(widget.terms[_tab.index].pdfNo);
      setState(() {}); // 버튼 상태 갱신
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // 앞/뒤 잡음 제거 + %%EOF 뒤 자르기
  Uint8List _sanitizePdfBytes(Uint8List src) {
    if (src.isEmpty) return src;
    int start = 0, end = src.length;

    if (src.length >= 3 && src[0] == 0xEF && src[1] == 0xBB && src[2] == 0xBF) start = 3;
    while (start < end) {
      final b = src[start];
      if (b == 0x00 || b == 0x09 || b == 0x0A || b == 0x0D || b == 0x20) {
        start++;
      } else {
        break;
      }
    }
    const sig = [0x25, 0x50, 0x44, 0x46];
    final limit = (end - start) > 8192 ? start + 8192 : end;
    int idx = -1;
    outer:
    for (int i = start; i + sig.length <= limit; i++) {
      for (int j = 0; j < sig.length; j++) {
        if (src[i + j] != sig[j]) continue outer;
      }
      idx = i; break;
    }
    if (idx >= 0) start = idx;

    while (end > start) {
      final b = src[end - 1];
      if (b == 0x00 || b == 0x09 || b == 0x0A || b == 0x0D || b == 0x20) {
        end--;
      } else {
        break;
      }
    }
    final eof = [0x25, 0x25, 0x45, 0x4F, 0x46];
    for (int i = end - eof.length; i >= start; i--) {
      bool hit = true;
      for (int j = 0; j < eof.length; j++) {
        if (src[i + j] != eof[j]) { hit = false; break; }
      }
      if (hit) { end = i + eof.length; break; }
    }

    if (start == 0 && end == src.length) return src;
    return Uint8List.sublistView(src, start, end);
  }

  Future<void> _ensureLoaded(int pdfNo) async {
    if (_cache.containsKey(pdfNo) || _err.containsKey(pdfNo)) return;
    if (kIsWeb) return; // 웹에서는 네트워크 위젯이 직접 로드함

    try {
      final url = '${api.API.baseUrl}/api/card/apply/pdf/$pdfNo';
      final headers = <String, String>{
        ...Map<String, String>.from(await api.API.authHeader()),
        'Accept': 'application/pdf',
      };

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      Uint8List b = res.bodyBytes;
      b = _sanitizePdfBytes(b);
      if (b.length < 4 || !(b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46)) {
        throw Exception('PDF 시그니처 아님 (len=${b.length})');
      }

      if (b.length >= 8) {
        // ignore: avoid_print
        print('[PDF] head ${b.sublist(0, 8).map((e) => e.toRadixString(16).padLeft(2, "0")).join(" ")} len=${b.length}');
      }

      setState(() {
        _cache[pdfNo] = b;
        _err.remove(pdfNo);
      });
    } catch (e) {
      setState(() => _err[pdfNo] = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 로드 실패: $e')),
        );
      }
    }
  }

  Future<File> _writeTempPdf(int pdfNo, Uint8List data) async {
    final dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final f = File('${dir!.path}/__tmp_term_$pdfNo.pdf');
    await f.writeAsBytes(data, flush: true);
    return f;
  }

  void _onLoaded(int pdfNo) {
    final c = _ctrl(pdfNo).pageCount;
    final n = _ctrl(pdfNo).pageNumber;
    setState(() {
      _pageCount[pdfNo] = c;
      _pageNow[pdfNo] = n;
    });
    if (mounted && n >= c && !_lastToastShown.contains(pdfNo)) {
      _lastToastShown.add(pdfNo);
      // 더 이상 스낵바를 띄우지 않음
    }
  }

  void _onChanged(int pdfNo, PdfPageChangedDetails d) {
    final c = _ctrl(pdfNo).pageCount;
    final n = d.newPageNumber;
    setState(() {
      _pageCount[pdfNo] = c;
      _pageNow[pdfNo] = n;
    });
    if (mounted && n >= c && !_lastToastShown.contains(pdfNo)) {
      _lastToastShown.add(pdfNo);
      // 더 이상 스낵바를 띄우지 않음
    }
  }

  Future<void> _agreeCurrent() async {
    final t = widget.terms[_tab.index];
    widget.onAgree(t.pdfNo);

    if (widget.autoFlow) {
      final nextIdx = widget.terms.indexWhere((e) => e.isRequired && !e.agreed);
      if (nextIdx != -1) {
        _tab.animateTo(
          nextIdx,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
        return;
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _downloadCurrent() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('앱에서는 파일 저장을 지원하지 않습니다.')));
      return;
    }
    setState(() => _downloading = true);
    final t = widget.terms[_tab.index];
    try {
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
    // ── 웹: 헤더 포함 네트워크 로딩 (사전 프리페치 X)
    if (kIsWeb) {
      final url = '${api.API.baseUrl}/api/card/apply/pdf/${t.pdfNo}';
      final ctrl = _ctrl(t.pdfNo);
      return FutureBuilder<Map<String, String>>(
        future: api.API.authHeader(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final headers = {...snap.data!, 'Accept': 'application/pdf'};
          return SfPdfViewer.network(
            url,
            headers: headers,
            controller: ctrl,
            key: ValueKey('pdf_net_${t.pdfNo}'),
            pageSpacing: 8,
            onDocumentLoaded: (_) => _onLoaded(t.pdfNo),
            onPageChanged: (d) => _onChanged(t.pdfNo, d),
            onDocumentLoadFailed: (d) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('PDF 로드 실패: ${d.description}')));
            },
          );
        },
      );
    }

    // ── 앱: file 우선 / memory fallback
    final path = _filePath[t.pdfNo];
    final data = _cache[t.pdfNo];
    final err  = _err[t.pdfNo];
    final ctrl = _ctrl(t.pdfNo);

    if (path != null) {
      return SfPdfViewer.file(
        File(path),
        controller: ctrl,
        key: ValueKey('pdf_file_${t.pdfNo}'),
        pageSpacing: 8,
        onDocumentLoaded: (_) => _onLoaded(t.pdfNo),
        onPageChanged: (d) => _onChanged(t.pdfNo, d),
        onDocumentLoadFailed: (d) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('PDF 렌더 실패: ${d.description}')));
        },
      );
    }

    if (data != null) {
      return SfPdfViewer.memory(
        data,
        controller: ctrl,
        key: ValueKey('pdf_mem_${t.pdfNo}'),
        pageSpacing: 8,
        onDocumentLoaded: (_) => _onLoaded(t.pdfNo),
        onPageChanged: (d) => _onChanged(t.pdfNo, d),
        onDocumentLoadFailed: (d) async {
          // 메모리 렌더 실패 → 파일로 저장해 다시 시도
          try {
            final f = await _writeTempPdf(t.pdfNo, data);
            setState(() => _filePath[t.pdfNo] = f.path);
          } catch (e) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('PDF 임시파일 저장 실패: $e')));
          }
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

    _ensureLoaded(t.pdfNo);
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    final canAgree = _canAgreeNow;

    return Scaffold(
      backgroundColor: Colors.white, // 흰 배경
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
                  onPressed: canAgree ? _agreeCurrent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAgree ? widget.primaryColor : Colors.grey.shade300,
                    foregroundColor: canAgree ? Colors.white : Colors.black45,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(canAgree ? '동의' : '마지막 페이지까지 읽어주세요'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

