import 'package:flutter/material.dart';

/// Warna dari desain Figma (src/index.css pada ekspor Figma Make).
class AppColors {
  AppColors._();

  static const canvas = Color(0xFFF4F7F3);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF15231E);
  static const muted = Color(
    0xFF5B6A64,
  ); // digelapkan dari #687872 agar lolos WCAG AA
  static const subtle = Color(
    0xFF63716C,
  ); // digelapkan dari #98A49F agar lolos WCAG AA
  static const line = Color(0xFFE4EAE6);
  static const sidebar = Color(0xFF102D24);
  static const primary = Color(0xFF166B52);
  static const primaryDark = Color(0xFF0F5742);
  static const lime = Color(0xFFC9F45A);
  static const mint = Color(0xFFE8F4EC);
  static const mintStrong = Color(0xFFB9DCCA);
  static const coral = Color(0xFFF06F5F);
  static const emeraldSoft = Color(0xFFE6F5ED);
  static const emeraldDeep = Color(0xFF1C7D59);
  static const amberSoft = Color(0xFFFFF3D6);
  static const amberDeep = Color(0xFFA66808);
  static const blueSoft = Color(0xFFE6F0FF);
  static const blueDeep = Color(0xFF3769A8);
  static const violetSoft = Color(0xFFEEE9FF);
  static const violetDeep = Color(0xFF6D52A6);
  static const roseSoft = Color(0xFFFEE9E7);
  static const roseDeep = Color(0xFFBD5149);
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: Color(0x08102D24), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A102D24), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.canvas,
  );
  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  return base.copyWith(
    textTheme: text,
    dividerColor: AppColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.canvas,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.subtle, fontSize: 13),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.primary),
      errorBorder: border(AppColors.roseDeep),
      focusedErrorBorder: border(AppColors.roseDeep),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.subtle,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.line),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.sidebar,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
