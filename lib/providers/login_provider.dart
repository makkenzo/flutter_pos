import 'package:flutter_pos/providers/api_provider.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginProvider = StateNotifierProvider.autoDispose<LoginNotifier, AsyncValue<void>>((ref) {
  return LoginNotifier(ref);
});

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  LoginNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    if (state.isLoading) {
      return;
    }

    state = const AsyncValue.loading();

    try {
      final apiService = _ref.read(apiServiceProvider);

      final token = await apiService.login(email, password);

      _ref.read(authProvider.notifier).loginSuccess(token);

      state = const AsyncValue.data(null);
    } on UnauthorizedException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void resetState() {
    if (!state.isLoading) {
      state = const AsyncValue.data(null);
    }
  }
}
