import 'package:flutter/material.dart';

/// Visual preset identity. The literal must stay one of the ten canonical
/// factory presets — this app ships SPACE_COSMOS with the ticket palette.
class PMPreset {
  const PMPreset({required this.name});

  final String name;
}

const PMPreset pmPreset = PMPreset(name: 'SPACE_COSMOS');

/// SPACE_COSMOS palette overridden with the ticket hexes.
class PMColors {
  const PMColors._();

  static const Color bgDeep = Color(0xFF07091A);
  static const Color bgBase = Color(0xFF11162D);
  static const Color surface = Color(0xFF1A2142);
  static const Color surfaceHi = Color(0xFF232B52);
  static const Color violet = Color(0xFF4B38A2);
  static const Color cyan = Color(0xFF2FC5CC);
  static const Color gold = Color(0xFFF2C94C);
  static const Color rose = Color(0xFFEA5C82);
  static const Color textPrimary = Color(0xFFF7F2E9);

  static const List<Color> nodeColors = <Color>[cyan, gold, rose];

  static Color text(double alpha) => textPrimary.withValues(alpha: alpha);

  /// Hairline border used on every glass surface.
  static Border hairline([double alpha = 0.10, double width = 1]) =>
      Border.all(color: textPrimary.withValues(alpha: alpha), width: width);
}

/// Tabular figures keep counters from jittering as digits change.
const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

ThemeData buildPMTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: PMColors.violet,
    brightness: Brightness.dark,
  ).copyWith(
    primary: PMColors.violet,
    secondary: PMColors.cyan,
    tertiary: PMColors.gold,
    surface: PMColors.surface,
    onSurface: PMColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: PMColors.bgBase,
    canvasColor: PMColors.bgBase,
    splashColor: PMColors.cyan.withValues(alpha: 0.12),
    highlightColor: Colors.transparent,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: 5.0,
        color: PMColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 3.6,
        color: PMColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.6,
        color: PMColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: PMColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: PMColors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
        color: PMColors.textPrimary,
      ),
    ),
  );
}
