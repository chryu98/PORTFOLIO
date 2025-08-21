// lib/user/models/pin_models.dart
class SetPinReq {
  final String pin1;
  final String pin2;
  const SetPinReq({required this.pin1, required this.pin2});

  Map<String, dynamic> toJson() => {'pin1': pin1, 'pin2': pin2};
}

class PinSaveResult {
  final bool ok;
  final String message;
  const PinSaveResult({required this.ok, required this.message});

  factory PinSaveResult.fromJson(Map<String, dynamic> j) {
    return PinSaveResult(
      ok: j['ok'] == true,
      message: (j['message'] ?? '').toString(),
    );
  }
}
