import 'package:sultan/core/constants/api_constants.dart';
import 'package:sultan/core/services/api_client.dart';
import 'package:sultan/core/services/auth_service.dart';
import 'package:sultan/features/auth/domain/models/login_request.dart';
import 'package:sultan/features/auth/domain/models/login_response.dart';

class AuthRepository {
  final ApiClient _client;
  final AuthService _authService;
  void Function()? _onForceLogout;

  AuthRepository({ApiClient? apiClient, AuthService? authService})
    : _client = apiClient ?? ApiClient.instance,
      _authService = authService ?? AuthService.instance {
    // Wire the 401 handler so the API client can silently refresh the token
    _client.setOnUnauthorized(_refresh);
  }

  void setOnForceLogout(void Function() callback) {
    _onForceLogout = callback;
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final json = await _client.post(
      ApiConstants.loginPath,
      body: request.toJson(),
    );
    final response = LoginResponse.fromJson(json);
    await _authService.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<void> _refresh() async {
    final refreshToken = await _authService.getRefreshToken();
    if (refreshToken == null) {
      await _authService.clearTokens();
      return;
    }
    try {
      final json = await _client.post(
        ApiConstants.refreshPath,
        body: {'refresh_token': refreshToken},
      );
      final response = LoginResponse.fromJson(json);
      await _authService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } catch (_) {
      await _authService.clearTokens();
      _onForceLogout?.call();
    }
  }

  Future<void> logout() async {
    final refreshToken = await _authService.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _client.delete(
          ApiConstants.logoutPath,
          body: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // Best-effort — clear locally regardless
      }
    }
    await _authService.clearTokens();
  }
}
