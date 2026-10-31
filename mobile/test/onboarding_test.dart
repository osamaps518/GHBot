import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
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

  // The other tests run with an English (en_US) phone, the default.

  testWidgets('reopening goes straight to the targets, and editing updates '
      'them', (tester) async {
    final backend = FakeBackend()..profile = savedProfile();

    await pumpApp(tester, backend, storedName: 'alice');

    final token = backend.requestsTo('POST', '/dev/token').single;
    expect(jsonDecode(token.body), {'subject': 'alice'});
    expect(find.text('2210'), findsOneWidget);
    expect(find.text(english.goalRow('lose')), findsOneWidget);
    expect(find.text(english.minimumNote), findsNothing);

    await _tapText(tester, english.editMyInfo);
    expect(find.text('180'), findsOneWidget);
    backend.targets = {
      ...exampleTargets,
      'calories': 2760,
      'carbs_g': 401,
      'fat_g': 61,
    };
    await _tapText(tester, english.goalName('maintain'));
    await _tapText(tester, english.calculateButton);

    final put = backend.requestsTo('PUT', '/me/profile').single;
    expect(jsonDecode(put.body), savedProfile(goal: 'maintain'));
    expect(find.text('2760'), findsNWidgets(2));
    expect(find.text(english.goalRow('maintain')), findsOneWidget);
    expect(find.text(english.goalAdjustment('maintain')), findsOneWidget);
  });

  group('the form', () {
    // A stored name without a profile opens the form directly.
    Future<FakeBackend> openForm(WidgetTester tester) async {
      final backend = FakeBackend();
      await pumpApp(tester, backend, storedName: 'alice');
      expect(find.text(english.profileTitle), findsOneWidget);
      return backend;
    }

    testWidgets('shows a field error and sends nothing', (tester) async {
      final backend = await openForm(tester);

      await _fillForm(tester, english, weight: '8');
      await _tapText(tester, english.calculateButton);

      expect(find.text(english.errorWeight), findsOneWidget);
      expect(backend.requestsTo('PUT', '/me/profile'), isEmpty);
    });

    testWidgets("shows the server's age error on the birth date", (
      tester,
    ) async {
      final backend = await openForm(tester);
      backend.intercept = (request) => request.method == 'PUT'
          ? http.Response(
              jsonEncode({
                'detail': [
                  {
                    'type': 'age_out_of_range',
                    'loc': ['body', 'birth_year'],
                    'msg': 'Age must be between 18 and 100',
                    'input': 1900,
                  },
                ],
              }),
              422,
            )
          : null;

      await _fillForm(tester, english);
      await _tapText(tester, english.calculateButton);

      expect(find.text(english.errorAge), findsOneWidget);
      expect(find.text(english.profileTitle), findsOneWidget);
    });

    testWidgets('keeps the values when it can\'t connect, and Retry sends '
        'them', (tester) async {
      final backend = await openForm(tester);

      await _fillForm(tester, english);
      backend.offline = true;
      await _tapText(tester, english.calculateButton);

      expect(find.text(english.errorConnection), findsOneWidget);
      expect(find.text('180'), findsOneWidget);

      backend.offline = false;
      await _tapText(tester, english.retry);

      expect(find.text('2210'), findsOneWidget);
      final put = backend.requestsTo('PUT', '/me/profile').last;
      expect(jsonDecode(put.body), savedProfile());
    });
  });

  testWidgets('gets a new token and retries once after a 401', (tester) async {
    final backend = FakeBackend()..profile = savedProfile();
    await pumpApp(tester, backend, storedName: 'alice');
    // Tokens last 15 minutes; the app may stay open longer.
    backend.expireTokens();

    await _tapText(tester, english.editMyInfo);
    await _tapText(tester, english.calculateButton);

    final tokens = backend.requestsTo('POST', '/dev/token').toList();
    expect(tokens, hasLength(2));
    expect(jsonDecode(tokens.last.body), {'subject': 'alice'});
    expect(backend.requestsTo('PUT', '/me/profile'), hasLength(2));
    expect(find.text('2210'), findsOneWidget);
    expect(find.text(english.profileTitle), findsNothing);
  });

  testWidgets('explains a target raised to the minimum', (tester) async {
    // Worked example C from #8: female, 45, 52 kg, 155 cm, sedentary, lose.
    final backend = FakeBackend()
      ..profile = savedProfile()
      ..targets = {
        'calories': 1200,
        'protein_g': 114,
        'fat_g': 27,
        'carbs_g': 125,
        'maintenance_calories': 1320,
        'at_minimum': true,
      };

    await pumpApp(tester, backend, storedName: 'alice');

    expect(find.text('1200'), findsOneWidget);
    expect(find.text(english.minimumNote), findsOneWidget);
  });
}
