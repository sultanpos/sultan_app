import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sultan/features/configuration/data/configuration_service.dart';
import 'package:sultan/features/configuration/domain/models/app_configuration.dart';

class ConfigurationRepository {
  ConfigurationRepository({ConfigurationService? service})
    : _service = service ?? ConfigurationService.instance;

  final ConfigurationService _service;

  Future<bool> isConfigured() => _service.isConfigured();

  Future<AppConfiguration?> getConfiguration() => _service.getConfiguration();

  Future<void> saveConfiguration(AppConfiguration config) =>
      _service.saveConfiguration(config);

  Future<void> clearConfiguration() => _service.clearConfiguration();
}

final configurationRepositoryProvider = Provider<ConfigurationRepository>(
  (_) => ConfigurationRepository(),
);
