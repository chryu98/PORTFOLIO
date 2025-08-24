// lib/sign/sign_page.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:bnkandroid/constants/api.dart' as API;
import 'package:bnkandroid/user/service/SignService.dart';

// 축하 페이지
import 'sign_congrats_page.dart';

class SignPage extends StatefulWidget {
  final int applicationNo;
  const SignPage({super.key, required this.applicationNo});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  // ── Drawing state ─────────────────────────────────────────────
  final GlobalKey _paintKey = GlobalKey();
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset> _current = <Offset>[];

  bool get _isEmpty => _strokes.isEmpty && _current.isEmpty;

  // ── Server state ──────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  SignInfo? _info;
  bool _exists = false;

  @override
  void initState() {
    super.initState();
    _load();
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
      _toast(e.message ?? '서명 대상 조회 실패');
    } catch (e) {
      if (!mounted) return;
      _toast('오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Gesture handlers (with point densification) ──────────────
  void _onPanStart(DragStartDetails d) {
    setState(() => _current = <Offset>[d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final p = d.localPosition;
    setState(() {
      if (_current.isEmpty) {
        _current = <Offset>[p];
      } else {
        // 샘플링 밀도 보강: 이전 점과 거리가 너무 짧으면 건너뛰고,
        // 길면 중간보간 점까지 넣어 끊김을 줄임
        final last = _current.last;
        final dist = (last - p).distance;

        // 아주 짧은 미세 이동은 무시 (노이즈 제거)
        if (dist < 0.7) return;

        // 거리가 멀면 중간 보간점 추가
        final steps = (dist / 2.0).floor(); // 2px 당 한 점
        if (steps > 1) {
          for (int i = 1; i < steps; i++) {
            final t = i / steps;
            _current.add(Offset(
              last.dx + (p.dx - last.dx) * t,
              last.dy + (p.dy - last.dy) * t,
            ));
          }
        }
        _current.add(p);
      }
    });
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
        // 진행 중인 획은 취소
        _current = <Offset>[];
      } else if (_strokes.isNotEmpty) {
        // 완료된 마지막 한 획만 되돌리기
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

  // ── Export PNG ────────────────────────────────────────────────
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

  // ── Submit ───────────────────────────────────────────────────
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
        await SignService.confirmDone(widget.applicationNo);
        // 성공 → 축하 페이지로 전환
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SignCongratsPage(
              applicationNo: widget.applicationNo,
              onDone: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (r) => false),
            ),
          ),
        );
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

  // ── UI ────────────────────────────────────────────────────────
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
            Text(
              '현재상태: ${_info?.status ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
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

            // ── Signature Pad (smoother) ─────────────────────────
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
                            behavior: HitTestBehavior.opaque, // 히트영역 보강
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: CustomPaint(
                              isComplex: true,
                              willChange: true,
                              painter: _SmoothSignaturePainter(
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

// ── Smoother Painter (Quadratic Bezier + Antialias) ─────────────
class _SmoothSignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final double strokeWidth;
  final Color color;

  _SmoothSignaturePainter({
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
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // 완료된 획
    for (final pts in strokes) {
      final path = _buildSmoothPath(pts);
      if (path != null) canvas.drawPath(path, paint);
    }
    // 진행 중인 획
    final cur = _buildSmoothPath(current);
    if (cur != null) canvas.drawPath(cur, paint);
  }

  Path? _buildSmoothPath(List<Offset> pts) {
    if (pts.length < 2) return null;

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);

    // Quadratic Bezier 보간으로 매끈하게
    for (int i = 1; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    // 마지막 점까지 자연스럽게 이어주기
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _SmoothSignaturePainter old) {
    return old.strokes != strokes ||
        old.current != current ||
        old.strokeWidth != strokeWidth ||
        old.color != color;
  }
}
