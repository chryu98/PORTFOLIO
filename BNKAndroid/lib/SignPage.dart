// lib/sign/sign_page.dart
import 'dart:typed_data';
import 'package:bnkandroid/user/service/SignService.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import 'package:bnkandroid/constants/api.dart' as API;      // ApiException 캐치용

import 'package:bnkandroid/ui/signature_pad.dart';          // 재사용 사인 패드 UI

class SignPage extends StatefulWidget {
  final int applicationNo;
  const SignPage({super.key, required this.applicationNo});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black87,
    exportBackgroundColor: Colors.white, // PNG 배경색
  );

  bool _loading = true;   // 초기 정보 로딩
  bool _saving  = false;  // 업로드 중
  SignInfo? _info;
  bool _exists = false;   // 기존 서명 존재 여부

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final info   = await SignService.fetchInfo(widget.applicationNo);
      final exists = await SignService.exists(widget.applicationNo);
      if (!mounted) return;
      setState(() {
        _info = info;
        _exists = exists;
      });
    } on API.ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '서명 대상 조회 실패')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서명을 먼저 입력해 주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final Uint8List? png = await _controller.toPngBytes();
      if (png == null || png.isEmpty) {
        throw Exception('PNG 추출 실패');
      }

      final ok = await SignService.uploadSignature(
        applicationNo: widget.applicationNo,
        pngBytes: png,
      );

      if (!mounted) return;
      if (ok) {
        // 서버에서 save() 마지막에 appMapper.updateStatus(appNo, "SIGNED") 가 들어가 있으면,
        // 업로드 즉시 최종 완료 상태가 됩니다.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전자서명이 완료되었습니다.')),
        );
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서명 업로드 실패')),
        );
      }
    } on API.ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '요청 실패')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('전자서명')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: ListView(
          children: [
            Text('신청번호: ${widget.applicationNo}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('현재상태: ${_info?.status ?? '-'}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),

            if (_exists) ...[
              const Text('기존 서명', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  SignService.imageUrl(widget.applicationNo),
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('이미지 로드 실패'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ✅ 재사용 가능한 사인 패드 UI (lib/ui/signature_pad.dart)
            SignaturePad(
              controller: _controller,
              height: 260,
              hint: '박스 안에 서명해 주세요.',
              showActions: true, // 되돌리기/지우기 버튼 노출
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.check_rounded),
              label: const Text('제출'),
            ),
          ),
        ),
      ),
    );
  }
}
