import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._([http.Client? httpClient, AuthService? authService])
    : _client = httpClient ?? http.Client(),
      _authService = authService ?? AuthService.instance;

  static final _instance = ApiClient._();
  static ApiClient get instance => _instance;

  final http.Client _client;
  final AuthService _authService;

  /// Creates a non-singleton instance with injected dependencies.
  /// Use only in tests.
  @visibleForTesting
  static ApiClient withHttpClient(
    http.Client httpClient, {
    AuthService? authService,
  }) => ApiClient._(httpClient, authService);

  // Called by the auth repository to inject a refresh callback after init,
  // avoiding a circular dependency.
  Future<void> Function()? _onUnauthorized;
  bool _isRefreshing = false;

  void setOnUnauthorized(Future<void> Function() callback) {
    _onUnauthorized = callback;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<http.Response> _send(
    Future<http.Response> Function() fn, {
    required String method,
    required String path,
    Object? body,
  }) async {
    _logRequest(method, path, body);
    var response = await fn();
    _logResponse(response);
    if (response.statusCode == 401 &&
        _onUnauthorized != null &&
        !_isRefreshing) {
      debugPrint(
        '[ApiClient] 401 — refreshing token and retrying $method $path',
      );
      _isRefreshing = true;
      try {
        await _onUnauthorized!();
      } finally {
        _isRefreshing = false;
      }
      response = await fn();
      _logResponse(response);
    }
    return response;
  }

  void _logRequest(String method, String path, Object? body) {
    if (!kDebugMode) return;
    final buffer = StringBuffer()
      ..writeln('[ApiClient] --> $method ${ApiConstants.baseUrl}$path');
    if (body != null) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        buffer.writeln(encoder.convert(body));
      } catch (_) {
        buffer.writeln(body);
      }
    }
    debugPrint(buffer.toString());
  }

  void _logResponse(http.Response response) {
    if (!kDebugMode) return;
    final buffer = StringBuffer()
      ..writeln(
        '[ApiClient] <-- ${response.statusCode} ${response.request?.url}',
      );
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        const encoder = JsonEncoder.withIndent('  ');
        buffer.writeln(encoder.convert(decoded));
      } catch (_) {
        buffer.writeln(response.body);
      }
    }
    debugPrint(buffer.toString());
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _send(
      () async => _client.get(
        ApiConstants.uri(path, query),
        headers: await _authHeaders(),
      ),
      method: 'GET',
      path: path,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _send(
      () async => _client.get(
        ApiConstants.uri(path, query),
        headers: await _authHeaders(),
      ),
      method: 'GET',
      path: path,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      return jsonDecode(response.body) as List<dynamic>;
    }
    _throwFromResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final response = await _send(
      () async => _client.post(
        ApiConstants.uri(path),
        headers: await _authHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ),
      method: 'POST',
      path: path,
      body: body,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final response = await _send(
      () async => _client.put(
        ApiConstants.uri(path),
        headers: await _authHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ),
      method: 'PUT',
      path: path,
      body: body,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final response = await _send(
      () async => _client.patch(
        ApiConstants.uri(path),
        headers: await _authHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ),
      method: 'PATCH',
      path: path,
      body: body,
    );
    return _handleResponse(response);
  }

  Future<void> delete(String path, {Object? body}) async {
    final response = await _send(
      () async => _client.delete(
        ApiConstants.uri(path),
        headers: await _authHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ),
      method: 'DELETE',
      path: path,
      body: body,
    );
    if (response.statusCode >= 400) {
      _throwFromResponse(response);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwFromResponse(response);
  }

  Never _throwFromResponse(http.Response response) {
    String message = 'Request failed';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message =
          body['message'] as String? ?? body['error'] as String? ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }
    throw ApiException(statusCode: response.statusCode, message: message);
  }
}
