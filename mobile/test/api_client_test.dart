import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/api_failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/testing.dart';

void main() {
  test('a timed-out body closes its socket', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final closed = Completer<void>();
    server.listen((socket) {
      socket.listen(
        (_) {},
        onDone: () {
          if (!closed.isCompleted) closed.complete();
        },
      );
      socket.write('HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n');
    });
    final httpClient = HttpClient();
    final api = ApiClient(
      client: IOClient(httpClient),
      baseUrl: 'http://127.0.0.1:${server.port}',
    );

    try {
      await expectLater(
        api.send('GET', '/stall'),
        throwsA(isA<ConnectionFailure>()),
      );
      await closed.future.timeout(const Duration(seconds: 1));
    } finally {
      httpClient.close(force: true);
      await server.close();
    }
  });

  test("a 422 gives each error's code, and the context of those that have "
      'one', () async {
    final api = ApiClient(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'detail': [
              {
                'type': 'below_minimum',
                'loc': ['body', 'calories'],
                'msg': 'Calories are below the minimum',
                'input': 1100,
                'ctx': {'minimum': 1500},
              },
              {
                'type': 'macros_mismatch',
                'loc': ['body'],
                'msg': 'Macro calories differ by at least 100',
                'input': {},
              },
            ],
          }),
          422,
        ),
      ),
      baseUrl: 'http://backend.test',
    );

    final response = await api.send('PUT', '/me/targets/custom');

    expect(
      () => api.decode(response),
      throwsA(
        isA<ValidationFailure>()
            .having((failure) => failure.types, 'types', [
              'below_minimum',
              'macros_mismatch',
            ])
            .having((failure) => failure.ctx, 'ctx', {
              'below_minimum': {'minimum': 1500},
            }),
      ),
    );
  });
}
