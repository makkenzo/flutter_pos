import 'package:flutter/material.dart';
import 'package:flutter_pos/providers/login_provider.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_pos/utils/helpers/error_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  String? _lastError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _lastError = null;
    });

    ref.read(loginProvider.notifier).resetState();

    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      await ref.read(loginProvider.notifier).login(username, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(loginProvider, (previous, next) {
      if (!next.isLoading && next.hasError) {
        final errorMessage = formatErrorMessage(next.error);

        if (errorMessage != _lastError) {
          setState(() {
            _lastError = errorMessage;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (next is! AsyncError) {
        if (_lastError != null) {
          setState(() {
            _lastError = null;
          });
        }
      }
    });

    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: TSizes.xl * 1.5),
                    child: Icon(Icons.point_of_sale, size: 80, color: Theme.of(context).colorScheme.primary),
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Имя пользователя',
                      hintText: 'Введите ваше имя пользователя',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      hintText: 'Введите ваш пароль',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        tooltip: _isPasswordVisible ? 'Скрыть пароль' : 'Показать пароль',
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => isLoading ? null : _submitLogin(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите пароль';
                      }

                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  ElevatedButton.icon(
                    style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: TSizes.md - 2)),
                    ),
                    icon:
                        isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                            : const Icon(Icons.login, size: 22),
                    label: Text(isLoading ? 'ВХОД...' : 'ВОЙТИ'),

                    onPressed: isLoading ? null : _submitLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
