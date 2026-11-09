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
  });

  factory Targets.fromJson(Map<String, Object?> json) => Targets(
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    fatG: json['fat_g'] as int,
    carbsG: json['carbs_g'] as int,
    maintenanceCalories: json['maintenance_calories'] as int,
    atMinimum: json['at_minimum'] as bool,
    aboveTestedAge: json['above_tested_age'] as bool,
    goal: Goal.values.byName(json['goal'] as String),
    goalAdjustmentPercent: json['goal_adjustment_percent'] as int,
  );

  final int calories;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final int maintenanceCalories;
  final bool atMinimum;

  /// Older than the calorie formula was tested for, so the app warns once.
  final bool aboveTestedAge;
  final Goal goal;
  final int goalAdjustmentPercent;
}
