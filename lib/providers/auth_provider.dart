import 'package:flutter_pos/providers/api_provider.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:flutter_pos/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

@immutable
class AuthState {
  final AuthStatus status;
  final String? token;

  const AuthState._({required this.status, this.token});

  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticated({required String token}) : this._(status: AuthStatus.authenticated, token: token);

  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState && runtimeType == other.runtimeType && status == other.status && token == other.token;

  @override
  int get hashCode => status.hashCode ^ token.hashCode;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider), StorageService(), ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;
  final Ref _ref;

  AuthNotifier(this._apiService, this._storageService, this._ref) : super(const AuthState.unknown()) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    print("AuthNotifier: Checking for stored token...");
    try {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        print("AuthNotifier: Found stored token.");

        /*
        try {
          
          
           print("AuthNotifier: Token appears valid (или проверка прошла успешно).");
           state = AuthState.authenticated(token: token);
        } on UnauthorizedException {
           print("AuthNotifier: Stored token is invalid or expired.");
           await _storageService.deleteToken();
           state = const AuthState.unauthenticated();
        } catch (e) {
          
           print("AuthNotifier: Error validating token: $e. Assuming unauthenticated for now.");
          
          
           state = const AuthState.unauthenticated();
        }
        */

        state = AuthState.authenticated(token: token);
      } else {
        print("AuthNotifier: No stored token found.");
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      print("AuthNotifier: Error reading token from storage: $e");
      state = const AuthState.unauthenticated();
    }
  }

  void loginSuccess(String token) {
    print("AuthNotifier: Login successful. Updating state to authenticated.");

    state = AuthState.authenticated(token: token);
  }

  Future<void> logout() async {
    print("AuthNotifier: Logging out...");
    try {
      await _apiService.logout();
    } catch (e) {
      print("AuthNotifier: Error during API logout call (ignoring): $e");

      try {
        await _storageService.deleteToken();
      } catch (storageError) {
        print("AuthNotifier: Error deleting token from storage during logout: $storageError");
      }
    } finally {
      state = const AuthState.unauthenticated();
      print("AuthNotifier: State set to unauthenticated.");
    }
  }
}
