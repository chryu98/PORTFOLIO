// lib/ApplicationStep8CardPinPage.dart
import 'package:flutter/material.dart';
import 'ApplicationStep1Page.dart' show kPrimaryRed;
import 'package:bnkandroid/constants/api.dart' as API; // ApiException 캐치용
import 'package:bnkandroid/user/service/card_password_service.dart' as cps;
import 'ui/pin/fullscreen_pin_pad.dart'; // 전체화면 PIN 패드

class ApplicationStep8CardPinPage extends StatefulWidget {
  final int applicationNo;
  final int cardNo;
  final String? birthYmd; // YYYYMMDD (있으면 연속/생일 금지 검증에 사용)

  const ApplicationStep8CardPinPage({
    super.key,
    required this.applicationNo,
    required this.cardNo,
    this.birthYmd,
  });

  @override
  State<ApplicationStep8CardPinPage> createState() => _ApplicationStep8CardPinPageState();
}

class _ApplicationStep8CardPinPageState extends State<ApplicationStep8CardPinPage> {
  bool _saving = false;

  Future<void> _openPadAndSave() async {
    if (_saving) return;

    // ✅ 전체화면 PIN 패드 호출 (4자리, 2회 확인, 연속/반복/생일 금지 내장)
    final pin = await FullscreenPinPad.open(
      context,
      title: '카드 비밀번호를 입력해주세요',
      confirm: true,       // 신규 설정 → 2회 확인
      length: 4,           // 🔴 6 → 4자리로 변경
      birthYmd: widget.birthYmd, // 생년월일 있으면 전달
    );
    if (pin == null) return; // 사용자가 닫음

    setState(() => _saving = true);
    try {
      await cps.CardPasswordService.savePinAndPromote(
        applicationNo: widget.applicationNo,
        cardNo: widget.cardNo,
        pin1: pin,
        pin2: pin,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 저장되고 신청이 준비되었습니다.')),
      );

      // 서명 화면으로 이동 (rootNavigator 사용)
      Navigator.of(context, rootNavigator: true).pushReplacementNamed(
        '/sign',
        arguments: {'applicationNo': widget.applicationNo},
      );
    } on API.ApiException catch (e) {
      if (!mounted) return;
      var msg = e.message ?? '요청 처리 중 오류가 발생했습니다.';
      if (e.statusCode == 401) {
        msg = '로그인이 필요합니다. 다시 로그인해 주세요.';
      } else if (e.statusCode == 404) {
        msg = '신청서를 찾을 수 없습니다. 처음부터 다시 시도해주세요.';
      } else if (e.statusCode == 400) {
        // 🔴 메시지도 4자리 기준으로 수정
        msg = '형식 오류: 숫자 4자리로 설정했는지 확인해주세요.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black87),
        title: const Text('카드 비밀번호 설정', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _StepHeader8(current: 8, total: 8),
            SizedBox(height: 16),
            // 🔴 안내 문구도 4자리로 수정
            Text(
              '카드 결제/인증에 사용할 비밀번호(4자리 숫자)를 설정합니다.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '※ 보안을 위해 숫자 키패드가 무작위로 재배열될 수 있어요.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saving ? null : _openPadAndSave,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('비밀번호 설정'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader8 extends StatelessWidget {
  final int current;
  final int total;
  const _StepHeader8({required this.current, this.total = 8});
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
