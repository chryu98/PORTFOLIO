// ==============================================
// 파일: lib/analytics/behavior_logger.dart
// ==============================================
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
// ↓ 웹에서도 안전한 Platform 제공
import 'package:universal_io/io.dart' show Platform;

import 'package:bnkandroid/constants/api.dart'; // API.baseUrl 사용

/// 앱 행동 로깅 서비스: 즉시 전송 + 실패 시 로컬 큐 적재 후 재시도
class BehaviorLogger {
  BehaviorLogger._();
  static final BehaviorLogger instance = BehaviorLogger._();

  static const _queueKey = 'behavior_log_queue_v1';

  // 서버 엔드포인트 (RecoController.addLog 에 매핑)
  static String get _logEndpoint => '${API.baseUrl}/admin/reco/log';

  String _deviceType = 'MOBILE';
  String _userAgent = 'BNKApp/unknown';
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // deviceType
    try {
      if (kIsWeb) {
        _deviceType = 'WEB';
      } else if (Platform.isAndroid || Platform.isIOS) {
        _deviceType = 'MOBILE';
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        _deviceType = 'PC';
      } else {
        _deviceType = 'UNKNOWN';
      }
    } catch (_) {
      _deviceType = kIsWeb ? 'WEB' : 'UNKNOWN';
    }

    // userAgent (앱/OS/브라우저/모델 조합)
    try {
      final pkg = await PackageInfo.fromPlatform();
      final di = DeviceInfoPlugin();
      final app = '${pkg.appName}/${pkg.version}+${pkg.buildNumber}';

      if (kIsWeb) {
        final web = await di.webBrowserInfo;
        final browser = web.browserName.name; // chrome, safari 등
        final plat = web.platform ?? 'web';
        _userAgent = '$app ($plat; $browser)';
      } else if (Platform.isAndroid) {
        final a = await di.androidInfo;
        final os = 'Android ${a.version.release ?? ''}';
        final model = a.model ?? '';
        _userAgent = model.isNotEmpty ? '$app ($os; $model)' : '$app ($os)';
      } else if (Platform.isIOS) {
        final i = await di.iosInfo;
        final os = 'iOS ${i.systemVersion ?? ''}';
        final model = i.utsname.machine ?? '';
        _userAgent = model.isNotEmpty ? '$app ($os; $model)' : '$app ($os)';
      } else if (Platform.isMacOS) {
        _userAgent = '$app (macOS)';
      } else if (Platform.isWindows) {
        _userAgent = '$app (Windows)';
      } else if (Platform.isLinux) {
        _userAgent = '$app (Linux)';
      } else {
        _userAgent = '$app (UnknownOS)';
      }
    } catch (_) {
      // ignore: fallback 유지
    }

    // 앱 시작 시 큐 비우기 시도
    await flushQueue();
  }

  Future<void> log({
    required String behaviorType, // 'VIEW' | 'CLICK' | 'APPLY'
    required int cardNo,
    int? memberNo,                // 로그인 전이면 null 가능
    DateTime? when,               // 기본: now(UTC)
  }) async {
    await init();

    final payload = {
      if (memberNo != null) 'memberNo': memberNo,
      'cardNo': cardNo,
      'behaviorType': behaviorType,
      'behaviorTime': (when ?? DateTime.now().toUtc().toIso8601String()),
      'deviceType': _deviceType,
      'userAgent': _userAgent,
    };

    final url = Uri.parse(_logEndpoint);
    try {
      final res = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return; // OK
      }
      await _enqueue(payload); // 실패 → 큐 적재
    } catch (_) {
      await _enqueue(payload); // 네트워크/타임아웃 → 큐 적재
    }
  }

  Future<void> logView({required int cardNo, int? memberNo}) =>
      log(behaviorType: 'VIEW', cardNo: cardNo, memberNo: memberNo);

  Future<void> logClick({required int cardNo, int? memberNo}) =>
      log(behaviorType: 'CLICK', cardNo: cardNo, memberNo: memberNo);

  Future<void> logApply({required int cardNo, int? memberNo}) =>
      log(behaviorType: 'APPLY', cardNo: cardNo, memberNo: memberNo);

  // ===== 로컬 큐 =====

  Future<void> _enqueue(Map<String, dynamic> item) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_queueKey) ?? <String>[];
    list.add(jsonEncode(item));
    await sp.setStringList(_queueKey, list);
  }

  Future<void> flushQueue() async {
    final sp = await SharedPreferences.getInstance();
    final list = List<String>.from(sp.getStringList(_queueKey) ?? <String>[]);
    if (list.isEmpty) return;

    final url = Uri.parse(_logEndpoint);
    final kept = <String>[];

    for (final s in list) {
      try {
        final payload = jsonDecode(s);
        final res = await http
            .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 6));
        if (res.statusCode < 200 || res.statusCode >= 300) {
          kept.add(s);
        }
      } catch (_) {
        kept.add(s);
      }
    }

    await sp.setStringList(_queueKey, kept);
  }
}
