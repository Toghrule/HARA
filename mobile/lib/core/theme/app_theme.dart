import 'package:flutter/material.dart';

/// HARA's look, taken from the logo: gold and purple. The light theme is cream with purple buttons and gold touches; the
/// dark theme is the logo's own black with gold buttons and purple touches. Both keep a black bar on top, where the logo
/// sits in its natural colours.
class AppTheme {
  AppTheme._();

  /// The logo's colours.
  static const gold = Color(0xFFE4B744);
  static const purple = Color(0xFF9E4CB6);
  static const deepPurple = Color(0xFF7B2D9E);
  static const copper = Color(0xFFBB8069);

  static const _barBlack = Color(0xFF000000);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: deepPurple,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEBD9F4),
    onPrimaryContainer: Color(0xFF3A0F4D),
    secondary: gold,
    onSecondary: Color(0xFF2A1B00),
    secondaryContainer: Color(0xFFF6E3B0),
    onSecondaryContainer: Color(0xFF3B2A00),
    tertiary: copper,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF3DDD3),
    onTertiaryContainer: Color(0xFF3E2318),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFBF3E6),
    onSurface: Color(0xFF2B1A33),
    onSurfaceVariant: Color(0xFF6E5C77),
    outline: Color(0xFFB8A58E),
    outlineVariant: Color(0xFFEBDFCB),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFF9F0),
    surfaceContainer: Color(0xFFF8EEDC),
    surfaceContainerHigh: Color(0xFFF3E6CF),
    surfaceContainerHighest: Color(0xFFEDE0C8),
    inverseSurface: Color(0xFF2B1A33),
    onInverseSurface: Color(0xFFFBF3E6),
    inversePrimary: gold,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: gold,
    onPrimary: Color(0xFF2A1B00),
    primaryContainer: Color(0xFF5A4410),
    onPrimaryContainer: Color(0xFFFFE9AE),
    secondary: purple,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF3B1F4A),
    onSecondaryContainer: Color(0xFFF0D6FA),
    tertiary: copper,
    onTertiary: Color(0xFF2E1A10),
    tertiaryContainer: Color(0xFF5A3A2A),
    onTertiaryContainer: Color(0xFFF7DCCD),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF3B0A06),
    surface: Color(0xFF0F0A14),
    onSurface: Color(0xFFF6EDDD),
    onSurfaceVariant: Color(0xFFB4A6C0),
    outline: Color(0xFF6F6079),
    outlineVariant: Color(0xFF2E2238),
    surfaceContainerLowest: Color(0xFF0A060E),
    surfaceContainerLow: Color(0xFF150F1B),
    surfaceContainer: Color(0xFF1B1422),
    surfaceContainerHigh: Color(0xFF251C2E),
    surfaceContainerHighest: Color(0xFF2E2238),
    inverseSurface: Color(0xFFF6EDDD),
    onInverseSurface: Color(0xFF1B1422),
    inversePrimary: deepPurple,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  );

  static ThemeData get light => _build(_lightScheme, cardColor: _lightScheme.surfaceContainerLowest);

  static ThemeData get dark => _build(_darkScheme, cardColor: _darkScheme.surfaceContainer);

  static ThemeData _build(ColorScheme scheme, {required Color cardColor}) {
    const radius = BorderRadius.all(Radius.circular(14));
    final inputBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: scheme.outline),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      // The bar is black in both themes: the logo is on black, and gold on black reads well everywhere.
      appBarTheme: const AppBarTheme(
        backgroundColor: _barBlack,
        foregroundColor: gold,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: gold),
        actionsIconTheme: IconThemeData(color: gold),
        titleTextStyle: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: gold,
        unselectedLabelColor: Color(0xFFB4A6C0),
        indicatorColor: gold,
        dividerColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: scheme.outlineVariant)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 44),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: const StadiumBorder())),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: scheme.primary, width: 2)),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.primary),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.primary : null),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest),
      ),
      expansionTileTheme: const ExpansionTileThemeData(shape: Border(), collapsedShape: Border()),
    );
  }
}
