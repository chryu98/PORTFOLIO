// lib/sign/sign_page.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:bnkandroid/user/service/SignService.dart';
import 'package:bnkandroid/constants/api.dart' as API;
import 'package:flutter/rendering.dart';

class SignPage extends StatefulWidget {
  final int applicationNo;
  const SignPage({super.key, required this.applicationNo});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  // ── 서버 상태 ────────────────────────────────────────────────
  bool _loading = true;   // 초기 정보 로딩
  bool _saving  = false;  // 업로드 중
  SignInfo? _info;
  bool _exists = false;   // 기존 서명 존재 여부

  // ── 사인 보드 상태 ───────────────────────────────────────────
  final _boardKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redo = [];
  bool _eraser = false;
  double _thickness = 3.5;
  Rect? _bounds; // 현재 서명의 외접 박스

  // 최소 서명 영역(너무 작게 그린 경우 방지)
  static const double _minBoxW = 120;
  static const double _minBoxH = 36;

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

  // ── 그리기 이벤트 ───────────────────────────────────────────
  void _onPanStart(Offset p) {
    if (_saving) return;
    setState(() {
      _redo.clear();
      _strokes.add(_Stroke(
        points: [p],
        width: _thickness,
        eraser: _eraser,
        color: Colors.black,
      ));
    });
  }

  void _onPanUpdate(Offset p) {
    if (_saving) return;
    setState(() {
      _strokes.last.points.add(p);
      _bounds = _computeBounds(_strokes);
    });
  }

  void _onPanEnd() {
    if (_saving) return;
    setState(() {
      _bounds = _computeBounds(_strokes);
    });
  }

  void _undo() {
    if (_strokes.isEmpty || _saving) return;
    setState(() {
      _redo.add(_strokes.removeLast());
      _bounds = _computeBounds(_strokes);
    });
  }

  void _redoBtn() {
    if (_redo.isEmpty || _saving) return;
    setState(() {
      _strokes.add(_redo.removeLast());
      _bounds = _computeBounds(_strokes);
    });
  }

  void _clearAll() {
    if (_saving) return;
    setState(() {
      _strokes.clear();
      _redo.clear();
      _bounds = null;
    });
  }

  bool get _hasDrawable =>
      _strokes.any((s) => !s.eraser && s.points.length > 1);

  // ── 제출(업로드) ────────────────────────────────────────────
  Future<void> _submit() async {
    if (_saving) return;

    if (!_hasDrawable || _bounds == null) {
      _toast('서명을 먼저 입력해 주세요.');
      return;
    }
    if (_bounds!.width < _minBoxW || _bounds!.height < _minBoxH) {
      _toast('조금 더 크게 서명해 주세요.');
      return;
    }

    setState(() => _saving = true);
    try {
      final png = await _exportToPng(pixelRatio: 3.0);
      if (png.isEmpty) throw Exception('PNG 추출 실패');

      // 서버가 업로드 시점에 바로 SIGNED 로 바꾸도록 구현되어 있다면 이 호출만으로 완료.
      final ok = await SignService.uploadSignature(
        applicationNo: widget.applicationNo,
        pngBytes: png,
      );

      if (!mounted) return;
      if (ok) {
        // (안전) 혹시 READY로 남겨둘 수 있으니 confirm도 덧붙임
        await SignService.confirmDone(widget.applicationNo);
        _toast('전자서명이 완료되었습니다.');
        Navigator.of(context).popUntil((r) => r.isFirst);
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

  Future<Uint8List> _exportToPng({double pixelRatio = 3.0}) async {
    final boundary =
    _boardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Rect? _computeBounds(List<_Stroke> strokes) {
    double? minX, minY, maxX, maxY;
    for (final s in strokes) {
      if (s.points.isEmpty || s.eraser) continue;
      for (final p in s.points) {
        minX = (minX == null) ? p.dx : (p.dx < minX ? p.dx : minX);
        minY = (minY == null) ? p.dy : (p.dy < minY ? p.dy : minY);
        maxX = (maxX == null) ? p.dx : (p.dx > maxX ? p.dx : maxX);
        maxY = (maxY == null) ? p.dy : (p.dy > maxY ? p.dy : maxY);
      }
    }
    if (minX == null) return null;
    return Rect.fromLTRB(minX!, minY!, maxX!, maxY!);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final info = _info;
    final status = info?.status ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('전자서명')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 정보
            Text('신청번호: ${widget.applicationNo}',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('현재상태: $status',
                style:
                const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),

            if (_exists) ...[
              const Text('기존 서명',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  SignService.imageUrl(widget.applicationNo),
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Text('이미지 로드 실패'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 서명 보드
            _buildSignBoard(),

            const SizedBox(height: 10),

            // 툴바
            _Toolbar(
              busy: _saving,
              canUndo: _strokes.isNotEmpty && !_saving,
              canRedo: _redo.isNotEmpty && !_saving,
              canClear: _strokes.isNotEmpty && !_saving,
              eraser: _eraser,
              thickness: _thickness,
              onUndo: _undo,
              onRedo: _redoBtn,
              onEraserToggle: () => setState(() => _eraser = !_eraser),
              onThicknessChanged: (v) => setState(() => _thickness = v),
              onClearAll: _clearAll,
            ),

            const Spacer(),
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
                width: 16,
                height: 16,
                child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.check_rounded),
              label: const Text('제출'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignBoard() {
    return RepaintBoundary(
      key: _boardKey,
      child: AspectRatio(
        aspectRatio: 3.2, // 가로로 넓게
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9ECF1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (_, c) => GestureDetector(
                onPanStart: (d) => _onPanStart(d.localPosition),
                onPanUpdate: (d) => _onPanUpdate(d.localPosition),
                onPanEnd: (_) => _onPanEnd(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 가이드(중앙선 + 모서리 도트)
                    CustomPaint(painter: _GridPainter()),
                    // 실제 서명
                    CustomPaint(painter: _SignPainter(strokes: _strokes)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  내부 클래스들 (한 파일 안에 구현)
// ─────────────────────────────────────────────────────────────

class _Stroke {
  final List<Offset> points;
  final double width;
  final bool eraser;
  final Color color;
  _Stroke({
    required this.points,
    required this.width,
    required this.eraser,
    required this.color,
  });
}

class _SignPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _SignPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final layerRect = Offset.zero & size;
    // 지우개(BlendMode.clear) 처리를 위해 레이어
    canvas.saveLayer(layerRect, Paint());

    for (final s in strokes) {
      if (s.points.length < 2) continue;

      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (s.eraser) paint.blendMode = BlendMode.clear;

      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (int i = 1; i < s.points.length; i++) {
        final p0 = s.points[i - 1];
        final p1 = s.points[i];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SignPainter old) => old.strokes != strokes;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = const Color(0xFFEFF2F7)
      ..strokeWidth = 1;

    // 중앙 기준선
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      guide,
    );

    // 모서리 라운드 가이드 도트
    final dot = Paint()..color = const Color(0xFFE9ECF1);
    const r = 2.0;
    canvas.drawCircle(const Offset(14, 14), r, dot);
    canvas.drawCircle(Offset(size.width - 14, 14), r, dot);
    canvas.drawCircle(Offset(14, size.height - 14), r, dot);
    canvas.drawCircle(Offset(size.width - 14, size.height - 14), r, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Toolbar extends StatelessWidget {
  final bool busy;
  final bool canUndo, canRedo, canClear;
  final bool eraser;
  final double thickness;
  final VoidCallback onUndo, onRedo, onClearAll, onEraserToggle;
  final ValueChanged<double> onThicknessChanged;

  const _Toolbar({
    super.key,
    required this.busy,
    required this.canUndo,
    required this.canRedo,
    required this.canClear,
    required this.eraser,
    required this.thickness,
    required this.onUndo,
    required this.onRedo,
    required this.onClearAll,
    required this.onEraserToggle,
    required this.onThicknessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 버튼줄
        Row(
          children: [
            _iconBtn(Icons.undo_rounded, enabled: canUndo && !busy, onTap: onUndo),
            const SizedBox(width: 6),
            _iconBtn(Icons.redo_rounded, enabled: canRedo && !busy, onTap: onRedo),
            const SizedBox(width: 6),
            _toggleBtn(
              iconOn: Icons.cleaning_services_rounded, // 지우개
              iconOff: Icons.brush_rounded,            // 펜
              value: eraser,
              onTap: busy ? null : onEraserToggle,
            ),
            const Spacer(),
            _outlineBtn(
              label: '전체 지우기',
              enabled: canClear && !busy,
              onTap: onClearAll,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 두께 슬라이더 + 미리보기
        Row(
          children: [
            const Text('두께', style: TextStyle(fontSize: 12, color: Colors.black54)),
            Expanded(
              child: Slider(
                value: thickness,
                min: 1.5,
                max: 8.0,
                onChanged: busy ? null : onThicknessChanged,
              ),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              child: Container(
                width: thickness,
                height: thickness,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, {required bool enabled, VoidCallback? onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF5F6F8) : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE9ECF1)),
        ),
        child: Icon(icon, size: 20, color: enabled ? Colors.black87 : Colors.black26),
      ),
    );
  }

  Widget _toggleBtn({
    required IconData iconOn,
    required IconData iconOff,
    required bool value,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFFEEF6FF)
              : (enabled ? const Color(0xFFF5F6F8) : const Color(0xFFF8F9FB)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? const Color(0xFFB3D6FF) : const Color(0xFFE9ECF1),
          ),
        ),
        child: Icon(
          value ? iconOn : iconOff,
          size: 20,
          color: value ? const Color(0xFF1063D1) : (enabled ? Colors.black87 : Colors.black26),
        ),
      ),
    );
  }

  Widget _outlineBtn({required String label, required bool enabled, required VoidCallback onTap}) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: enabled ? Colors.black87 : Colors.black38,
          side: BorderSide(color: enabled ? const Color(0xFFD6DAE1) : const Color(0xFFE9ECF1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
