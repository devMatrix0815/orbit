import 'package:flutter/material.dart';

class BadgeDef {
  final IconData icon;
  final Color color;
  final String label;
  const BadgeDef({required this.icon, required this.color, required this.label});
}

// Badge-Definitionen — neue Badges hier eintragen, Firestore-Feld: badges: ['developer']
const Map<String, BadgeDef> kBadges = {
  'developer': BadgeDef(
    icon: Icons.code,
    color: Color(0xFF5C6BC0),
    label: 'Entwickler',
  ),
};
