import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GuidedMode { idCard, face }

class GuidedCameraPage extends StatefulWidget {
  const GuidedCameraPage({super.key, required this.mode});
  final GuidedMode mode;

  @override
  State<GuidedCameraPage> createState() => _GuidedCameraPageState();
}

class _GuidedCameraPageState extends State<GuidedCameraPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _busy = true;
  bool _torch = false;

  // 고정 줌(사용자 제스처 비활성)
  double _zoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  @override
  void initState() {
    super.initState();
    // ✅ 둘 다 세로 고정(회전 이슈 근절)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _init() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();

      final cam = widget.mode == GuidedMode.face
          ? _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      )
          : _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        cam,
        widget.mode == GuidedMode.idCard
            ? ResolutionPreset.medium   // 신분증: 용량/속도 밸런스
            : ResolutionPreset.high,    // 얼굴: 조금 더 선명
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // 줌 한계
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();

      // ✅ 초기 고정 줌(신분증은 조금 더 당겨서 인식 안정화)
      final desired = widget.mode == GuidedMode.idCard ? 2.0 : 1.3;
      _zoom = desired.clamp(_minZoom, _maxZoom);
      await _controller!.setZoomLevel(_zoom);

      // 플래시는 기본 Off
      if (_controller!.value.flashMode != FlashMode.off) {
        await _controller!.setFlashMode(FlashMode.off);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.description.lensDirection != CameraLensDirection.back) return;
    _torch = !_torch;
    await _controller!.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() {});
  }

  Future<void> _tapToFocus(TapDownDetails d, BoxConstraints cons) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final nx = (d.localPosition.dx / cons.maxWidth).clamp(0.0, 1.0);
    final ny = (d.localPosition.dy / cons.maxHeight).clamp(0.0, 1.0);
    try {
      await _controller!.setFocusPoint(Offset(nx, ny));
      await _controller!.setExposurePoint(Offset(nx, ny));
    } catch (_) {}
  }

  Future<void> _take() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final x = await _controller!.takePicture();
    if (!mounted) return;
    Navigator.pop(context, File(x.path));
  }

  /// ▶︎ 하드웨어/제스처 뒤로가기를 허용하고, 나가기 전에 토치가 켜져 있으면 끕니다.
  Future<bool> _onWillPop() async {
    try {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          _controller!.description.lensDirection == CameraLensDirection.back &&
          _torch) {
        await _controller!.setFlashMode(FlashMode.off);
        _torch = false;
      }
    } catch (_) {
      // 무시: 일부 단말에서 초기화 중 종료 시 에러 발생 가능
    }
    return true; // ← 시스템 뒤로가기 허용
  }

  /// 실제 센서 비율에 맞춘 프리뷰 + 화면 채우기
  Widget _previewCovered() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final ar = _controller!.value.aspectRatio; // width/height
    return LayoutBuilder(
      builder: (context, cons) {
        // 센서 비율대로 캔버스 잡고, scale로 화면 꽉 채움
        final previewH = cons.maxHeight;
        final previewW = previewH * ar;
        final coverScale = (cons.maxWidth / previewW).clamp(1.0, 3.0);

        return Center(
          child: Transform.scale(
            scale: coverScale,
            alignment: Alignment.center,
            child: SizedBox(
              width: previewW,
              height: previewH,
              child: CameraPreview(_controller!),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBack = _controller?.description.lensDirection == CameraLensDirection.back;

    return WillPopScope(
      onWillPop: _onWillPop, // ← 하드웨어 뒤로가기 허용
      child: Scaffold(
        appBar: AppBar(
          // 상단 버튼도 필요하면 유지, 원치 않으면 다음 두 줄 삭제 가능
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final allow = await _onWillPop();
              if (!mounted) return;
              if (allow) Navigator.of(context).maybePop();
            },
          ),
          title: Text(widget.mode == GuidedMode.idCard ? '신분증 촬영' : '얼굴 촬영'),
          toolbarHeight: 44,
          actions: [
            if (isBack)
              IconButton(
                tooltip: _torch ? '플래시 끄기' : '플래시 켜기',
                onPressed: _toggleTorch,
                icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
              ),
          ],
        ),
        body: _busy
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
          builder: (context, cons) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _tapToFocus(d, cons),
            // ⛔ 핀치/더블탭 줌 비활성(미리보기-촬영 화각 불일치 유발 방지)
            child: Stack(
              fit: StackFit.expand,
              children: [
                _previewCovered(),

                // 안내
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.mode == GuidedMode.idCard
                            ? '카드를 브래킷(모서리 ㄱ자)에 정확히 맞춰주세요'
                            : '얼굴을 원 안에 맞추고 눈높이를 선에 맞춰주세요',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),

                // 오버레이
                IgnorePointer(
                  child: widget.mode == GuidedMode.idCard
                      ? const _IdBracketOverlay()
                      : const _FaceGuideOverlay(),
                ),

                // 셔터
                Positioned(
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _take,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── 오버레이들 ───────────────────────────────────────────────────────────────

class _IdBracketOverlay extends StatelessWidget {
  const _IdBracketOverlay({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _IdBracketPainter());
}

class _IdBracketPainter extends CustomPainter {
  static const ratio = 1.585; // ISO/ID 카드 가로:세로

  @override
  void paint(Canvas canvas, Size size) {
    final layer = Offset.zero & size;

    // 화면 높이의 80% → 가로는 비율, 폭 92% 초과 시 폭에 맞춤
    double h = size.height * 0.80;
    double w = h * ratio;
    if (w > size.width * 0.92) {
      w = size.width * 0.92;
      h = w / ratio;
    }
    final rect = Rect.fromCenter(center: layer.center, width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // 바깥 약한 딤 + 중앙 clear
    canvas.saveLayer(layer, Paint());
    final dim = Paint()..color = Colors.black.withOpacity(0.20);
    canvas.drawRect(layer, dim);
    final clear = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(rr, clear);
    canvas.restore();

    // 모서리 브래킷
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    const L = 26.0;

    void bracket(bool left, bool top) {
      final x = left ? rect.left : rect.right;
      final y = top ? rect.top : rect.bottom;
      final dx = left ? L : -L;
      final dy = top ? L : -L;
      canvas.drawLine(Offset(x, y), Offset(x + dx, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy), p);
    }

    bracket(true,  true);
    bracket(false, true);
    bracket(true,  false);
    bracket(false, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FaceGuideOverlay extends StatelessWidget {
  const _FaceGuideOverlay({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _FaceGuidePainter());
}

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final layer = Offset.zero & size;

    canvas.saveLayer(layer, Paint());
    final dim = Paint()..color = Colors.black.withOpacity(0.25);
    canvas.drawRect(layer, dim);

    final d = size.shortestSide * 0.72; // 살짝 더 큼
    final c = Offset(size.width / 2, size.height * 0.42);
    final clear = Paint()..blendMode = BlendMode.clear;
    canvas.drawOval(Rect.fromCircle(center: c, radius: d / 2), clear);
    canvas.restore();

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(c, d / 2, border);

    final eye = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(c.dx - d * 0.46, c.dy),
      Offset(c.dx + d * 0.46, c.dy),
      eye,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
