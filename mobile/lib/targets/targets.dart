class Targets {
  const Targets({
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.maintenanceCalories,
    required this.atMinimum,
  });

  factory Targets.fromJson(Map<String, Object?> json) => Targets(
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    fatG: json['fat_g'] as int,
    carbsG: json['carbs_g'] as int,
    maintenanceCalories: json['maintenance_calories'] as int,
    atMinimum: json['at_minimum'] as bool,
  );

  final int calories;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final int maintenanceCalories;
  final bool atMinimum;
}
