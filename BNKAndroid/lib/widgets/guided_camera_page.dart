import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
      // 신분증은 후면, 얼굴은 전면 권장
      final camera = widget.mode == GuidedMode.face
          ? _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first)
          : _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first);

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
    } catch (_) {} finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _take() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final x = await _controller!.takePicture();
    if (!mounted) return;
    Navigator.pop(context, File(x.path));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == GuidedMode.idCard ? '신분증 촬영' : '얼굴 촬영';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!),
          IgnorePointer(
            child: CustomPaint(
              painter: _GuidePainter(mode: widget.mode),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _take,
                child: const Icon(Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter({required this.mode});
  final GuidedMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withOpacity(0.45);
    final clear = Paint()..blendMode = BlendMode.clear;
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(r, overlay);

    if (mode == GuidedMode.idCard) {
      // 신분증 가이드: 화면 가운데 가로 꽉 + 신분증 비율(약 1.58:1)
      final guideW = size.width * 0.88;
      final guideH = guideW / 1.58;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: r.center, width: guideW, height: guideH),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, clear);

      final border = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(rect, border);
    } else {
      // 얼굴 가이드: 원형
      final d = size.width * 0.70;
      final c = Offset(size.width / 2, size.height / 2.1);
      canvas.drawCircle(c, d / 2, clear);

      final border = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(c, d / 2, border);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
