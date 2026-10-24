import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/home_screen.dart';
import 'package:ghbot/l10n/app_localizations.dart';
import 'package:ghbot/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _healthy = MockClient((request) async {
  expect(request.url, Uri.parse('http://backend.test/health'));
  return http.Response('{"status": "ok"}', 200);
});

Future<void> _pumpApp(
  WidgetTester tester,
  http.Client client, {
  String apiBaseUrl = 'http://backend.test',
}) async {
  await tester.pumpWidget(GhbotApp(client: client, apiBaseUrl: apiBaseUrl));
  await tester.pumpAndSettle();
}

TextDirection _direction(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(HomeScreen)));

void main() {
  group('language', () {
    for (final locale in const [Locale('ar'), Locale('fr')]) {
      testWidgets('$locale phone shows Arabic, right to left', (tester) async {
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await _pumpApp(tester, _healthy);

        final arabic = lookupAppLocalizations(const Locale('ar'));
        expect(find.text(arabic.backendReached), findsOneWidget);
        expect(_direction(tester), TextDirection.rtl);
      });
    }

    testWidgets('English phone shows English, left to right', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await _pumpApp(tester, _healthy);

      final english = lookupAppLocalizations(const Locale('en'));
      expect(find.text(english.backendReached), findsOneWidget);
      expect(_direction(tester), TextDirection.ltr);
    });
  });

  // Tests run with an English (en_US) phone by default.
  group('health check', () {
    final english = lookupAppLocalizations(const Locale('en'));

    testWidgets('shows reached when /health answers', (tester) async {
      await _pumpApp(tester, _healthy);

      expect(find.text(english.backendReached), findsOneWidget);
    });

    testWidgets('trailing slash in base URL reaches /health', (tester) async {
      final requestedUrls = <Uri>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url);
        return http.Response('', request.url.path == '/health' ? 200 : 404);
      });

      await _pumpApp(tester, client, apiBaseUrl: 'http://backend.test/');

      expect(requestedUrls, [Uri.parse('http://backend.test/health')]);
      expect(find.text(english.backendReached), findsOneWidget);
    });

    testWidgets('shows not reached when the request fails', (tester) async {
      final failing = MockClient(
        (request) async => throw http.ClientException('Connection refused'),
      );

      await _pumpApp(tester, failing);

      expect(find.text(english.backendNotReached), findsOneWidget);
    });
  });
}
