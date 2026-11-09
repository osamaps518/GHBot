import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_failure.dart';

/// Sends backend requests and decodes successful responses or failures.
class ApiClient {
  // Callers pass `client:`; a private named parameter keeps the field private.
  ApiClient({required this._client, required String baseUrl})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<http.Response> send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final abort = Completer<void>();
    final request = http.AbortableRequest(
      method,
      Uri.parse('$_baseUrl$path'),
      abortTrigger: abort.future,
    );
    if (headers != null) request.headers.addAll(headers);
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
      abort.complete();
      throw const ConnectionFailure();
    } on http.ClientException {
      throw const ConnectionFailure();
    } on TlsException {
      throw const ConnectionFailure();
    }
  }

  Map<String, Object?> decode(http.Response response) {
    if (response.statusCode >= 300 && response.statusCode != 422) {
      throw ServerFailure(response.statusCode);
    }
    Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const UnexpectedResponseFailure();
    }
    if (response.statusCode == 422) {
      if (body is! Map<String, dynamic> || body['detail'] is! List) {
        throw const UnexpectedResponseFailure();
      }
      final types = <String>[];
      for (final error in body['detail'] as List) {
        if (error is! Map<String, dynamic> || error['type'] is! String) {
          throw const UnexpectedResponseFailure();
        }
        types.add(error['type'] as String);
      }
      throw ValidationFailure(types);
    }
    if (body is! Map<String, dynamic>) {
      throw const UnexpectedResponseFailure();
    }
    return body;
  }
}
