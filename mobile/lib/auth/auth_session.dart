import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/api_failure.dart';

/// Owns dev sign-in and the token for authorized calls.
///
/// Dev sign-in (docs/decisions.md, 17): the name is the token subject. We
/// store the name, not the token, because tokens last 15 minutes. A token is
/// fetched on the first call that needs one, and again on a 401.
///
/// The user's ID from `GET /me` is stored with the name: it names the user's
/// database file (decision 25).
class AuthSession {
  AuthSession(this._client);

  final ApiClient _client;
  final _preferences = SharedPreferencesAsync();
  static const _subjectKey = 'dev_subject';
  static const _userIdKey = 'user_id';

  String? _subject;
  String? _userId;
  Future<String>? _token;

  /// The signed-in user's ID. Null before sign-in, and for a name stored
  /// before IDs were, until [fetchUserId].
  String? get userId => _userId;

  /// Loads the name and ID from an earlier sign-in. False on a fresh install.
  Future<bool> restoreSignIn() async {
    _subject = await _preferences.getString(_subjectKey);
    _userId = await _preferences.getString(_userIdKey);
    return _subject != null;
  }

  /// Signs in and stores the name and ID only once both calls succeed.
  Future<void> signIn(String name) async {
    final token = await _requestToken(name);
    _subject = name;
    _token = Future.value(token);
    await fetchUserId();
    await _preferences.setString(_subjectKey, name);
  }

  /// Gets the signed-in user's ID from the server and stores it.
  Future<void> fetchUserId() async {
    final id = await get('/me', (json) => json['id'] as String);
    await _preferences.setString(_userIdKey, id!);
    _userId = id;
  }

  Future<T?> get<T>(
    String path,
    T Function(Map<String, Object?>) parse, {
    bool absentOn404 = false,
  }) async {
    final response = await _sendAuthorized('GET', path);
    if (response.statusCode == 404 && absentOn404) return null;
    return _parse(() => parse(_client.decode(response)));
  }

  /// Gets a JSON list and parses each of its objects.
  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, Object?>) parse,
  ) async {
    final response = await _sendAuthorized('GET', path);
    return _parse(
      () => [
        for (final item in _client.decodeList(response))
          parse(item as Map<String, Object?>),
      ],
    );
  }

  Future<T> put<T>(
    String path,
    Object body,
    T Function(Map<String, Object?>) parse,
  ) async {
    final response = await _sendAuthorized('PUT', path, body: body);
    return _parse(() => parse(_client.decode(response)));
  }

  Future<T> delete<T>(
    String path,
    T Function(Map<String, Object?>) parse,
  ) async {
    final response = await _sendAuthorized('DELETE', path);
    return _parse(() => parse(_client.decode(response)));
  }

  /// Sends with the current token, and once more with a new one after a 401.
  /// Calls made in parallel share one new token.
  Future<http.Response> _sendAuthorized(
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
    if (identical(_token, token)) _token = null;
    return _client.send(
      method,
      path,
      body: body,
      headers: {'authorization': 'Bearer ${await _currentToken()}'},
    );
  }

  Future<String> _currentToken() {
    final current = _token;
    if (current != null) return current;
    late final Future<String> pending;
    pending =
        _requestToken(
          _subject ??
              (throw StateError(
                'Sign in before making an authorized request.',
              )),
        ).catchError((Object error, StackTrace stack) {
          if (identical(_token, pending)) _token = null;
          Error.throwWithStackTrace(error, stack);
        });
    _token = pending;
    return pending;
  }

  Future<String> _requestToken(String subject) async {
    final response = await _client.send(
      'POST',
      '/dev/token',
      body: {'subject': subject},
    );
    return _parse(() => _client.decode(response)['access_token'] as String);
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on ApiFailure {
      rethrow;
    } on Object {
      throw const UnexpectedResponseFailure();
    }
  }
}
