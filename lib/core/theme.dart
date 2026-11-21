import 'package:flutter/material.dart';

/// رنگ‌ها مستقیم از فیگما (Colors daymode + صفحه‌ها)
class BColors {
  static const primary = Color(0xFF545F71);
  static const primaryDark = Color(0xFF40506A);
  static const secondary = Color(0xFF9BA5B7);
  static const tertiary = Color(0xFFEEF1F4);
  static const annotation = Color(0xFFF6CA56);
  static const incomeCard = Color(0xFFB0F5D2);
  static const expenseCard = Color(0xFFFFC7C7);
  static const incomeRow = Color(0x404DD44D);
  static const expenseRow = Color(0x40FF4B4B);
  static const quoteBg = Color(0xFFFAFAFA);
  static const recentBg = Color(0xFFFFF9CD);
  static const balanceBg = Color(0xFFEEEEEE);
  static const fabPanel = Color(0xFFFFEECF);
  static const incomeText = Color(0xFF2E7D4F);
  static const expenseText = Color(0xFFC62828);
  static const splashBg = Color(0xFFFBEFE0);
}

const kFont = 'YekanBakh';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BColors.primary,
    primary: BColors.primary,
    secondary: BColors.annotation,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kFont,
    scaffoldBackgroundColor: Colors.white,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: BColors.primaryDark, displayColor: BColors.primaryDark),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: BColors.primaryDark,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: BColors.tertiary,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontFamily: kFont)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BColors.tertiary,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BColors.primaryDark,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BColors.annotation,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
  );
}
