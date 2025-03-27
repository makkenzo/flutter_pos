import 'package:flutter/material.dart';
import 'package:flutter_pos/screens/products/product_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter POS',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const ProductListScreen(),
    );
  }
}
