import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:ghbot/main.dart';
import 'package:ghbot/profiles/profile_form_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

Future<void> _choose(WidgetTester tester, String field, String option) async {
  await tester.tap(find.byKey(ValueKey(field)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// The backend's answer to a `PUT /me/profile` with an age out of range.
http.Response? _rejectAge(http.Request request) => request.method == 'PUT'
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
      'goal': 'maintain',
      'goal_adjustment_percent': 0,
    };
    await _tapText(tester, english.goalName('maintain'));
    await _tapText(tester, english.calculateButton);

    final put = backend.requestsTo('PUT', '/me/profile').single;
    expect(jsonDecode(put.body), savedProfile(goal: 'maintain'));
    expect(find.text('2760'), findsNWidgets(2));
    expect(find.text(english.goalRow('maintain')), findsOneWidget);
    expect(find.text(english.goalAdjustment('maintain', '0')), findsOneWidget);
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
      backend.intercept = _rejectAge;

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

  group('Back from Edit while saving', () {
    // Opens Edit, starts a save the backend holds, and goes back.
    Future<FakeBackend> leaveDuringSave(WidgetTester tester) async {
      final backend = FakeBackend()..profile = savedProfile();
      await pumpApp(tester, backend, storedName: 'alice');
      await _tapText(tester, english.editMyInfo);
      backend.holdSave = Completer();
      await tester.tap(find.text(english.calculateButton));
      await tester.pump();
      await tester.pageBack();
      // Settles: a pending request schedules no frames.
      await tester.pumpAndSettle();
      expect(find.byType(ProfileFormScreen), findsNothing);
      return backend;
    }

    testWidgets('a save that finishes later leaves a new edit form open', (
      tester,
    ) async {
      final backend = await leaveDuringSave(tester);
      await _tapText(tester, english.editMyInfo);

      backend.holdSave!.complete();
      await tester.pumpAndSettle();

      expect(find.text(english.profileTitle), findsOneWidget);
    });

    for (final (failure, fail) in [
      ('age error', (FakeBackend backend) => backend.intercept = _rejectAge),
      ('connection error', (FakeBackend backend) => backend.offline = true),
    ]) {
      testWidgets('a $failure that comes later is dropped', (tester) async {
        final backend = await leaveDuringSave(tester);

        fail(backend);
        backend.holdSave!.complete();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(english.errorConnection), findsNothing);
        expect(find.text(english.editMyInfo), findsOneWidget);
      });
    }

    testWidgets('a connection error shown on the form goes with it', (
      tester,
    ) async {
      final backend = FakeBackend()..profile = savedProfile();
      await pumpApp(tester, backend, storedName: 'alice');
      await _tapText(tester, english.editMyInfo);
      backend.offline = true;
      await _tapText(tester, english.calculateButton);
      expect(find.text(english.retry), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(english.retry), findsNothing);
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

  testWidgets('retries a 401 only once', (tester) async {
    final backend = FakeBackend()..profile = savedProfile();
    await pumpApp(tester, backend, storedName: 'alice');
    var puts = 0;
    // A 401 that a new token doesn't fix. The 500 stops a retry loop, so
    // the test fails instead of hanging.
    backend.intercept = (request) => request.method == 'PUT'
        ? http.Response('', ++puts <= 3 ? 401 : 500)
        : null;

    await _tapText(tester, english.editMyInfo);
    await _tapText(tester, english.calculateButton);

    expect(puts, 2);
    expect(backend.requestsTo('POST', '/dev/token'), hasLength(2));
    expect(find.text(english.errorGeneral), findsOneWidget);
    expect(find.text(english.profileTitle), findsOneWidget);
  });

  testWidgets('offline at startup shows the error, and Retry recovers', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..profile = savedProfile()
      ..offline = true;

    await pumpApp(tester, backend, storedName: 'alice');

    expect(find.text(english.errorConnection), findsOneWidget);
    backend.offline = false;
    await _tapText(tester, english.retry);

    expect(find.text('2210'), findsOneWidget);
    expect(find.text(english.signInTitle), findsNothing);
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
        'above_tested_age': false,
        'goal': 'lose',
        'goal_adjustment_percent': -20,
      };

    await pumpApp(tester, backend, storedName: 'alice');

    expect(find.text('1200'), findsOneWidget);
    expect(find.text(english.minimumNote), findsOneWidget);
  });

  group('age warning', () {
    // The backend decides who is above the tested age, so the form's
    // values don't matter here.
    Future<void> onboard(WidgetTester tester, FakeBackend backend) async {
      await pumpApp(tester, backend, storedName: 'alice');
      await _fillForm(tester, english);
      await _tapText(tester, english.calculateButton);
    }

    testWidgets('a 79-year-old sees it after onboarding, then the targets', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..targets = {...exampleTargets, 'above_tested_age': true};

      await onboard(tester, backend);

      expect(find.text(english.ageWarning), findsOneWidget);
      expect(find.text('2210'), findsNothing);

      await _tapText(tester, english.understandButton);

      expect(find.text('2210'), findsOneWidget);
      expect(find.text(english.ageWarning), findsNothing);
    });

    testWidgets('someone who turns 79 sees it after editing their info', (
      tester,
    ) async {
      final backend = FakeBackend()..profile = savedProfile();
      await pumpApp(tester, backend, storedName: 'alice');
      expect(find.text('2210'), findsOneWidget);

      await _tapText(tester, english.editMyInfo);
      backend.targets = {...exampleTargets, 'above_tested_age': true};
      await _tapText(tester, english.calculateButton);

      expect(find.text(english.profileTitle), findsNothing);
      expect(find.text(english.ageWarning), findsOneWidget);
      expect(find.text('2210'), findsNothing);

      await _tapText(tester, english.understandButton);

      expect(find.text('2210'), findsOneWidget);
      expect(find.text(english.ageWarning), findsNothing);
    });

    testWidgets('shows once: the next start goes straight to the targets', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..profile = savedProfile()
        ..targets = {...exampleTargets, 'above_tested_age': true};
      await pumpApp(tester, backend, storedName: 'alice');
      await _tapText(tester, english.understandButton);

      // A new key makes a new app, as after closing it. What the app stored
      // on the phone stays.
      await tester.pumpWidget(
        GhbotApp(
          key: UniqueKey(),
          client: backend.client,
          apiBaseUrl: 'http://backend.test',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2210'), findsOneWidget);
      expect(find.text(english.ageWarning), findsNothing);
    });

    testWidgets('stays until acknowledged, even after a restart', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..profile = savedProfile()
        ..targets = {...exampleTargets, 'above_tested_age': true};
      await pumpApp(tester, backend, storedName: 'alice');

      expect(find.text(english.ageWarning), findsOneWidget);
      expect(find.text('2210'), findsNothing);
      // The warning replaces the targets, so Back can't skip it.
      final warning = tester.element(find.text(english.ageWarning));
      expect(Navigator.of(warning).canPop(), isFalse);

      await tester.pumpWidget(
        GhbotApp(
          key: UniqueKey(),
          client: backend.client,
          apiBaseUrl: 'http://backend.test',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(english.ageWarning), findsOneWidget);
      expect(find.text('2210'), findsNothing);

      await _tapText(tester, english.understandButton);

      expect(find.text('2210'), findsOneWidget);
    });

    testWidgets('a 78-year-old never sees it', (tester) async {
      final backend = FakeBackend();

      await onboard(tester, backend);

      expect(find.text('2210'), findsOneWidget);
      expect(find.text(english.ageWarning), findsNothing);
    });
  });

  testWidgets('a response that stalls after its headers times out', (
    tester,
  ) async {
    final body = StreamController<List<int>>();
    addTearDown(body.close);
    // Headers arrive at once; the body never finishes.
    final stalling = MockClient.streaming(
      (request, _) async => http.StreamedResponse(body.stream, 200),
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'dev_subject': 'alice'});

    await tester.pumpWidget(
      GhbotApp(client: stalling, apiBaseUrl: 'http://backend.test'),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.text(english.errorConnection), findsOneWidget);
  });
}
