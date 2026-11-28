import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/core/theme.dart';
import 'package:ghbot/foods/food.dart';
import 'package:ghbot/foods/own_food_form_screen.dart';
import 'package:ghbot/l10n/app_localizations.dart';

final english = lookupAppLocalizations(const Locale('en'));

/// Opens the form from a home screen on an in-memory database. Returns the
/// database and what the form closed with.
Future<(AppDatabase, List<Food?>)> _pumpForm(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final database = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);
  final closedWith = <Food?>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: lightTheme,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => closedWith.add(
            await Navigator.push<Food>(
              context,
              MaterialPageRoute(
                builder: (_) => OwnFoodFormScreen(database: database),
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return (database, closedWith);
}

/// Types [text] into the field with the key [field].
Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text(english.save));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Save keeps the food on the phone, own and waiting to be '
      'sent, and closes with it', (tester) async {
    final (database, closedWith) = await _pumpForm(tester);
    expect(find.text(english.newFood), findsOneWidget);

    await _type(tester, 'nameAr', '  معمول بالتمر ');
    await _type(tester, 'calories', '442');
    await _type(tester, 'protein', '5.6');
    await _type(tester, 'carbs', '٦٤');
    await _type(tester, 'fat', '18,2');
    await _save(tester);

    final stored = (await database.unsentOwnFoods()).single;
    expect(
      [stored.nameAr, stored.nameEn, stored.own],
      ['معمول بالتمر', null, true],
    );
    final values = stored.per100g;
    expect(
      [values.calories, values.protein, values.carbs, values.fat],
      [4420, 56, 640, 182],
    );
    expect(closedWith.single?.id, stored.id);
    expect(find.text(english.newFood), findsNothing);
  });

  testWidgets('Save with values the server would refuse shows what to fix '
      'and saves nothing', (tester) async {
    final (database, closedWith) = await _pumpForm(tester);

    await _type(tester, 'nameEn', '   ');
    await _type(tester, 'calories', '900.1');
    await _type(tester, 'protein', '50');
    await _type(tester, 'carbs', '40');
    await _type(tester, 'fat', '10.1');
    await _save(tester);

    expect(find.text(english.newFood), findsOneWidget);
    final hint = tester.widget<Text>(find.text(english.namesHint));
    expect(hint.style!.color, lightTheme.colorScheme.error);
    expect(find.text(english.errorCaloriesPer100g), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(english.errorMacrosOver100g),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(await database.select(database.foodTable).get(), isEmpty);
    expect(closedWith, isEmpty);

    await _type(tester, 'nameEn', 'x' * 81);
    expect(find.text(english.errorFoodName), findsOneWidget);
  });
}
