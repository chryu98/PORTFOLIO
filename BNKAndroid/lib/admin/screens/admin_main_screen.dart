import 'package:flutter/material.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("관리자 메인 페이지"),
      ),
      body: const Center(
        child: Text(
          "관리자 대시보드입니다.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}