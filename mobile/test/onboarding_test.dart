import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

Future<void> _choose(WidgetTester tester, String field, String option) async {
  await tester.tap(find.byKey(ValueKey(field)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// Types into a field and rebuilds, so buttons see the new text.
Future<void> _type(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Fills in the form with [savedProfile]'s values, using [l10n]'s labels.
Future<void> _fillForm(
  WidgetTester tester,
  AppLocalizations l10n, {
  String height = '180',
  String weight = '80',
}) async {
  await _choose(tester, 'birthMonth', l10n.monthName('3'));
  await _choose(tester, 'birthYear', '${DateTime.now().year - 30}');
  await _tapText(tester, l10n.sexMale);
  await _type(tester, find.byKey(const ValueKey('height')), height);
  await _type(tester, find.byKey(const ValueKey('weight')), weight);
  await _choose(
    tester,
    'activityLevel',
    l10n.activityName('moderately_active'),
  );
  await _tapText(tester, l10n.goalName('lose'));
}

void main() {
  testWidgets(
    'first launch: sign in, fill in the form in Arabic, see targets',
    (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('ar')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final arabic = lookupAppLocalizations(const Locale('ar'));
      final backend = FakeBackend();

      await pumpApp(tester, backend);
      await _type(tester, find.byType(TextField), 'alice');
      await _tapText(tester, arabic.continueButton);

      expect(find.text(arabic.profileTitle), findsOneWidget);
      // Some Arabic keyboards send Arabic-Indic digits and the Arabic comma.
      await _fillForm(tester, arabic, height: '١٨٠', weight: '٨٠٫٠');
      await _tapText(tester, arabic.calculateButton);

      final put = backend.requestsTo('PUT', '/me/profile').single;
      expect(jsonDecode(put.body), savedProfile());
      expect(find.text('2210'), findsOneWidget);
      expect(await SharedPreferencesAsync().getString('dev_subject'), 'alice');
    },
  );
}
