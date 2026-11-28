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
import 'package:http/http.dart' as http;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

/// What the search screen passed on when a food was chosen.
typedef _Chosen = ({String foodId, int grams});

/// Opens the search screen on an in-memory database for a signed-in user.
/// Returns the database, the foods chosen, and the screen's API.
Future<(AppDatabase, List<_Chosen>, FoodsApi)> _pumpSearch(
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
  final foodsApi = FoodsApi(session);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: lightTheme,
      home: FoodSearchScreen(
        title: 'Add to lunch',
        database: database,
        foodsApi: foodsApi,
        onChosen: (food, grams) => chosen.add((foodId: food.id, grams: grams)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (database, chosen, foodsApi);
}

/// Adds home yogurt, from the mockups, as an own food on the phone.
Future<Food> _addYogurt(AppDatabase database) => database.addOwnFood(
  nameAr: 'لبن رائب منزلي',
  nameEn: 'Home yogurt',
  per100g: const Nutrients(calories: 650, protein: 35, carbs: 47, fat: 33),
  barcode: null,
);

/// Plain yogurt, a catalog food whose ID sorts before any UUID, so the own
/// food comes first only by being own.
const _yogurtJson = {
  'id': '000-yogurt',
  'name_ar': 'لبن رائب',
  'name_en': 'Yogurt',
  'calories': 61.0,
  'protein': 3.5,
  'carbs': 4.7,
  'fat': 3.3,
  'barcode': null,
  'own': false,
  'revision': 0,
};

/// The search result tile of the food named [name].
Finder _tile(String name) => find.widgetWithText(ListTile, name);

/// Whether the tile of [name] shows the own food badge.
bool _hasBadge(String name) => find
    .descendant(of: _tile(name), matching: find.text(english.ownFoodBadge))
    .evaluate()
    .isNotEmpty;

/// Types [text] and waits for the search to start and answer.
Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('online, shows the server results; a food starts at 100 g', (
    tester,
  ) async {
    final (_, chosen, _) = await _pumpSearch(tester, FakeBackend());

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
    final (database, _, _) = await _pumpSearch(tester, backend);
    await database.storeFood(Food.fromJson(riceJson));

    await _search(tester, 'white');
    expect(find.text(english.searchOffline), findsOneWidget);
    expect(find.text('Cooked white rice'), findsOneWidget);

    await _search(tester, 'bread');
    expect(find.text(english.noResultsTitle('bread')), findsOneWidget);
  });

  testWidgets('before typing, shows recently logged foods, newest first, '
      'each with the grams it was last logged with', (tester) async {
    final (database, chosen, _) = await _pumpSearch(tester, FakeBackend());
    final noon = DateTime.utc(2026, 11, 23, 12);
    for (final (food, grams, minutes) in [
      (riceJson, 1500, 0),
      (oilJson, 123, 1),
      (riceJson, 1800, 2),
    ]) {
      await database.logEntry(
        food: Food.fromJson(food),
        meal: const DiaryMeal(Meal.lunch),
        grams: grams,
        diaryDay: '2026-11-23',
        loggedAt: noon.add(Duration(minutes: minutes)),
      );
    }
    await tester.pumpAndSettle();

    final rice = tester.getTopLeft(find.text('Cooked white rice'));
    final oil = tester.getTopLeft(find.text('Olive oil'));
    expect(rice.dy, lessThan(oil.dy));
    expect(find.text('180 ${english.gramsUnit}'), findsOneWidget);
    expect(find.text('12.3 ${english.gramsUnit}'), findsOneWidget);

    await tester.tap(find.text('Cooked white rice'));
    expect(chosen, [(foodId: 'rice', grams: 1800)]);
  });

  testWidgets('offline, own foods show with the logged ones, first, with '
      'the badge', (tester) async {
    final backend = FakeBackend()..offline = true;
    final (database, _, _) = await _pumpSearch(tester, backend);
    await database.storeFood(Food.fromJson(_yogurtJson));
    await _addYogurt(database);

    await _search(tester, 'yogurt');

    expect(
      tester.getTopLeft(_tile('Home yogurt')).dy,
      lessThan(tester.getTopLeft(_tile('Yogurt')).dy),
    );
    expect(_hasBadge('Home yogurt'), isTrue);
    expect(_hasBadge('Yogurt'), isFalse);
  });

  testWidgets("online, the server's own foods have the badge", (tester) async {
    final backend = FakeBackend()..foods = [_yogurtJson];
    final (database, _, foodsApi) = await _pumpSearch(tester, backend);
    await foodsApi.send(database, await _addYogurt(database));

    await _search(tester, 'yogurt');

    expect(_hasBadge('Home yogurt'), isTrue);
    expect(_hasBadge('Yogurt'), isFalse);
  });

  /// Whether the tile of [name] has the error tint.
  bool tinted(WidgetTester tester, String name) =>
      tester.widget<ListTile>(_tile(name)).tileColor ==
      lightTheme.colorScheme.errorContainer;

  for (final offline in [false, true]) {
    testWidgets('${offline ? 'offline' : 'online'}, a refused own food shows '
        'first, tinted', (tester) async {
      final backend = FakeBackend()
        ..foods = [_yogurtJson]
        ..intercept = (request) => request.url.path.startsWith('/me/foods/')
            ? http.Response('{"detail": [{"type": "value_error"}]}', 422)
            : null;
      final (database, _, foodsApi) = await _pumpSearch(tester, backend);
      await database.storeFood(Food.fromJson(_yogurtJson));
      await foodsApi.send(database, await _addYogurt(database));
      backend.offline = offline;

      await _search(tester, 'yogurt');

      expect(
        find.text(english.searchOffline),
        offline ? findsOne : findsNothing,
      );
      expect(
        tester.getTopLeft(_tile('Home yogurt')).dy,
        lessThan(tester.getTopLeft(_tile('Yogurt')).dy),
      );
      expect(tinted(tester, 'Home yogurt'), isTrue);
      expect(tinted(tester, 'Yogurt'), isFalse);
    });
  }

  testWidgets("online, a refused change of a food the server has shows once, "
      "as the phone's copy, tinted", (tester) async {
    final backend = FakeBackend();
    final (database, _, foodsApi) = await _pumpSearch(tester, backend);
    final yogurt = await _addYogurt(database);
    await foodsApi.send(database, yogurt);
    // #66 will change own foods; until then the test writes the change.
    await database.customStatement(
      "UPDATE foods SET name_en = 'Home yogurt, thick', revision = 2, "
      'refused = 1',
    );

    await _search(tester, 'yogurt');

    expect(_tile('Home yogurt, thick'), findsOne);
    expect(find.text('Home yogurt'), findsNothing);
    expect(tinted(tester, 'Home yogurt, thick'), isTrue);
  });

  group('adding a food', () {
    /// The text in the form's field with the key [key].
    String typed(WidgetTester tester, String key) =>
        tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

    Future<void> openForm(WidgetTester tester) async {
      await tester.tap(find.text(english.addOwnFood));
      await tester.pumpAndSettle();
    }

    testWidgets('with no results, the form starts with the typed name in its '
        'script, and the saved food is chosen at 100 g', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final (database, chosen, _) = await _pumpSearch(tester, FakeBackend());
      await _search(tester, 'قرص عيد');
      expect(find.text(english.noResultsBody), findsOneWidget);

      await openForm(tester);
      expect(typed(tester, 'nameAr'), 'قرص عيد');
      expect(typed(tester, 'nameEn'), isEmpty);
      for (final key in ['calories', 'protein', 'carbs', 'fat']) {
        await tester.enterText(find.byKey(ValueKey(key)), '10');
      }
      await tester.tap(find.text(english.save));
      await tester.pumpAndSettle();

      final food = (await database.unsentOwnFoods()).single;
      expect(chosen, [(foodId: food.id, grams: 1000)]);
    });

    testWidgets('below results too, online or offline; an English name '
        'starts in the English field', (tester) async {
      final backend = FakeBackend();
      final (database, _, _) = await _pumpSearch(tester, backend);
      await database.storeFood(Food.fromJson(riceJson));

      for (final (query, offline) in [('rice', false), ('white rice', true)]) {
        backend.offline = offline;
        await _search(tester, query);
        expect(find.text('Cooked white rice'), findsOneWidget);
        expect(find.text(english.cantFindIt), findsOneWidget);
      }

      await openForm(tester);
      expect(typed(tester, 'nameAr'), isEmpty);
      expect(typed(tester, 'nameEn'), 'white rice');
    });

    for (final (shown, previous) in [
      ('results', 'white rice'),
      ('no results', 'bread'),
    ]) {
      testWidgets('with $shown still showing, the form starts with the text '
          'typed since, before its search answers', (tester) async {
        final backend = FakeBackend()..offline = true;
        final (database, _, _) = await _pumpSearch(tester, backend);
        await database.storeFood(Food.fromJson(riceJson));
        await _search(tester, previous);

        // Before the 300 ms wait, so the last results still show.
        await tester.enterText(find.byType(TextField), '  Date maamoul ');
        await tester.pump();
        await openForm(tester);

        expect(typed(tester, 'nameEn'), 'Date maamoul');
      });
    }
  });
}
