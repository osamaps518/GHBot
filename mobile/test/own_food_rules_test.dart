import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/foods/food.dart';

typedef _OwnFood = ({
  String? nameAr,
  String? nameEn,
  Nutrients per100g,
  String? barcode,
});

/// Home hummus, the own food the backend's tests send, with values in
/// tenths. A null passed in replaces the default.
_OwnFood _hummus({
  String? nameAr = 'حمص بيتي',
  String? nameEn = 'Home hummus',
  int calories = 1700,
  int protein = 80,
  int carbs = 150,
  int fat = 90,
  String? barcode = '12345678',
}) => (
  nameAr: nameAr,
  nameEn: nameEn,
  per100g: Nutrients(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  ),
  barcode: barcode,
);

bool _passes(_OwnFood food) => passesOwnFoodChecks(
  nameAr: food.nameAr,
  nameEn: food.nameEn,
  per100g: food.per100g,
  barcode: food.barcode,
);

void main() {
  group('the phone refuses what the server refuses '
      '(backend/tests/test_own_foods.py)', () {
    for (final (refused, food) in [
      ('no name', _hummus(nameAr: null, nameEn: null)),
      ('an empty name', _hummus(nameEn: '')),
      ('an Arabic name of only spaces', _hummus(nameAr: '  ')),
      ('an English name of only spaces', _hummus(nameEn: '  ')),
      ('a name of only a no-break space', _hummus(nameEn: ' ')),
      ('a name of 81 characters', _hummus(nameEn: 'x' * 81)),
      ('a name with NUL', _hummus(nameAr: 'a\u0000b')),
      ('calories below 0', _hummus(calories: -1)),
      ('calories above 900', _hummus(calories: 9001)),
      ('protein above 100 g', _hummus(protein: 1001)),
      ('carbs below 0', _hummus(carbs: -1)),
      (
        'macros above 100 g together',
        _hummus(protein: 500, carbs: 400, fat: 101),
      ),
      ('a barcode of 7 digits', _hummus(barcode: '1234567')),
      ('a barcode of 15 digits', _hummus(barcode: '123456789012345')),
      ('a barcode with a letter', _hummus(barcode: '1234567a')),
      ('a barcode with a newline', _hummus(barcode: '12345678\n')),
    ]) {
      test(refused, () => expect(_passes(food), isFalse));
    }
  });

  test('the phone takes what the server takes: one name, the range edges, '
      "and calories that don't match the macros", () {
    expect(_passes(_hummus()), isTrue);
    expect(
      _passes(
        _hummus(
          nameAr: null,
          nameEn: 'Rice',
          calories: 9000,
          protein: 0,
          carbs: 1000,
          fat: 0,
          barcode: '12345678901234',
        ),
      ),
      isTrue,
    );
    expect(_passes(_hummus(nameEn: null, barcode: null)), isTrue);
  });

  test('a name counts characters as the server does: 80 emoji fit', () {
    expect(_passes(_hummus(nameEn: '😀' * 80)), isTrue);
    expect(_passes(_hummus(nameEn: '😀' * 81)), isFalse);
  });

  test('a typed value per 100 g is tenths up to its maximum, with at most 1 '
      'decimal, in Western or Arabic-Indic digits', () {
    expect(parsePer100g('18.2', 1000), 182);
    expect(parsePer100g('٤٤٢', 9000), 4420);
    expect(parsePer100g('0', 1000), 0);
    expect(parsePer100g('100', 1000), 1000);
    expect(parsePer100g('100.1', 1000), isNull);
    expect(parsePer100g('1.11', 1000), isNull);
    expect(parsePer100g('-1', 1000), isNull);
    expect(parsePer100g('', 1000), isNull);
  });

  group('adding an own food', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    });
    tearDown(() => database.close());

    test('keeps it on the phone, own and waiting to be sent, under a new '
        'ID', () async {
      final added = await database.addOwnFood(
        nameAr: 'معمول بالتمر',
        nameEn: null,
        per100g: const Nutrients(
          calories: 4420,
          protein: 56,
          carbs: 640,
          fat: 182,
        ),
        barcode: '6251003451205',
      );

      final stored = (await database.unsentOwnFoods()).single;
      expect(stored.id, added.id);
      expect(
        [stored.nameAr, stored.own, stored.barcode, stored.revision],
        ['معمول بالتمر', true, '6251003451205', 1],
      );
      expect(stored.per100g.fat, 182);
      expect((await database.searchStoredFoods('معمول')).single.id, added.id);
    });

    test('saves nothing when the server would refuse it', () async {
      await expectLater(
        database.addOwnFood(
          nameAr: null,
          nameEn: 'Too rich',
          per100g: const Nutrients(
            calories: 1000,
            protein: 500,
            carbs: 500,
            fat: 10,
          ),
          barcode: null,
        ),
        throwsArgumentError,
      );

      expect(await database.select(database.foodTable).get(), isEmpty);
    });
  });
}
