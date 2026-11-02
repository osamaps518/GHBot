import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';

/// Owns dev sign-in and the token for authorized calls.
///
/// Dev sign-in (docs/decisions.md, 17): the name is the token subject. We
/// store the name, not the token, because tokens last 15 minutes. A token is
/// fetched on the first call after each start, and again on a 401.
class AuthSession {
  AuthSession(this._client);

  final ApiClient _client;
  final _preferences = SharedPreferencesAsync();
  static const _subjectKey = 'dev_subject';

  String? _subject;
  Future<String>? _token;

  /// Loads the name from an earlier sign-in. False on a fresh install.
  Future<bool> restoreSignIn() async {
    _subject = await _preferences.getString(_subjectKey);
    return _subject != null;
  }

  Future<void> signIn(String name) async {
    final token = await _requestToken(name);
    await _preferences.setString(_subjectKey, name);
    _subject = name;
    _token = Future.value(token);
  }

  Future<http.Response> sendAuthorized(
    String method,
    String path, {
    Object? body,
  }) async {
    final token = _currentToken();
    final response = await _client.send(
      method,
      path,
      body: body,
      headers: {'authorization': 'Bearer ${await token}'},
    );
    if (response.statusCode != 401) return response;
    // Calls made in parallel share one new token.
    if (identical(_token, token)) _token = null;
    return _client.send(
      method,
      path,
      body: body,
      headers: {'authorization': 'Bearer ${await _currentToken()}'},
    );
  }

  Future<String> _currentToken() =>
      _token ??= _requestToken(_subject!)
          .catchError((Object error, StackTrace stack) {
            _token = null;
            Error.throwWithStackTrace(error, stack);
          });

  Future<String> _requestToken(String subject) async {
    final response = await _client.send(
      'POST',
      '/dev/token',
      body: {'subject': subject},
    );
    return _client.decode(response)['access_token'] as String;
  }
}
