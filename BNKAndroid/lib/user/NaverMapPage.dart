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
  static const _channel = MethodChannel('naver_map_channel');
  bool _mapReady = false; // ✅ 추가

  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Branch> _all = [];
  List<Branch> _filtered = [];

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_onNativeCallback);
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final res = await http.get(Uri.parse('http://192.168.0.224:8090/api/branches'));
    if (res.statusCode != 200) {
      debugPrint('HTTP ${res.statusCode} body=${res.body}');
      throw Exception('API 실패: ${res.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded is List
        ? decoded
        : (decoded is Map ? (decoded['data'] ?? decoded['items'] ?? decoded['content'] ?? []) as List : []);

    final all = data.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
    final withCoord = all.where((b) => b.latitude != null && b.longitude != null).toList();

    setState(() {
      _all = all;
      _filtered = withCoord;
    });

    // 지도가 준비된 경우에만 전송. (준비 전이면 onMapReady에서 전송됨)
    if (_mapReady) {
      await _sendMarkers(withCoord, fitBounds: true);
    }
  }


  Future<void> _sendMarkers(List<Branch> items, {bool fitBounds = false}) async {
    if (!_mapReady) return; // ✅ 준비 전 호출 방지
    final markers = items
        .where((b) => b.latitude != null && b.longitude != null)
        .map((b) => {
      'lat': b.latitude!,
      'lng': b.longitude!,
      'title': b.branchName,
      'snippet': '${b.branchTel}\n${b.branchAddress}',
    })
        .toList();

    await _channel.invokeMethod('setMarkers', {'markers': markers});

    if (items.isEmpty) return;

    if (fitBounds && items.length > 1) {
      await _channel.invokeMethod('fitBounds', {
        'points': items
            .where((b) => b.latitude != null && b.longitude != null)
            .map((b) => {'lat': b.latitude!, 'lng': b.longitude!})
            .toList(),
        'padding': 80, // dp
      });
    } else if (items.length == 1) {
      final b = items.first;
      await _channel.invokeMethod('moveCamera', {
        'lat': b.latitude!,   // ✅ 널 아님이 보장된 시점
        'lng': b.longitude!,
        'zoom': 16.0,
        'animate': true,
      });
    }
  }

  Future<dynamic> _onNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onMapReady':
        if (!_mapReady) {
          setState(() => _mapReady = true);
          // 지도가 준비된 시점에 현재 필터된 마커들을 반영
          await _sendMarkers(_filtered, fitBounds: true);
        }
        return null;
      default:
        return null;
    }
  }

  // ✅ 서버 검색 전용: 검색어로 Spring 검색 API 호출 → 마커 갱신
  int _reqSeq = 0; // 응답 선행/지연 뒤바뀜 방지용

  Future<void> _searchBranches(String keyword) async {
    final q = keyword.trim();
    final mySeq = ++_reqSeq;

    // 빈 검색어면 전체목록
    if (q.isEmpty) {
      final withCoord = _all.where((b) => b.latitude != null && b.longitude != null).toList();
      setState(() => _filtered = withCoord);
      await _sendMarkers(withCoord, fitBounds: true);
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

    // 최신 요청이 아니면 무시(느린 응답 역전 방지)
    if (mySeq != _reqSeq) return;

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
        .where((b) => b.latitude != null && b.longitude != null) // 혹시 모를 안전장치
        .toList();

    setState(() => _filtered = results);
    await _sendMarkers(results, fitBounds: true);
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchBranches(q); // ✅ 로컬 필터링 대신 서버 호출
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
                hintText: '지점명/주소/전화로 검색',
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
            // 기존 네이티브 플랫폼뷰 호출
            child: const AndroidView(
              viewType: 'naver_map_view', // MainActivity/Factory에서 등록한 viewType과 동일
              creationParams: {},
              creationParamsCodec: StandardMessageCodec(),
            ),
          ),
        ],
      ),
    );
  }
}
