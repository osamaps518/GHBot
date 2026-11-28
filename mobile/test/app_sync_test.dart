import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

void main() {
  /// Opens the diary for alice, whose profile the server has.
  Future<(FakeBackend, PhoneStorage)> openDiary(WidgetTester tester) async {
    final backend = FakeBackend()..profile = savedProfile();
    final storage = PhoneStorage();
    await pumpApp(tester, backend, storedName: 'alice', storage: storage);
    return (backend, storage);
  }

  /// Finds rice and logs 100 g of it into breakfast from the diary. With
  /// [offline], the connection drops just before the entry is saved.
  Future<void> logRice(
    WidgetTester tester,
    FakeBackend backend, {
    bool offline = false,
  }) async {
    await tester.tap(find.text(english.addFood).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'rice');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cooked white rice'));
    await tester.pumpAndSettle();
    backend.offline = offline;
    final log = find.text(english.logButton(english.mealName('breakfast')));
    await tester.ensureVisible(log);
    await tester.tap(log);
    await tester.pumpAndSettle();
  }

  testWidgets('a logged entry is sent 2 s after it is saved', (tester) async {
    final (backend, _) = await openDiary(tester);

    await logRice(tester, backend);
    expect(backend.entries, isEmpty);
    await tester.pump(const Duration(seconds: 2));

    expect(backend.entries.values.single, containsPair('grams', 100.0));
  });

  testWidgets('an entry logged offline is sent when the app next starts with '
      'a connection', (tester) async {
    final (backend, storage) = await openDiary(tester);
    await logRice(tester, backend, offline: true);
    await tester.pump(const Duration(seconds: 2));

    backend.offline = false;
    await restartApp(tester, backend, storage);

    expect(backend.entries, hasLength(1));
  });

  testWidgets('entries waiting are sent when the app returns to the '
      'foreground', (tester) async {
    final (backend, _) = await openDiary(tester);
    await logRice(tester, backend, offline: true);
    await tester.pump(const Duration(seconds: 2));
    backend.offline = false;

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();

    expect(backend.entries, hasLength(1));
  });
}
