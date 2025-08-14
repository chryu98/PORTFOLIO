// 예: lib/user/NaverMapPage.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class Branch {
  final int branchNo;
  final String branchName;
  final String branchTel;
  final String branchAddress;
  final double? latitude;
  final double? longitude;

  Branch({
    required this.branchNo,
    required this.branchName,
    required this.branchTel,
    required this.branchAddress,
    required this.latitude,
    required this.longitude,
  });

  // 숫자/문자/null 모두 안전하게 처리
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return double.tryParse(s);
    }
    return null;
  }

  factory Branch.fromJson(Map<String, dynamic> j) => Branch(
    branchNo: (j['branchNo'] as num).toInt(),
    branchName: (j['branchName'] ?? '') as String,
    branchTel: (j['branchTel'] ?? '') as String,
    branchAddress: (j['branchAddress'] ?? '') as String,
    latitude: _toDouble(j['latitude']),
    longitude: _toDouble(j['longitude']),
  );
}

class NaverMapPage extends StatefulWidget {
  const NaverMapPage({super.key});
  @override
  State<NaverMapPage> createState() => _NaverMapPageState();
}

class _NaverMapPageState extends State<NaverMapPage> {
  static const _channel = MethodChannel('bnk_naver_map_channel');




  void _onPlatformViewCreated(int id) {
    debugPrint('[Flutter] AndroidView created. id=$id');
    // 바로 핑 찍어보기 (안드 로직에 아래 3번의 "ping" 분기 추가해야 합니다)
    _channel.invokeMethod('ping', {'from': 'flutter'});
  }

  // ✅ 지도/데이터 준비 조율용
  bool _mapReady = false;
  bool _firstMarkersSent = false; // 최초 1회 전체 마커 전송 보장
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Branch> _all = [];
  List<Branch> _filtered = []; // 화면에 뿌리는 현재 리스트(검색 결과 포함)

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_onNativeCallback);
    _loadBranches(); // 전체 목록 로드 시작
  }

  // ─────────────────────────────────────────────────────────────
  // 1) 데이터 로드
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadBranches() async {
    final res = await http.get(Uri.parse('http://192.168.0.224:8090/api/branches'));
    if (res.statusCode != 200) {
      debugPrint('HTTP ${res.statusCode} body=${res.body}');
      throw Exception('API 실패: ${res.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded is List
        ? decoded
        : (decoded is Map
        ? (decoded['data'] ?? decoded['items'] ?? decoded['content'] ?? []) as List
        : []);

    final all = data.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
    final withCoord = all.where((b) => b.latitude != null && b.longitude != null).toList();

    setState(() {
      _all = all;
      _filtered = withCoord; // 기본은 전체 목록
    });

    // ✅ 데이터가 먼저 준비되었을 수 있으니, 최초 전송 시도
    _trySendAllOnce();
  }

  // ─────────────────────────────────────────────────────────────
  // 2) 최초 1회 전체 마커 전송 로직
  //    (지도 준비 & 데이터 준비가 둘 다 끝났을 때 단 한 번)
  // ─────────────────────────────────────────────────────────────
  void _trySendAllOnce() {
    if (_firstMarkersSent || !_mapReady || _filtered.isEmpty) return;
    _firstMarkersSent = true;
    _sendMarkers(_filtered, fitBounds: true, padding: 80);
  }

  // ─────────────────────────────────────────────────────────────
  // 3) 네이티브 호출: 마커/카메라
  //    - Android 쪽에 setMarkers → (필요 시) fitBounds or moveCamera 호출
  // ─────────────────────────────────────────────────────────────
  Future<void> _sendMarkers(List<Branch> items,
      {bool fitBounds = false, int padding = 80}) async {
    if (!_mapReady) return;

    final markers = items
        .where((b) => b.latitude != null && b.longitude != null)
        .map((b) => {
              'lat': b.latitude!,
              'lng': b.longitude!,
              'title': b.branchName,
              'snippet': '${b.branchTel}\n${b.branchAddress}',
            })
        .toList();

    // ✅ 여기서 로그 찍기
    debugPrint('[Flutter] sendMarkers size=${markers.length} fitBounds=$fitBounds');

    await _channel.invokeMethod('setMarkers', {'markers': markers});

    if (items.isEmpty) return;

    if (fitBounds && items.length > 1) {
      await _channel.invokeMethod('fitBounds', {
        'points': items
            .where((b) => b.latitude != null && b.longitude != null)
            .map((b) => {'lat': b.latitude!, 'lng': b.longitude!})
            .toList(),
        'padding': padding, // dp
      });
    } else if (items.length == 1) {
      final b = items.first;
      await _channel.invokeMethod('moveCamera', {
        'lat': b.latitude!,
        'lng': b.longitude!,
        'zoom': 16.0,
        'animate': true,
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4) 네이티브 → 플러터 콜백
  // ─────────────────────────────────────────────────────────────

  Future<dynamic> _onNativeCallback(MethodCall call) async {
    if (call.method == 'onMapReady') {
      if (!_mapReady) {
        setState(() => _mapReady = true);
        _trySendAllOnce();
      }
    }
    return null;
  }
  // ─────────────────────────────────────────────────────────────
  // 5) 검색
  //    - 빈 검색어: 전체 목록 복원 + fitBounds
  //    - 검색어 있음: 서버로 검색 → 결과 반영 + fitBounds
  // ─────────────────────────────────────────────────────────────
  int _reqSeq = 0; // 응답 역전 방지

  Future<void> _searchBranches(String keyword) async {
    final q = keyword.trim();
    final mySeq = ++_reqSeq;

    if (q.isEmpty) {
      // ✅ 전체 목록 복원
      final withCoord = _all.where((b) => b.latitude != null && b.longitude != null).toList();
      setState(() => _filtered = withCoord);
      await _sendMarkers(withCoord, fitBounds: true, padding: 80);
      return;
    }

    final uri = Uri.parse('http://192.168.0.224:8090/api/branches/search?q=$q');
    http.Response res;
    try {
      res = await http.get(uri);
    } catch (e) {
      debugPrint('검색 API 네트워크 오류: $e');
      return;
    }

    if (mySeq != _reqSeq) return; // 최신 요청만 반영

    if (res.statusCode != 200) {
      debugPrint('검색 API 실패: ${res.statusCode} body=${res.body}');
      return;
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is! List) {
      debugPrint('검색 API 응답 형식이 리스트가 아님: $decoded');
      return;
    }

    final results = decoded
        .map<Branch>((e) => Branch.fromJson(e as Map<String, dynamic>))
        .where((b) => b.latitude != null && b.longitude != null)
        .toList();

    setState(() => _filtered = results);
    await _sendMarkers(results, fitBounds: true, padding: 80);
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchBranches(q);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영업점 찾기')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '지점명으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: AndroidView(
              viewType: 'bnk_naver_map_view', // MainActivity/Factory와 동일
              creationParams: const {},
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated, // ← 추가
            ),
          ),
        ],
      ),
    );
  }
}
