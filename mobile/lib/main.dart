import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_flow.dart';
import 'auth/auth_session.dart';
import 'auth/sign_in_screen.dart';
import 'core/api_client.dart';
import 'core/database.dart';
import 'core/error_views.dart';
import 'core/theme.dart';
import 'food_log/diary_screen.dart';
import 'foods/foods_api.dart';
import 'l10n/app_localizations.dart';
import 'profiles/profile_form_screen.dart';
import 'profiles/profiles_api.dart';
import 'targets/age_warning_screen.dart';
import 'targets/targets.dart';
import 'targets/targets_api.dart';
import 'targets/targets_edit_screen.dart';
import 'targets/targets_screen.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  validateApiBaseUrl(apiBaseUrl, releaseMode: kReleaseMode);
  runApp(
    GhbotApp(
      client: http.Client(),
      apiBaseUrl: apiBaseUrl,
      openDatabase: openUserDatabase,
    ),
  );
}

void validateApiBaseUrl(String address, {required bool releaseMode}) {
  if (address.isEmpty) {
    throw StateError(
      'API_BASE_URL is not set. Copy config.example.json to config.json '
      'and run with --dart-define-from-file=config.json.',
    );
  }
  if (releaseMode &&
      (!address.startsWith('https://') ||
          (Uri.tryParse(address)?.host.isEmpty ?? true))) {
    throw StateError('Release builds require an HTTPS API_BASE_URL.');
  }
}

class GhbotApp extends StatefulWidget {
  const GhbotApp({
    super.key,
    required this.client,
    required this.apiBaseUrl,
    required this.openDatabase,
  });

  final http.Client client;
  final String apiBaseUrl;

  /// Opens a user's database. Tests pass one that uses a temporary folder.
  final AppDatabase Function(String userId) openDatabase;

  @override
  State<GhbotApp> createState() => _GhbotAppState();
}

/// Picks the screen from the app flow and owns the targets and Edit
/// navigation: no stored name → sign-in, no profile → onboarding, otherwise
/// the diary. Users older than the formula was tested for see a warning
/// before the diary, until they accept it.
class _GhbotAppState extends State<GhbotApp> {
  late final _client = ApiClient(
    client: widget.client,
    baseUrl: widget.apiBaseUrl,
  );
  late final _session = AuthSession(_client);
  late final _profilesApi = ProfilesApi(_session);
  late final _targetsApi = TargetsApi(_session);
  late final _foodsApi = FoodsApi(_session);
  late final _flow = AppFlow(
    _session,
    _profilesApi,
    _targetsApi,
    widget.openDatabase,
  );

  /// The targets and Edit my info open on top, so the back button returns.
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

  /// Opens the targets from the diary. They follow the app flow, so a save
  /// from Edit my info shows at once, and the age warning when that save
  /// makes it due. If the flow drops the targets, the last ones shown stay.
  void _openTargets() {
    var shown = _flow.targets!;
    _navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) => ListenableBuilder(
          listenable: _flow,
          builder: (context, child) {
            shown = _flow.targets ?? shown;
            return _ageWarningDue(shown)
                ? AgeWarningScreen(onUnderstood: _flow.acceptAgeWarning)
                : TargetsScreen(
                    targets: shown,
                    onEdit: _edit,
                    onEditTargets: _editTargets,
                    onReset: _flow.resetCustomTargets,
                  );
          },
        ),
      ),
    );
  }

  bool _ageWarningDue(Targets targets) =>
      targets.aboveTestedAge && !_flow.ageWarningSeen;

  /// Opens the form for Edit my info. After a save it closes only this form:
  /// Back may have closed it while it saved, and another may be open now.
  void _edit() {
    _navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileFormScreen(
          initial: _flow.profile,
          onSubmit: (profile) async {
            await _flow.save(profile);
            if (context.mounted && ModalRoute.of(context)!.isCurrent) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  /// Opens the targets form. Like [_edit], a save closes only this form.
  void _editTargets() {
    _navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) => TargetsEditScreen(
          targets: _flow.targets!,
          onSave: (values) async {
            await _flow.saveCustomTargets(values);
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
    AppStage.diary when _ageWarningDue(_flow.targets!) => AgeWarningScreen(
      onUnderstood: _flow.acceptAgeWarning,
    ),
    AppStage.diary => DiaryScreen(
      database: _flow.database,
      foodsApi: _foodsApi,
      targets: _flow.targets!,
      onOpenTargets: _openTargets,
    ),
    AppStage.failed => ErrorScreen(
      failure: _flow.failure!,
      onRetry: _flow.load,
    ),
  };

  /// For the language, Flutter matches the phone's ordered preferences against
  /// `supportedLocales`, then falls back to the first entry when none match
  /// (decision 12). With both `theme` and `darkTheme` set, the app follows
  /// the phone's light or dark setting (decision 16).
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: lightTheme,
      darkTheme: darkTheme,
      home: ListenableBuilder(
        listenable: _flow,
        builder: (context, child) => _screen(),
      ),
    );
  }
}
