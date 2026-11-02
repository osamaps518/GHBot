enum Sex { male, female }

/// The backend's codes, in order from least to most active.
enum ActivityLevel {
  sedentary('sedentary'),
  lightlyActive('lightly_active'),
  moderatelyActive('moderately_active'),
  veryActive('very_active'),
  extremelyActive('extremely_active');

  const ActivityLevel(this.code);
  final String code;
}

enum Goal { lose, maintain, gain }

class Profile {
  const Profile({
    required this.birthYear,
    required this.birthMonth,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
  });

  factory Profile.fromJson(Map<String, Object?> json) => Profile(
    birthYear: json['birth_year'] as int,
    birthMonth: json['birth_month'] as int,
    sex: Sex.values.byName(json['sex'] as String),
    heightCm: (json['height_cm'] as num).toDouble(),
    weightKg: (json['weight_kg'] as num).toDouble(),
    activityLevel: ActivityLevel.values.firstWhere(
      (level) => level.code == json['activity_level'],
    ),
    goal: Goal.values.byName(json['goal'] as String),
  );

  final int birthYear;
  final int birthMonth;
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final Goal goal;

  Map<String, Object?> toJson() => {
    'birth_year': birthYear,
    'birth_month': birthMonth,
    'sex': sex.name,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'activity_level': activityLevel.code,
    'goal': goal.name,
  };
}
