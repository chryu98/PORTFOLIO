import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'UserRegistFormPage.dart';

const kPrimaryRed = Color(0xffB91111);

class TermsAgreePage extends StatefulWidget {
  final String selectedRole;
  const TermsAgreePage({super.key, required this.selectedRole});

  @override
  State<TermsAgreePage> createState() => _TermsAgreePageState();
}

class Term {
  final int termNo;
  final String termType;
  final String content;
  final String isRequired;
  bool isChecked;
  bool isVisible;

  Term({
    required this.termNo,
    required this.termType,
    required this.content,
    required this.isRequired,
    this.isChecked = false,
    this.isVisible = false,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      termNo: json['termNo'],
      termType: json['termType'],
      content: json['content'],
      isRequired: json['isRequired'],
    );
  }
}

class _TermsAgreePageState extends State<TermsAgreePage> {
  List<Term> terms = [];
  bool allChecked = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.229:8090/user/api/regist/getTerms'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          terms = data.map((item) => Term.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('약관 데이터를 불러오는 데 실패했습니다.');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void toggleAll(bool? value) {
    setState(() {
      allChecked = value ?? false;
      for (var term in terms) {
        term.isChecked = allChecked;
        term.isVisible = allChecked;
      }
    });
  }

  Future<void> submitTerms() async {
    for (var term in terms) {
      if (term.isRequired == 'Y' && !term.isChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 약관에 모두 동의해 주세요.')),
        );
        return;
      }
    }

    Map<String, String> termsData = {};
    for (var term in terms) {
      termsData['terms${term.termNo}'] = term.isChecked ? 'Y' : 'N';
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.229:8090/user/api/regist/terms'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(termsData),
      );

      final result = json.decode(response.body);
      if (response.statusCode == 200) {
        Navigator.pushNamed(context, '/userRegistForm');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '알 수 없는 오류')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신 중 오류가 발생했습니다.')),
      );
    }
  }

  void goToUserRegistForm() {
    // 필수 약관 체크
    for (var term in terms) {
      if (term.isRequired == 'Y' && !term.isChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 약관에 모두 동의해 주세요.')),
        );
        return;
      }
    }

    // 약관 데이터 Map 생성
    Map<String, String> agreedTerms = {};
    for (var term in terms) {
      agreedTerms['${term.termNo}'] = term.isChecked ? 'Y' : 'N';
    }

    // 다음 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserRegistFormPage(
          role: widget.selectedRole,
          agreedTerms: agreedTerms,
        ),
      ),
    );
  }

  Widget _buildTermItem(Term term) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: term.isChecked,
                onChanged: (value) {
                  setState(() {
                    term.isChecked = value ?? false;
                    term.isVisible = term.isChecked;
                    allChecked = terms.every((t) => t.isChecked);
                  });
                },
                title: Text(
                  "${term.termType} (${term.isRequired == 'Y' ? '필수' : '선택'})",
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            IconButton(
              icon: Icon(
                term.isVisible
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              onPressed: () {
                setState(() {
                  term.isVisible = !term.isVisible;
                });
              },
            ),
          ],
        ),
        if (term.isVisible)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey),
              //borderRadius: BorderRadius.circular(12),
            ),
            height: 200,
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Html(data: term.content),
              ),
            ),
          ),
      ],
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "약관에 동의해주세요",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                // const SizedBox(height: 6),
                // const Text(
                //   "약관에 동의해주세요",
                //   style: TextStyle(fontSize: 14, color: Colors.grey),
                // ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: allChecked,
                  onChanged: toggleAll,
                  title: const Text("모두 동의"),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const Divider(),
                ...terms.map(_buildTermItem).toList(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: goToUserRegistForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      "다음",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
