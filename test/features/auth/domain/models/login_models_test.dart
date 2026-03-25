import 'package:flutter_test/flutter_test.dart';
import 'package:sultan/features/auth/domain/models/login_request.dart';
import 'package:sultan/features/auth/domain/models/login_response.dart';

void main() {
  group('LoginRequest', () {
    test('toJson returns correct map', () {
      const request = LoginRequest(username: 'sultan', password: 'secret');
      expect(request.toJson(), {'username': 'sultan', 'password': 'secret'});
    });

    test('toJson does not include extra keys', () {
      const request = LoginRequest(username: 'a', password: 'b');
      expect(request.toJson().length, 2);
    });
  });

  group('LoginResponse', () {
    test('fromJson parses access_token and refresh_token', () {
      final response = LoginResponse.fromJson({
        'access_token': 'abc123',
        'refresh_token': 'xyz789',
      });
      expect(response.accessToken, 'abc123');
      expect(response.refreshToken, 'xyz789');
    });

    test('fromJson throws when access_token is missing', () {
      expect(
        () => LoginResponse.fromJson({'refresh_token': 'xyz'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson throws when refresh_token is missing', () {
      expect(
        () => LoginResponse.fromJson({'access_token': 'abc'}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
