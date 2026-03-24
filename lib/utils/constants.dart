import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AppCategories {
  static const List<String> names = [
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Entertainment',
    'Bills',
    'Other',
  ];

  static const Map<String, IconData> icons = {
    'Food': Iconsax.cup,
    'Transport': Iconsax.car,
    'Shopping': Iconsax.bag,
    'Health': Iconsax.health,
    'Entertainment': Iconsax.game,
    'Bills': Iconsax.document_text,
    'Other': Iconsax.category,
  };

  static const Map<String, Color> colors = {
    'Food': Color(0xFF4CAF50),
    'Transport': Color(0xFF2196F3),
    'Shopping': Color(0xFFFF9800),
    'Health': Color(0xFFE91E63),
    'Entertainment': Color(0xFF9C27B0),
    'Bills': Color(0xFFFF5722),
    'Other': Color(0xFF607D8B),
  };

  static IconData getIcon(String category) =>
      icons[category] ?? Iconsax.category;

  static Color getColor(String category) =>
      colors[category] ?? const Color(0xFF607D8B);
}