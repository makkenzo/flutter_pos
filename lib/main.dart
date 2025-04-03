import 'package:flutter/material.dart';
import 'package:flutter_pos/models/app_settings.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/providers/settings_provider.dart';
import 'package:flutter_pos/screens/dashboard_screen.dart';
import 'package:flutter_pos/screens/login/login_screen.dart';

import 'package:flutter_pos/screens/splash_screen.dart';
import 'package:flutter_pos/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru_RU', null);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authProvider);
    final AppSettings settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Mini-POS',
      themeMode: settings.themeMode,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: _buildHome(authState.status),
    );
  }

  Widget _buildHome(AuthStatus status) {
    switch (status) {
      case AuthStatus.authenticated:
        return const DashboardScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.unknown:
        return const SplashScreen();
    }
  }
}
