import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

class CustomCardEditorPage extends StatefulWidget {
  const CustomCardEditorPage({super.key});

  @override
  State<CustomCardEditorPage> createState() => _CustomCardEditorPageState();
}

class _CustomCardEditorPageState extends State<CustomCardEditorPage> {
  // ===== 카드/배경 상태 =====
  final GlobalKey _cardKey = GlobalKey();            // 카드 전체의 위치/크기 계산용
  final GlobalKey _repaintKey = GlobalKey();         // 저장(캡쳐)용
  ui.Image? _bgImage;                                 // 배경 이미지 (메모리상)
  ImageProvider? _bgProvider;                         // 배경 이미지 Provider (화면 표시용)
  Offset _bgOffset = Offset.zero;                     // 배경 위치(드래그)
  double _bgScale = 1.0;                              // 배경 확대/축소
  double _bgRotateDeg = 0.0;                          // 배경 회전(도)

  Color _cardBgColor = Colors.white;                  // 카드 배경색 (이미지 없는 경우)

  // ===== 텍스트/이모지 요소 =====
  int _seed = 0;
  int? _selectedId;
  final List<_TextElement> _elements = [];

  // ===== 하단 패널 토글 =====
  bool _showEmojiList = false;
  bool _showFontList = false;

  // ===== 폰트 프리셋 =====
  final List<_FontPreset> _fonts = [
    _FontPreset('기본', (size, color) => TextStyle(fontSize: size, color: color)), // 기본 폰트
    _FontPreset('Serif', (s, c) => GoogleFonts.notoSerif(fontSize: s, color: c)),
    _FontPreset('Mono', (s, c) => GoogleFonts.inconsolata(fontSize: s, color: c)),
    _FontPreset('Courier', (s, c) => GoogleFonts.courierPrime(fontSize: s, color: c)),
    _FontPreset('Comic', (s, c) => GoogleFonts.comicNeue(fontSize: s, color: c)),
    _FontPreset('Times', (s, c) => GoogleFonts.ptSerif(fontSize: s, color: c)),
  ];

  // ===== 이모지 목록 =====
  static const _emojis = [
    '😀','😂','😍','👍','🔥','🎉','💖','🐱','🌈','😎','🥳','🤩','🤔','😺'
  ];

  // =============== 유틸 ===============

  _TextElement? get _selected =>
      _elements.firstWhere((e) => e.id == _selectedId, orElse: () => _TextElement.none());

  void _deselectAll() {
    setState(() => _selectedId = null);
  }

  // 카드 위젯 크기/좌표 → 전역좌표 변환용
  Rect _cardRectGlobal() {
    final ctx = _cardKey.currentContext;
    if (ctx == null) return Rect.zero;
    final rb = ctx.findRenderObject() as RenderBox;
    final topLeft = rb.localToGlobal(Offset.zero);
    final size = rb.size;
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
  }

  // =============== 배경 처리 ===============

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _bgImage = frame.image;
      _bgProvider = MemoryImage(bytes);
      _bgOffset = Offset.zero;
      _bgScale = 1.0;
      _bgRotateDeg = 0.0;
      _cardBgColor = Colors.white; // 이미지 선택 시 배경색 의미 약화
    });
  }

  void _zoomInBg() {
    setState(() => _bgScale = (_bgScale + 0.1).clamp(0.3, 3.0));
  }

  void _zoomOutBg() {
    setState(() => _bgScale = (_bgScale - 0.1).clamp(0.3, 3.0));
  }

  void _resetAll() {
    setState(() {
      _bgOffset = Offset.zero;
      _bgScale = 1.0;
      _bgRotateDeg = 0.0;
      _cardBgColor = Colors.white;
      _selectedId = null;
    });
  }

  // =============== 요소(텍스트/이모지) 처리 ===============

  void _addText() {
    setState(() {
      final id = ++_seed;
      _elements.add(_TextElement(
        id: id,
        text: '새 텍스트 $id',
        offset: const Offset(20, 20),
        rotationDeg: 0,
        fontSize: 20,
        color: Colors.black,
        fontIndex: 0,
        isEditing: false,
      ));
      _selectedId = id;
    });
  }

  void _addEmoji(String emoji) {
    setState(() {
      final id = ++_seed;
      _elements.add(_TextElement(
        id: id,
        text: emoji,
        offset: const Offset(30, 30),
        rotationDeg: 0,
        fontSize: 24,
        color: Colors.black,
        fontIndex: 0,
        isEditing: false,
      ));
      _selectedId = id;
    });
  }

  void _removeSelected() {
    if (_selectedId == null) return;
    setState(() {
      _elements.removeWhere((e) => e.id == _selectedId);
      _selectedId = null;
    });
  }

  void _increaseFont() {
    final sel = _selected;
    if (sel == null || sel.id == -1) return;
    setState(() => sel.fontSize = (sel.fontSize + 2).clamp(10, 200).toDouble());
  }

  void _decreaseFont() {
    final sel = _selected;
    if (sel == null || sel.id == -1) return;
    setState(() => sel.fontSize = (sel.fontSize - 2).clamp(10, 200).toDouble());
  }

  void _pickFontColor() async {
    final sel = _selected;
    if (sel == null || sel.id == -1) return;

    Color temp = sel.color;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('글자 색상'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('적용')),
        ],
      ),
    );

    setState(() => sel.color = temp);
  }

  void _setBgColor() async {
    Color temp = _cardBgColor;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('배경 색상'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('적용')),
        ],
      ),
    );
    setState(() => _cardBgColor = temp);
  }

  void _applyFontIndexToSelected(int idx) {
    final sel = _selected;
    if (sel == null || sel.id == -1) return;
    setState(() => sel.fontIndex = idx.clamp(0, _fonts.length - 1));
  }

  // double tap / long press 로 편집 모드 토글
  void _toggleEdit(_TextElement el, {bool? force}) {
    setState(() => el.isEditing = force ?? !el.isEditing);
  }

  // 회전 핸들 드래그 시 각도 계산
  void _onRotateDrag(_TextElement el, DragUpdateDetails d, GlobalKey boxKey) {
    final cardRect = _cardRectGlobal();
    final boxCtx = boxKey.currentContext;
    if (boxCtx == null) return;
    final rb = boxCtx.findRenderObject() as RenderBox;
    final boxSize = rb.size;

    // 요소의 "화면 내 중심 전역좌표"
    final elementCenterGlobal = Offset(
      cardRect.left + el.offset.dx + boxSize.width / 2,
      cardRect.top + el.offset.dy + boxSize.height / 2,
    );

    final pointer = d.globalPosition;
    final dx = pointer.dx - elementCenterGlobal.dx;
    final dy = pointer.dy - elementCenterGlobal.dy;
    final deg = math.atan2(dy, dx) * 180 / math.pi;

    setState(() => el.rotationDeg = deg);
  }

  // =============== 저장: PNG로 갤러리에 저장 ===============

  Future<void> _saveCardAsImage() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image img = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 100,
        name: 'custom_card_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 완료: ${result['filePath'] ?? ''}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  // =============== 빌드 ===============

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('커스텀 카드 에디터')),
      body: GestureDetector(
        onTap: _deselectAll, // 빈 곳 탭하면 선택 해제
        child: Column(
          children: [
            // ---- 상단 컨트롤 바 ----
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton(onPressed: _addText, child: const Text('텍스트 추가')),
                  OutlinedButton(onPressed: _increaseFont, child: const Text('A+')),
                  OutlinedButton(onPressed: _decreaseFont, child: const Text('A-')),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _showFontList = !_showFontList;
                      _showEmojiList = false;
                    }),
                    child: const Text('🔤 폰트'),
                  ),
                  OutlinedButton(onPressed: _pickFontColor, child: const Text('T 색상')),
                  ElevatedButton.icon(
                    onPressed: _pickBackgroundImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('배경 이미지'),
                  ),
                  OutlinedButton(onPressed: _setBgColor, child: const Text('배경 색상')),
                  IconButton(onPressed: _zoomInBg, icon: const Icon(Icons.zoom_in)),
                  IconButton(onPressed: _zoomOutBg, icon: const Icon(Icons.zoom_out)),
                  TextButton(onPressed: _resetAll, child: const Text('초기화')),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('회전'),
                      SizedBox(
                        width: 140,
                        child: Slider(
                          min: -180,
                          max: 180,
                          value: _bgRotateDeg,
                          onChanged: (v) => setState(() => _bgRotateDeg = v),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _showEmojiList = !_showEmojiList;
                      _showFontList = false;
                    }),
                    child: const Text('😊 이모티콘'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveCardAsImage,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('카드 저장'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ---- 카드 영역 ----
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    key: _cardKey,
                    width: math.min(w * 0.9, 340),
                    // aspect-ratio 3:5
                    height: math.min(w * 0.9, 340) * (5 / 3),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _bgProvider == null ? _cardBgColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Stack(
                      children: [
                        // --- 배경 이미지 (드래그/줌/회전) ---
                        if (_bgProvider != null)
                          GestureDetector(
                            onPanUpdate: (d) => setState(() => _bgOffset += d.delta),
                            child: Center(
                              child: Transform.translate(
                                offset: _bgOffset,
                                child: Transform.rotate(
                                  angle: _bgRotateDeg * math.pi / 180,
                                  child: Transform.scale(
                                    scale: _bgScale,
                                    child: IgnorePointer(
                                      ignoring: true,
                                      child: Image(
                                        image: _bgProvider!,
                                        fit: BoxFit.cover,
                                        height: double.infinity,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // --- 요소(텍스트/이모지)들 ---
                        ..._elements.map((el) => _TextElementWidget(
                          element: el,
                          selected: el.id == _selectedId,
                          fontBuilder: _fonts[el.fontIndex].builder,
                          onTap: () => setState(() => _selectedId = el.id),
                          onDrag: (delta) => setState(() => el.offset += delta),
                          onStartEdit: () => _toggleEdit(el, force: true),
                          onSubmitEdit: (value) => setState(() {
                            el.text = value.isEmpty ? el.text : value;
                            el.isEditing = false;
                          }),
                          onDelete: _removeSelected,
                          onRotateDrag: (d, key) => _onRotateDrag(el, d, key),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---- 하단 패널: 폰트 / 이모지 ----
            if (_showFontList) _buildFontBar(),
            if (_showEmojiList) _buildEmojiBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFontBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xfff8f8f8),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => ChoiceChip(
          label: Text(_fonts[i].name),
          selected: _selected?.fontIndex == i,
          onSelected: (_) => _applyFontIndexToSelected(i),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _fonts.length,
      ),
    );
  }

  Widget _buildEmojiBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xfff0f0f0),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _addEmoji(_emojis[i]),
          child: Text(_emojis[i], style: const TextStyle(fontSize: 28)),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: _emojis.length,
      ),
    );
  }
}

// ===== 모델 =====
class _TextElement {
  _TextElement({
    required this.id,
    required this.text,
    required this.offset,
    required this.rotationDeg,
    required this.fontSize,
    required this.color,
    required this.fontIndex,
    required this.isEditing,
  });

  final int id;
  String text;
  Offset offset;
  double rotationDeg;
  double fontSize;
  Color color;
  int fontIndex;
  bool isEditing;

  static _TextElement none() => _TextElement(
    id: -1,
    text: '',
    offset: Offset.zero,
    rotationDeg: 0,
    fontSize: 16,
    color: Colors.black,
    fontIndex: 0,
    isEditing: false,
  );
}

class _FontPreset {
  final String name;
  final TextStyle Function(double size, Color color) builder;
  const _FontPreset(this.name, this.builder);
}

// ===== 텍스트 박스 위젯 =====
class _TextElementWidget extends StatefulWidget {
  const _TextElementWidget({
    required this.element,
    required this.selected,
    required this.fontBuilder,
    required this.onTap,
    required this.onDrag,
    required this.onRotateDrag,
    required this.onStartEdit,
    required this.onSubmitEdit,
    required this.onDelete,
  });

  final _TextElement element;
  final bool selected;
  final TextStyle Function(double, Color) fontBuilder;
  final VoidCallback onTap;
  final void Function(Offset delta) onDrag;
  final void Function(DragUpdateDetails details, GlobalKey boxKey) onRotateDrag;
  final VoidCallback onStartEdit;
  final void Function(String text) onSubmitEdit;
  final VoidCallback onDelete;

  @override
  State<_TextElementWidget> createState() => _TextElementWidgetState();
}

class _TextElementWidgetState extends State<_TextElementWidget> {
  final GlobalKey _boxKey = GlobalKey();
  late TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.element.text);
    _focus.addListener(() {
      if (!_focus.hasFocus && widget.element.isEditing) {
        widget.onSubmitEdit(_ctrl.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TextElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.text != widget.element.text) {
      _ctrl.text = widget.element.text;
    }
    if (widget.element.isEditing && !_focus.hasFocus) {
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.element;

    return Positioned(
      left: el.offset.dx,
      top: el.offset.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onStartEdit,         // 모바일: 길게 눌러 편집
        onDoubleTap: widget.onStartEdit,         // 데스크탑: 더블탭 편집
        onPanUpdate: (d) => widget.onDrag(d.delta),
        child: Transform.rotate(
          angle: el.rotationDeg * math.pi / 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 텍스트/에디터 본체
              Container(
                key: _boxKey,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: widget.selected
                    ? BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(4),
                )
                    : null,
                child: el.isEditing
                    ? ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 40, maxWidth: 220),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    style: widget.fontBuilder(el.fontSize, el.color),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    onSubmitted: (v) => widget.onSubmitEdit(v),
                  ),
                )
                    : Text(el.text, style: widget.fontBuilder(el.fontSize, el.color)),
              ),

              // 삭제(X) 버튼 - 우상단
              if (widget.selected)
                Positioned(
                  right: -14,
                  top: -14,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: _roundIcon(Colors.red, Icons.close, size: 18),
                  ),
                ),

              // 회전(⟳) 버튼 - 좌상단 (드래그 회전)
              if (widget.selected)
                Positioned(
                  left: -14,
                  top: -14,
                  child: GestureDetector(
                    onPanUpdate: (d) => widget.onRotateDrag(d, _boxKey),
                    child: _roundIcon(Colors.black54, Icons.rotate_right, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIcon(Color bg, IconData icon, {double size = 16}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
