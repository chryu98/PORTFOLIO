import 'package:flutter/material.dart';
import 'client.dart';
import 'service.dart';
import 'models.dart';

Future<void> showFeedbackSheet(
    BuildContext context, {
      required int cardNo,
      int? userNo,
    }) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FeedbackSheet(cardNo: cardNo, userNo: userNo),
  );
}

class _FeedbackSheet extends StatefulWidget {
  final int cardNo;
  final int? userNo;
  const _FeedbackSheet({required this.cardNo, this.userNo});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _commentCtl = TextEditingController();
  int _rating = 5;
  bool _loading = false;

  late final FeedbackService _svc;

  @override
  void initState() {
    super.initState();
    _svc = FeedbackService(FeedbackHttp());
  }

  @override
  void dispose() {
    _commentCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final req = FeedbackCreateReq(
        cardNo: widget.cardNo,
        userNo: widget.userNo,
        rating: _rating,
        comment: _commentCtl.text.trim(),
      );
      final resp = await _svc.create(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드백 접수 완료 (No: ${resp.feedbackNo})')),
      );
      Navigator.of(context).pop(); // 모달 닫기
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('카드 발급 절차는 어떠셨나요?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('평점 (1~5)', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(5, (i) {
                  final s = i + 1;
                  return IconButton(
                    icon: Icon(s <= _rating ? Icons.star : Icons.star_border),
                    onPressed: () => setState(() => _rating = s),
                  );
                }),
              ),
              const SizedBox(height: 8),
              const Text('한 줄 의견', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentCtl,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '자유롭게 작성해주세요',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? '전송 중…' : '제출'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
