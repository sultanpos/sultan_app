import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/features/configuration/data/repositories/configuration_repository.dart';
import 'package:sultan/features/configuration/domain/models/app_configuration.dart';
import 'package:sultan/features/configuration/presentation/controllers/configuration_controller.dart';

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

  ProviderContainer buildContainer() => ProviderContainer(
    overrides: [configurationRepositoryProvider.overrideWithValue(mockRepo)],
  );

  group('ConfigurationController initial state', () {
    test('starts as ConfigurationInitial', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(
        container.read(configurationControllerProvider),
        isA<ConfigurationInitial>(),
      );
    });
  });

  group('ConfigurationController.save', () {
    test('transitions to ConfigurationSaved on success', () async {
      when(() => mockRepo.saveConfiguration(any())).thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      const config = AppConfiguration(mode: ServerMode.standalone);
      final result = await container
          .read(configurationControllerProvider.notifier)
          .save(config);

      expect(result, isTrue);
      final state = container.read(configurationControllerProvider);
      expect(state, isA<ConfigurationSaved>());
      expect(
        (state as ConfigurationSaved).configuration.mode,
        ServerMode.standalone,
      );
    });

    test('transitions to ConfigurationError on failure', () async {
      when(
        () => mockRepo.saveConfiguration(any()),
      ).thenThrow(Exception('disk full'));

      final container = buildContainer();
      addTearDown(container.dispose);

      const config = AppConfiguration(mode: ServerMode.standalone);
      final result = await container
          .read(configurationControllerProvider.notifier)
          .save(config);

      expect(result, isFalse);
      final state = container.read(configurationControllerProvider);
      expect(state, isA<ConfigurationError>());
      expect(
        (state as ConfigurationError).message,
        'Failed to save configuration. Please try again.',
      );
    });

    test('saves client config with host and port', () async {
      when(() => mockRepo.saveConfiguration(any())).thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      const config = AppConfiguration(
        mode: ServerMode.client,
        host: '192.168.1.10',
        port: 9000,
      );
      await container
          .read(configurationControllerProvider.notifier)
          .save(config);

      final captured =
          verify(() => mockRepo.saveConfiguration(captureAny())).captured.single
              as AppConfiguration;

      expect(captured.mode, ServerMode.client);
      expect(captured.host, '192.168.1.10');
      expect(captured.port, 9000);
    });

    test('returns true on success and false on failure', () async {
      when(() => mockRepo.saveConfiguration(any())).thenAnswer((_) async {});

      final container = buildContainer();
      addTearDown(container.dispose);

      const config = AppConfiguration(mode: ServerMode.standalone);
      expect(
        await container
            .read(configurationControllerProvider.notifier)
            .save(config),
        isTrue,
      );
    });
  });
}
