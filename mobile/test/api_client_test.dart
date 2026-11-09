import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/api_failure.dart';
import 'package:http/io_client.dart';

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
}
