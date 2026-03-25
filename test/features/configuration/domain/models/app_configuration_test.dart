import 'package:flutter_test/flutter_test.dart';
import 'package:sultan/features/configuration/domain/models/app_configuration.dart';

void main() {
  group('AppConfiguration.fromJson', () {
    test('parses standalone mode', () {
      final config = AppConfiguration.fromJson({'mode': 'standalone'});

      expect(config.mode, ServerMode.standalone);
      expect(config.host, isNull);
      expect(config.port, isNull);
    });

    test('parses client mode with host and port', () {
      final config = AppConfiguration.fromJson({
        'mode': 'client',
        'host': '192.168.1.100',
        'port': 9000,
      });

      expect(config.mode, ServerMode.client);
      expect(config.host, '192.168.1.100');
      expect(config.port, 9000);
    });

    test('parses client mode with missing optional fields', () {
      final config = AppConfiguration.fromJson({'mode': 'client'});

      expect(config.mode, ServerMode.client);
      expect(config.host, isNull);
      expect(config.port, isNull);
    });
  });

  group('AppConfiguration.toJson', () {
    test('serializes standalone mode without host and port', () {
      const config = AppConfiguration(mode: ServerMode.standalone);
      final json = config.toJson();

      expect(json, {'mode': 'standalone'});
      expect(json.containsKey('host'), isFalse);
      expect(json.containsKey('port'), isFalse);
    });

    test('serializes client mode with host and port', () {
      const config = AppConfiguration(
        mode: ServerMode.client,
        host: '10.0.0.5',
        port: 8080,
      );

      expect(config.toJson(), {
        'mode': 'client',
        'host': '10.0.0.5',
        'port': 8080,
      });
    });
  });

  group('AppConfiguration.fromJson/toJson round-trip', () {
    test('standalone round-trips correctly', () {
      const original = AppConfiguration(mode: ServerMode.standalone);
      final restored = AppConfiguration.fromJson(original.toJson());

      expect(restored.mode, original.mode);
      expect(restored.host, original.host);
      expect(restored.port, original.port);
    });

    test('client round-trips correctly', () {
      const original = AppConfiguration(
        mode: ServerMode.client,
        host: '172.16.0.1',
        port: 3000,
      );
      final restored = AppConfiguration.fromJson(original.toJson());

      expect(restored.mode, original.mode);
      expect(restored.host, original.host);
      expect(restored.port, original.port);
    });
  });

  group('AppConfiguration.baseUrl', () {
    test('returns localhost:8721 for standalone mode', () {
      const config = AppConfiguration(mode: ServerMode.standalone);

      expect(config.baseUrl, 'http://localhost:8721');
    });

    test('returns host:port for client mode', () {
      const config = AppConfiguration(
        mode: ServerMode.client,
        host: '192.168.1.50',
        port: 9090,
      );

      expect(config.baseUrl, 'http://192.168.1.50:9090');
    });
  });
}
