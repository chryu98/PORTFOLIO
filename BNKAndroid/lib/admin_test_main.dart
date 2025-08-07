import 'package:flutter/material.dart';
import 'admin/screens/admin_login_screen.dart';
import 'admin/service/admin_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = AdminApiService();
  await apiService.init(); // 세션 불러오기

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AdminLoginScreen(apiService: apiService),
  ));
}
