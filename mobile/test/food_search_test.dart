import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/auth/auth_session.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/core/theme.dart';
import 'package:ghbot/food_log/meal.dart';
import 'package:ghbot/foods/food.dart';
import 'package:ghbot/foods/food_search_screen.dart';
import 'package:ghbot/foods/foods_api.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

/// What the search screen passed on when a food was chosen.
typedef _Chosen = ({String foodId, int grams});

/// Opens the search screen on an in-memory database for a signed-in user.
Future<(AppDatabase, List<_Chosen>)> _pumpSearch(
  WidgetTester tester,
  FakeBackend backend,
) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({'dev_subject': 'alice'});
  final session = AuthSession(
    ApiClient(client: backend.client, baseUrl: 'http://backend.test'),
  );
  await session.restoreSignIn();
  final database = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);
  final chosen = <_Chosen>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: lightTheme,
      home: FoodSearchScreen(
        title: 'Add to lunch',
        database: database,
        foodsApi: FoodsApi(session),
        onChosen: (food, grams) => chosen.add((foodId: food.id, grams: grams)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (database, chosen);
}

/// Types [text] and waits for the search to start and answer.
Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

/// Logs [food] the way the diary does, at [loggedAt].
Future<void> _logged(
  AppDatabase database,
  Map<String, Object?> food, {
  required int grams,
  required DateTime loggedAt,
}) async {
  final stored = Food.fromJson(food);
  await database.storeFood(stored);
  await database
      .into(database.foodLogEntryTable)
      .insert(
        FoodLogEntryTableCompanion.insert(
          id: 'entry-${food['id']}-${loggedAt.millisecondsSinceEpoch}',
          foodId: stored.id,
          meal: Meal.lunch,
          diaryDay: '2026-11-23',
          grams: grams,
          caloriesPer100g: stored.per100g.calories,
          proteinPer100g: stored.per100g.protein,
          carbsPer100g: stored.per100g.carbs,
          fatPer100g: stored.per100g.fat,
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          loggedAt: loggedAt,
        ),
      );
}

void main() {
  testWidgets('online, shows the server results; a food starts at 100 g', (
    tester,
  ) async {
    final (_, chosen) = await _pumpSearch(tester, FakeBackend());

    await _search(tester, 'rice');
    expect(find.text('Cooked white rice'), findsOneWidget);
    expect(find.text('130 ${english.caloriesUnit}'), findsOneWidget);

    await tester.tap(find.text('Cooked white rice'));
    expect(chosen, [(foodId: 'rice', grams: 1000)]);
  });

  testWidgets("an older search's late answer doesn't replace a newer one", (
    tester,
  ) async {
    final backend = FakeBackend();
    final olderAnswer = Completer<void>();
    backend.holdSearches['o'] = olderAnswer;
    await _pumpSearch(tester, backend);

    // Not _search: settling would wait past the 5-second timeout.
    await tester.enterText(find.byType(TextField), 'o');
    await tester.pump(const Duration(milliseconds: 300));
    await _search(tester, 'oil');
    expect(find.text('Olive oil'), findsOneWidget);

    olderAnswer.complete();
    await tester.pumpAndSettle();
    expect(find.text('Olive oil'), findsOneWidget);
    expect(find.text('Cooked white rice'), findsNothing);
  });

  testWidgets("offline, filters the phone's foods and says other foods need "
      'internet', (tester) async {
    final backend = FakeBackend()..offline = true;
    final (database, _) = await _pumpSearch(tester, backend);
    await database.storeFood(Food.fromJson(riceJson));

    await _search(tester, 'white');
    expect(find.text(english.searchOffline), findsOneWidget);
    expect(find.text('Cooked white rice'), findsOneWidget);

    await _search(tester, 'bread');
    expect(find.text(english.noResultsTitle('bread')), findsOneWidget);
  });

  testWidgets('before typing, shows recently logged foods, newest first, '
      'each with the grams it was last logged with', (tester) async {
    final (database, chosen) = await _pumpSearch(tester, FakeBackend());
    final noon = DateTime.utc(2026, 11, 23, 12);
    await _logged(database, riceJson, grams: 1500, loggedAt: noon);
    await _logged(
      database,
      oilJson,
      grams: 123,
      loggedAt: noon.add(const Duration(minutes: 1)),
    );
    await _logged(
      database,
      riceJson,
      grams: 1800,
      loggedAt: noon.add(const Duration(minutes: 2)),
    );
    await tester.pumpAndSettle();

    final rice = tester.getTopLeft(find.text('Cooked white rice'));
    final oil = tester.getTopLeft(find.text('Olive oil'));
    expect(rice.dy, lessThan(oil.dy));
    expect(find.text('180 ${english.gramsUnit}'), findsOneWidget);
    expect(find.text('12.3 ${english.gramsUnit}'), findsOneWidget);

    await tester.tap(find.text('Cooked white rice'));
    expect(chosen, [(foodId: 'rice', grams: 1800)]);
  });
}
