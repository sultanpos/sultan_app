import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/login_request.dart';

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
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = AuthRepository();
    return const AuthInitial();
  }

  Future<void> login(String username, String password) async {
    state = const AuthLoading();
    try {
      await _repository.login(
        LoginRequest(username: username, password: password),
      );
      state = const AuthAuthenticated();
    } catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Invalid username or password.';
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Cannot connect to server. Check the server is running.';
    }
    return 'An error occurred. Please try again.';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
