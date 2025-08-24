// lib/util/pin_policy.dart
class PinPolicy {
  /// 규칙 위반이면 에러 메시지, 정상이면 null
  static String? validate6(String pin, {String? birthYmd}) {
    // 6자리 숫자
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return '비밀번호는 숫자 6자리여야 합니다.';

    // 동일 숫자 3회 이상 연속 금지 (예: 111234, 990000)
    if (RegExp(r'(.)\1\1').hasMatch(pin)) return '같은 숫자를 3번 이상 연속으로 사용할 수 없습니다.';

    // 연속수 금지(옵션) : 123456 / 654321 등
    const badSeq = {
      '012345','123456','234567','345678','456789',
      '987654','876543','765432','654321','543210',
    };
    if (badSeq.contains(pin)) return '연속된 숫자는 사용할 수 없습니다.';

    // 생년월일(yymmdd) 금지 (birthYmd = yyyyMMdd 또는 yyyymmdd 형태)
    if (birthYmd != null) {
      final only = birthYmd.replaceAll(RegExp(r'[^0-9]'), '');
      if (only.length == 8) {
        final yyMMdd = only.substring(2, 8); // yymmdd
        if (pin == yyMMdd) return '생년월일과 동일한 숫자는 사용할 수 없습니다.';
      }
    }

    return null;
  }
}
