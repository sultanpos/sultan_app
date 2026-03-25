import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/core/constants/api_constants.dart';
import 'package:sultan/core/services/api_client.dart';
import 'package:sultan/core/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

MockAuthService _noAuthService() {
  final svc = MockAuthService();
  when(() => svc.getAccessToken()).thenAnswer((_) async => null);
  return svc;
}

ApiClient _buildClient({
  required int statusCode,
  Map<String, dynamic> responseBody = const {},
}) {
  final mockHttp = MockClient(
    (_) async => http.Response(jsonEncode(responseBody), statusCode),
  );
  return ApiClient.withHttpClient(mockHttp, authService: _noAuthService());
}

ApiClient _withFakeAuth(http.Client httpClient) =>
    ApiClient.withHttpClient(httpClient, authService: _noAuthService());

void main() {
  setUp(() => ApiConstants.setBaseUrl('http://localhost:8721'));

  group('ApiClient.post', () {
    test('returns parsed JSON on 200', () async {
      final client = _buildClient(
        statusCode: 200,
        responseBody: {'access_token': 'tok', 'refresh_token': 'ref'},
      );
      final result = await client.post('/api/auth', body: {'user': 'u'});
      expect(result['access_token'], 'tok');
      expect(result['refresh_token'], 'ref');
    });

    test('throws ApiException with statusCode 400', () {
      final client = _buildClient(
        statusCode: 400,
        responseBody: {'message': 'Bad request'},
      );
      expect(
        () => client.post('/api/auth', body: {}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('throws ApiException with statusCode 401', () {
      final client = _buildClient(
        statusCode: 401,
        responseBody: {'message': 'Unauthorized'},
      );
      expect(
        () => client.post('/api/auth', body: {}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('parses error message from response body', () {
      final client = _buildClient(
        statusCode: 500,
        responseBody: {'error': 'Internal server error'},
      );
      expect(
        () => client.post('/api/auth', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Internal server error',
          ),
        ),
      );
    });
  });

  group('ApiClient.get', () {
    test('returns parsed JSON on 200', () async {
      final client = _buildClient(statusCode: 200, responseBody: {'id': 1});
      final result = await client.get('/api/user');
      expect(result['id'], 1);
    });

    test('returns empty map on 200 with empty body', () async {
      final mockHttp = MockClient((_) async => http.Response('', 200));
      final client = _withFakeAuth(mockHttp);
      final result = await client.get('/api/user');
      expect(result, isEmpty);
    });

    test('passes query parameters in the URL', () async {
      Uri? capturedUri;
      final mockHttp = MockClient((request) async {
        capturedUri = request.url;
        return http.Response('{}', 200);
      });
      final client = _withFakeAuth(mockHttp);
      await client.get('/api/user', query: {'page': '2'});
      expect(capturedUri?.queryParameters['page'], '2');
    });
  });

  group('ApiClient.delete', () {
    test('does not throw on 204 No Content', () async {
      final mockHttp = MockClient((_) async => http.Response('', 204));
      final client = _withFakeAuth(mockHttp);
      await expectLater(client.delete('/api/auth', body: {}), completes);
    });

    test('throws ApiException on 400', () {
      final client = _buildClient(
        statusCode: 400,
        responseBody: {'message': 'Bad'},
      );
      expect(() => client.delete('/api/auth'), throwsA(isA<ApiException>()));
    });
  });

  group('ApiClient 401 retry', () {
    test('calls onUnauthorized and retries once on 401', () async {
      int callCount = 0;
      bool refreshCalled = false;

      final mockHttp = MockClient((_) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('{"message":"Unauthorized"}', 401);
        }
        return http.Response('{"id": 42}', 200);
      });

      final client = _withFakeAuth(mockHttp);
      client.setOnUnauthorized(() async {
        refreshCalled = true;
      });

      final result = await client.get('/api/user');

      expect(refreshCalled, isTrue);
      expect(callCount, 2);
      expect(result['id'], 42);
    });

    test('does not retry when onUnauthorized is not set', () async {
      int callCount = 0;
      final mockHttp = MockClient((_) async {
        callCount++;
        return http.Response('{"message":"Unauthorized"}', 401);
      });
      final client = _withFakeAuth(mockHttp);

      await expectLater(
        () => client.get('/api/user'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(callCount, 1);
    });
  });

  group('ApiException', () {
    test('toString includes statusCode and message', () {
      const e = ApiException(statusCode: 404, message: 'Not found');
      expect(e.toString(), 'ApiException(404): Not found');
    });
  });
}
