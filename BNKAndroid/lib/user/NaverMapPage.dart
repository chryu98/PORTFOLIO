import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class NaverMapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('네이버 지도')),
      body: AndroidView(
        viewType: 'naver_map_view', // 네이티브에서 등록한 viewType과 동일해야 함
      ),
    );
  }
}