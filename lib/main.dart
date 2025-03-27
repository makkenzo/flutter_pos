import 'package:flutter/material.dart';
import 'package:flutter_pos/screens/products/product_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos/database/database.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru_RU', null);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter POS',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ProductListScreen(),
    );
  }
}
