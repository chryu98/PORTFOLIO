import 'package:flutter/material.dart';
import '../service/admin_api_service.dart';

class AdminMainScreen extends StatefulWidget {
  final AdminApiService apiService;

  const AdminMainScreen({super.key, required this.apiService});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  String? adminName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    try {
      await widget.apiService.init();
      final response = await widget.apiService.getAdminInfo();

      setState(() {
        adminName = response['name'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        adminName = '불러오기 실패';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("관리자 메인")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Text("환영합니다, $adminName 님!", style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
