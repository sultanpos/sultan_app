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
}
