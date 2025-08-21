// lib/user/service/api_client.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 401 발생 시 accessToken을 갱신해 한 번 재시도하는 Dio 기반 API 클라이언트
class ApiClient {
  ApiClient({
    required this.baseUrl,                 // 예: http://192.168.0.5:8090
    this.initialJwt,                       // 선택: 앱 최초 부팅 시 임시 토큰
    this.refreshPath = '/auth/refresh',    // 서버 엔드포인트에 맞게 변경
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
          ),
        ) {
    // 인터셉터: 매 요청마다 최신 토큰 첨부 + 401 한 번 재시도
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getAccessToken();
          // FormData일 수 있으니 Content-Type은 건드리지 않고 Authorization만 주입
          final hdr = options.headers;
          if (token != null && token.isNotEmpty) {
            hdr['Authorization'] = 'Bearer $token';
          } else if (initialJwt != null && initialJwt!.isNotEmpty) {
            hdr['Authorization'] = 'Bearer $initialJwt';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          if (_shouldTryRefresh(err)) {
            try {
              final newToken = await _refreshAccessToken();
              if (newToken != null && newToken.isNotEmpty) {
                final req = err.requestOptions;
                req.headers['Authorization'] = 'Bearer $newToken';
                req.extra['__retried'] = true; // 재귀 방지
                final resp = await _dio.fetch(req);
                return handler.resolve(resp);
              }
            } catch (_) {
              // 리프레시 실패 시 그대로 에러 전달
            }
          }
          handler.next(err);
        },
      ),
    );
  }

  // ========= 필드 =========
  final String baseUrl;
  final String? initialJwt;
  final String refreshPath;
  final Dio _dio;

  // ========= 공개 API =========

  /// 본인확인(신분증+얼굴+applicationNo)
  Future<Response<dynamic>> sendVerification({
    required File idImage,
    required File faceImage,
    required int applicationNo, // 서버에서 주민번호/가입자 조회 등에 사용
  }) async {
    final form = FormData.fromMap({
      'idImage': await MultipartFile.fromFile(idImage.path, filename: 'id.jpg'),
      'faceImage': await MultipartFile.fromFile(faceImage.path, filename: 'face.jpg'),
      'applicationNo': applicationNo,
    });
    return _dio.post('/api/verify', data: form);
  }

  /// 신분증만 OCR (이름/주민번호 일부/발급일 등 자동 채움)
  Future<Response<dynamic>> ocrIdOnly({required File idImage}) async {
    final form = FormData.fromMap({
      'idImage': await MultipartFile.fromFile(idImage.path, filename: 'id.jpg'),
    });
    return _dio.post('/api/verify/ocr', data: form);
  }

  /// 일반 GET
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }

  /// 일반 POST(JSON)
  Future<Response<dynamic>> postJson(String path, {Map<String, dynamic>? body}) {
    return _dio.post(path, data: body);
  }

  /// 수동으로 accessToken 저장
  Future<void> setAccessToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }

  // ========= 내부 유틸 =========

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    // 과거 키 호환
    return prefs.getString('accessToken') ?? prefs.getString('jwt_token');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  bool _shouldTryRefresh(DioException e) {
    final retried = (e.requestOptions.extra['__retried'] == true);
    return e.response?.statusCode == 401 && !retried;
  }

  /// accessToken 갱신 시도 (성공 시 prefs 저장 후 새 토큰 반환)
  Future<String?> _refreshAccessToken() async {
    final refresh = await _getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;

    // 인터셉터 영향 안 받도록 별도 Dio 사용
    final bare = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final res = await bare.post(refreshPath, data: {'refreshToken': refresh});
    final data = res.data;

    String? access;
    if (data is Map) {
      access = (data['accessToken'] ?? data['access'] ?? data['token'])?.toString();
    } else {
      access = data?.toString();
    }
    if (access == null || access.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', access);
    return access;
  }
}
