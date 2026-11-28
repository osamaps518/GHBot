import 'dart:async';

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
import 'package:ghbot/food_log/entry.dart';
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

/// Today's diary day, and the day [days] before it.
String _today() => diaryDayOf(DateTime.now());
String _daysAgo(int days) => addDays(_today(), -days);

/// A day as the diary writes it, such as "Monday, November 23".
String _dateText(String day) => diaryDateText(english, day);

/// An in-memory database whose diary for a day in [held] answers only once
/// that day's completer completes, as a slow first read would.
class _SlowDayDatabase extends AppDatabase {
  _SlowDayDatabase()
    : super(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );

  final held = <String, Completer<void>>{};

  @override
  Stream<List<LoggedFood>> watchDiaryDay(String diaryDay) async* {
    await held[diaryDay]?.future;
    yield* super.watchDiaryDay(diaryDay);
  }
}

/// Opens the diary for a signed-in user with [exampleTargets], whose account
/// was created on [firstDay] (30 days ago unless given), on a new in-memory
/// database unless [database] is given. Given one, it closes the open diary
/// first, as when the app restarts. [clock] stands in for the phone's clock.
Future<AppDatabase> _pumpDiary(
  WidgetTester tester, {
  AppDatabase? database,
  String? firstDay,
  DateTime Function() clock = DateTime.now,
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
        firstDay: firstDay ?? _daysAgo(30),
        clock: clock,
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
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Flutter's own English text, as in the date picker.
const _material = DefaultMaterialLocalizations();

/// Types [day] into the open date picker, switching it to typing first,
/// and taps OK.
Future<void> _typeDate(WidgetTester tester, String day) async {
  final typing = find.byIcon(Icons.edit_outlined);
  if (typing.evaluate().isNotEmpty) {
    await tester.tap(typing);
    await tester.pumpAndSettle();
  }
  await tester.enterText(
    find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)),
    _material.formatCompactDate(DateTime.parse(day)),
  );
  await tester.tap(find.text(_material.okButtonLabel));
  await tester.pumpAndSettle();
}

/// Scrolls the diary back to its day and totals.
Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

/// Scrolls the diary to [finder] and taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
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
        diaryDay: diaryDayOf(loggedAt),
        loggedAt: loggedAt,
      );
    }
    await tester.pumpAndSettle();

    expect(find.text('1906'), findsOneWidget);
    expect(find.text(english.eatenOfTarget('304', '2210')), findsOneWidget);
    expect(find.text(english.macroOfTarget('176')), findsOneWidget);
    final lunch = english.mealName('lunch');
    await _scrollTo(tester, find.text('12.3 ${english.gramsUnit}'));
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
        diaryDay: diaryDayOf(DateTime.now()),
        loggedAt: DateTime.now(),
      );
    }
    await tester.pumpAndSettle();
    final waitingMarks = find.descendant(
      of: find.byType(ListTile),
      matching: find.byIcon(Icons.schedule),
    );

    expect(find.text(english.waitingToSync(2)), findsOneWidget);
    await _scrollTo(tester, find.text('Olive oil'));
    expect(waitingMarks, findsNWidgets(2));

    await _sync(database, FakeBackend());
    await tester.pumpAndSettle();

    expect(waitingMarks, findsNothing);
    await _scrollToTop(tester);
    expect(find.text(english.waitingToSync(2)), findsNothing);
    expect(find.text(english.today), findsOneWidget);
  });

  testWidgets('a refused entry is tinted and says so; tapping it explains '
      'and offers change or delete', (tester) async {
    final database = await _pumpDiary(tester);
    await database.logEntry(
      food: Food.fromJson(riceJson),
      meal: const DiaryMeal(Meal.lunch),
      grams: 1500,
      diaryDay: diaryDayOf(DateTime.now()),
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

  group('past days', () {
    /// Logs [grams] (in tenths) of [json] into lunch on [day].
    Future<void> logLunch(
      AppDatabase database,
      Map<String, Object?> json,
      int grams,
      String day,
    ) => database.logEntry(
      food: Food.fromJson(json),
      meal: const DiaryMeal(Meal.lunch),
      grams: grams,
      diaryDay: day,
      loggedAt: DateTime.now(),
    );

    bool enabled(WidgetTester tester, String arrow) =>
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip(arrow),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed !=
        null;

    Future<void> tapArrow(WidgetTester tester, String arrow) async {
      await tester.tap(find.byTooltip(arrow));
      await tester.pumpAndSettle();
    }

    testWidgets('the arrows go a day back and forward, between the account '
        'day and today, and each day shows its own entries and totals', (
      tester,
    ) async {
      final database = await _pumpDiary(tester, firstDay: _daysAgo(2));
      await logLunch(database, riceJson, 1500, _today());
      await logLunch(database, oilJson, 123, _daysAgo(1));
      await tester.pumpAndSettle();

      expect(find.text(english.today), findsOneWidget);
      expect(find.text(english.backToToday), findsNothing);
      expect(enabled(tester, english.nextDay), isFalse);
      expect(find.text(english.eatenOfTarget('195', '2210')), findsOneWidget);

      await tapArrow(tester, english.previousDay);
      expect(find.text(english.yesterday), findsOneWidget);
      expect(find.text(_dateText(_daysAgo(1))), findsOneWidget);
      expect(find.text(english.eatenOfTarget('109', '2210')), findsOneWidget);
      expect(find.text(english.macroOfTarget('176')), findsOneWidget);
      expect(enabled(tester, english.nextDay), isTrue);
      await _scrollTo(tester, find.text('Olive oil'));
      expect(find.text('Cooked white rice'), findsNothing);
      await _scrollToTop(tester);

      await tapArrow(tester, english.previousDay);
      // An older day shows its date as the title, with no second line.
      expect(find.text(_dateText(_daysAgo(2))), findsOneWidget);
      expect(find.text(english.yesterday), findsNothing);
      expect(find.text(english.today), findsNothing);
      expect(find.text(english.eatenOfTarget('0', '2210')), findsOneWidget);
      expect(enabled(tester, english.previousDay), isFalse);

      await tapArrow(tester, english.nextDay);
      expect(find.text(english.yesterday), findsOneWidget);

      await tester.tap(find.text(english.backToToday));
      await tester.pumpAndSettle();
      expect(find.text(english.today), findsOneWidget);
      expect(find.text(english.backToToday), findsNothing);
      expect(find.text(english.eatenOfTarget('195', '2210')), findsOneWidget);
    });

    testWidgets("a day whose entries haven't loaded yet shows none of the "
        "day before's", (tester) async {
      final database = _SlowDayDatabase();
      addTearDown(database.close);
      await _pumpDiary(tester, database: database);
      await logLunch(database, riceJson, 1500, _today());
      await logLunch(database, oilJson, 123, _daysAgo(1));
      await tester.pumpAndSettle();
      expect(find.text(english.eatenOfTarget('195', '2210')), findsOneWidget);

      final yesterday = database.held[_daysAgo(1)] = Completer();
      await tester.tap(find.byTooltip(english.previousDay));
      await tester.pump();

      expect(find.text(english.yesterday), findsOneWidget);
      expect(find.text(english.eatenOfTarget('195', '2210')), findsNothing);
      expect(find.text('Cooked white rice'), findsNothing);

      yesterday.complete();
      await tester.pumpAndSettle();
      expect(find.text(english.eatenOfTarget('109', '2210')), findsOneWidget);
    });

    testWidgets('at 4:00, a diary showing today moves to the new today', (
      tester,
    ) async {
      var now = DateTime(2026, 11, 28, 3, 59);
      final database = await _pumpDiary(
        tester,
        firstDay: '2026-11-01',
        clock: () => now,
      );
      await logLunch(database, riceJson, 1500, '2026-11-27');
      await logLunch(database, oilJson, 123, '2026-11-28');
      await tester.pumpAndSettle();
      expect(find.text(_dateText('2026-11-27')), findsOneWidget);
      expect(find.text(english.eatenOfTarget('195', '2210')), findsOneWidget);

      now = DateTime(2026, 11, 28, 4);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text(english.today), findsOneWidget);
      expect(find.text(_dateText('2026-11-28')), findsOneWidget);
      expect(find.text(english.eatenOfTarget('109', '2210')), findsOneWidget);
      expect(enabled(tester, english.nextDay), isFalse);
    });

    testWidgets('at 4:00, a diary showing a past day stays on it, and names '
        'it from the new today', (tester) async {
      var now = DateTime(2026, 11, 28, 3, 59);
      final database = await _pumpDiary(
        tester,
        firstDay: '2026-11-01',
        clock: () => now,
      );
      await logLunch(database, riceJson, 1500, '2026-11-26');
      await tapArrow(tester, english.previousDay);
      expect(find.text(english.yesterday), findsOneWidget);

      now = DateTime(2026, 11, 28, 4);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text(english.yesterday), findsNothing);
      expect(find.text(_dateText('2026-11-26')), findsOneWidget);
      expect(find.text(english.eatenOfTarget('195', '2210')), findsOneWidget);
      await tester.tap(find.text(english.backToToday));
      await tester.pumpAndSettle();
      expect(find.text(english.today), findsOneWidget);
      expect(find.text(_dateText('2026-11-28')), findsOneWidget);
    });

    testWidgets('food logged on a past day goes on that day', (tester) async {
      final database = await _pumpDiary(tester);
      await tapArrow(tester, english.previousDay);
      final dinner = english.mealName('dinner');

      await _tap(tester, _inMeal(dinner, find.text(english.addFood)));
      await tester.enterText(find.byType(TextField), 'rice');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Cooked white rice'));
      await _tap(tester, find.text(english.logButton(dinner)));

      expect(_inMeal(dinner, find.text('Cooked white rice')), findsOne);
      expect((await database.unsentEntries()).single.diaryDay, _daysAgo(1));
    });

    testWidgets('a food added from search is logged at once, on the day and '
        'in the meal search was opened for', (tester) async {
      final database = await _pumpDiary(tester);
      await tapArrow(tester, english.previousDay);
      final dinner = english.mealName('dinner');

      await _tap(tester, _inMeal(dinner, find.text(english.addFood)));
      await tester.enterText(find.byType(TextField), 'Date maamoul');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await _tap(tester, find.text(english.addOwnFood));
      for (final (key, typed) in [
        ('calories', '442'),
        ('protein', '5.6'),
        ('carbs', '64'),
        ('fat', '18.2'),
      ]) {
        await tester.enterText(find.byKey(ValueKey(key)), typed);
      }
      await _tap(tester, find.text(english.save));
      await _tap(tester, find.text(english.logButton(dinner)));

      expect(_inMeal(dinner, find.text('Date maamoul')), findsOne);
      final entry = (await database.unsentEntries()).single;
      expect([entry.diaryDay, entry.grams], [_daysAgo(1), 1000]);
      expect((await database.unsentOwnFoods()).single.id, entry.foodId);
    });

    testWidgets('tapping the day opens the date picker, which goes from the '
        'account day to today', (tester) async {
      await _pumpDiary(tester, firstDay: _daysAgo(5));

      await tester.tap(find.text(english.today));
      await tester.pumpAndSettle();
      for (final outside in [_daysAgo(6), addDays(_today(), 1)]) {
        await _typeDate(tester, outside);
        expect(find.text(_material.dateOutOfRangeLabel), findsOneWidget);
      }
      await _typeDate(tester, _daysAgo(5));

      expect(find.byType(Dialog), findsNothing);
      expect(find.text(_dateText(_daysAgo(5))), findsOneWidget);
      expect(enabled(tester, english.previousDay), isFalse);
    });
  });

  group('changing an entry', () {
    /// Logs rice, 150 g, into today's lunch, and opens it from the diary of
    /// an account created on [firstDay].
    Future<AppDatabase> openRice(
      WidgetTester tester, {
      String? firstDay,
    }) async {
      final database = await _pumpDiary(tester, firstDay: firstDay);
      await database.logEntry(
        food: Food.fromJson(riceJson),
        meal: const DiaryMeal(Meal.lunch),
        grams: 1500,
        diaryDay: diaryDayOf(DateTime.now()),
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

    testWidgets('Save closes the screen when sync removed the entry '
        'meanwhile, and the entry stays deleted', (tester) async {
      final database = await openRice(tester);
      final id = (await database.unsentEntries()).single.id;
      final backend = FakeBackend()
        ..entries[id] = {'id': id, 'revision': 0, 'deleted': true};
      await _sync(database, backend);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '200');
      await tester.pump();
      await tester.tap(find.text(english.save));
      await tester.pumpAndSettle();
      await _sync(database, backend);

      expect(find.byType(EntryEditScreen), findsNothing);
      expect(find.text('Cooked white rice'), findsNothing);
      expect(backend.entryRequests, hasLength(1));
      expect(backend.entries[id], containsPair('deleted', true));
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

    /// The move sheet's row for [day], by its name or date.
    Finder sheetRow(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.widgetWithText(ListTile, text),
    );

    testWidgets('the date opens the move sheet with today and the six days '
        "before it, the entry's day marked; Save moves it there with its "
        'new amount', (tester) async {
      final database = await openRice(tester);

      await tester.tap(find.text(_dateText(_today())));
      await tester.pumpAndSettle();
      expect(find.text(english.moveToAnotherDay), findsOneWidget);
      expect(
        find.text(english.moveStaysInMeal(english.mealName('lunch'))),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheetRow(english.today),
          matching: find.byIcon(Icons.check),
        ),
        findsOne,
      );
      expect(sheetRow(english.yesterday), findsOne);
      for (var days = 2; days <= 6; days++) {
        expect(sheetRow(_dateText(_daysAgo(days))), findsOne);
      }
      expect(find.text(_dateText(_daysAgo(7))), findsNothing);
      expect(find.text(english.otherDate), findsOneWidget);

      await tester.tap(sheetRow(_dateText(_daysAgo(3))));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(_dateText(_daysAgo(3))), findsOneWidget);
      await tester.enterText(find.byType(TextField), '200');
      await tester.pump();
      await tester.tap(find.text(english.save));
      await tester.pumpAndSettle();

      expect(find.byType(DiaryScreen), findsOneWidget);
      expect(find.text(english.eatenOfTarget('0', '2210')), findsOneWidget);
      final moved = (await database.unsentEntries()).single;
      expect(
        (moved.diaryDay, moved.grams, moved.meal),
        (_daysAgo(3), 2000, Meal.lunch),
      );
    });

    testWidgets('the sheet lists no day before the account day, and Another '
        'date opens the date picker from the account day to today', (
      tester,
    ) async {
      final database = await openRice(tester, firstDay: _daysAgo(3));

      await tester.tap(find.text(_dateText(_today())));
      await tester.pumpAndSettle();
      expect(sheetRow(_dateText(_daysAgo(3))), findsOne);
      expect(find.text(_dateText(_daysAgo(4))), findsNothing);

      await tester.tap(find.text(english.otherDate));
      await tester.pumpAndSettle();
      await _typeDate(tester, _daysAgo(4));
      expect(find.text(_material.dateOutOfRangeLabel), findsOneWidget);
      await _typeDate(tester, _daysAgo(3));
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tap(find.text(english.save));
      await tester.pumpAndSettle();

      expect((await database.unsentEntries()).single.diaryDay, _daysAgo(3));
    });

    testWidgets('choosing the day the entry is on leaves Save off', (
      tester,
    ) async {
      await openRice(tester);

      await tester.tap(find.text(_dateText(_today())));
      await tester.pumpAndSettle();
      await tester.tap(sheetRow(english.today));
      await tester.pumpAndSettle();

      expect(save(tester).onPressed, isNull);
    });

    testWidgets('the move sheet takes today from the clock each time it '
        'opens, not when the entry opened', (tester) async {
      var now = DateTime(2026, 11, 28, 3, 59);
      final database = await _pumpDiary(
        tester,
        firstDay: '2026-11-01',
        clock: () => now,
      );
      await database.logEntry(
        food: Food.fromJson(riceJson),
        meal: const DiaryMeal(Meal.lunch),
        grams: 1500,
        diaryDay: '2026-11-27',
        loggedAt: now,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Cooked white rice'));
      Finder rowWithDate(String name, String day) => find.descendant(
        of: sheetRow(name),
        matching: find.text(_dateText(day)),
      );

      now = DateTime(2026, 11, 28, 4, 1);
      await tester.tap(find.text(_dateText('2026-11-27')));
      await tester.pumpAndSettle();
      expect(rowWithDate(english.today, '2026-11-28'), findsOne);
      expect(rowWithDate(english.yesterday, '2026-11-27'), findsOne);
      await tester.tap(find.text(english.cancel));
      await tester.pumpAndSettle();

      now = DateTime(2026, 11, 29, 4, 1);
      await tester.tap(find.text(_dateText('2026-11-27')));
      await tester.pumpAndSettle();
      expect(rowWithDate(english.today, '2026-11-29'), findsOne);
      await tester.tap(sheetRow(english.today));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.save));
      await tester.pumpAndSettle();

      expect((await database.unsentEntries()).single.diaryDay, '2026-11-29');
    });
  });
}
