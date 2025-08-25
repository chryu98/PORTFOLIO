import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:http_parser/http_parser.dart';
import 'package:bnkandroid/user/custom_benefit_page.dart';

const String apiPublicBase = 'http://192.168.0.5:8090/api/custom-cards';
const String aiModerateUrl = 'http://192.168.0.5:8001/moderate';

class CustomCardEditorPage extends StatefulWidget {
  final int memberNo;
  const CustomCardEditorPage({super.key,  required this.memberNo});

  @override
  State<CustomCardEditorPage> createState() => _CustomCardEditorPageState();
}

class _CustomCardEditorPageState extends State<CustomCardEditorPage> {
  bool get _hasSelection => _selectedId != null && _selected?.id != -1;
  bool _bgEditMode = true; // 배경 편집 모드 토글

  String _activeBottom = '배경'; // 기본은 배경 선택 상태

  Future<Uint8List> _captureCardPngBytes() async {
    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image img = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ===== 카드/배경 상태 =====
  final GlobalKey _cardKey = GlobalKey();            // 카드 전체의 위치/크기 계산용
  final GlobalKey _repaintKey = GlobalKey();         // 저장(캡쳐)용
  ui.Image? _bgImage;                                // 배경 이미지 (메모리상)
  ImageProvider? _bgProvider;                        // 배경 이미지 Provider (화면 표시용)
  Offset _bgOffset = Offset.zero;                    // 배경 위치(드래그)
  double _bgScale = 1.0;                             // 배경 확대/축소
  double _bgRotateDeg = 0.0;                         // 배경 회전(도)
  Color _cardBgColor = Colors.white;                 // 배경색(이미지와 병행)

  // 핀치 제스처용 베이스 값
  double _baseScale = 1.0;
  double _baseRotationDeg = 0.0;

  // ===== 텍스트/이모지 요소 =====
  int _seed = 0;
  int? _selectedId;
  final List<_TextElement> _elements = [];

  // ===== 하단 패널 토글 =====
  bool _showEmojiList = false;
  bool _showFontList = false;
  bool _submitting = false;

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
    setState(() {
      _selectedId = null;
      _bgEditMode = false; // 빈 곳 탭 시 배경 모드 종료(대기 상태)
    });
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
      // 배경색은 유지
    });
  }

  void _resetAll() {
    setState(() {
      // 배경 관련
      _bgImage = null;
      _bgProvider = null;
      _bgOffset = Offset.zero;
      _bgScale = 1.0;
      _bgRotateDeg = 0.0;

      // 배경색 초기화
      _cardBgColor = Colors.white;

      // 요소(텍스트/이모지)
      _elements.clear();
      _selectedId = null;

      // 하단 패널 토글들 닫기
      _showEmojiList = false;
      _showFontList = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카드를 초기화했습니다.')),
      );
    }
  }

  Future<void> _confirmAndReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('초기화'),
        content: const Text('텍스트, 이모티콘, 배경 이미지/색을 모두 삭제합니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (ok == true) _resetAll();
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
      _bgEditMode = false; // 텍스트 추가 후 상단 툴바를 "텍스트 전용"으로 전환
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
      _bgEditMode = false; // 이모지 추가 후에도 텍스트 전용 툴바로
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
     showDialog(
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

  // 회전 핸들 드래그 시 각도 계산 (텍스트 요소용)
  void _onRotateDrag(_TextElement el, DragUpdateDetails d, GlobalKey boxKey) {
    final cardRect = _cardRectGlobal();
    final boxCtx = boxKey.currentContext;
    if (boxCtx == null) return;
    final rb = boxCtx.findRenderObject() as RenderBox;
    final boxSize = rb.size;

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

      final result = await ImageGallerySaverPlus.saveImage(pngBytes);

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
      backgroundColor: const Color(0xFF111216), // 🔸 어두운 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFF111216),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('커스텀 카드 에디터'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ───── 상단 툴바 ─────
            _buildTopToolbar(),

            const SizedBox(height: 8),

            // ───── 카드 영역 ─────
            Expanded(
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0D0E),  // 카드 주변 배경 더 어둡게
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: Container(
                        key: _cardKey,
                        width: math.min(w * 0.9, 340),
                        height: math.min(w * 0.9, 340) * (5 / 3), // 3:5 비율
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: _cardBgColor, // ✅ 항상 선택한 배경색 사용
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 18,
                              spreadRadius: 2,
                              color: Colors.black54,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 배경 (한 손가락: 이동, 두 손가락: 확대/축소 + 회전)
                            if (_bgProvider != null)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,

                                  onScaleStart: (details) {
                                    _baseScale = _bgScale;
                                    _baseRotationDeg = _bgRotateDeg;
                                  },

                                  onScaleUpdate: (details) {
                                    setState(() {
                                      if (details.pointerCount == 1) {
                                        // 한 손가락: 이동
                                        _bgOffset += details.focalPointDelta;
                                      } else if (details.pointerCount == 2) {
                                        // 두 손가락: 확대/축소 + 회전
                                        _bgScale = (_baseScale * details.scale).clamp(0.3, 3.0);
                                        _bgRotateDeg =
                                            _baseRotationDeg + (details.rotation * 180 / math.pi);
                                      }
                                    });
                                  },

                                  child: Transform.translate(
                                    offset: _bgOffset,
                                    child: Transform.rotate(
                                      angle: _bgRotateDeg * math.pi / 180,
                                      child: Transform.scale(
                                        scale: _bgScale,
                                        child: Image(
                                          image: _bgProvider!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // 요소(텍스트/이모티콘)
                            ..._elements.map((el) => _TextElementWidget(
                              element: el,
                              selected: el.id == _selectedId,
                              fontBuilder: _fonts[el.fontIndex].builder,
                              onTap: () => setState(() {
                                _selectedId = el.id;
                                _bgEditMode = false; // 텍스트/이모지 선택 시 배경 편집 모드 종료
                              }),
                              onDrag: (delta) => setState(() => el.offset += delta),
                              onStartEdit: () => _toggleEdit(el, force: true),
                              onSubmitEdit: (value) => setState(() {
                                el.text = value.isEmpty ? el.text : value;
                                el.isEditing = false;
                              }),
                              onDelete: _removeSelected,
                              onRotateDrag: (d, key) => _onRotateDrag(el, d, key),
                            )),

                            // 오버레이 자산
                            Positioned(
                              top: 20,
                              left: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Image.asset(
                                  'assets/custommag.png',
                                  width: 60,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Image.asset(
                                'assets/customlogo.png',
                                width: 80,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 폰트/이모티콘 패널(토글)
            if (_showFontList) _buildFontBar()
            else if (_showEmojiList) _buildEmojiBar(),

            // ───── 하단 액션 바 ─────
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF15171A),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: _bgEditMode
          ? _buildTopToolbarForBackground() // 배경 모드
          : (_hasSelection
          ? _buildTopToolbarForText()     // 텍스트/이모지 선택 시
          : _buildTopToolbarIdle()),      // 기본(대기) 모드
    );
  }

  // ✅ 슬라이더 제거 버전
  Widget _buildTopToolbarForBackground() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chipBtn('완료', onTap: () => setState(() => _bgEditMode = false)),
          _chipBtnIcon(Icons.image_outlined, '배경 이미지', onTap: _pickBackgroundImage),
          _chipBtn('배경 색상', onTap: _setBgColor),
          _chipBtn('위치 초기화', onTap: () => setState(() => _bgOffset = Offset.zero)),
        ],
      ),
    );
  }

  Widget _buildTopToolbarIdle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        children: [
          _chipBtn('초기화', onTap: _confirmAndReset),
        ],
      ),
    );
  }

  Widget _buildTopToolbarForText() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chipBtn('A+', onTap: _increaseFont),
          _chipBtn('A-', onTap: _decreaseFont),
          _chipBtn('🔤 폰트', onTap: () => setState(() {
            _showFontList = !_showFontList;
            _showEmojiList = false;
          })),
          _chipBtn('T 색상', onTap: _pickFontColor),
          _chipBtn('삭제', onTap: _removeSelected),
          _chipBtn('편집', onTap: () {
            final sel = _selected;
            if (sel != null && sel.id != -1) _toggleEdit(sel, force: true);
          }),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF15171A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _actionItem(Icons.text_fields, '텍스트', _addText),
            _actionItem(Icons.layers, '배경', () {
              setState(() {
                _bgEditMode = true;     // 상단 툴바를 배경 모드로
                _selectedId = null;     // 요소 선택 해제
              });
            }),
            _actionItem(Icons.emoji_emotions, '이모티콘', () => setState(() {
              _showEmojiList = !_showEmojiList; _showFontList = false;
            })),
            _actionItem(Icons.download, '이미지', _saveCardAsImage),
            _actionItem(Icons.check_circle, '디자인 결정', _finishDesign),

          ],
        ),
      ),
    );
  }

  Future<void> _finishDesign() async {
    if (_submitting) return; // 중복 실행 방지
    _submitting = true;

    // 1) 진행 다이얼로그 보여주기(대기 없이 표시)
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.black87,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'AI 부적절한 이미지를 검증중입니다.\n잠시만 기다려주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    // UI가 먼저 그려지도록 한 프레임 양보
    await Future.delayed(const Duration(milliseconds: 50));

    const timeoutShort = Duration(seconds: 15);
    const timeoutLong  = Duration(seconds: 20);

    try {
      // 2) 카드 PNG 캡처
      final pngBytes = await _captureCardPngBytes();

      // 3) 카드 저장 → customNo 획득
      final req = http.MultipartRequest('POST', Uri.parse(apiPublicBase))
        ..fields['memberNo'] = widget.memberNo.toString()
        ..fields['customService'] = '우대금리 + 영화예매 1천원 할인'
        ..files.add(http.MultipartFile.fromBytes(
          'image', pngBytes,
          filename: 'card.png',
          contentType: MediaType('image', 'png'),
        ));

      final streamed = await req.send().timeout(timeoutLong);
      final saveRes  = await http.Response.fromStream(streamed);

      debugPrint('[SAVE] ${saveRes.statusCode} ${saveRes.body}');
      if (saveRes.statusCode != 201) {
        throw Exception('저장 실패: ${saveRes.statusCode} ${saveRes.body}');
      }
      final customNo = (json.decode(saveRes.body)['customNo'] as num).toInt();

      // 4) AI 서버 검증 (multipart 기준)
      final modReq = http.MultipartRequest('POST', Uri.parse(aiModerateUrl))
        ..fields['customNo'] = customNo.toString()
        ..fields['memberNo'] = widget.memberNo.toString()
        ..files.add(http.MultipartFile.fromBytes(
          'image', pngBytes,
          filename: 'card.png',
          contentType: MediaType('image', 'png'),
        ));
      final modStream = await modReq.send().timeout(timeoutLong);
      final modRes    = await http.Response.fromStream(modStream);

      debugPrint('[AI] ${modRes.statusCode} ${modRes.body}');
      if (modRes.statusCode != 200) {
        throw Exception('AI 검증 실패: ${modRes.statusCode} ${modRes.body}');
      }
      final mod      = json.decode(modRes.body) as Map<String, dynamic>;
      final decision = ((mod['decision'] ?? mod['result']) ?? 'ACCEPT').toString().toUpperCase();
      final reason   = (mod['reason'] ?? 'OK').toString();

      // 5) 결과 기록 (스프링에 /api/custom-cards/{customNo}/ai 가 꼭 있어야 함)
      final uriAi = Uri.parse('$apiPublicBase/$customNo/ai');
      final aiRes = await http.post(
        uriAi,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'aiResult': decision,            // 'ACCEPT' / 'REJECT'
          'aiReason': _humanReadable(reason),
        }),
      ).timeout(timeoutShort);

      debugPrint('[AI-UPDATE] ${aiRes.statusCode} ${aiRes.body}');
      if (aiRes.statusCode != 200) {
        // 404가 난다면 백엔드에 해당 엔드포인트 추가 필요!
        throw Exception('AI 결과 저장 실패: ${aiRes.statusCode}');
      }

      // 6) 진행 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // 7) 안내 & 분기
      if (decision == 'REJECT') {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('사용자 불허'),
            content: Text('부적절한 이미지가 감지되었습니다.\n사유: ${_humanReadable(reason)}'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
            ],
          ),
        );
        return;
      }

      // ✅ 통과
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('통과'),
          content: Text('심사가 끝났습니다. 혜택 편집 페이지로 이동합니다.'),
        ),
      );
      if (!mounted) return;

      // 8) 혜택 페이지로 이동 (스택 정리하며 교체)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CustomBenefitPage(
            applicationNo: null,        // 새 작성이면 null 권장 (아래 2번 참고)
            customNo: customNo,         // 방금 저장한 커스텀 번호
            memberNo: widget.memberNo,  // 🔹에디터가 들고 있는 회원번호 전달
            allowEditBeforeApproval: true,
          ),
        ),
      );
    } catch (e) {
      // 에러 시 진행 다이얼로그가 떠있다면 닫아주기
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      _submitting = false;
    }
  }



// “VIOLENCE_GUN” → “총 이미지 노출” 등 보기 좋게
  String _humanReadable(String reason) {
    final r = reason.toUpperCase();
    if (r.contains('GUN'))   return '총 이미지 노출';
    if (r.contains('KNIFE')) return '칼 이미지 노출';
    return reason; // 기본
  }






  Widget _chipBtn(String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2126),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _chipBtnIcon(IconData icon, String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2126),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, VoidCallback onTap) {
    final bool isActive = _activeBottom == label;


    return InkWell(
      onTap: () {
        setState(() {
          _activeBottom = label; // 눌린 항목을 active 상태로 기록
        });
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? Colors.white : Colors.white70,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryActionItem(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB91111), // BNK 레드 톤
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
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


//김성훈 수정
class _AiDecision {
  final bool allow;     // 통과 여부
  final String? reason; // 불허 사유 (총/칼 등)
  _AiDecision(this.allow, this.reason);
}

Future<_AiDecision> _runAiModeration(Uint8List pngBytes) async {
  // 기본: multipart 업로드로 /moderate 호출, 응답 예시: { "result":"ACCEPT"|"REJECT", "reason":"총, 칼" }
  final uri = Uri.parse(aiModerateUrl);
  final req = http.MultipartRequest('POST', uri)
    ..files.add(http.MultipartFile.fromBytes(
      'image', pngBytes,
      filename: 'card.png',
      contentType: MediaType('image', 'png'),
    ));

  final streamed = await req.send();
  final res = await http.Response.fromStream(streamed);

  if (res.statusCode >= 300) {
    // 서버 오류 시 안전하게 불허 처리
    return _AiDecision(false, '서버 응답 오류(${res.statusCode})');
  }

  // JSON 파싱 (result/decision 필드 어느 쪽이든 허용)
  try {
    final Map<String, dynamic> j = json.decode(res.body);
    final result = (j['result'] ?? j['decision'] ?? '').toString().toUpperCase();
    final reason = j['reason']?.toString();
    final allow = result == 'ACCEPT' || result == 'ALLOW' || result == 'OK';
    return _AiDecision(allow, allow ? null : (reason ?? '정책 위반 이미지'));
  } catch (_) {
    // 파싱 실패 시도 불허
    return _AiDecision(false, '응답 파싱 실패');
  }
}

void _showProgressDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
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

  static const double _kHandlePad = 20; // 버튼이 들어갈 여유 공간

  @override
  Widget build(BuildContext context) {
    final el = widget.element;

    return Positioned(
      left: el.offset.dx,
      top: el.offset.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onStartEdit,
        onDoubleTap: widget.onStartEdit,
        child: Transform.rotate(
          angle: el.rotationDeg * math.pi / 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                key: _boxKey,
                padding: const EdgeInsets.all(_kHandlePad),
                child: GestureDetector(
                  onPanUpdate: (d) => widget.onDrag(d.delta), // 요소 이동 제스처
                  child: Container(
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
                        onSubmitted: widget.onSubmitEdit,
                      ),
                    )
                        : Text(el.text, style: widget.fontBuilder(el.fontSize, el.color)),
                  ),
                ),
              ),

              if (widget.selected)
                Positioned(
                  right: 2,
                  top: 2,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: _roundIcon(Colors.red, Icons.close, size: 18),
                  ),
                ),

              if (widget.selected)
                Positioned(
                  left: 2,
                  top: 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) => widget.onRotateDrag(d, _boxKey),
                    child: _roundIcon(Colors.black54, Icons.rotate_right, size: 18),
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
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
