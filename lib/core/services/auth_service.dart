import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  AuthService._();

  static final _instance = AuthService._();
  static AuthService get instance => _instance;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // Web uses in-memory fallback since flutter_secure_storage web support
  // requires additional setup.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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
}
