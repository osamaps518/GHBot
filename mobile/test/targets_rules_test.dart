import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/targets/targets.dart';

void main() {
  TargetsDraft draft({
    String calories = '2400',
    String protein = '160',
    String carbs = '296',
    String fat = '64',
  }) => TargetsDraft.parse(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );

  test('macros give 4 kcal per gram of protein and carbs, 9 per gram of '
      'fat', () {
    final typed = draft(protein: '96', carbs: '143', fat: '27');

    expect(typed.macroCalories, 1199);
    expect(typed.difference, 1201);
  });

  test('reads Arabic-Indic digits', () {
    final typed = draft(calories: '٢٤٠٠', protein: '١٦٠');

    expect(typed.values, (
      calories: 2400,
      proteinG: 160,
      fatG: 64,
      carbsG: 296,
    ));
  });

  for (final (name, typed, field) in [
    ('calories over 6000', draft(calories: '6001'), TargetsField.calories),
    ('protein over 500', draft(protein: '501'), TargetsField.protein),
    ('carbs over 1000', draft(carbs: '1001'), TargetsField.carbs),
    ('fat over 300', draft(fat: '301'), TargetsField.fat),
    ('negative fat', draft(fat: '-1'), TargetsField.fat),
    ('a decimal', draft(protein: '160.5'), TargetsField.protein),
    ('an empty field', draft(carbs: ''), TargetsField.carbs),
  ]) {
    test('$name is out of range', () {
      expect(typed.invalidFields, {field});
      expect(typed.values, isNull);
    });
  }

  test('the highest values the server takes are in range', () {
    expect(
      draft(
        calories: '6000',
        protein: '500',
        carbs: '1000',
        fat: '300',
      ).invalidFields,
      isEmpty,
    );
  });

  test('macros 99 kcal apart can be saved, 100 apart cannot', () {
    expect(draft(calories: '2499').macrosTooFar, isFalse);
    expect(draft(calories: '2500').macrosTooFar, isTrue);
    expect(draft(calories: '2300').macrosTooFar, isTrue);
  });

  test('with a macro not typed, there are no macro calories to compare', () {
    final typed = draft(fat: '');

    expect(typed.macroCalories, isNull);
    expect(typed.macrosTooFar, isFalse);
  });
}
