import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class NaverMapPage extends StatefulWidget {
  @override
  _NaverMapPageState createState() => _NaverMapPageState();
}

class _NaverMapPageState extends State<NaverMapPage> {
  static const platform = MethodChannel('com.example.bnkandroid/naver_map');

  @override
  void initState() {
    super.initState();
    _loadBranchMarkers();
  }

  Future<void> _loadBranchMarkers() async {
    // 여기에 본인 서버 주소 설정
    final response = await http.get(Uri.parse('http://192.168.0.224:8090/api/branches'));

    if (response.statusCode == 200) {
      List<dynamic> branches = json.decode(response.body);
      print('✅ Flutter에서 받은 branchList: $branches');

      // Android로 전달
      await platform.invokeMethod('setMarkers', {
        'branches': branches,
      });
    } else {
      print('지점 정보를 불러오지 못했습니다');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('네이버 지도')),
      body: AndroidView(
        viewType: 'naver_map_view',
      ),
    );
  }
}
