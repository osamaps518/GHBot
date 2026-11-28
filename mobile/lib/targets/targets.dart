import '../core/typed_number.dart';
import '../profiles/profile.dart';

class Targets {
  const Targets({
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.maintenanceCalories,
    required this.atMinimum,
    required this.aboveTestedAge,
    required this.goal,
    required this.goalAdjustmentPercent,
    required this.custom,
    required this.macrosAdjusted,
    required this.recommendedCalories,
    required this.recommendedProteinG,
    required this.recommendedFatG,
    required this.recommendedCarbsG,
  });

  factory Targets.fromJson(Map<String, Object?> json) {
    final recommended = json['recommended'] as Map<String, Object?>;
    return Targets(
      calories: json['calories'] as int,
      proteinG: json['protein_g'] as int,
      fatG: json['fat_g'] as int,
      carbsG: json['carbs_g'] as int,
      maintenanceCalories: json['maintenance_calories'] as int,
      atMinimum: json['at_minimum'] as bool,
      aboveTestedAge: json['above_tested_age'] as bool,
      goal: Goal.values.byName(json['goal'] as String),
      goalAdjustmentPercent: json['goal_adjustment_percent'] as int,
      custom: json['custom'] as bool,
      macrosAdjusted: json['macros_adjusted'] as bool,
      recommendedCalories: recommended['calories'] as int,
      recommendedProteinG: recommended['protein_g'] as int,
      recommendedFatG: recommended['fat_g'] as int,
      recommendedCarbsG: recommended['carbs_g'] as int,
    );
  }

  final int calories;
  final int proteinG;
  final int fatG;
  final int carbsG;

  /// The calories and goal behind the recommended targets, for "How we
  /// calculated this", even while custom targets are in effect.
  final int maintenanceCalories;

  /// The minimum was used for the targets in effect.
  final bool atMinimum;

  /// Older than the calorie formula was tested for, so the app warns once.
  final bool aboveTestedAge;
  final Goal goal;
  final int goalAdjustmentPercent;

  /// The trainee set these targets by hand (decision 37).
  final bool custom;

  /// Custom calories were below the minimum, so the server raised them to
  /// it and adjusted the macros.
  final bool macrosAdjusted;

  /// The recommended targets, the same as the ones in effect unless
  /// [custom].
  final int recommendedCalories;
  final int recommendedProteinG;
  final int recommendedFatG;
  final int recommendedCarbsG;
}

/// Daily calories and macros in whole numbers, as `PUT /me/targets/custom`
/// takes them.
typedef TargetValues = ({int calories, int proteinG, int fatG, int carbsG});

enum TargetsField { calories, protein, carbs, fat }

/// What the trainee typed into the targets form, each field read as a whole
/// number with Western or Arabic-Indic digits (null when it isn't one).
///
/// The ranges and the 100 kcal rule are the server's, checked here too
/// (decision 37). The calorie minimum is checked only by the server, so it
/// has one copy (docs/security.md).
class TargetsDraft {
  TargetsDraft.parse({
    required String calories,
    required String protein,
    required String carbs,
    required String fat,
  }) : calories = _wholeNumber(calories),
       proteinG = _wholeNumber(protein),
       carbsG = _wholeNumber(carbs),
       fatG = _wholeNumber(fat);

  final int? calories;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;

  /// The fields that aren't a whole number in the server's range.
  Set<TargetsField> get invalidFields => {
    if (!_inRange(calories, 6000)) TargetsField.calories,
    if (!_inRange(proteinG, 500)) TargetsField.protein,
    if (!_inRange(carbsG, 1000)) TargetsField.carbs,
    if (!_inRange(fatG, 300)) TargetsField.fat,
  };

  /// The four values, once every field is valid.
  TargetValues? get values => invalidFields.isEmpty
      ? (calories: calories!, proteinG: proteinG!, fatG: fatG!, carbsG: carbsG!)
      : null;

  /// The calories the macros give: 4 per gram of protein and of carbs, 9
  /// per gram of fat. Null until all three are whole numbers.
  int? get macroCalories => switch ((proteinG, carbsG, fatG)) {
    (final int protein, final int carbs, final int fat) =>
      4 * (protein + carbs) + 9 * fat,
    _ => null,
  };

  /// How far [macroCalories] is from [calories], or null until both are
  /// known.
  int? get difference => switch ((macroCalories, calories)) {
    (final int fromMacros, final int typed) => (fromMacros - typed).abs(),
    _ => null,
  };

  /// The server refuses a save whose macros are 100 kcal or more from its
  /// calories.
  bool get macrosTooFar => (difference ?? 0) >= 100;

  static int? _wholeNumber(String text) =>
      int.tryParse(westernNumberText(text));

  static bool _inRange(int? value, int max) =>
      value != null && value >= 0 && value <= max;
}
