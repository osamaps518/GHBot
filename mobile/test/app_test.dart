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
    for (final (name, locales, expectedLocale, direction) in [
      ('Arabic', [const Locale('ar')], const Locale('ar'), TextDirection.rtl),
      (
        'English',
        [const Locale('en', 'US')],
        const Locale('en'),
        TextDirection.ltr,
      ),
      ('French', [const Locale('fr')], const Locale('en'), TextDirection.ltr),
      (
        'French then Arabic',
        [const Locale('fr', 'FR'), const Locale('ar')],
        const Locale('ar'),
        TextDirection.rtl,
      ),
      (
        'French then English',
        [const Locale('fr', 'FR'), const Locale('en', 'US')],
        const Locale('en'),
        TextDirection.ltr,
      ),
      ('no preference', <Locale>[], const Locale('en'), TextDirection.ltr),
    ]) {
      testWidgets('$name phone uses ${expectedLocale.languageCode}', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = locales;
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await _pumpApp(tester);

        final l10n = lookupAppLocalizations(expectedLocale);
        expect(find.text(l10n.signInTitle), findsOneWidget);
        expect(_direction(tester), direction);
      });
    }
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
