import 'dart:convert';
import 'dart:io';
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
  ApiClient._();

  static final _instance = ApiClient._();
  static ApiClient get instance => _instance;

  final _client = http.Client();

  // Called by the auth repository to inject a refresh callback after init,
  // avoiding a circular dependency.
  Future<void> Function()? _onUnauthorized;

  void setOnUnauthorized(Future<void> Function() callback) {
    _onUnauthorized = callback;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getAccessToken();
    return {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<http.Response> _send(Future<http.Response> Function() fn) async {
    var response = await fn();
    if (response.statusCode == 401 && _onUnauthorized != null) {
      await _onUnauthorized!();
      // Retry once with the fresh token
      response = await fn();
    }
    return response;
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
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final response = await _send(
      () async => _client.post(
        ApiConstants.uri(path),
        headers: await _authHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ),
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
