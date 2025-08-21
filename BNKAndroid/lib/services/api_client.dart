// services/api_client.dart
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

  final String baseUrl;
  final String? jwt;
  final Dio _dio;

  Future<Response> sendVerification({
    required File idImage,
    required File faceImage,
    required int applicationNo, // ✅ 서버에서 주민번호 조회용
  }) async {
    final form = FormData.fromMap({
      'idImage': await MultipartFile.fromFile(idImage.path, filename: 'id.jpg'),
      'faceImage': await MultipartFile.fromFile(faceImage.path, filename: 'face.jpg'),
      'applicationNo': applicationNo,
    });
    return _dio.post('/api/verify', data: form);
  }

  Future<Response> ocrIdOnly({required File idImage}) async {
    final form = FormData.fromMap({
      'idImage': await MultipartFile.fromFile(idImage.path, filename: 'id.jpg'),
    });
    return _dio.post('/api/verify/ocr', data: form);
  }
}
