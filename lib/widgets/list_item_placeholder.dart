import 'package:flutter/material.dart';

class ProductListItemPlaceholder extends StatelessWidget {
  const ProductListItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Colors.grey.shade300;
    return ListTile(
      // --- Убираем leading, как и в реальном списке ---
      // leading: CircleAvatar(backgroundColor: color),
      title: Container(
        height: 16, // Примерная высота строки заголовка
        width: MediaQuery.of(context).size.width * 0.5, // Половина ширины
        color: color,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Container(
            height: 12, // Примерная высота строки подзаголовка
            width: MediaQuery.of(context).size.width * 0.7, // 70% ширины
            color: color,
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            width: MediaQuery.of(context).size.width * 0.4, // 40% ширины
            color: color,
          ),
        ],
      ),
      trailing: Container(
        height: 20,
        width: 60, // Примерная ширина цены
        color: color,
      ),
    );
  }
}

class SalesHistoryListItemPlaceholder extends StatelessWidget {
  const SalesHistoryListItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Colors.grey.shade300;
    return ListTile(
      leading: CircleAvatar(backgroundColor: color), // Оставляем кругляш для ID
      title: Container(height: 14, width: MediaQuery.of(context).size.width * 0.6, color: color),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Container(height: 10, width: MediaQuery.of(context).size.width * 0.7, color: color),
          const SizedBox(height: 4),
          Container(height: 10, width: MediaQuery.of(context).size.width * 0.5, color: color),
          const SizedBox(height: 4),
          Container(height: 10, width: MediaQuery.of(context).size.width * 0.4, color: color),
        ],
      ),
      isThreeLine: true,
      trailing: Icon(Icons.chevron_right, color: color),
    );
  }
}
