// lib/application_step0_terms_page.dart
import 'dart:typed_data';
import 'dart:io' show Platform, File;
import 'package:bnkandroid/user/LoginPage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// ▶ 분리한 모델/서비스 사용
import 'package:bnkandroid/user/model/TermItem.dart';
import 'package:bnkandroid/user/service/ApplyTermsService.dart';
import 'package:bnkandroid/user/service/card_apply_service.dart' as apply;
// Step1 실제 경로/이름에 맞게 수정
import 'ApplicationStep1Page.dart';
import 'package:bnkandroid/constants/api.dart' as api; // ← 추가

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
  bool _agreeAllTapped = false;
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

      // (디버그) 현재 헤더 확인
      final h = await api.API.authHeader();
      // ignore: avoid_print
      print('[Step0] calling customer-info headers=$h');

      final memberNo = await ApplyTermsService.fetchMemberNo(cardNo: widget.cardNo);
      final items    = await ApplyTermsService.fetchTerms(cardNo: widget.cardNo);

      if (!mounted) return;
      setState(() { _memberNo = memberNo; _terms = items; });

    } on api.ApiException catch (e) {
      if (e.statusCode == 401) {
        if (_openingLogin) return;     // ✅ 이미 열려있으면 무시
        _openingLogin = true;

        if (!mounted) return;
        final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        _openingLogin = false;

        if (ok == true) {
          // 로그인 직후 디스크 I/O 타이밍으로 값이 늦게 보이는 경우가 있어 아주 살짝 기다렸다 재시도
          await Future.delayed(const Duration(milliseconds: 100));
          await _load();               // ✅ 재시도
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        Navigator.pop(context);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('약관 불러오기 실패: ApiException(${e.statusCode})')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('약관 불러오기 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _allRequiredAgreed => _terms.where((t) => t.isRequired).every((t) => t.agreed);

  Future<void> _startSequentialAgreement() async {
    setState(() {
      for (final t in _terms) t.checked = true;
      _agreeAllTapped = true;
    });
    final idx = _terms.indexWhere((t) => t.isRequired && !t.agreed);
    if (idx != -1) await _openPdfTabs(initialIndex: idx, autoFlow: true);
  }

  Future<void> _openPdfTabs({required int initialIndex, bool autoFlow = false}) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TermsPdfTabs(
          terms: _terms,
          initialIndex: initialIndex,
          onAgree: (pdfNo) {
            final t = _terms.firstWhere((e) => e.pdfNo == pdfNo);
            setState(() {
              t.agreed = true;
              t.checked = true;
            });
          },
          autoFlow: autoFlow,
          primaryColor: kPrimaryRed,
        ),
      ),
    );

    if (res == true && autoFlow) {
      final next = _terms.indexWhere((t) => t.isRequired && !t.agreed);
      if (next != -1) await _openPdfTabs(initialIndex: next, autoFlow: true);
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

      // 1) 약관 동의 저장
      final agreedPdfNos = _terms.where((t) => t.agreed).map((e) => e.pdfNo).toList();
      await ApplyTermsService.saveAgreements(
        memberNo: _memberNo!,
        cardNo: widget.cardNo,
        pdfNos: agreedPdfNos,
      );

      // 2) 발급 시작 → applicationNo 받아서 Step1로
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('진행 실패: $e')),
        );
      }
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
                        child: Text('모두 동의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _terms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = _terms[i];
                    return _TermRow(
                      term: t,
                      onView: () => _openPdfTabs(initialIndex: i),
                      onToggle: () => setState(() => t.checked = !t.checked),
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
                    height: 24, width: 24,
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

class _TermRow extends StatelessWidget {
  final TermItem term;
  final VoidCallback onView;
  final VoidCallback onToggle;

  const _TermRow({required this.term, required this.onView, required this.onToggle});

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
          InkWell(
            onTap: onToggle,
            child: Icon(
              term.checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: term.checked ? kPrimaryRed : Colors.black38,
            ),
          ),
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
                      child: Text(term.isRequired ? '(필수)' : '(선택)',
                          style: TextStyle(fontSize: 11, fontWeight: term.isRequired ? FontWeight.w600 : FontWeight.w400)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        term.pdfName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      onTap: onView,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2),
                        child: Text('보기', style: TextStyle(decoration: TextDecoration.underline)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (term.agreed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.green.shade50,
                        ),
                        child: const Text('동의됨', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ),
                  ],
                )
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF 탭 뷰어
// ─────────────────────────────────────────────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.terms.length, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
    final t = widget.terms[_tab.index];
    if (t.data == null) return;

    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('웹에서는 파일 저장을 지원하지 않습니다.')),
      );
      return;
    }

    final dir = Platform.isAndroid ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final file = File('${dir!.path}/term_${t.pdfNo}.pdf');
    await file.writeAsBytes(t.data!, flush: true);
    await OpenFilex.open(file.path);
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
        children: [
          for (final t in widget.terms)
            t.data == null
                ? const Center(child: Text('PDF 데이터가 없습니다.'))
                : SfPdfViewer.memory(t.data!, pageSpacing: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _downloadCurrent,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('다운로드'),
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
