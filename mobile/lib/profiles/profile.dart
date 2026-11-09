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

enum ProfileField {
  birthMonth,
  birthYear,
  sex,
  height,
  weight,
  activityLevel,
  goal,
}

/// Values being edited, including fields the user has not filled in yet.
class ProfileDraft {
  const ProfileDraft({
    required this.birthYear,
    required this.birthMonth,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
  });

  final int? birthYear;
  final int? birthMonth;
  final Sex? sex;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel? activityLevel;
  final Goal? goal;
}

/// Checks a draft using the server's saved-profile rules as of a UTC date.
Set<ProfileField> validateProfileDraft(ProfileDraft draft, DateTime today) {
  final errors = <ProfileField>{};
  final month = draft.birthMonth;
  final year = draft.birthYear;
  if (month == null || month < 1 || month > 12) {
    errors.add(ProfileField.birthMonth);
  }
  if (year == null) errors.add(ProfileField.birthYear);
  if (month != null && month >= 1 && month <= 12 && year != null) {
    final utc = today.toUtc();
    final lastDay = DateTime.utc(utc.year, month + 1, 0).day;
    final hadBirthday =
        utc.month > month || (utc.month == month && utc.day >= lastDay);
    final age = utc.year - year - (hadBirthday ? 0 : 1);
    if (age < 18 || age > 100) {
      errors.addAll([ProfileField.birthMonth, ProfileField.birthYear]);
    }
  }
  if (draft.sex == null) errors.add(ProfileField.sex);
  if (!_inRange(draft.heightCm, 130, 220)) errors.add(ProfileField.height);
  if (!_inRange(draft.weightKg, 35, 250)) errors.add(ProfileField.weight);
  if (draft.activityLevel == null) errors.add(ProfileField.activityLevel);
  if (draft.goal == null) errors.add(ProfileField.goal);
  return errors;
}

// Written this way round so NaN, which double.tryParse accepts, fails.
bool _inRange(double? value, double min, double max) =>
    value != null && value >= min && value <= max;

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
