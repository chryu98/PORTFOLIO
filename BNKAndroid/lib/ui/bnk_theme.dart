import 'package:flutter/material.dart';

class BNKColors {
  // 브랜드 컬러
  static const primary = Color(0xFFB91111);

  // 중립 팔레트 (핀테크 감성)
  static const bg       = Color(0xFFF7F8FA);  // 화면 배경
  static const line     = Color(0xFFEFF1F4);  // 경계/디바이더
  static const text     = Color(0xFF111827);
  static const textSub  = Color(0xFF6B7280);
  static const success  = Color(0xFF2E7D32);
  static const danger   = Color(0xFFDC2626);
}

class BNKTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,

    // ColorScheme에서 background 파라미터는 최신 버전에서 deprecated.
    colorScheme: ColorScheme.fromSeed(
      seedColor: BNKColors.primary,
      primary: BNKColors.primary,
    ),

    scaffoldBackgroundColor: BNKColors.bg,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: BNKColors.text,
      elevation: 0.5,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: BNKColors.text,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      // withOpacity 경고 → withValues로 교체
      indicatorColor: BNKColors.primary.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      // MaterialStatePropertyAll 경고 → WidgetStatePropertyAll 로 교체
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BNKColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BNKColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BNKColors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BNKColors.danger),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BNKColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),

    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black87,
      contentTextStyle: TextStyle(color: Colors.white),
    ),

    // ✅ ThemeData.cardTheme 는 CardThemeData 를 요구
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: BNKColors.line, thickness: 1, space: 1,
    ),
  );
}
