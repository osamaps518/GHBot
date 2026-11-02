import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_session.dart';
import 'auth/sign_in_screen.dart';
import 'core/api_client.dart';
import 'core/api_failure.dart';
import 'core/error_views.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'profiles/profile.dart';
import 'profiles/profile_form_screen.dart';
import 'profiles/profiles_api.dart';
import 'targets/age_warning_screen.dart';
import 'targets/targets.dart';
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

enum _Stage { loading, signIn, onboarding, targets, failed }

/// Picks the screen from what the app knows: no stored name → sign-in, no
/// profile → onboarding, otherwise the targets. Users older than the formula
/// was tested for see a warning before the targets, until they accept it.
class _GhbotAppState extends State<GhbotApp> {
  late final _client = ApiClient(
    client: widget.client,
    baseUrl: widget.apiBaseUrl,
  );
  late final _session = AuthSession(_client);
  late final _profilesApi = ProfilesApi(_client, _session);
  late final _targetsApi = TargetsApi(_client, _session);
  // "Edit my info" opens the form on top, so the back button returns.
  final _navigator = GlobalKey<NavigatorState>();
  // Kept on the phone, so after a reinstall the warning shows once more.
  final _preferences = SharedPreferencesAsync();
  static const _ageWarningSeenKey = 'age_warning_seen';

  var _stage = _Stage.loading;
  Profile? _profile;
  Targets? _targets;
  Exception? _failure;
  var _ageWarningSeen = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    _ageWarningSeen = await _preferences.getBool(_ageWarningSeenKey) ?? false;
    if (await _session.restoreSignIn()) {
      await _load();
    } else {
      setState(() => _stage = _Stage.signIn);
    }
  }

  Future<void> _signIn(String name) async {
    await _session.signIn(name);
    await _load();
  }

  Future<void> _load() async {
    setState(() => _stage = _Stage.loading);
    try {
      final results = await Future.wait([
        _profilesApi.getProfile(),
        _targetsApi.getTargets(),
      ]);
      final profile = results[0] as Profile?;
      final targets = results[1] as Targets?;
      if (profile != null && targets == null) throw const ServerFailure(404);
      setState(() {
        _profile = profile;
        _targets = targets;
        _stage = profile == null ? _Stage.onboarding : _Stage.targets;
      });
    } on Exception catch (failure) {
      setState(() {
        _failure = failure;
        _stage = _Stage.failed;
      });
    }
  }

  Future<void> _save(Profile profile) async {
    await _profilesApi.putProfile(profile);
    final targets = await _targetsApi.getTargets();
    if (targets == null) throw const ServerFailure(404);
    setState(() {
      _profile = profile;
      _targets = targets;
      _stage = _Stage.targets;
    });
  }

  Future<void> _acceptAgeWarning() async {
    setState(() => _ageWarningSeen = true);
    await _preferences.setBool(_ageWarningSeenKey, true);
  }

  void _edit() {
    _navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileFormScreen(
          initial: _profile,
          onSubmit: (profile) async {
            await _save(profile);
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

  Widget _screen() => switch (_stage) {
    _Stage.loading => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    _Stage.signIn => SignInScreen(onSubmit: _signIn),
    _Stage.onboarding => ProfileFormScreen(onSubmit: _save),
    _Stage.targets when _targets!.aboveTestedAge && !_ageWarningSeen =>
      AgeWarningScreen(onUnderstood: _acceptAgeWarning),
    _Stage.targets => TargetsScreen(
      profile: _profile!,
      targets: _targets!,
      onEdit: _edit,
    ),
    _Stage.failed => ErrorScreen(failure: _failure!, onRetry: _load),
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
      home: _screen(),
    );
  }
}
