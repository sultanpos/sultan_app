import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sultan/features/configuration/data/repositories/configuration_repository.dart';
import 'package:sultan/features/configuration/domain/models/app_configuration.dart';

sealed class ConfigurationState {
  const ConfigurationState();
}

class ConfigurationInitial extends ConfigurationState {
  const ConfigurationInitial();
}

class ConfigurationLoading extends ConfigurationState {
  const ConfigurationLoading();
}

class ConfigurationSaved extends ConfigurationState {
  final AppConfiguration configuration;
  const ConfigurationSaved(this.configuration);
}

class ConfigurationError extends ConfigurationState {
  final String message;
  const ConfigurationError(this.message);
}

class ConfigurationController extends Notifier<ConfigurationState> {
  @override
  ConfigurationState build() => const ConfigurationInitial();

  Future<bool> save(AppConfiguration config) async {
    state = const ConfigurationLoading();
    try {
      await ref.read(configurationRepositoryProvider).saveConfiguration(config);
      state = ConfigurationSaved(config);
      return true;
    } catch (_) {
      state = const ConfigurationError(
        'Failed to save configuration. Please try again.',
      );
      return false;
    }
  }
}

final configurationControllerProvider =
    NotifierProvider<ConfigurationController, ConfigurationState>(
      ConfigurationController.new,
    );
