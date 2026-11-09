import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_flow.dart';
import 'auth/auth_session.dart';
import 'auth/sign_in_screen.dart';
import 'core/api_client.dart';
import 'core/error_views.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'profiles/profile_form_screen.dart';
import 'profiles/profiles_api.dart';
import 'targets/age_warning_screen.dart';
import 'targets/targets_api.dart';
import 'targets/targets_screen.dart';

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

class GhbotApp extends StatefulWidget {
  const GhbotApp({super.key, required this.client, required this.apiBaseUrl});

  final http.Client client;
  final String apiBaseUrl;

  @override
  State<GhbotApp> createState() => _GhbotAppState();
}

/// Picks the screen from the app flow and owns Edit navigation.
class _GhbotAppState extends State<GhbotApp> {
  late final _client = ApiClient(
    client: widget.client,
    baseUrl: widget.apiBaseUrl,
  );
  late final _session = AuthSession(_client);
  late final _profilesApi = ProfilesApi(_session);
  late final _targetsApi = TargetsApi(_session);
  late final _flow = AppFlow(_session, _profilesApi, _targetsApi);
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _flow.start();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  void _edit() {
    _navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileFormScreen(
          initial: _flow.profile,
          onSubmit: (profile) async {
            await _flow.save(profile);
            // Back may have closed this form while it saved, and another
            // may be open now. Close only this one.
            if (context.mounted && ModalRoute.of(context)!.isCurrent) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Widget _screen() => switch (_flow.stage) {
    AppStage.loading => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    AppStage.signIn => SignInScreen(onSubmit: _flow.signIn),
    AppStage.onboarding => ProfileFormScreen(onSubmit: _flow.save),
    AppStage.targets
        when _flow.targets!.aboveTestedAge && !_flow.ageWarningSeen =>
      AgeWarningScreen(onUnderstood: _flow.acceptAgeWarning),
    AppStage.targets => TargetsScreen(targets: _flow.targets!, onEdit: _edit),
    AppStage.failed => ErrorScreen(
      failure: _flow.failure!,
      onRetry: _flow.load,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Flutter matches the phone's ordered preferences, then falls back to
      // the first entry when none match.
      supportedLocales: const [Locale('en'), Locale('ar')],
      // With both set, the app follows the phone's light or dark setting.
      theme: lightTheme,
      darkTheme: darkTheme,
      home: ListenableBuilder(
        listenable: _flow,
        builder: (context, child) => _screen(),
      ),
    );
  }
}
