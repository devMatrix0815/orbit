import 'package:flutter/material.dart';
import '../constants/badges.dart';

// zeigt Badge-Icons neben einem Nutzernamen an
class UserBadgesRow extends StatelessWidget {
  final List<String> badges;
  final double size;

  const UserBadgesRow({super.key, required this.badges, this.size = 15});

  @override
  Widget build(BuildContext context) {
    final defs = badges.map((id) => kBadges[id]).whereType<BadgeDef>().toList();
    if (defs.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: defs
          .map(
            (def) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Tooltip(
                message: def.label,
                child: Icon(def.icon, size: size, color: def.color),
              ),
            ),
          )
          .toList(),
    );
  }
}

// Hilfsfunktion: Name + Badges als Row — für ListTile.title
Widget nameWithBadges(
  String name, {
  List<String> badges = const [],
  TextStyle? style,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(name, style: style, overflow: TextOverflow.ellipsis)),
      UserBadgesRow(badges: badges),
    ],
  );
}
