// lib/ApplicationStep7AddressPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // ✅ WebView
import 'ApplicationStep1Page.dart' show kPrimaryRed;
import 'package:bnkandroid/user/service/card_apply_service.dart' as apply;
import 'package:bnkandroid/postcode_search_page.dart';

import 'ApplicationStep8CardPinPage.dart';

class ApplicationStep7AddressPage extends StatefulWidget {
  final int applicationNo;
  final int cardNo; // ✅ 추가

  const ApplicationStep7AddressPage({
    super.key,
    required this.applicationNo,
    required this.cardNo, // ✅ 추가
  });

  @override
  State<ApplicationStep7AddressPage> createState() => _ApplicationStep7AddressPageState();
}

class _ApplicationStep7AddressPageState extends State<ApplicationStep7AddressPage> {
  // 현재 탭 (H=집, W=직장)
  String _addrType = 'H';

  // 집/회사 버퍼
  String? _homeZip, _homeAddr1, _homeExtra, _homeAddr2;
  String? _workZip, _workAddr1, _workExtra, _workAddr2;

  final _formKey = GlobalKey<FormState>();

  // 입력 컨트롤러
  final _zip   = TextEditingController();
  final _addr1 = TextEditingController(); // 기본주소(도로명/지번)
  final _extra = TextEditingController(); // 추가주소(동/리, 건물명 등)
  final _addr2 = TextEditingController(); // 상세주소(동/호 등)

  bool _loading = true;   // 프리필 로딩
  bool _saving  = false;  // 저장 중

  @override
  void initState() {
    super.initState();
    _loadPrefill();
  }

  @override
  void dispose() {
    _zip.dispose();
    _addr1.dispose();
    _extra.dispose();
    _addr2.dispose();
    super.dispose();
  }

  // ───────────────── 프리필 ─────────────────
  Future<void> _loadPrefill() async {
    setState(() => _loading = true);
    try {
      final p = await apply.CardApplyService.fetchHomeAddress(); // 토큰 포함 호출
      if (!mounted) return;
      if (p != null) {
        // 컨트롤러 채우기 (집 기준)
        _zip.text   = p.zipCode;
        _addr1.text = p.address1; // 기본주소
        _addr2.text = p.address2; // 상세주소
        _extra.text = '';         // 선택 (없으면 공란)

        // 집 버퍼에도 저장
        _homeZip   = _zip.text;
        _homeAddr1 = _addr1.text;
        _homeAddr2 = _addr2.text;
        _homeExtra = _extra.text;

        _addrType   = 'H';        // 기본 탭 집
      }
    } catch (e) {
      debugPrint('prefill error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ──────────────── 탭 전환 유틸 ────────────────
  void _saveCurrentToBuffer() {
    if (_addrType == 'H') {
      _homeZip   = _zip.text;
      _homeAddr1 = _addr1.text;
      _homeExtra = _extra.text;
      _homeAddr2 = _addr2.text;
    } else {
      _workZip   = _zip.text;
      _workAddr1 = _addr1.text;
      _workExtra = _extra.text;
      _workAddr2 = _addr2.text;
    }
  }

  void _loadBuffer(String t) {
    if (t == 'H') {
      _zip.text   = _homeZip   ?? '';
      _addr1.text = _homeAddr1 ?? '';
      _extra.text = _homeExtra ?? '';
      _addr2.text = _homeAddr2 ?? '';
    } else {
      _zip.text   = _workZip   ?? '';
      _addr1.text = _workAddr1 ?? '';
      _extra.text = _workExtra ?? '';
      _addr2.text = _workAddr2 ?? '';
    }
  }

  void _switchType(String t) {
    if (_addrType == t) return;
    _saveCurrentToBuffer();
    setState(() => _addrType = t);
    _loadBuffer(t);
  }

  bool get _hasHomeSaved =>
      (_homeZip ?? '').isNotEmpty || (_homeAddr1 ?? '').isNotEmpty || (_homeAddr2 ?? '').isNotEmpty;

  // ───────────────── 저장 호출 ─────────────────
  String? _req(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label을(를) 입력하세요.' : null;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final ok = await apply.CardApplyService.saveAddress(
        applicationNo: widget.applicationNo,
        zipCode: _zip.text.trim(),
        address1: _addr1.text.trim(),
        extraAddress: _extra.text.trim(),
        address2: _addr2.text.trim(),
        addressType: _addrType, // 'H' | 'W'
      );

      if (!mounted) return;
      if (ok) {
        // TODO: 다음 단계 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicationStep8CardPinPage(
              applicationNo: widget.applicationNo, // ✅ 추가
              cardNo: widget.cardNo,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주소 저장에 실패했습니다.')),
        );
      }
    } on apply.ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ✅ 카카오 우편번호 WebView 열기
  Future<void> _openPostcode() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => const PostcodeSearchPage()),
    );
    if (result != null) {
      setState(() {
        _zip.text   = (result['zonecode'] ?? '').toString();
        final road  = (result['roadAddress'] ?? '').toString();
        final jibun = (result['jibunAddress'] ?? '').toString();
        _addr1.text = road.isNotEmpty ? road : jibun;
        _extra.text = (result['extraAddress'] ?? '').toString();
      });
    }
  }

  // ───────────────── UI ─────────────────
  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: kPrimaryRed),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isBusy = _saving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black87),

        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const _StepHeader7(current: 6, total: 6),
              const SizedBox(height: 14),
              const Text('수령지를 선택해주세요', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // 유형 선택(토스풍)
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: '집',
                      selected: _addrType == 'H',
                      onTap: () => _switchType('H'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeChip(
                      label: '직장',
                      selected: _addrType == 'W',
                      onTap: () => _switchType('W'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 우편번호 + 찾기
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _zip,
                      keyboardType: TextInputType.number,
                      decoration: _dec('우편번호'),
                      validator: (v) => _req(v, '우편번호'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _openPostcode, // ✅ WebView 열기
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCED4DA)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('우편번호 찾기'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 기본주소
              TextFormField(
                controller: _addr1,
                readOnly: false,
                decoration: _dec('기본주소 (도로명/지번)'),
                validator: (v) => _req(v, '기본주소'),
              ),
              const SizedBox(height: 12),

              // 추가주소(선택)
              TextFormField(
                controller: _extra,
                decoration: _dec('추가주소 (동/리, 건물명 등) — 선택'),
              ),
              const SizedBox(height: 12),

              // 상세주소
              TextFormField(
                controller: _addr2,
                decoration: _dec('상세주소 (동/호 등)'),
                validator: (v) => _req(v, '상세주소'),
              ),
              const SizedBox(height: 6),
              const Text(
                '※ 서버에서 기본주소(address1)와 추가주소(extraAddress)를 합쳐 저장합니다.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),

              // 회사 탭일 때만 노출: 집 주소 불러오기
              if (_addrType == 'W' && _hasHomeSaved) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('집 주소 불러오기'),
                    onPressed: () {
                      _zip.text   = _homeZip   ?? '';
                      _addr1.text = _homeAddr1 ?? '';
                      _extra.text = _homeExtra ?? '';
                      _addr2.text = _homeAddr2 ?? '';

                      _workZip   = _zip.text;
                      _workAddr1 = _addr1.text;
                      _workExtra = _extra.text;
                      _workAddr2 = _addr2.text;

                      setState(() {});
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isBusy ? null : _save,
              child: isBusy
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('다음'),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDECEC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kPrimaryRed : const Color(0xFFE5E5E5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? kPrimaryRed : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _StepHeader7 extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const _StepHeader7({required this.current, this.total = 8});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = (i + 1) <= current;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            color: active ? kPrimaryRed : const Color(0xFFE5E5E5),
          ),
        );
      }),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// 우편번호 WebView 페이지
/// ─────────────────────────────────────────────────────────────
/// 준비:
/// 1) pubspec.yaml
///   dependencies:
///     webview_flutter: ^4.8.0
///   flutter:
///     assets:
///       - assets/postcode.html
///
/// 2) assets/postcode.html 내용(요지)
///   - daum postcode v2 스크립트 로드
///   - embed 모드로 띄우고 oncomplete에서
///     window.App.postMessage(JSON.stringify({...})) 호출
///

