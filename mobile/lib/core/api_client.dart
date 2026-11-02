import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_failure.dart';

/// Sends backend requests and decodes successful responses or failures.
class ApiClient {
  ApiClient({required http.Client client, required String baseUrl})
    : _client = client,
      _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<http.Response> send(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          // Without a timeout, an unreachable address can spin for minutes.
          // It covers the body too: a stream can stall after its headers.
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      throw const ConnectionFailure();
    } on http.ClientException {
      throw const ConnectionFailure();
    }
  }

  Map<String, Object?> decode(http.Response response) {
    if (response.statusCode == 422) {
      throw ValidationFailure([
        for (final error in (jsonDecode(response.body) as Map)['detail'])
          (error as Map)['type'] as String,
      ]);
    }
    if (response.statusCode >= 300) throw ServerFailure(response.statusCode);
    return (jsonDecode(response.body) as Map).cast();
  }
}
