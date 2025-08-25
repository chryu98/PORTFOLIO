// lib/user/NaverMapPage.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
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

class _NaverMapPageState extends State<NaverMapPage>
    with TickerProviderStateMixin {
  static const _channel = MethodChannel('bnk_naver_map_channel');

  void _onPlatformViewCreated(int id) {
    debugPrint('[Flutter] AndroidView created. id=$id');
    // 네이티브 핑 테스트(선택)
    _channel.invokeMethod('ping', {'from': 'flutter'});
  }

  // 지도/데이터 준비 플래그
  bool _mapReady = false;
  bool _firstMarkersSent = false;

  // 검색
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _reqSeq = 0;

  // 데이터
  List<Branch> _all = [];
  List<Branch> _filtered = []; // 현재 탭의 “전체/검색 결과”
  List<Branch> _nearby = [];   // 근처 영업점 (임시: 전체와 동일, 원하시면 현위치 반경 로직으로 교체)

  // 패널 스냅 포인트 (비율)
  final double _minSnap = 0.20;  // 바닥에 걸치기
  final double _midSnap = 0.50;  // 화면 중앙(절반)
  final double _maxSnap = 0.80;  // (옵션) 거의 전체

  double _panelFactor = 0.25;    // 초기 높이 비율
  double? _dragStartFactor;
  double? _dragStartDy;

  // 탭 제어 (‘전체/근처’ 전환에 사용)
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _channel.setMethodCallHandler(_onNativeCallback);
    _loadBranches();
  }

  // ─────────────────────────────────────────────────────────────
  // 1) 데이터 로드
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadBranches() async {
    final res =
    await http.get(Uri.parse('http://192.168.0.224:8090/api/branches'));
    if (res.statusCode != 200) {
      debugPrint('HTTP ${res.statusCode} body=${res.body}');
      throw Exception('API 실패: ${res.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded is List
        ? decoded
        : (decoded is Map
        ? (decoded['data'] ??
        decoded['items'] ??
        decoded['content'] ??
        []) as List
        : []);

    final all = data
        .map((e) => Branch.fromJson(e as Map<String, dynamic>))
        .toList();

    final withCoord =
    all.where((b) => b.latitude != null && b.longitude != null).toList();

    setState(() {
      _all = all;
      _filtered = withCoord;
      _nearby = withCoord; // 임시: 근처 = 전체. (현위치 기반으로 필터링 가능)
    });

    _trySendAllOnce();
  }

  // ─────────────────────────────────────────────────────────────
  // 2) 최초 1회 전체 마커 전송(지도/데이터 모두 준비됐을 때만)
  // ─────────────────────────────────────────────────────────────
  void _trySendAllOnce() {
    if (_firstMarkersSent || !_mapReady || _filtered.isEmpty) return;
    _firstMarkersSent = true;
    _sendMarkers(_filtered, fitBounds: true, padding: 80);
  }

  // ─────────────────────────────────────────────────────────────
  // 3) 네이티브 호출: 마커/카메라
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

    debugPrint('[Flutter] sendMarkers size=${markers.length} fitBounds=$fitBounds');

    await _channel.invokeMethod('setMarkers', {'markers': markers});

    if (items.isEmpty) return;

    if (fitBounds && items.length > 1) {
      await _channel.invokeMethod('fitBounds', {
        'points': items
            .where((b) => b.latitude != null && b.longitude != null)
            .map((b) => {'lat': b.latitude!, 'lng': b.longitude!})
            .toList(),
        'padding': padding,
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
  // ─────────────────────────────────────────────────────────────
  Future<void> _searchBranches(String keyword) async {
    final q = keyword.trim();
    final mySeq = ++_reqSeq;

    if (q.isEmpty) {
      final withCoord =
      _all.where((b) => b.latitude != null && b.longitude != null).toList();
      setState(() => _filtered = withCoord);
      await _sendMarkers(withCoord, fitBounds: true, padding: 80);
      return;
    }

    final uri =
    Uri.parse('http://192.168.0.224:8090/api/branches/search?q=$q');
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
  // ─────────────────────────────────────────────────────────────
  // 6) 위치기반
  // ─────────────────────────────────────────────────────────────

  /// 위·경도 간 거리(m) — 하버사인
  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0; // Earth radius (m)
    final dLat = (lat2 - lat1) * (3.141592653589793 / 180.0);
    final dLng = (lng2 - lng1) * (3.141592653589793 / 180.0);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(lat1 * (3.141592653589793 / 180.0)) *
                cos(lat2 * (3.141592653589793 / 180.0)) *
                (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// 내 위치 기준 근처 리스트 만들기 (상위 N개 혹은 반경 km)
  void _updateNearbyFrom(double myLat, double myLng) {
    final withCoord = _all.where((b) => b.latitude != null && b.longitude != null);
    final sorted = withCoord.toList()
      ..sort((a, b) {
        final da = _distanceMeters(myLat, myLng, a.latitude!, a.longitude!);
        final db = _distanceMeters(myLat, myLng, b.latitude!, b.longitude!);
        return da.compareTo(db);
      });

    // 2km 이내만, 없다면 상위 10개
    final nearby = sorted.where((b) =>
    _distanceMeters(myLat, myLng, b.latitude!, b.longitude!) <= 2000
    ).take(30).toList();
    setState(() {
      _nearby = nearby.isNotEmpty ? nearby : sorted.take(10).toList();
    });
  }

  /// 근처 탭으로 전환 + 패널을 중앙으로 열기
  void _openNearbyPanel() {
    _tabController.index = 1;                 // ‘근처 영업점’ 탭
    setState(() => _panelFactor = _midSnap);  // 패널 중앙까지 올리기
  }
  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1) 네이버 지도(네이티브)
          Positioned.fill(
            child: AndroidView(
              viewType: 'bnk_naver_map_view',
              creationParams: const {},
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            ),
          ),

          // 2) 스냅 패널 (손잡이 드래그로 높이 조절)
          _buildSnapPanel(context),

          // 3) 상단 고정 검색바(지도 위에 떠 있음)
          _buildTopSearchBar(context),
        ],
      ),
    );
  }

  Widget _buildSnapPanel(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Positioned(
      left: 0,
      right: 0,
      // AnimatedContainer로 부드럽게 높이 변화
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: (h * _panelFactor).clamp(h * _minSnap, h * _maxSnap),
        child: Material(
          elevation: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          child: Column(
            children: [
              // ====== 손잡이 영역 (여기를 잡고 드래그) ======
              GestureDetector(
                behavior: HitTestBehavior.translucent, // 빈 공간까지 터치 인식
                onVerticalDragStart: (d) {
                  _dragStartDy = d.globalPosition.dy;
                  _dragStartFactor = _panelFactor;
                },
                onVerticalDragUpdate: (d) {
                  if (_dragStartDy == null || _dragStartFactor == null) return;
                  final dy = d.globalPosition.dy - _dragStartDy!;
                  final deltaFactor = -dy / MediaQuery.of(context).size.height;
                  setState(() {
                    _panelFactor = (_dragStartFactor! + deltaFactor)
                        .clamp(_minSnap, _maxSnap);
                  });
                },
                onVerticalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  double target = _panelFactor;

                  if (v < -500) {
                    target = (_panelFactor < (_midSnap + _minSnap) / 2)
                        ? _midSnap
                        : _maxSnap;
                  } else if (v > 500) {
                    target = (_panelFactor > (_midSnap + _maxSnap) / 2)
                        ? _midSnap
                        : _minSnap;
                  } else {
                    final snaps = <double>[_minSnap, _midSnap];
                    target = snaps.reduce((a, b) =>
                    (a - _panelFactor).abs() < (b - _panelFactor).abs() ? a : b);
                  }

                  setState(() => _panelFactor = target);
                  _dragStartDy = null;
                  _dragStartFactor = null;
                },
                child: Container(
                  height: 40, // 👈 손잡이 터치 영역을 60~80 정도로 크게
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.black26,
                    ),
                  ),
                ),
              ),

              // ====== 탭 + 리스트 (리스트는 내부에서 독립 스크롤) ======
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TabBar(
                          controller: _tabController,  // ✅ DefaultTabController 대신 직접 만든 controller 연결
                          indicator: BoxDecoration(
                            color: Color(0xFFF83030),
                            borderRadius: BorderRadius.all(Radius.circular(18)),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black87,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,

                          // ⬇️ 글자 크기/굵기 키우기
                          labelStyle: const TextStyle(
                            fontSize: 16,            // 필요하면 17~18로 더 키워도 OK
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),

                          tabs: const [
                            Tab(text: '전체'),
                            Tab(text: '근처 영업점'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,  // ✅ TabBarView도 같은 컨트롤러로 연결
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildInnerList(_filtered),
                          _buildInnerList(_nearby),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildInnerList(List<Branch> items) {
    if (items.isEmpty) {
      return const Center(child: Text('표시할 영업점이 없습니다.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = items[i];
        return InkWell(
          onTap: () async {
            if (b.latitude != null && b.longitude != null) {
              // 선택한 지점만 마커 표시
              await _channel.invokeMethod('setMarkers', {
                'markers': [
                  {
                    'lat': b.latitude!,
                    'lng': b.longitude!,
                    'title': b.branchName,
                    'snippet': '${b.branchTel}\n${b.branchAddress}',
                  }
                ]
              });

              // 카메라는 적당한 줌으로 이동 (예: 17~18)
              await _channel.invokeMethod('moveCamera', {
                'lat': b.latitude!,
                'lng': b.longitude!,
                'zoom': 18.0,   // 👈 확대 수준 직접 조절
                'animate': true,
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.branchName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  '${b.branchTel}\n${b.branchAddress}',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.35),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 상단 검색바 오른쪽에 작은 동그란 버튼 하나 추가한 예
  Widget _buildTopSearchBar(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12), // ⬅️ top=0
          child: Row(
            children: [
              // ⬇️ 뒤로가기 버튼 (동그란 카드 스타일)
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                child: IconButton(
                  tooltip: '뒤로가기',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    // rootNavigator로 push했으니 동일 컨텍스트에서 pop 시도
                    final canPopRoot = await Navigator.of(context, rootNavigator: true).maybePop();
                    if (!canPopRoot && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 검색바
              Expanded(
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchCtrl,
                      builder: (context, value, _) {
                        final hasText = value.text.isNotEmpty;
                        return TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: '지역이나 장소를 입력하세요',
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: hasText
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                FocusScope.of(context).unfocus();
                                _onSearchChanged('');
                              },
                            )
                                : null,
                          ),
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 현위치 버튼
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                child: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _onPressMyLocation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// 현위치 버튼 핸들러
  Future<void> _onPressMyLocation() async {
    // 1) 권한 확인/요청
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 권한을 허용해 주세요.')),
      );
      return;
    }

    // 2) 현재 위치
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final lat = pos.latitude;
    final lng = pos.longitude;

    // 3) 네이티브에 내 위치 마커 표시 + 카메라 이동(줌 17.5~18 권장)
    await _channel.invokeMethod('setMyLocation', {
      'lat': lat,
      'lng': lng,
      'zoom': 17.5,
      'animate': true,
    });

    // 4) 근처 리스트 계산 & UI 열기
    _updateNearbyFrom(lat, lng);
    _openNearbyPanel();
  }



}
