// lib/sign/sign_page.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:bnkandroid/constants/api.dart' as API;
import 'package:bnkandroid/user/service/SignService.dart';

// 축하 페이지
import 'sign_congrats_page.dart';

/// 브랜드 컬러(앱과 동일한 톤)
const kBrand = Color(0xFFB91111);
const kCardBorder = Color(0xFFE5E8EC);
const kSurface = Color(0xFFF7F8FA);

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
      final info = await SignService.fetchInfo(widget.applicationNo);
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
        final last = _current.last;
        final dist = (last - p).distance;
        if (dist < 0.7) return; // 미세 노이즈 제거

        // 거리가 멀면 중간 보간점 추가(부드럽게)
        final steps = (dist / 2.0).floor();
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
              onDone: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('전자서명'),
        backgroundColor: Colors.white,
        elevation: 0.6,
        centerTitle: false,
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // 상단 정보 (토스 느낌으로 가벼운 칩들)
            _TopInfoChips(
              applicationNo: widget.applicationNo,
              status: _info?.status ?? '-',
            ),
            const SizedBox(height: 14),

            if (_exists) ...[
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('기존 서명',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        SignService.imageUrl(widget.applicationNo),
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                        const Text('이미지 로드 실패', style: TextStyle(color: Colors.black54)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 서명 카드
            _SectionCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('서명 입력',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kCardBorder),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text(
                          '아래 흰 영역에 손가락 또는 펜으로 서명해 주세요.',
                          style: TextStyle(fontSize: 12.5, color: Colors.black54),
                        ),
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
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isEmpty ? null : _undo,
                                icon: const Icon(Icons.undo_rounded, size: 18),
                                label: const Text('되돌리기'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(color: kCardBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isEmpty ? null : _clear,
                                icon:
                                const Icon(Icons.delete_sweep_rounded, size: 18),
                                label: const Text('지우기'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(color: kCardBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                                ),
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
          ],
        ),
      ),

      // 하단 고정 제출 버튼(넓고 말랑)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kBrand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
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

    for (final pts in strokes) {
      final path = _buildSmoothPath(pts);
      if (path != null) canvas.drawPath(path, paint);
    }
    final cur = _buildSmoothPath(current);
    if (cur != null) canvas.drawPath(cur, paint);
  }

  Path? _buildSmoothPath(List<Offset> pts) {
    if (pts.length < 2) return null;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
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

/// 상단 “신청번호/상태” 칩들
class _TopInfoChips extends StatelessWidget {
  final int applicationNo;
  final String status;
  const _TopInfoChips({required this.applicationNo, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusChip(status);
    return Row(
      children: [
        _Chip(text: '신청번호 ${applicationNo}', color: const Color(0xFFEFF4FF), textColor: const Color(0xFF1E40AF)),
        const SizedBox(width: 8),
        _Chip(text: label, color: color.withOpacity(.12), textColor: color),
      ],
    );
  }

  /// 상태 라벨/컬러(필요에 맞게 보정)
  (String, Color) _statusChip(String s) {
    final up = s.toUpperCase();
    if (up.contains('READY')) return ('서명 대기', const Color(0xFF2563EB)); // 파랑
    if (up.contains('DONE') || up.contains('COMPLETE')) {
      return ('완료', const Color(0xFF16A34A)); // 초록
    }
    if (up.contains('REJECT')) return ('반려', const Color(0xFFEF4444)); // 빨강
    return (s, const Color(0xFF64748B)); // 중립
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _Chip({required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 12.5),
      ),
    );
  }
}

/// 공통 섹션 카드(토스 톤: 라운드+옅은 테두리+아주 약한 그림자)
class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardBorder),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x0F000000), offset: Offset(0, 4))],
      ),
      padding: padding,
      child: child,
    );
  }
}
