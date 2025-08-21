import 'dart:io';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required this.baseUrl, this.jwt})
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  )) {
    if (jwt != null && jwt!.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $jwt';
    }
  }

  final String baseUrl; // 예: http://192.168.0.5:8090
  final String? jwt;
  final Dio _dio;

  Future<Response<dynamic>> sendVerification({
    required File idImage,
    required File faceImage,
    required String encryptedRrn,
    required String userNo,
  }) async {
    final form = FormData.fromMap({
      'idImage': await MultipartFile.fromFile(idImage.path, filename: 'id.jpg'),
      'faceImage': await MultipartFile.fromFile(faceImage.path, filename: 'face.jpg'),
      'encryptedRrn': encryptedRrn,
      'userNo': userNo,
    });
    return _dio.post('/api/verify', data: form);
  }

  // ✅ 신분증만 먼저 보내서 OCR로 주민번호 추출(자동 채움용)
  Future<Response<dynamic>> ocrIdOnly({required File idImage}) async {
    final form = FormData.fromMap({
      'idImage': await MultipartFile.fromFile(idImage.path, filename: 'id.jpg'),
    });
    // 스프링을 타고 파이썬으로 프록시하는 엔드포인트(권장)
    return _dio.post('/api/verify/ocr', data: form);
    // 만약 스프링 엔드포인트가 아직 없으면 파이썬 직접 호출도 임시로 가능:
    // final dio2 = Dio(BaseOptions(baseUrl: 'http://192.168.0.5:8000'));
    // return dio2.post('/ocr-id', data: form);
  }
}
