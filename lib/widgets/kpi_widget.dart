import 'package:flutter/material.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';

class KpiWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const KpiWidget({super.key, required this.title, required this.value, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.sm),
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по левому краю
        mainAxisSize: MainAxisSize.min, // Занимать минимум места
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: TSizes.iconMd, // Стандартный размер
              color: iconColor ?? theme.colorScheme.primary, // Основной цвет или заданный
            ),
            const SizedBox(height: TSizes.xs),
          ],
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TSizes.xs / 2),
          Text(title, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
