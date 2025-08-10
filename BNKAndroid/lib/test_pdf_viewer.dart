import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(home: TestPdfViewer()));
}

class TestPdfViewer extends StatefulWidget {
  const TestPdfViewer({super.key});

  @override
  State<TestPdfViewer> createState() => _TestPdfViewerState();
}

class _TestPdfViewerState extends State<TestPdfViewer> {
  String? localPath;
  bool isLoading = true;

  static const String pdfUrl = 'http://192.168.0.222:8090/admin/pdf/view/34';

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp.pdf');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else {
        throw Exception('PDF 다운로드 실패');
      }
    } catch (e) {
      debugPrint('PDF 다운로드 에러: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF 보기")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : localPath == null
          ? const Center(child: Text("PDF 로딩 실패"))
          : PDFView(
        filePath: localPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageSnap: true,
      ),
    );
  }
}
