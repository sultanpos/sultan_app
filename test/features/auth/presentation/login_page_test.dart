import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/features/auth/data/repositories/auth_repository.dart';
import 'package:sultan/features/auth/domain/models/login_request.dart';
import 'package:sultan/features/auth/domain/models/login_response.dart';
import 'package:sultan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sultan/features/auth/presentation/login_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget _buildApp(MockAuthRepository mockRepo) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const LoginRequest(username: '', password: ''));
  });

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('LoginPage rendering', () {
    testWidgets('shows username and password fields', (tester) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    });

    testWidgets('shows Sign In button', (tester) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
    });
  });

  group('LoginPage form validation', () {
    testWidgets('shows validation errors when submitted empty', (tester) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows username error only when password is filled', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'secret',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsNothing);
    });
  });

  group('LoginPage loading state', () {
    testWidgets('shows spinner while login is in progress', (tester) async {
      final completer = Completer<LoginResponse>();
      when(() => mockRepo.login(any())).thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'sultan',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'sultan',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump(); // trigger state update to AuthLoading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign In'), findsNothing);

      // Resolve the future so the test can settle cleanly
      completer.complete(
        const LoginResponse(accessToken: 'tok', refreshToken: 'ref'),
      );
      await tester.pumpAndSettle();
    });
  });

  group('LoginPage error display', () {
    testWidgets('shows error banner on failed login', (tester) async {
      when(
        () => mockRepo.login(any()),
      ).thenAnswer((_) async => throw Exception('401 Unauthorized'));

      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'bad',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'creds',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid username or password.'), findsOneWidget);
    });
  });

  group('LoginPage navigation', () {
    testWidgets('navigates to /home after successful login', (tester) async {
      when(() => mockRepo.login(any())).thenAnswer(
        (_) async =>
            const LoginResponse(accessToken: 'tok', refreshToken: 'ref'),
      );

      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'sultan',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'sultan',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}
