import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';

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
  });
}
