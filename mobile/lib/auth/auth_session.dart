import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/api_failure.dart';

/// Owns dev sign-in and the token for authorized calls.
///
/// Dev sign-in: the name is the token subject, and the name is stored, not
/// the token (decision 17). A token is fetched on the first call that needs
/// one, and again on a 401.
///
/// The user's ID and when their account was created, from `GET /me`, are
/// stored with the name. The ID names the user's database file (decision
/// 25); the diary goes back no further than the day the account was created
/// (decision 34).
class AuthSession {
  AuthSession(this._client);

  final ApiClient _client;
  final _preferences = SharedPreferencesAsync();
  static const _subjectKey = 'dev_subject';
  static const _userIdKey = 'user_id';
  static const _createdAtKey = 'user_created_at';

  String? _subject;
  String? _userId;
  DateTime? _createdAt;
  Future<String>? _token;

  /// The signed-in user's ID. Null before sign-in, and for a name stored
  /// before IDs were, until [fetchUser].
  String? get userId => _userId;

  /// When the signed-in user's account was created, in UTC. Null before
  /// sign-in, and for a sign-in stored before this was, until [fetchUser].
  DateTime? get createdAt => _createdAt;

  /// Loads the name, ID and account creation time from an earlier sign-in.
  /// False on a fresh install.
  Future<bool> restoreSignIn() async {
    _subject = await _preferences.getString(_subjectKey);
    _userId = await _preferences.getString(_userIdKey);
    final createdAt = await _preferences.getString(_createdAtKey);
    _createdAt = createdAt == null ? null : DateTime.parse(createdAt);
    return _subject != null;
  }

  /// Signs in and stores the name, ID and account creation time only once
  /// both calls succeed. Until then, calls keep the previous user's name, ID
  /// and token, so no call sees the new token with the old ID.
  Future<void> signIn(String name) async {
    final token = await _requestToken(name);
    final response = await _client.send(
      'GET',
      '/me',
      headers: {'authorization': 'Bearer $token'},
    );
    final user = _parse(() => _parseUser(_client.decode(response)));
    await _storeUser(user);
    await _preferences.setString(_subjectKey, name);
    _subject = name;
    _userId = user.id;
    _createdAt = user.createdAt;
    _token = Future.value(token);
  }

  /// Gets the signed-in user's ID and account creation time from the
  /// server and stores them.
  Future<void> fetchUser() async {
    final user = (await get('/me', _parseUser))!;
    await _storeUser(user);
    _userId = user.id;
    _createdAt = user.createdAt;
  }

  ({String id, DateTime createdAt}) _parseUser(Map<String, Object?> json) => (
    id: json['id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );

  Future<void> _storeUser(({String id, DateTime createdAt}) user) async {
    await _preferences.setString(_userIdKey, user.id);
    await _preferences.setString(
      _createdAtKey,
      user.createdAt.toIso8601String(),
    );
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
  ///
  /// A call belongs to the user signed in when it starts. If another user
  /// signed in since, its 401 is the answer: a retry would send this user's
  /// request with the other user's token.
  Future<http.Response> _sendAuthorized(
    String method,
    String path, {
    Object? body,
  }) async {
    final subject = _subject;
    final token = _currentToken();
    final response = await _client.send(
      method,
      path,
      body: body,
      headers: {'authorization': 'Bearer ${await token}'},
    );
    if (response.statusCode != 401 || _subject != subject) return response;
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
