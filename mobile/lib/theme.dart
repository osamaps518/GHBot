import 'package:flutter/material.dart';

/// The app's look: option D4, charcoal and tangerine (docs/decisions.md).
/// Screens read colors and text styles from the theme, never hardcode them.
final ThemeData lightTheme = _theme(
  ColorScheme.fromSeed(
    seedColor: _tangerine,
    brightness: Brightness.light,
  ).copyWith(
    primary: _charcoal,
    onPrimary: Colors.white,
    surface: const Color(0xFFF5F5F3),
    onSurface: _charcoal,
    onSurfaceVariant: const Color(0xFF55555B),
    surfaceContainer: Colors.white,
    surfaceContainerHighest: const Color(0xFFE6E6E3),
    outline: const Color(0xFF929298),
    error: const Color(0xFFB3261E),
    onError: Colors.white,
    inverseSurface: _charcoal,
    onInverseSurface: Colors.white,
    inversePrimary: const Color(0xFFFF9A4D),
  ),
  const TargetsColors(
    heroBackground: _tangerine,
    onHero: _charcoal,
    heroNumber: _charcoal,
    heroMuted: Color(0xFF4A2405),
    protein: _charcoal,
    carbs: _tangerine,
    fat: Color(0xFFB8B8BC),
  ),
);

final ThemeData darkTheme = _theme(
  ColorScheme.fromSeed(
    seedColor: _tangerine,
    brightness: Brightness.dark,
  ).copyWith(
    primary: _tangerine,
    onPrimary: _charcoal,
    surface: const Color(0xFF111113),
    onSurface: _offWhite,
    onSurfaceVariant: const Color(0xFFA8A8AE),
    surfaceContainer: _darkCard,
    surfaceContainerHighest: const Color(0xFF2A2A2F),
    outline: const Color(0xFF5E5E66),
    error: const Color(0xFFFF6B7A),
    onError: _charcoal,
    inverseSurface: _offWhite,
    onInverseSurface: _charcoal,
    inversePrimary: const Color(0xFFA34200),
  ),
  const TargetsColors(
    heroBackground: _darkCard,
    onHero: _offWhite,
    heroNumber: _tangerine,
    heroMuted: Color(0xFFA8A8AE),
    protein: _offWhite,
    carbs: _tangerine,
    fat: Color(0xFF6E6E76),
  ),
);

const _charcoal = Color(0xFF1C1C1E);
const _tangerine = Color(0xFFFF7A1A);
const _offWhite = Color(0xFFF2F2F0);
const _darkCard = Color(0xFF1D1D20);

ThemeData _theme(ColorScheme colors, TargetsColors targets) {
  final base = ThemeData(colorScheme: colors, fontFamily: 'Rubik');

  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
  // Text fields and dropdowns share one look. DropdownMenu doesn't read the
  // app-wide inputDecorationTheme, so it gets this too.
  final fields = InputDecorationThemeData(
    filled: true,
    fillColor: colors.surfaceContainer,
    enabledBorder: border(colors.outline, 1.5),
    focusedBorder: border(colors.primary, 2),
    errorBorder: border(colors.error, 2),
    focusedErrorBorder: border(colors.error, 2),
  );

  const buttonSize = Size(64, 54);
  // A button's textStyle replaces the default one instead of merging with
  // it, so these start from the text theme to keep the Rubik font.
  final buttonText = base.textTheme.titleMedium!.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      // The daily calories number on the targets screen.
      displayLarge: base.textTheme.displayLarge!.copyWith(
        fontSize: 80,
        fontWeight: FontWeight.w600,
        height: 1.05,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineSmall: base.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: fields,
    dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: fields),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        textStyle: buttonText.copyWith(fontWeight: FontWeight.w500),
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outline, width: 1.5),
      ),
    ),
    // Gender and goal pickers: a pill-shaped track, the chosen option filled.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
        selectedBackgroundColor: colors.primary,
        selectedForegroundColor: colors.onPrimary,
        side: BorderSide.none,
        textStyle: base.textTheme.titleSmall!.copyWith(fontSize: 15),
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    // The "no connection" message. Its colors already come from the inverse
    // roles in the color scheme.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    extensions: [targets],
  );
}

/// Colors for the targets screen that Material's color scheme has no role
/// for: the daily calories card and one color per macro.
@immutable
class TargetsColors extends ThemeExtension<TargetsColors> {
  const TargetsColors({
    required this.heroBackground,
    required this.onHero,
    required this.heroNumber,
    required this.heroMuted,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final Color heroBackground;
  final Color onHero;
  final Color heroNumber;
  final Color heroMuted;
  final Color protein;
  final Color carbs;
  final Color fat;

  static TargetsColors of(BuildContext context) =>
      Theme.of(context).extension<TargetsColors>()!;

  @override
  TargetsColors copyWith({
    Color? heroBackground,
    Color? onHero,
    Color? heroNumber,
    Color? heroMuted,
    Color? protein,
    Color? carbs,
    Color? fat,
  }) => TargetsColors(
    heroBackground: heroBackground ?? this.heroBackground,
    onHero: onHero ?? this.onHero,
    heroNumber: heroNumber ?? this.heroNumber,
    heroMuted: heroMuted ?? this.heroMuted,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
  );

  @override
  TargetsColors lerp(TargetsColors? other, double t) {
    if (other == null) return this;
    return TargetsColors(
      heroBackground: Color.lerp(heroBackground, other.heroBackground, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      heroNumber: Color.lerp(heroNumber, other.heroNumber, t)!,
      heroMuted: Color.lerp(heroMuted, other.heroMuted, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
    );
  }
}
