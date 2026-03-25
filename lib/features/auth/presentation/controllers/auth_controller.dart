import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sultan/core/services/api_client.dart';
import 'package:sultan/features/auth/data/repositories/auth_repository.dart';
import 'package:sultan/features/auth/domain/models/login_request.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Register forced-logout callback: when the refresh token expires,
    // the repository clears tokens and notifies us to go back to login.
    ref.read(authRepositoryProvider).setOnForceLogout(() {
      state = const AuthUnauthenticated();
    });
    return const AuthInitial();
  }

  Future<void> login(String username, String password) async {
    state = const AuthLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .login(LoginRequest(username: username, password: password));
      state = const AuthAuthenticated();
    } on ApiException catch (e) {
      state = AuthError(
        e.statusCode == 401 ? 'Invalid username or password.' : e.message,
      );
    } on SocketException {
      state = const AuthError(
        'Cannot connect to server. Check the server is running.',
      );
    } catch (_) {
      state = const AuthError('An error occurred. Please try again.');
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    await ref.read(authRepositoryProvider).logout();
    state = const AuthUnauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
