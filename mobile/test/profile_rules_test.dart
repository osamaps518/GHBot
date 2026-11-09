import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/profiles/profile.dart';

void main() {
  ProfileDraft draft({int year = 1998, int month = 4, double height = 167.5}) =>
      ProfileDraft(
        birthYear: year,
        birthMonth: month,
        sex: Sex.female,
        heightCm: height,
        weightKg: 63.25,
        activityLevel: ActivityLevel.moderatelyActive,
        goal: Goal.maintain,
      );

  for (final (today, year, month, allowed) in [
    (DateTime.utc(2026, 10, 25), 2008, 10, false),
    (DateTime.utc(2026, 10, 25), 2008, 9, true),
    (DateTime.utc(2026, 10, 31), 2008, 10, true),
    (DateTime.utc(2026, 10, 31), 1926, 10, true),
    (DateTime.utc(2026, 10, 25), 1925, 11, true),
    (DateTime.utc(2026, 10, 31), 1925, 10, false),
    (DateTime.utc(2026, 10, 25), 2026, 11, false),
  ]) {
    test('age $year/$month on ${today.toIso8601String()}', () {
      final errors = validateProfileDraft(
        draft(year: year, month: month),
        today,
      );
      expect(errors.contains(ProfileField.birthYear), !allowed);
    });
  }

  test('an old saved height outside the current range is flagged', () {
    final errors = validateProfileDraft(
      draft(height: 229),
      DateTime.utc(2026, 10, 25),
    );
    expect(errors, contains(ProfileField.height));
  });
}
