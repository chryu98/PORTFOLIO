import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed; // 버튼/상단 컬러
import 'ApplicationStep7AddressPage.dart';
import 'user/service/card_apply_service.dart';


class ApplicationStep6CardOptionPage extends StatefulWidget {
  final int applicationNo;
  final int cardNo; // ✅ 추가

  const ApplicationStep6CardOptionPage({
    super.key,
    required this.applicationNo,
    required this.cardNo, // ✅ 추가
  });

  @override
  State<ApplicationStep6CardOptionPage> createState() => _ApplicationStep6CardOptionPageState();
}

class _ApplicationStep6CardOptionPageState extends State<ApplicationStep6CardOptionPage> {
  String? _brand;       // 'VISA' | 'MASTER'
  bool _postpaid = false;
  bool _saving = false;

  Future<void> _save() async {
    if (_brand == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('브랜드를 선택하세요.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await CardApplyService.saveCardOptions(
        applicationNo: widget.applicationNo,
        cardBrand: _brand!,
        postpaid: _postpaid,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ApplicationStep7AddressPage(
              applicationNo: widget.applicationNo,
              cardNo: widget.cardNo, // ✅ 추가
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 실패')));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canNext = _brand != null && !_saving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black87),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepHeader6(current: 5, total: 6), // 진행바(디자인 자유)
            const SizedBox(height: 16),
            Row(
              children: const [
                Text('카드 브랜드', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),

            // 브랜드 선택 카드 2개 (토스 풍, 심플/라운드/섀도우)
            Row(
              children: [
                Expanded(child: _BrandTile(
                  label: 'VISA',
                  selected: _brand == 'VISA',
                  onTap: () => setState(() => _brand = 'VISA'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _BrandTile(
                  label: 'MASTER',
                  selected: _brand == 'MASTER',
                  onTap: () => setState(() => _brand = 'MASTER'),
                )),
              ],
            ),

            const SizedBox(height: 22),
            const Text('옵션', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            // 후불교통카드 스위치 (토스 느낌 리스트 타일)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEAECEE)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: const Text('후불교통카드'),
                trailing: CupertinoSwitch(
                  value: _postpaid,
                  activeColor: kPrimaryRed,
                  onChanged: (v) => setState(() => _postpaid = v),
                ),
                onTap: () => setState(() => _postpaid = !_postpaid),
              ),
            ),

            const Spacer(),

            // 가이드 박스(선택): 최근 20일 룰 등 넣어도 됨
            // const _InfoBox(text: '설명...'),

          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: canNext ? _save : null,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('다음'),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BrandTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final border = selected ? kPrimaryRed : const Color(0xFFE6E8EB);
    final bg     = selected ? const Color(0xFFFFF5F5) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Color(0x0D000000), offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF1F3F5),
              child: Icon(Icons.credit_card, color: Colors.black54, size: 18),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? kPrimaryRed : const Color(0xFFB0B8C1),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader6 extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const _StepHeader6({required this.current, this.total = 3});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = (i + 1) <= current;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            color: active ? kPrimaryRed : const Color(0xFFE5E5E5),
          ),
        );
      }),
    );
  }
}
