import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/core/services/api_client.dart';
import 'package:sultan/core/services/auth_service.dart';
import 'package:sultan/core/constants/api_constants.dart';
import 'package:sultan/features/auth/data/repositories/auth_repository.dart';
import 'package:sultan/features/auth/domain/models/login_request.dart';
import 'package:sultan/features/auth/domain/models/login_response.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockApiClient mockClient;
  late MockAuthService mockAuthService;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockApiClient();
    mockAuthService = MockAuthService();
    // setOnUnauthorized is a void method — mocktail stubs void calls automatically
    repo = AuthRepository(apiClient: mockClient, authService: mockAuthService);
  });

  setUpAll(() {
    registerFallbackValue(const LoginRequest(username: '', password: ''));
  });

  group('AuthRepository.login', () {
    test('calls post, saves tokens, and returns LoginResponse', () async {
      when(
        () => mockClient.post(ApiConstants.loginPath, body: any(named: 'body')),
      ).thenAnswer(
        (_) async => {'access_token': 'acc123', 'refresh_token': 'ref456'},
      );
      when(
        () => mockAuthService.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      final response = await repo.login(
        const LoginRequest(username: 'sultan', password: 'sultan'),
      );

      expect(response.accessToken, 'acc123');
      expect(response.refreshToken, 'ref456');
      verify(
        () => mockAuthService.saveTokens(
          accessToken: 'acc123',
          refreshToken: 'ref456',
        ),
      ).called(1);
    });

    test('propagates ApiException from the API client', () async {
      when(
        () => mockClient.post(any(), body: any(named: 'body')),
      ).thenThrow(const ApiException(statusCode: 401, message: 'Unauthorized'));

      await expectLater(
        repo.login(const LoginRequest(username: 'bad', password: 'creds')),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('AuthRepository.logout', () {
    test('calls delete with refresh token and clears tokens', () async {
      when(
        () => mockAuthService.getRefreshToken(),
      ).thenAnswer((_) async => 'myRefreshToken');
      when(
        () => mockClient.delete(any(), body: any(named: 'body')),
      ).thenAnswer((_) async {});
      when(() => mockAuthService.clearTokens()).thenAnswer((_) async {});

      await repo.logout();

      verify(
        () => mockClient.delete(any(), body: any(named: 'body')),
      ).called(1);
      verify(() => mockAuthService.clearTokens()).called(1);
    });

    test('still clears tokens even when delete throws', () async {
      when(
        () => mockAuthService.getRefreshToken(),
      ).thenAnswer((_) async => 'myRefreshToken');
      when(
        () => mockClient.delete(any(), body: any(named: 'body')),
      ).thenThrow(Exception('Network error'));
      when(() => mockAuthService.clearTokens()).thenAnswer((_) async {});

      await repo.logout(); // should not rethrow

      verify(() => mockAuthService.clearTokens()).called(1);
    });

    test('skips delete call when refresh token is null', () async {
      when(
        () => mockAuthService.getRefreshToken(),
      ).thenAnswer((_) async => null);
      when(() => mockAuthService.clearTokens()).thenAnswer((_) async {});

      await repo.logout();

      verifyNever(() => mockClient.delete(any()));
      verify(() => mockAuthService.clearTokens()).called(1);
    });
  });

  group('AuthRepository token refresh (via ApiClient 401 callback)', () {
    test('refresh saves new tokens on success', () async {
      final freshClient = MockApiClient();
      final freshAuthService = MockAuthService();
      late Future<void> Function() capturedRefresh;

      // Stub setOnUnauthorized on freshClient BEFORE creating the repo
      // so the constructor call is captured.
      when(() => freshClient.setOnUnauthorized(any())).thenAnswer((inv) {
        capturedRefresh = inv.positionalArguments[0] as Future<void> Function();
      });

      AuthRepository(apiClient: freshClient, authService: freshAuthService);

      when(
        () => freshAuthService.getRefreshToken(),
      ).thenAnswer((_) async => 'oldRefresh');
      when(
        () => freshClient.post(
          ApiConstants.refreshPath,
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => {'access_token': 'newAcc', 'refresh_token': 'newRef'},
      );
      when(
        () => freshAuthService.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      await capturedRefresh();

      verify(
        () => freshAuthService.saveTokens(
          accessToken: 'newAcc',
          refreshToken: 'newRef',
        ),
      ).called(1);
    });

    test('refresh clears tokens when refresh token is null', () async {
      final freshClient = MockApiClient();
      final freshAuthService = MockAuthService();
      late Future<void> Function() capturedRefresh;

      when(() => freshClient.setOnUnauthorized(any())).thenAnswer((inv) {
        capturedRefresh = inv.positionalArguments[0] as Future<void> Function();
      });

      AuthRepository(apiClient: freshClient, authService: freshAuthService);

      when(
        () => freshAuthService.getRefreshToken(),
      ).thenAnswer((_) async => null);
      when(() => freshAuthService.clearTokens()).thenAnswer((_) async {});

      await capturedRefresh();

      verify(() => freshAuthService.clearTokens()).called(1);
    });
  });
}
