import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  /// Opens online once, so the profile and targets are stored on the phone.
  Future<(FakeBackend, PhoneStorage)> openOnce(WidgetTester tester) async {
    final backend = FakeBackend()..profile = savedProfile();
    final storage = PhoneStorage();
    await pumpApp(tester, backend, storedName: 'alice', storage: storage);
    expect(find.text('2210'), findsOneWidget);
    return (backend, storage);
  }

  testWidgets('opens on the stored targets without a connection', (
    tester,
  ) async {
    final (backend, storage) = await openOnce(tester);

    backend.offline = true;
    await restartApp(tester, backend, storage);

    expect(find.text('2210'), findsOneWidget);
    expect(find.text(english.errorConnection), findsNothing);
  });

  testWidgets('shows the stored targets at once, then stores the refreshed '
      'ones', (tester) async {
    final (backend, storage) = await openOnce(tester);
    backend.targets = {...exampleTargets, 'calories': 1990};
    final reply = Completer<void>();
    backend.holdNextTargets = reply;

    await restartApp(tester, backend, storage);
    expect(find.text('2210'), findsOneWidget);

    reply.complete();
    await tester.pumpAndSettle();
    expect(find.text('1990'), findsOneWidget);

    backend.offline = true;
    await restartApp(tester, backend, storage);
    expect(find.text('1990'), findsOneWidget);
  });

  testWidgets('a profile gone from the server clears the stored one and opens '
      'onboarding', (tester) async {
    final (backend, storage) = await openOnce(tester);
    backend.profile = null;

    await restartApp(tester, backend, storage);
    expect(find.text(english.profileTitle), findsOneWidget);

    backend.offline = true;
    await restartApp(tester, backend, storage);
    expect(find.text(english.errorConnection), findsOneWidget);
  });

  for (final (name, fail) in [
    ('offline', (FakeBackend backend) => backend.offline = true),
    (
      'a server error',
      (FakeBackend backend) =>
          backend.intercept = (request) =>
              request.url.path == '/me/targets' ? http.Response('', 500) : null,
    ),
  ]) {
    testWidgets('a refresh that fails ($name) keeps the stored data', (
      tester,
    ) async {
      final (backend, storage) = await openOnce(tester);
      fail(backend);

      await restartApp(tester, backend, storage);
      expect(find.text('2210'), findsOneWidget);
      expect(find.text(english.errorGeneral), findsNothing);

      backend
        ..intercept = null
        ..offline = true;
      await restartApp(tester, backend, storage);
      expect(find.text('2210'), findsOneWidget);
    });
  }

  testWidgets('a save stores and shows the profile and targets the server '
      'returned', (tester) async {
    final (backend, storage) = await openOnce(tester);
    await editMyInfo(tester);
    await _tapText(tester, english.goalName('maintain'));
    backend
      ..targets = {...exampleTargets, 'calories': 1990}
      ..intercept = (request) => request.method == 'PUT'
          ? http.Response(
              jsonEncode({
                ...savedProfile(goal: 'maintain'),
                'weight_kg': 81.5,
              }),
              200,
            )
          : null;
    await _tapText(tester, english.calculateButton);

    expect(find.text('1990'), findsOneWidget);
    await editMyInfo(tester);
    expect(find.text('81.5'), findsOneWidget);

    backend.offline = true;
    await restartApp(tester, backend, storage);

    expect(find.text('1990'), findsOneWidget);
    await editMyInfo(tester);
    expect(find.text('81.5'), findsOneWidget);
  });

  testWidgets('an offline save shows the error and stores nothing', (
    tester,
  ) async {
    final (backend, storage) = await openOnce(tester);
    await editMyInfo(tester);
    await _tapText(tester, english.goalName('maintain'));
    backend.offline = true;
    await _tapText(tester, english.calculateButton);
    expect(find.text(english.errorConnection), findsOneWidget);

    await restartApp(tester, backend, storage);

    expect(find.text('2210'), findsOneWidget);
    await openTargets(tester);
    expect(find.text(english.goalRow('lose')), findsOneWidget);
  });

  for (final (oldReply, setUpOldReply) in [
    ('the old targets', (FakeBackend backend) {}),
    ('no profile', (FakeBackend backend) => backend.profile = null),
  ]) {
    testWidgets('a refresh that started before a save does not replace it '
        '($oldReply)', (tester) async {
      final (backend, storage) = await openOnce(tester);
      setUpOldReply(backend);
      final refreshReply = Completer<void>();
      backend.holdNextTargets = refreshReply;
      await restartApp(tester, backend, storage);

      await editMyInfo(tester);
      await _tapText(tester, english.goalName('maintain'));
      backend.targets = {...exampleTargets, 'calories': 1990};
      await _tapText(tester, english.calculateButton);
      expect(find.text('1990'), findsOneWidget);

      refreshReply.complete();
      await tester.pumpAndSettle();
      expect(find.text('1990'), findsOneWidget);

      backend.offline = true;
      await restartApp(tester, backend, storage);
      expect(find.text('1990'), findsOneWidget);
    });
  }

  testWidgets('a refresh that finishes after the app closed is dropped', (
    tester,
  ) async {
    final (backend, storage) = await openOnce(tester);
    final aliceReply = Completer<void>();
    backend.holdNextTargets = aliceReply;
    await restartApp(tester, backend, storage);

    await storeSignedInUser('bob');
    backend.targets = {...exampleTargets, 'calories': 1990};
    await restartApp(tester, backend, storage);
    expect(find.text('1990'), findsOneWidget);

    aliceReply.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('1990'), findsOneWidget);

    backend.offline = true;
    await restartApp(tester, backend, storage);
    expect(find.text('1990'), findsOneWidget);
  });

  testWidgets('offline, a logged entry shows at once, and its food can be '
      'found again', (tester) async {
    final (backend, storage) = await openOnce(tester);

    /// Opens search from breakfast, the first meal, and searches for rice.
    Future<void> searchRice() async {
      final addFood = find.text(english.addFood).first;
      await tester.ensureVisible(addFood);
      await tester.pumpAndSettle();
      await tester.tap(addFood);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'rice');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    /// Logs the rice found, at the 100 g it starts with.
    Future<void> logRice() async {
      await _tapText(tester, 'Cooked white rice');
      await _tapText(tester, english.logButton(english.mealName('breakfast')));
    }

    await searchRice();
    await logRice();
    expect(find.text('2080'), findsOneWidget);

    backend.offline = true;
    await restartApp(tester, backend, storage);
    expect(find.text('Cooked white rice'), findsOneWidget);

    await searchRice();
    expect(find.text(english.searchOffline), findsOneWidget);
    await logRice();

    expect(find.text('Cooked white rice'), findsNWidgets(2));
    expect(find.text('1950'), findsOneWidget);
  });
}
