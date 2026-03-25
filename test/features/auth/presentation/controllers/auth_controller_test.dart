import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/core/services/api_client.dart';
import 'package:sultan/features/auth/data/repositories/auth_repository.dart';
import 'package:sultan/features/auth/domain/models/login_request.dart';
import 'package:sultan/features/auth/domain/models/login_response.dart';
import 'package:sultan/features/auth/presentation/controllers/auth_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const LoginRequest(username: '', password: ''));
  });

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.setOnForceLogout(any())).thenAnswer((_) {});
  });

  ProviderContainer buildContainer() => ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
  );

  group('AuthController initial state', () {
    test('starts as AuthInitial', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(authControllerProvider), isA<AuthInitial>());
    });
  });

  group('AuthController.login', () {
    test('transitions to AuthAuthenticated on success', () async {
      when(() => mockRepo.login(any())).thenAnswer(
        (_) async =>
            const LoginResponse(accessToken: 'acc', refreshToken: 'ref'),
      );

      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('sultan', 'sultan');

      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    });

    test('sets AuthError with credential message on 401', () async {
      when(
        () => mockRepo.login(any()),
      ).thenThrow(const ApiException(statusCode: 401, message: 'Unauthorized'));

      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('bad', 'creds');

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, 'Invalid username or password.');
    });

    test('sets AuthError with connection message on SocketException', () async {
      when(
        () => mockRepo.login(any()),
      ).thenThrow(const SocketException('Connection refused'));

      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('sultan', 'sultan');

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthError>());
      expect(
        (state as AuthError).message,
        'Cannot connect to server. Check the server is running.',
      );
    });

    test('sets AuthError with generic message on unknown error', () async {
      when(
        () => mockRepo.login(any()),
      ).thenThrow(Exception('Unexpected failure'));

      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('sultan', 'sultan');

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthError>());
      expect(
        (state as AuthError).message,
        'An error occurred. Please try again.',
      );
    });

    test('passes through username and password to the repository', () async {
      when(() => mockRepo.login(any())).thenAnswer(
        (_) async => const LoginResponse(accessToken: 'a', refreshToken: 'r'),
      );

      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('myuser', 'mypass');

      final captured =
          verify(() => mockRepo.login(captureAny())).captured.single
              as LoginRequest;
      expect(captured.username, 'myuser');
      expect(captured.password, 'mypass');
    });
  });

  group('AuthController.logout', () {
    test('transitions to AuthUnauthenticated on success', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).logout();

      expect(
        container.read(authControllerProvider),
        isA<AuthUnauthenticated>(),
      );
    });

    test('calls repository logout exactly once', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).logout();

      verify(() => mockRepo.logout()).called(1);
    });
  });

  group('AuthController forced logout (token expiry)', () {
    test(
      'transitions to AuthUnauthenticated when repository fires onForceLogout',
      () {
        void Function()? capturedCallback;
        when(() => mockRepo.setOnForceLogout(any())).thenAnswer((inv) {
          capturedCallback = inv.positionalArguments[0] as void Function();
        });

        final container = buildContainer();
        addTearDown(container.dispose);

        // Reading the provider triggers build(), which calls setOnForceLogout
        container.read(authControllerProvider);

        expect(capturedCallback, isNotNull);

        // Simulate the repository firing the forced-logout callback
        capturedCallback!();

        expect(
          container.read(authControllerProvider),
          isA<AuthUnauthenticated>(),
        );
      },
    );
  });
}
