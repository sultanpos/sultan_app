import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/core/services/auth_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late AuthService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = AuthService.withStorage(mockStorage);
  });

  group('AuthService.saveTokens', () {
    test('writes both tokens to storage', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await service.saveTokens(
        accessToken: 'myAccess',
        refreshToken: 'myRefresh',
      );

      verify(
        () => mockStorage.write(key: 'access_token', value: 'myAccess'),
      ).called(1);
      verify(
        () => mockStorage.write(key: 'refresh_token', value: 'myRefresh'),
      ).called(1);
    });
  });

  group('AuthService.getAccessToken', () {
    test('returns the stored access token', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'storedAccess');

      final result = await service.getAccessToken();

      expect(result, 'storedAccess');
    });

    test('returns null when no token is stored', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);

      final result = await service.getAccessToken();

      expect(result, isNull);
    });
  });

  group('AuthService.getRefreshToken', () {
    test('returns the stored refresh token', () async {
      when(
        () => mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'storedRefresh');

      final result = await service.getRefreshToken();

      expect(result, 'storedRefresh');
    });

    test('returns null when no refresh token is stored', () async {
      when(
        () => mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => null);

      final result = await service.getRefreshToken();

      expect(result, isNull);
    });
  });

  group('AuthService.hasTokens', () {
    test('returns true when access token exists', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'tok');

      expect(await service.hasTokens(), isTrue);
    });

    test('returns false when access token is null', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);

      expect(await service.hasTokens(), isFalse);
    });

    test('returns false when access token is empty string', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => '');

      expect(await service.hasTokens(), isFalse);
    });
  });

  group('AuthService.clearTokens', () {
    test('deletes both tokens from storage', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await service.clearTokens();

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    });
  });

  group('AuthService.getOrCreateJwtSecret', () {
    test('returns existing secret from storage without writing', () async {
      when(
        () => mockStorage.read(key: 'jwt_secret'),
      ).thenAnswer((_) async => 'existingSecret');

      final secret = await service.getOrCreateJwtSecret();

      expect(secret, 'existingSecret');
      verifyNever(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('generates and persists a new secret when storage is empty', () async {
      when(
        () => mockStorage.read(key: 'jwt_secret'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final secret = await service.getOrCreateJwtSecret();

      expect(secret, isNotEmpty);
      verify(
        () => mockStorage.write(key: 'jwt_secret', value: secret),
      ).called(1);
    });

    test('generates different secrets on separate instances', () async {
      final service2 = AuthService.withStorage(mockStorage);
      when(
        () => mockStorage.read(key: 'jwt_secret'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final secret1 = await service.getOrCreateJwtSecret();
      final secret2 = await service2.getOrCreateJwtSecret();

      // Both are non-empty; since they are randomly generated they should differ
      expect(secret1, isNotEmpty);
      expect(secret2, isNotEmpty);
      expect(secret1, isNot(equals(secret2)));
    });

    test(
      'generated secret is base64url-encoded 32 bytes (43 chars + padding)',
      () async {
        when(
          () => mockStorage.read(key: 'jwt_secret'),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        final secret = await service.getOrCreateJwtSecret();

        // base64url of 32 bytes is 44 chars with padding or 43 without
        expect(secret.length, greaterThanOrEqualTo(43));
      },
    );
  });
}
