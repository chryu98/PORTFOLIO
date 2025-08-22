// lib/sign/sign_page.dart
import 'dart:typed_data';
import 'dart:ui' as ui; // PNG 변환용
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:bnkandroid/constants/api.dart' as API;         // ApiException 캐치용
import 'package:bnkandroid/user/service/SignService.dart';     // 서버 연동

class SignPage extends StatefulWidget {
  final int applicationNo;
  const SignPage({super.key, required this.applicationNo});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  // ── 서명 그리기 상태 ─────────────────────────────────────────────
  final GlobalKey _paintKey = GlobalKey();                // PNG 추출용
  final List<List<Offset>> _strokes = <List<Offset>>[];   // 완료된 스트로크
  List<Offset> _current = <Offset>[];                     // 진행중인 스트로크

  bool get _isEmpty => _strokes.isEmpty && _current.isEmpty;

  // ── 서버 상태 ──────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  SignInfo? _info;
  bool _exists = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── 서버 데이터 로딩 ───────────────────────────────────────────
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
      _toast(e.message ?? '서명 대상 조회 실패');
    } catch (e) {
      if (!mounted) return;
      _toast('오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── 제스처 핸들러 (그리기) ─────────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    setState(() => _current = <Offset>[d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _current.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() {
      if (_current.isNotEmpty) _strokes.add(List<Offset>.from(_current));
      _current = <Offset>[];
    });
  }

  void _undo() {
    setState(() {
      if (_current.isNotEmpty) {
        _current = <Offset>[];
      } else if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current = <Offset>[];
    });
  }

  // ── PNG 추출 ───────────────────────────────────────────────────
  Future<Uint8List> _exportPngBytes() async {
    final boundary = _paintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('렌더 경계(boundary) 탐색 실패');
    }
    final ui.Image img = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) throw Exception('PNG 변환 실패');
    return bd.buffer.asUint8List();
  }

  // ── 제출 ───────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_isEmpty) {
      _toast('서명을 먼저 입력해 주세요.');
      return;
    }

    setState(() => _saving = true);
    try {
      final png = await _exportPngBytes();

      final ok = await SignService.uploadSignature(
        applicationNo: widget.applicationNo,
        pngBytes: png,
      );

      if (!mounted) return;

      if (ok) {
        // 안전하게 확정까지
        await SignService.confirmDone(widget.applicationNo);
        _toast('전자서명이 완료되었습니다.');

        // 메인으로 복귀 (앱 라우트명에 맞게 바꾸세요)
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else {
        _toast('서명 업로드 실패');
      }
    } on API.ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message ?? '요청 실패');
    } catch (e) {
      if (!mounted) return;
      _toast('오류: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

            // ── 서명 패드 (토스/카뱅 느낌, 깔끔한 카드) ────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E8EC)),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0F000000))],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  const Text('박스 안에 서명해 주세요.',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 8),

                  AspectRatio(
                    aspectRatio: 3 / 2,
                    child: RepaintBoundary(
                      key: _paintKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3E6EA)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: CustomPaint(
                              painter: _SignaturePainter(
                                strokes: _strokes,
                                current: _current,
                                strokeWidth: 3.0,
                                color: Colors.black87,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 액션 버튼들 (되돌리기 / 지우기)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isEmpty ? null : _undo,
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('되돌리기'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isEmpty ? null : _clear,
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                          label: const Text('지우기'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 제출 버튼
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

// ── 서명 그리기용 Painter ─────────────────────────────────────────
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final double strokeWidth;
  final Color color;

  _SignaturePainter({
    required this.strokes,
    required this.current,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 완료된 스트로크
    for (final path in strokes) {
      _drawPath(canvas, path, paint);
    }
    // 진행 중 스트로크
    _drawPath(canvas, current, paint);
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) {
    return old.strokes != strokes ||
        old.current != current ||
        old.strokeWidth != strokeWidth ||
        old.color != color;
  }
}
