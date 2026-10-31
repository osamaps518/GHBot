import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  if (apiBaseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL is not set. Copy config.example.json to config.json '
      'and run with --dart-define-from-file=config.json.',
    );
  }
  runApp(GhbotApp(client: http.Client(), apiBaseUrl: apiBaseUrl));
}

class GhbotApp extends StatelessWidget {
  const GhbotApp({super.key, required this.client, required this.apiBaseUrl});

  final http.Client client;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Flutter matches the phone's ordered preferences, then falls back to
      // the first entry when none match.
      supportedLocales: const [Locale('en'), Locale('ar')],
      // With both set, the app follows the phone's light or dark setting.
      theme: lightTheme,
      darkTheme: darkTheme,
      home: HomeScreen(client: client, apiBaseUrl: apiBaseUrl),
    );
  }
}
