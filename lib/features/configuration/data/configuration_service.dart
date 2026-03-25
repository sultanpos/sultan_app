import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sultan/features/configuration/domain/models/app_configuration.dart';

class ConfigurationService {
  ConfigurationService._([SharedPreferences? prefs]) : _prefs = prefs;

  static final _instance = ConfigurationService._();
  static ConfigurationService get instance => _instance;

  @visibleForTesting
  static ConfigurationService withPrefs(SharedPreferences prefs) =>
      ConfigurationService._(prefs);

  SharedPreferences? _prefs;
  static const _configKey = 'app_configuration';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> isConfigured() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_configKey);
  }

  Future<AppConfiguration?> getConfiguration() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_configKey);
    if (jsonStr == null) return null;
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AppConfiguration.fromJson(json);
  }

  Future<void> saveConfiguration(AppConfiguration config) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(config.toJson());
    await prefs.setString(_configKey, jsonStr);
  }

  Future<void> clearConfiguration() async {
    final prefs = await _getPrefs();
    await prefs.remove(_configKey);
  }
}
