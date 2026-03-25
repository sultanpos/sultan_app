import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  AuthService._([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static final _instance = AuthService._();
  static AuthService get instance => _instance;

  /// Creates a non-singleton instance with an injected [FlutterSecureStorage].
  /// Use only in tests.
  @visibleForTesting
  static AuthService withStorage(FlutterSecureStorage storage) =>
      AuthService._(storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _jwtSecretKey = 'jwt_secret';

  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      _memoryFallback[_accessTokenKey] = accessToken;
      _memoryFallback[_refreshTokenKey] = refreshToken;
      return;
    }
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return _memoryFallback[_accessTokenKey];
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return _memoryFallback[_refreshTokenKey];
    return _storage.read(key: _refreshTokenKey);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      _memoryFallback.remove(_accessTokenKey);
      _memoryFallback.remove(_refreshTokenKey);
      return;
    }
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Returns the persisted JWT secret, or generates and persists a new one.
  Future<String> getOrCreateJwtSecret() async {
    final existing = kIsWeb
        ? _memoryFallback[_jwtSecretKey]
        : await _storage.read(key: _jwtSecretKey);

    if (existing != null && existing.isNotEmpty) return existing;

    // Generate a 32-byte (256-bit) cryptographically random secret.
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final secret = base64UrlEncode(bytes);

    if (kIsWeb) {
      _memoryFallback[_jwtSecretKey] = secret;
    } else {
      await _storage.write(key: _jwtSecretKey, value: secret);
    }
    return secret;
  }
}
