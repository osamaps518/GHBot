import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/core/theme.dart';
import 'package:ghbot/food_log/amount_screen.dart';
import 'package:ghbot/food_log/entry.dart';
import 'package:ghbot/food_log/meal.dart';
import 'package:ghbot/foods/food.dart';
import 'package:ghbot/l10n/app_localizations.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));
final _rice = Food.fromJson(riceJson);

AppDatabase _memoryDatabase() {
  final database = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);
  return database;
}

/// A database whose saves wait for [save] to complete.
class _SlowDatabase extends AppDatabase {
  _SlowDatabase()
    : super(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );

  final save = Completer<void>();

  @override
  Future<void> logEntry({
    required Food food,
    required DiaryMeal meal,
    required int grams,
    required String diaryDay,
    required DateTime loggedAt,
  }) async {
    await save.future;
    await super.logEntry(
      food: food,
      meal: meal,
      grams: grams,
      diaryDay: diaryDay,
      loggedAt: loggedAt,
    );
  }
}

/// Opens the amount step for rice at 150 g in lunch, from a home screen, and
/// returns what it closed with.
Future<List<bool?>> _pumpAmount(
  WidgetTester tester,
  AppDatabase database,
) async {
  final closedWith = <bool?>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: lightTheme,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => closedWith.add(
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => AmountScreen(
                  database: database,
                  food: _rice,
                  grams: 1500,
                  diaryDay: '2026-11-23',
                  meal: const DiaryMeal(Meal.lunch),
                  meals: const [
                    DiaryMeal(Meal.breakfast),
                    DiaryMeal(Meal.lunch),
                    DiaryMeal(Meal.dinner),
                    DiaryMeal(Meal.extra, 'Pre-workout'),
                  ],
                ),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return closedWith;
}

void main() {
  for (final (typed, grams) in [
    ('150', 1500),
    ('37.5', 375),
    ('٣٧٫٥', 375),
    ('0.1', 1),
    ('5000', 50000),
    ('0', null),
    ('5000.1', null),
    ('1.25', null),
    ('-5', null),
    ('', null),
    ('abc', null),
  ]) {
    test('grams "$typed" are ${grams ?? 'refused'}', () {
      expect(parseGrams(typed), grams);
    });
  }

  test('logging saves the entry on the day it is given, with its totals, and '
      'keeps the food on the phone so search finds it offline', () async {
    final database = _memoryDatabase();

    await database.logEntry(
      food: _rice,
      meal: const DiaryMeal(Meal.lunch),
      grams: 1500,
      diaryDay: '2026-11-20',
      loggedAt: DateTime.utc(2026, 11, 24, 9, 30),
    );

    final entry = await database.select(database.foodLogEntryTable).getSingle();
    expect(entry.diaryDay, '2026-11-20');
    expect(
      entry.loggedAt.isAtSameMomentAs(DateTime.utc(2026, 11, 24, 9, 30)),
      isTrue,
    );
    expect(entry.totals.calories, 1950);

    expect((await database.searchStoredFoods('rice')).single.id, 'rice');
    final recent = (await database.watchRecentFoods().first).single;
    expect((recent.grams, recent.calories), (1500, 1950));
  });

  test('a failed save keeps neither the entry nor the food change', () async {
    final database = _memoryDatabase();
    await database.storeFood(_rice);
    await database.customStatement(
      'CREATE TRIGGER refuse_entries BEFORE INSERT ON food_log_entries '
      "BEGIN SELECT RAISE(ABORT, 'refused'); END",
    );
    final changedRice = Food.fromJson({...riceJson, 'calories': 140.0});

    await expectLater(
      database.logEntry(
        food: changedRice,
        meal: const DiaryMeal(Meal.lunch),
        grams: 1500,
        diaryDay: '2026-11-23',
        loggedAt: DateTime.utc(2026, 11, 23, 12),
      ),
      throwsA(anything),
    );

    expect(await database.select(database.foodLogEntryTable).get(), isEmpty);
    final stored = (await database.searchStoredFoods('rice')).single;
    expect(stored.per100g.calories, 1300);
  });

  testWidgets('shows the totals for the grams, and + and − change them by 10', (
    tester,
  ) async {
    await _pumpAmount(tester, _memoryDatabase());
    expect(find.text('195'), findsOneWidget);
    expect(find.text('42 ${english.gramsUnit}'), findsOneWidget);

    await tester.tap(find.byTooltip(english.more));
    await tester.pump();
    expect(find.text('160'), findsOneWidget);
    expect(find.text('208'), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip(english.less));
      await tester.pump();
    }
    expect(find.text('140'), findsOneWidget);
  });

  testWidgets('grams the server would refuse show an error and save nothing', (
    tester,
  ) async {
    final database = _memoryDatabase();
    final closedWith = await _pumpAmount(tester, database);

    await tester.enterText(find.byType(TextField), '1.25');
    await tester.tap(find.text(english.logButton(english.mealName('lunch'))));
    await tester.pumpAndSettle();

    expect(find.text(english.errorGrams), findsOneWidget);
    expect(closedWith, isEmpty);
    expect(await database.watchRecentFoods().first, isEmpty);
  });

  testWidgets('adds the entry to the chosen meal on the diary day it was '
      'opened for, and closes', (tester) async {
    final database = _memoryDatabase();
    final closedWith = await _pumpAmount(tester, database);

    await tester.tap(find.text('Pre-workout'));
    await tester.pump();
    await tester.tap(find.text(english.logButton('Pre-workout')));
    await tester.pumpAndSettle();

    expect(closedWith, [true]);
    final entry = await database.select(database.foodLogEntryTable).getSingle();
    expect(
      (entry.meal, entry.mealName, entry.grams, entry.diaryDay),
      (Meal.extra, 'Pre-workout', 1500, '2026-11-23'),
    );
  });

  testWidgets('a save that finishes after Back leaves the screen behind open', (
    tester,
  ) async {
    final database = _SlowDatabase();
    addTearDown(database.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en'), Locale('ar')],
        theme: lightTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => AmountScreen(
                          database: database,
                          food: _rice,
                          grams: 1500,
                          diaryDay: '2026-11-23',
                          meal: const DiaryMeal(Meal.lunch),
                          meals: const [DiaryMeal(Meal.lunch)],
                        ),
                      ),
                    ),
                    child: const Text('search'),
                  ),
                ),
              ),
            ),
            child: const Text('diary'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('diary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('search'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(english.logButton(english.mealName('lunch'))));
    await tester.pump();
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 10));
    database.save.complete();
    await tester.pumpAndSettle();

    expect(find.text('search'), findsOneWidget);
  });
}
