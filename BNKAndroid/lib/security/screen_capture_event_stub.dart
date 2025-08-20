// 웹/데스크톱용 스텁: 실제 패키지와 동일한 시그니처(모두 void)
class ScreenCaptureEvent {
  void addScreenShotListener(void Function(dynamic) onShot) {}
  void addScreenRecordListener(void Function(dynamic) onRecord) {}
  void dispose() {}
}
