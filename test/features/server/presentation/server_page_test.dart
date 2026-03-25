import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/features/auth/data/repositories/auth_repository.dart';
import 'package:sultan/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sultan/features/server/presentation/server_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget _buildApp(MockAuthRepository mockRepo) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const ServerPage()),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login')),
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

  setUp(() {
    mockRepo = MockAuthRepository();
    // Silence the MethodChannel — MissingPluginException is caught in _checkStatus
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.sultan.android/server'),
          null,
        );
  });

  group('ServerPage rendering', () {
    testWidgets('shows app bar with title and logout button', (tester) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pump();

      expect(find.text('Sultan Server'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('shows Server Stopped state by default', (tester) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pump();

      expect(find.text('Server Stopped'), findsOneWidget);
      expect(find.text('Start Server'), findsOneWidget);
    });

    testWidgets('shows cloud_off icon when server is stopped', (tester) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });

  group('ServerPage MethodChannel — server running', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.sultan.android/server'),
            (call) async {
              if (call.method == 'isRunning') return true;
              if (call.method == 'start') return true;
              if (call.method == 'stop') return null;
              return null;
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.sultan.android/server'),
            null,
          );
    });

    testWidgets('shows Server Running after isRunning returns true', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Server Running'), findsOneWidget);
      expect(find.text('Stop Server'), findsOneWidget);
    });

    testWidgets('shows cloud_done icon when server is running', (tester) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('shows localhost URL when server is running', (tester) async {
      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('http://localhost:8721'), findsOneWidget);
    });
  });

  group('ServerPage logout', () {
    testWidgets('navigates to /login after logout', (tester) async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildApp(mockRepo));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });
  });
}
