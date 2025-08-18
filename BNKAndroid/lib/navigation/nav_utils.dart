import 'package:flutter/material.dart';

/// 항상 루트 네비게이터 기준으로 안전하게 닫기
Future<bool> safeRootPop(BuildContext context, [result]) async {
  final nav = Navigator.of(context, rootNavigator: true);
  // maybePop은 닫을 게 없으면 false를 리턴하므로 어서션이 안 터집니다.
  return nav.maybePop(result);
}
