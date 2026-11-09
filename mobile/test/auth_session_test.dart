import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/auth/auth_session.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/api_failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('a late failed token request cannot clear a newer sign-in', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'dev_subject': 'old'});
    final oldStarted = Completer<void>();
    final oldReply = Completer<http.Response>();
    var tokenCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/dev/token') {
        tokenCalls++;
        final subject = (jsonDecode(request.body) as Map)['subject'];
        if (subject == 'old') {
          oldStarted.complete();
          return oldReply.future;
        }
        return http.Response('{"access_token":"new-token"}', 200);
      }
      expect(request.headers['authorization'], 'Bearer new-token');
      return http.Response('{"ok":true}', 200);
    });
    final session = AuthSession(
      ApiClient(client: client, baseUrl: 'https://backend.test'),
    );
    expect(await session.restoreSignIn(), isTrue);

    final oldCall = session.get<bool>('/me', (json) => json['ok'] as bool);
    await oldStarted.future;
    await session.signIn('new');
    oldReply.complete(http.Response('', 500));
    await expectLater(oldCall, throwsA(isA<ServerFailure>()));

    expect(
      await session.get<bool>('/me', (json) => json['ok'] as bool),
      isTrue,
    );
    expect(tokenCalls, 2);
  });
}
