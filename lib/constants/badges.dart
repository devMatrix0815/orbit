import 'package:flutter/material.dart';

class BadgeDef {
  final IconData icon;
  final Color color;
  final String label;
  const BadgeDef({required this.icon, required this.color, required this.label});
}

const Map<String, BadgeDef> kBadges = {
  'developer': BadgeDef(
    icon: Icons.code,
    color: Color(0xFF5C6BC0),
    label: 'Entwickler',
  ),
  'Beta Tester': BadgeDef(
    icon: Icons.science,
    color: Color.fromARGB(255, 255, 0, 119),
    label: 'Beta Tester',
  ),
};
