import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

/// The custom targets from the #51 mockup: 2400 kcal, whose macros give
/// 4 × 160 + 4 × 296 + 9 × 64 = 2400 kcal, over [exampleTargets] as the
/// recommended ones.
final customTargets = {
  ...exampleTargets,
  'calories': 2400,
  'protein_g': 160,
  'fat_g': 64,
  'carbs_g': 296,
  'custom': true,
};

/// Opens the targets form from the diary, through the targets.
Future<void> _openForm(WidgetTester tester) async {
  await openTargets(tester);
  await tester.tap(find.text(english.editTargets));
  await tester.pumpAndSettle();
}

/// Types the four values into the targets form.
Future<void> _typeTargets(
  WidgetTester tester, {
  required String calories,
  required String protein,
  required String carbs,
  required String fat,
}) async {
  for (final (field, text) in [
    ('calories', calories),
    ('protein', protein),
    ('carbs', carbs),
    ('fat', fat),
  ]) {
    await tester.enterText(find.byKey(ValueKey(field)), text);
  }
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

FilledButton _saveButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, english.save),
);

void main() {
  testWidgets('custom targets show as custom, with the recommended calories '
      'and how those were calculated', (tester) async {
    final backend = FakeBackend()
      ..profile = savedProfile()
      ..targets = customTargets;

    await pumpApp(tester, backend, storedName: 'alice');
    await openTargets(tester);

    expect(find.text('2400'), findsOneWidget);
    expect(find.text(english.customBadge), findsOneWidget);
    expect(find.text(english.customTargetsNote('2210')), findsOneWidget);
    expect(find.text(english.howWeCalculatedRecommended), findsOneWidget);
    expect(find.text(english.howWeCalculated), findsNothing);
  });

  testWidgets('custom targets raised to the minimum say their macros were '
      'adjusted, not that the recommended ones were raised', (tester) async {
    final backend = FakeBackend()
      ..profile = savedProfile()
      ..targets = {
        ...customTargets,
        'calories': 1500,
        'protein_g': 128,
        'fat_g': 34,
        'carbs_g': 164,
        'at_minimum': true,
        'macros_adjusted': true,
      };

    await pumpApp(tester, backend, storedName: 'alice');
    await openTargets(tester);

    expect(find.text(english.macrosAdjustedNote), findsOneWidget);
    expect(find.text(english.minimumNote), findsNothing);
    expect(find.text(english.raisedToMinimum), findsNothing);
  });

  group('back to recommended', () {
    /// Opens alice's custom targets, stored on the phone in [storage].
    Future<FakeBackend> openCustom(
      WidgetTester tester,
      PhoneStorage storage,
    ) async {
      final backend = FakeBackend()
        ..profile = savedProfile()
        ..targets = customTargets;
      await pumpApp(tester, backend, storedName: 'alice', storage: storage);
      await openTargets(tester);
      return backend;
    }

    testWidgets('asks first, then the recommended targets show, offline too', (
      tester,
    ) async {
      final storage = PhoneStorage();
      final backend = await openCustom(tester, storage);

      await _tapText(tester, english.backToRecommended);
      expect(
        find.text(english.resetBody('2210', '176', '266', '49')),
        findsOne,
      );
      await _tapText(tester, english.cancel);
      expect(backend.requestsTo('DELETE', '/me/targets/custom'), isEmpty);
      expect(find.text(english.customBadge), findsOneWidget);

      await _tapText(tester, english.backToRecommended);
      await _tapText(tester, english.backToRecommended);
      expect(backend.requestsTo('DELETE', '/me/targets/custom'), hasLength(1));
      expect(find.text(english.customBadge), findsNothing);
      expect(find.text('2210'), findsOneWidget);

      backend.offline = true;
      await restartApp(tester, backend, storage);
      await openTargets(tester);
      expect(find.text(english.customBadge), findsNothing);
      expect(find.text('2210'), findsOneWidget);
    });

    testWidgets('offline, shows the connection error and keeps the custom '
        'targets; Retry resets them', (tester) async {
      final storage = PhoneStorage();
      final backend = await openCustom(tester, storage);

      backend.offline = true;
      await _tapText(tester, english.backToRecommended);
      await _tapText(tester, english.backToRecommended);
      expect(find.text(english.errorConnection), findsOneWidget);
      expect(find.text(english.customBadge), findsOneWidget);

      backend.offline = false;
      await _tapText(tester, english.retry);
      expect(find.text(english.customBadge), findsNothing);
    });
  });

  group('the targets form', () {
    testWidgets('opens on the targets in effect, saves on the server, and '
        'the custom targets it sends back show offline too', (tester) async {
      final backend = FakeBackend()..profile = savedProfile();
      final storage = PhoneStorage();
      await pumpApp(tester, backend, storedName: 'alice', storage: storage);
      await _openForm(tester);
      expect(find.text('2210'), findsOneWidget);
      expect(find.text(english.recommendedValue('protein', '176')), findsOne);

      await _typeTargets(
        tester,
        calories: '٢٤٠٠',
        protein: '160',
        carbs: '296',
        fat: '64',
      );
      expect(find.text(english.macroCaloriesLine('2400')), findsOneWidget);
      await _tapText(tester, english.save);

      final put = backend.requestsTo('PUT', '/me/targets/custom').single;
      expect(jsonDecode(put.body), {
        'calories': 2400,
        'protein_g': 160,
        'fat_g': 64,
        'carbs_g': 296,
      });
      expect(find.text(english.customBadge), findsOneWidget);
      expect(find.text('2400'), findsOneWidget);

      backend.offline = true;
      await restartApp(tester, backend, storage);
      await openTargets(tester);
      expect(find.text(english.customBadge), findsOneWidget);
      expect(find.text('2400'), findsOneWidget);
    });

    testWidgets("macros 100 kcal or more from the calories show an error and "
        "can't be saved", (tester) async {
      final backend = FakeBackend()..profile = savedProfile();
      await pumpApp(tester, backend, storedName: 'alice');
      await _openForm(tester);

      await _typeTargets(
        tester,
        calories: '2400',
        protein: '160',
        carbs: '330',
        fat: '60',
      );
      expect(find.text(english.macrosTooFar('2500', '100')), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNull);

      await _typeTargets(
        tester,
        calories: '2401',
        protein: '160',
        carbs: '330',
        fat: '60',
      );
      expect(find.text(english.macrosTooFar('2500', '99')), findsNothing);
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('macros under 100 kcal from the calories ask first: fix the '
        'numbers goes back, keep saves', (tester) async {
      final backend = FakeBackend()..profile = savedProfile();
      await pumpApp(tester, backend, storedName: 'alice');
      await _openForm(tester);
      await _typeTargets(
        tester,
        calories: '2400',
        protein: '160',
        carbs: '300',
        fat: '60',
      );

      await _tapText(tester, english.save);
      expect(find.text(english.macrosApartTitle('20')), findsOneWidget);
      await _tapText(tester, english.fixNumbers);
      expect(find.text(english.macrosApartTitle('20')), findsNothing);
      expect(find.text('300'), findsOneWidget);
      expect(backend.requestsTo('PUT', '/me/targets/custom'), isEmpty);

      await _tapText(tester, english.save);
      await _tapText(tester, english.keepNumbers);
      final put = backend.requestsTo('PUT', '/me/targets/custom').single;
      expect(jsonDecode(put.body), containsPair('carbs_g', 300));
      expect(find.text(english.customBadge), findsOneWidget);
    });

    testWidgets('offline, a save shows the connection error, keeps the typed '
        'numbers and changes nothing; Retry saves them', (tester) async {
      final backend = FakeBackend()..profile = savedProfile();
      final storage = PhoneStorage();
      await pumpApp(tester, backend, storedName: 'alice', storage: storage);
      await _openForm(tester);
      await _typeTargets(
        tester,
        calories: '2400',
        protein: '160',
        carbs: '296',
        fat: '64',
      );

      backend.offline = true;
      await _tapText(tester, english.save);
      expect(find.text(english.errorConnection), findsOneWidget);
      expect(find.text('2400'), findsOneWidget);
      expect(backend.targets, exampleTargets);

      await restartApp(tester, backend, storage);
      await openTargets(tester);
      expect(find.text('2210'), findsOneWidget);
      expect(find.text(english.customBadge), findsNothing);

      await _openForm(tester);
      await _typeTargets(
        tester,
        calories: '2400',
        protein: '160',
        carbs: '296',
        fat: '64',
      );
      await _tapText(tester, english.save);
      backend.offline = false;
      await _tapText(tester, english.retry);
      expect(find.text(english.customBadge), findsOneWidget);
    });

    testWidgets('Retry after an offline save keeps the 100 kcal check', (
      tester,
    ) async {
      final backend = FakeBackend()..profile = savedProfile();
      await pumpApp(tester, backend, storedName: 'alice');
      await _openForm(tester);
      await _typeTargets(
        tester,
        calories: '2400',
        protein: '160',
        carbs: '296',
        fat: '64',
      );
      backend.offline = true;
      await _tapText(tester, english.save);
      expect(find.text(english.retry), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('calories')), '2500');
      await tester.pump();
      backend.offline = false;
      await _tapText(tester, english.retry);

      expect(find.text(english.macrosTooFar('2400', '100')), findsOneWidget);
      expect(find.text(english.macrosApartTitle('100')), findsNothing);
      expect(backend.requestsTo('PUT', '/me/targets/custom'), hasLength(1));
    });

    testWidgets("a save below the minimum shows the server's minimum on the "
        'calories', (tester) async {
      final backend = FakeBackend()..profile = savedProfile();
      backend.intercept = (request) => request.method == 'PUT'
          ? http.Response(
              jsonEncode({
                'detail': [
                  {
                    'type': 'below_minimum',
                    'loc': ['body', 'calories'],
                    'msg': 'Calories are below the minimum',
                    'input': 1100,
                    'ctx': {'minimum': 1500},
                  },
                ],
              }),
              422,
            )
          : null;
      await pumpApp(tester, backend, storedName: 'alice');
      await _openForm(tester);
      await _typeTargets(
        tester,
        calories: '1100',
        protein: '85',
        carbs: '136',
        fat: '24',
      );

      await _tapText(tester, english.save);

      expect(find.text(english.errorBelowMinimum('1500')), findsOneWidget);
      expect(find.text(english.customBadge), findsNothing);
    });
  });
}
