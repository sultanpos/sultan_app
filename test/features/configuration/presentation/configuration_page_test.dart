import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/features/configuration/data/repositories/configuration_repository.dart';
import 'package:sultan/features/configuration/domain/models/app_configuration.dart';
import 'package:sultan/features/configuration/presentation/configuration_page.dart';

class MockConfigurationRepository extends Mock
    implements ConfigurationRepository {}

void main() {
  late MockConfigurationRepository mockRepo;

  setUp(() {
    mockRepo = MockConfigurationRepository();
  });

  setUpAll(() {
    registerFallbackValue(const AppConfiguration(mode: ServerMode.standalone));
  });

  Widget buildPage() {
    final router = GoRouter(
      initialLocation: '/configuration',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Splash')),
        ),
        GoRoute(
          path: '/configuration',
          builder: (context, state) => const ConfigurationPage(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [configurationRepositoryProvider.overrideWithValue(mockRepo)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ConfigurationPage layout', () {
    testWidgets('renders title and mode cards', (tester) async {
      await tester.pumpWidget(buildPage());

      expect(find.text('Server Configuration'), findsOneWidget);
      expect(find.text('Standalone'), findsOneWidget);
      expect(find.text('Client'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('standalone is selected by default', (tester) async {
      await tester.pumpWidget(buildPage());

      // Check icon is visible (standalone selected shows check)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // IP and Port fields are not visible
      expect(find.text('Server IP Address'), findsNothing);
      expect(find.text('Port'), findsNothing);
    });

    testWidgets('shows IP and Port fields when Client is selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Client'));
      await tester.pumpAndSettle();

      expect(find.text('Server IP Address'), findsOneWidget);
      expect(find.text('Port'), findsOneWidget);
    });

    testWidgets('hides IP and Port fields when switching back to Standalone', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Client'));
      await tester.pumpAndSettle();
      expect(find.text('Server IP Address'), findsOneWidget);

      await tester.tap(find.text('Standalone'));
      await tester.pumpAndSettle();
      expect(find.text('Server IP Address'), findsNothing);
    });
  });

  group('ConfigurationPage validation', () {
    testWidgets('shows error when IP address is empty in client mode', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Client'));
      await tester.pumpAndSettle();

      // Clear the port so only IP is the issue
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port'),
        '8721',
      );

      // Clear the IP field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Server IP Address'),
        '',
      );

      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('IP address is required'), findsOneWidget);
    });

    testWidgets('shows error when port is empty in client mode', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Client'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Server IP Address'),
        '192.168.1.1',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Port'), '');

      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Port is required'), findsOneWidget);
    });

    testWidgets('shows error for invalid port', (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Client'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Server IP Address'),
        '192.168.1.1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port'),
        '99999',
      );

      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid port (1–65535)'), findsOneWidget);
    });
  });

  group('ConfigurationPage save', () {
    testWidgets('saves standalone config on Continue tap', (tester) async {
      when(() => mockRepo.saveConfiguration(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final captured =
          verify(() => mockRepo.saveConfiguration(captureAny())).captured.single
              as AppConfiguration;

      expect(captured.mode, ServerMode.standalone);
      expect(captured.host, isNull);
      expect(captured.port, isNull);
    });

    testWidgets('saves client config with entered host and port', (
      tester,
    ) async {
      when(() => mockRepo.saveConfiguration(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Client'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Server IP Address'),
        '10.0.0.5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Port'),
        '9000',
      );

      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final captured =
          verify(() => mockRepo.saveConfiguration(captureAny())).captured.single
              as AppConfiguration;

      expect(captured.mode, ServerMode.client);
      expect(captured.host, '10.0.0.5');
      expect(captured.port, 9000);
    });

    testWidgets('shows error message when save fails', (tester) async {
      when(
        () => mockRepo.saveConfiguration(any()),
      ).thenThrow(Exception('write error'));

      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to save configuration. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('does not save when client validation fails', (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Client'));
      await tester.pumpAndSettle();

      // Leave fields empty
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Server IP Address'),
        '',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Port'), '');

      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepo.saveConfiguration(any()));
    });
  });
}
