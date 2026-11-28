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

  /// The trainee set these targets by hand (docs/decisions.md, 37).
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
