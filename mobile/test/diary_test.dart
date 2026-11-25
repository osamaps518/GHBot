import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/auth/auth_session.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/core/sync_runner.dart';
import 'package:ghbot/core/theme.dart';
import 'package:ghbot/food_log/diary_screen.dart';
import 'package:ghbot/food_log/entry_edit_screen.dart';
import 'package:ghbot/food_log/meal.dart';
import 'package:ghbot/foods/food.dart';
import 'package:ghbot/foods/food_search_screen.dart';
import 'package:ghbot/foods/foods_api.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:ghbot/targets/targets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

/// Opens the diary for a signed-in user with [exampleTargets], on a new
/// in-memory database unless [database] is given. Given one, it closes the
/// open diary first, as when the app restarts.
Future<AppDatabase> _pumpDiary(
  WidgetTester tester, {
  AppDatabase? database,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({'dev_subject': 'alice'});
  final session = AuthSession(
    ApiClient(client: FakeBackend().client, baseUrl: 'http://backend.test'),
  );
  await session.restoreSignIn();
  if (database == null) {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
  } else {
    await tester.pumpWidget(const SizedBox());
  }
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

/// Sends [database]'s unsent entries to [backend], signed in as alice.
Future<void> _sync(AppDatabase database, FakeBackend backend) async {
  final session = AuthSession(
    ApiClient(client: backend.client, baseUrl: 'http://backend.test'),
  );
  await session.signIn('alice');
  await SyncRunner(
    session: session,
    userId: userIdFor('alice'),
    database: database,
  ).run();
}

/// Scrolls the diary, which builds only what is on screen, to [finder].
/// `ensureVisible` covers a widget built just past the screen's edge.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
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

  testWidgets('a named extra meal shows after dinner until the screen closes, '
      'and stays once it has an entry', (tester) async {
    final database = await _pumpDiary(tester);

    await _tap(tester, find.text(english.addMeal));
    await tester.enterText(find.byType(TextField), '  Pre-workout ');
    await _tap(tester, find.widgetWithText(FilledButton, english.addFood));
    expect(find.text(english.searchTitle('Pre-workout')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_inMeal('Pre-workout', find.text(english.noEntries)), findsOne);
    expect(
      tester.getTopLeft(find.text('Pre-workout')).dy,
      greaterThan(tester.getTopLeft(find.text(english.mealName('dinner'))).dy),
    );

    await _pumpDiary(tester, database: database);
    await tester.scrollUntilVisible(
      find.text(english.addMeal),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(english.mealName('dinner')), findsOneWidget);
    expect(find.text('Pre-workout'), findsNothing);

    await _tap(tester, find.text(english.addMeal));
    await tester.enterText(find.byType(TextField), 'Pre-workout');
    await _tap(tester, find.widgetWithText(FilledButton, english.addFood));
    await tester.enterText(find.byType(TextField), 'oil');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Olive oil'));
    await _tap(tester, find.text(english.logButton('Pre-workout')));
    await _pumpDiary(tester, database: database);

    await tester.scrollUntilVisible(
      find.text('Pre-workout'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_inMeal('Pre-workout', find.text('Olive oil')), findsOne);
  });

  for (final (refused, typed) in [
    ('only spaces', '   '),
    ('a NUL character', 'a\u0000b'),
  ]) {
    testWidgets('an extra meal name with $refused is refused before search', (
      tester,
    ) async {
      final database = await _pumpDiary(tester);

      await _tap(tester, find.text(english.addMeal));
      await tester.enterText(find.byType(TextField), typed);
      await _tap(tester, find.widgetWithText(FilledButton, english.addFood));

      expect(find.text(english.errorMealName), findsOneWidget);
      expect(find.byType(FoodSearchScreen), findsNothing);
      expect(await database.unsentEntries(), isEmpty);
    });
  }

  testWidgets('the diary says how many entries wait to sync, and marks '
      'each, until they are sent', (tester) async {
    final database = await _pumpDiary(tester);
    for (final json in [riceJson, oilJson]) {
      await database.logEntry(
        food: Food.fromJson(json),
        meal: const DiaryMeal(Meal.lunch),
        grams: 1000,
        loggedAt: DateTime.now(),
      );
    }
    await tester.pumpAndSettle();
    final waitingMarks = find.descendant(
      of: find.byType(ListTile),
      matching: find.byIcon(Icons.schedule),
    );

    expect(find.text(english.waitingToSync(2)), findsOneWidget);
    expect(waitingMarks, findsNWidgets(2));

    await _sync(database, FakeBackend());
    await tester.pumpAndSettle();

    expect(find.text(english.waitingToSync(2)), findsNothing);
    expect(waitingMarks, findsNothing);
  });

  testWidgets('a refused entry is tinted and says so; tapping it explains '
      'and offers change or delete', (tester) async {
    final database = await _pumpDiary(tester);
    await database.logEntry(
      food: Food.fromJson(riceJson),
      meal: const DiaryMeal(Meal.lunch),
      grams: 1500,
      loggedAt: DateTime.now(),
    );
    final backend = FakeBackend()
      ..intercept = (request) =>
          request.url.path.startsWith('/me/food-log/entries/')
          ? http.Response('{"detail": [{"type": "value_error"}]}', 422)
          : null;

    await _sync(database, backend);
    await tester.pumpAndSettle();

    expect(find.text(english.refusedNote(1)), findsOneWidget);
    expect(find.text(english.waitingToSync(1)), findsNothing);
    final tile = find.widgetWithText(ListTile, 'Cooked white rice');
    expect(
      find.descendant(of: tile, matching: find.text(english.entryRefused)),
      findsOne,
    );
    final colors = lightTheme.colorScheme;
    expect(tester.widget<ListTile>(tile).tileColor, colors.errorContainer);

    await _tap(tester, find.text('Cooked white rice'));
    expect(find.text(english.entryRefusedAlert), findsOneWidget);
    expect(find.text(english.delete), findsOneWidget);
  });

  group('changing an entry', () {
    /// Logs rice, 150 g, into today's lunch, and opens it from the diary.
    Future<AppDatabase> openRice(WidgetTester tester) async {
      final database = await _pumpDiary(tester);
      await database.logEntry(
        food: Food.fromJson(riceJson),
        meal: const DiaryMeal(Meal.lunch),
        grams: 1500,
        loggedAt: DateTime.now(),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Cooked white rice'));
      return database;
    }

    FilledButton save(WidgetTester tester) => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, english.save),
    );

    testWidgets('Save waits for a new amount, and the diary shows it', (
      tester,
    ) async {
      await openRice(tester);
      expect(find.text(english.caloriesPer100g('130')), findsOneWidget);
      expect(save(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '200');
      await tester.pump();
      expect(find.text('260'), findsOneWidget);
      await tester.tap(find.text(english.save));
      await tester.pumpAndSettle();

      expect(find.byType(DiaryScreen), findsOneWidget);
      final lunch = english.mealName('lunch');
      expect(_inMeal(lunch, find.text('200 ${english.gramsUnit}')), findsOne);
      expect(_inMeal(lunch, find.text('260')), findsOne);
    });

    testWidgets('an amount the server would refuse shows the error and '
        'changes nothing', (tester) async {
      await openRice(tester);

      await tester.enterText(find.byType(TextField), '0');
      await tester.pump();
      await tester.tap(find.text(english.save));
      await tester.pumpAndSettle();

      expect(find.text(english.errorGrams), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('150 ${english.gramsUnit}'), findsOneWidget);
    });

    testWidgets('Delete asks first; Cancel keeps the entry, Delete removes '
        'it from the diary', (tester) async {
      await openRice(tester);
      final inDialog = find.byType(AlertDialog);

      await tester.tap(find.text(english.delete));
      await tester.pumpAndSettle();
      expect(
        find.text(english.deleteEntryTitle('Cooked white rice')),
        findsOne,
      );
      final now = DateTime.now();
      final today = english.diaryDate(
        english.weekdayName('${now.weekday}'),
        '${now.day}',
        english.monthName('${now.month}'),
      );
      expect(
        find.text(
          english.deleteEntryBody(english.mealName('lunch'), today, '195'),
        ),
        findsOne,
      );
      await tester.tap(
        find.descendant(of: inDialog, matching: find.text(english.cancel)),
      );
      await tester.pumpAndSettle();
      expect(inDialog, findsNothing);
      expect(find.byType(EntryEditScreen), findsOneWidget);

      await tester.tap(find.text(english.delete));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: inDialog, matching: find.text(english.delete)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DiaryScreen), findsOneWidget);
      expect(find.text('Cooked white rice'), findsNothing);
    });
  });
}
