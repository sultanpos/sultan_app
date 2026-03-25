import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/features/configuration/data/configuration_service.dart';
import 'package:sultan/features/configuration/data/repositories/configuration_repository.dart';
import 'package:sultan/features/configuration/domain/models/app_configuration.dart';

class MockConfigurationService extends Mock implements ConfigurationService {}

void main() {
  late MockConfigurationService mockService;
  late ConfigurationRepository repo;

  setUp(() {
    mockService = MockConfigurationService();
    repo = ConfigurationRepository(service: mockService);
  });

  group('ConfigurationRepository.isConfigured', () {
    test('returns true when service returns true', () async {
      when(() => mockService.isConfigured()).thenAnswer((_) async => true);

      expect(await repo.isConfigured(), isTrue);
      verify(() => mockService.isConfigured()).called(1);
    });

    test('returns false when service returns false', () async {
      when(() => mockService.isConfigured()).thenAnswer((_) async => false);

      expect(await repo.isConfigured(), isFalse);
    });
  });

  group('ConfigurationRepository.getConfiguration', () {
    test('returns configuration from service', () async {
      const config = AppConfiguration(
        mode: ServerMode.client,
        host: '10.0.0.1',
        port: 8080,
      );
      when(
        () => mockService.getConfiguration(),
      ).thenAnswer((_) async => config);

      final result = await repo.getConfiguration();

      expect(result, isNotNull);
      expect(result!.mode, ServerMode.client);
      expect(result.host, '10.0.0.1');
      expect(result.port, 8080);
    });

    test('returns null when not configured', () async {
      when(() => mockService.getConfiguration()).thenAnswer((_) async => null);

      expect(await repo.getConfiguration(), isNull);
    });
  });

  group('ConfigurationRepository.saveConfiguration', () {
    test('delegates to service', () async {
      const config = AppConfiguration(mode: ServerMode.standalone);
      when(
        () => mockService.saveConfiguration(config),
      ).thenAnswer((_) async {});

      await repo.saveConfiguration(config);

      verify(() => mockService.saveConfiguration(config)).called(1);
    });
  });

  group('ConfigurationRepository.clearConfiguration', () {
    test('delegates to service', () async {
      when(() => mockService.clearConfiguration()).thenAnswer((_) async {});

      await repo.clearConfiguration();

      verify(() => mockService.clearConfiguration()).called(1);
    });
  });
}
