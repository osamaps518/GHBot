import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/auth/auth_session.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/core/theme.dart';
import 'package:ghbot/food_log/diary_screen.dart';
import 'package:ghbot/food_log/meal.dart';
import 'package:ghbot/foods/food.dart';
import 'package:ghbot/foods/foods_api.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:ghbot/targets/targets.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

/// Opens the diary on an in-memory database for a signed-in user with
/// [exampleTargets].
Future<AppDatabase> _pumpDiary(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({'dev_subject': 'alice'});
  final session = AuthSession(
    ApiClient(client: FakeBackend().client, baseUrl: 'http://backend.test'),
  );
  await session.restoreSignIn();
  final database = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: lightTheme,
      home: DiaryScreen(
        database: database,
        foodsApi: FoodsApi(session),
        targets: Targets.fromJson(exampleTargets),
        onOpenTargets: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return database;
}

Finder _inMeal(String meal, Finder finder) => find.descendant(
  of: find.ancestor(of: find.text(meal), matching: find.byType(Card)),
  matching: finder,
);

/// Scrolls the diary, which builds only what is on screen, to [finder].
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("shows today's entries under their meals, and the day's totals "
      'next to the targets', (tester) async {
    final database = await _pumpDiary(tester);
    final now = DateTime.now();
    for (final (json, grams, meal, loggedAt) in [
      (riceJson, 1500, Meal.lunch, now),
      (oilJson, 123, Meal.lunch, now),
      (riceJson, 1000, Meal.breakfast, now.subtract(const Duration(days: 1))),
    ]) {
      await database.logEntry(
        food: Food.fromJson(json),
        meal: DiaryMeal(meal),
        grams: grams,
        loggedAt: loggedAt,
      );
    }
    await tester.pumpAndSettle();

    expect(find.text('1906'), findsOneWidget);
    expect(find.text(english.eatenOfTarget('304', '2210')), findsOneWidget);
    expect(find.text(english.macroOfTarget('176')), findsOneWidget);
    final lunch = english.mealName('lunch');
    expect(_inMeal(lunch, find.text('304 ${english.caloriesUnit}')), findsOne);
    expect(_inMeal(lunch, find.text('Cooked white rice')), findsOne);
    expect(_inMeal(lunch, find.text('12.3 ${english.gramsUnit}')), findsOne);
    expect(_inMeal(lunch, find.text('109')), findsOne);
    final breakfast = english.mealName('breakfast');
    expect(_inMeal(breakfast, find.text(english.noEntries)), findsOne);
  });

  testWidgets("a meal's Add food logs into that meal, and the entry shows at "
      'once', (tester) async {
    await _pumpDiary(tester);
    final dinner = english.mealName('dinner');

    await _tap(tester, _inMeal(dinner, find.text(english.addFood)));
    expect(find.text(english.searchTitle(dinner)), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'rice');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Cooked white rice'));
    await _tap(tester, find.text(english.logButton(dinner)));

    expect(find.byType(DiaryScreen), findsOneWidget);
    expect(_inMeal(dinner, find.text('Cooked white rice')), findsOne);
    expect(_inMeal(dinner, find.text('100 ${english.gramsUnit}')), findsOne);
  });
}
