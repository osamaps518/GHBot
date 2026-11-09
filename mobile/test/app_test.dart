import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:ghbot/auth/sign_in_screen.dart';
import 'package:ghbot/core/theme.dart';
import 'package:ghbot/main.dart' show validateApiBaseUrl;

import 'fake_backend.dart';

// A fresh install opens on the sign-in screen.
Future<void> _pumpApp(WidgetTester tester) => pumpApp(tester, FakeBackend());

TextDirection _direction(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(SignInScreen)));

void main() {
  test('release builds require an HTTPS backend address', () {
    expect(
      () => validateApiBaseUrl('http://backend.test', releaseMode: true),
      throwsStateError,
    );
    expect(
      () => validateApiBaseUrl('https://backend.test', releaseMode: true),
      returnsNormally,
    );
    expect(
      () => validateApiBaseUrl('https:backend.test', releaseMode: true),
      throwsStateError,
    );
    expect(
      () => validateApiBaseUrl('http://backend.test', releaseMode: false),
      returnsNormally,
    );
  });

  group('language', () {
    testWidgets('Arabic phone shows Arabic, right to left', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('ar')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await _pumpApp(tester);

      final arabic = lookupAppLocalizations(const Locale('ar'));
      expect(find.text(arabic.signInTitle), findsOneWidget);
      expect(_direction(tester), TextDirection.rtl);
    });

    testWidgets('English phone shows English, left to right', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await _pumpApp(tester);

      final english = lookupAppLocalizations(const Locale('en'));
      expect(find.text(english.signInTitle), findsOneWidget);
      expect(_direction(tester), TextDirection.ltr);
    });

    testWidgets('French-only phone falls back to English', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('fr')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await _pumpApp(tester);

      final english = lookupAppLocalizations(const Locale('en'));
      expect(find.text(english.signInTitle), findsOneWidget);
      expect(_direction(tester), TextDirection.ltr);
    });

    testWidgets('French then Arabic phone shows Arabic', (tester) async {
      tester.platformDispatcher.localesTestValue = const [
        Locale('fr', 'FR'),
        Locale('ar'),
      ];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await _pumpApp(tester);

      final arabic = lookupAppLocalizations(const Locale('ar'));
      expect(find.text(arabic.signInTitle), findsOneWidget);
      expect(_direction(tester), TextDirection.rtl);
    });

    testWidgets('French then English phone shows English', (tester) async {
      tester.platformDispatcher.localesTestValue = const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await _pumpApp(tester);

      final english = lookupAppLocalizations(const Locale('en'));
      expect(find.text(english.signInTitle), findsOneWidget);
      expect(_direction(tester), TextDirection.ltr);
    });

    testWidgets('no phone language preferences falls back to English', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = [];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await _pumpApp(tester);

      final english = lookupAppLocalizations(const Locale('en'));
      expect(find.text(english.signInTitle), findsOneWidget);
      expect(_direction(tester), TextDirection.ltr);
    });
  });

  group('theme', () {
    for (final brightness in Brightness.values) {
      testWidgets('follows the phone in ${brightness.name} mode', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await _pumpApp(tester);

        final theme = Theme.of(tester.element(find.byType(SignInScreen)));
        expect(theme.colorScheme.brightness, brightness);
        expect(theme.extension<TargetsColors>(), isNotNull);
      });
    }
  });
}
