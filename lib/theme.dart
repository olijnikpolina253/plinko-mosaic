/// Visual preset for PlinkoMosaic — preset name: 'SPACE_COSMOS'.
///
/// Accent hexes are the ticket palette; the preset identity stays canonical.
library;

import 'package:flutter/material.dart';

/// Palette tokens. Deep indigo night + luminous cyan, violet, gold and rose.
class AppColors {
  const AppColors._();

  static const Color bgDeep = Color(0xFF070A18);
  static const Color bgBase = Color(0xFF11162D);
  static const Color bgRaise = Color(0xFF1A2142);
  static const Color surface = Color(0xFF141A33);
  static const Color surfaceAlt = Color(0xFF242C55);

  static const Color violet = Color(0xFF4B38A2);
  static const Color violetLit = Color(0xFF7B5BD6);
  static const Color cyan = Color(0xFF2FC5CC);
  static const Color gold = Color(0xFFF2C94C);
  static const Color rose = Color(0xFFEA5C82);

  static const Color textPrimary = Color(0xFFF7F2E9);
  static const Color textMuted = Color(0xFF9FB0D9);
  static const Color textFaint = Color(0xFF5D6B93);
  static const Color textCaption = Color(0xFF7D8DB8);
}

class AppTheme {
  const AppTheme._();

  /// Canonical visual preset identifier.
  static const String name = 'SPACE_COSMOS';

  /// Brand name exactly as it appears on the ticket (Cyrillic homoglyphs kept).
  static const String brand = 'Рlіnко Mosaic';

  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static ThemeData build() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.cyan,
      onPrimary: AppColors.bgDeep,
      secondary: AppColors.gold,
      onSecondary: AppColors.bgDeep,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.rose,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      splashColor: AppColors.cyan.withValues(alpha: 0.14),
      highlightColor: AppColors.cyan.withValues(alpha: 0.06),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.textMuted,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
