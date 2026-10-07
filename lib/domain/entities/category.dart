import 'package:flutter/material.dart';

/// Spending categories with associated colors and icons.
enum Category {
  food(
    label: 'Food',
    icon: Icons.restaurant,
    color: Color(0xFFFF6B6B),
  ),
  study(
    label: 'Study',
    icon: Icons.menu_book,
    color: Color(0xFF4ECDC4),
  ),
  travel(
    label: 'Travel',
    icon: Icons.directions_bus,
    color: Color(0xFF45B7D1),
  ),
  gear(
    label: 'Gear',
    icon: Icons.devices,
    color: Color(0xFFFFA07A),
  ),
  entertainment(
    label: 'Entertainment',
    icon: Icons.movie,
    color: Color(0xFFDDA0DD),
  ),
  other(
    label: 'Other',
    icon: Icons.more_horiz,
    color: Color(0xFF95A5A6),
  );

  const Category({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  /// Human-friendly display name.
  String get displayName => label;

  /// Parse from a stored string, defaulting to [other].
  static Category fromString(String value) {
    return Category.values.firstWhere(
      (c) => c.name == value,
      orElse: () => Category.other,
    );
  }
}
